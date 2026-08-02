{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

unit Converter.Parser.DFM;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  System.Generics.Defaults,
  System.RTTI, System.TypInfo, System.IOUtils, System.Math,
  System.RegularExpressions, System.StrUtils,
  Converter.Core.Types, Converter.Mapper.Component;

type
  TDFMComponent = class
  private
    FName: string;
    FComponentClass: string;
    FParent: string;
    FParentComponent: TDFMComponent;
    FProperties: TDictionary<string, string>;
    FEvents: TDictionary<string, string>;
    FPropertyLines: TDictionary<string, Integer>;
    FEventLines: TDictionary<string, Integer>;
    FChildren: TObjectList<TDFMComponent>;
    FOriginalLine: Integer;
    FIsSubComponent: Boolean;
    FSubComponentType: string;
    FObjectName: string;
    FObjectClass: string;
    FIsCollection: Boolean;
    FCollectionItems: TObjectList<TDFMComponent>;
  public
    property Name: string read FName write FName;
    property ComponentClass: string read FComponentClass write FComponentClass;
    property Parent: string read FParent write FParent;
    property ParentComponent: TDFMComponent read FParentComponent;
    property Properties: TDictionary<string, string> read FProperties;
    property Events: TDictionary<string, string> read FEvents;
    property Children: TObjectList<TDFMComponent> read FChildren;
    property OriginalLine: Integer read FOriginalLine write FOriginalLine;
    property IsSubComponent: Boolean read FIsSubComponent write FIsSubComponent;
    property SubComponentType: string read FSubComponentType write FSubComponentType;
    property ObjectName: string read FObjectName write FObjectName;
    property ObjectClass: string read FObjectClass write FObjectClass;
    property IsCollection: Boolean read FIsCollection write FIsCollection;
    property CollectionItems: TObjectList<TDFMComponent> read FCollectionItems;

    constructor Create;
    destructor Destroy; override;

    function HasProperty(const PropName: string): Boolean;
    function GetPropertyValue(const PropName: string; const Default: string = ''): string;
    procedure SetPropertyValue(const PropName, Value: string);
    procedure SetPropertyLine(const PropName: string; ALine: Integer);
    procedure SetEventLine(const EventName: string; ALine: Integer);
    function GetPropertyLine(const PropName: string): Integer;
    function GetEventLine(const EventName: string): Integer;
    procedure AddChild(Child: TDFMComponent);
    procedure AddCollectionItem(Item: TDFMComponent);
  end;

  TDFMParser = class
  private
    FContext: TConversionContext;
    FComponents: TObjectList<TDFMComponent>;
    FCurrentComponent: TDFMComponent;
    FInObject: Boolean;
    FLineNumber: Integer;
    FSourceLines: TStringList;
    FIndentStack: TStack<Integer>;
    FRecursionDepth: Integer;
    FCurrentCollection: TDFMComponent;
    const MAX_RECURSION_DEPTH = 100;

    function IsBinaryDFM(const AFileName: string): Boolean;
    function ConvertBinaryToText(const AFileName: string): string;
    function ParseObjectDeclaration(const Line: string): Boolean;
    function ParseProperty(var LineIndex: Integer; const Line: string): Boolean;
    function ParseEnd(const Line: string): Boolean;
    procedure ExtractNameAndClass(const ObjText: string; var ObjName, ObjClass: string);
    function CleanPropertyValue(const Value: string): string;
    function GetIndentLevel(const Line: string): Integer;
    function IsSubComponentDeclaration(const Line: string): Boolean;
    function IsCollectionDeclaration(const Line: string): Boolean;
    function CountChar(const Text: string; Ch: Char): Integer;
    function ReadMultiLinePropertyValue(var LineIndex: Integer;
      const InitialValue: string): string;
    function IsStringContinuationLine(const Line: string): Boolean;
    function DecodeStringExpression(const Expr: string): string;
    procedure ParseSubComponent(const Line: string);
    procedure ParseCollection(const Line: string);
    function ExtractSubComponentType(const Line: string): string;
    function SafeFindComponent(const AName: string): TDFMComponent;
    procedure SafeAddChild(Parent, Child: TDFMComponent);
    function NormalizePath(const Value: string): string;
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    function LoadDFM(const AFileName: string): string;
    procedure Parse(const DFMContent: string);
    function Convert(AMapper: TComponentMapper = nil): string;
    function FindComponent(const AName: string): TDFMComponent;
    property Components: TObjectList<TDFMComponent> read FComponents;
  end;

function IsStringCollectionPropertyName(const PropName: string): Boolean;

implementation

uses
  Converter.Generator.FMX;

function IsStringCollectionPropertyName(const PropName: string): Boolean;
begin
  Result := EndsText('.Strings', Trim(PropName));
end;

{ TDFMComponent }

constructor TDFMComponent.Create;
begin
  inherited Create;
  FProperties := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  FEvents := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  FPropertyLines := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  FEventLines := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  FChildren := TObjectList<TDFMComponent>.Create(True);
  FCollectionItems := TObjectList<TDFMComponent>.Create(True);
  FIsSubComponent := False;
  FSubComponentType := '';
  FObjectName := '';
  FObjectClass := '';
  FIsCollection := False;
end;

destructor TDFMComponent.Destroy;
begin
  FProperties.Free;
  FEvents.Free;
  FPropertyLines.Free;
  FEventLines.Free;
  FChildren.Free;
  FCollectionItems.Free;
  inherited;
end;

function TDFMComponent.HasProperty(const PropName: string): Boolean;
begin
  Result := FProperties.ContainsKey(PropName);
end;

function TDFMComponent.GetPropertyValue(const PropName: string; const Default: string = ''): string;
begin
  if not FProperties.TryGetValue(PropName, Result) then
    Result := Default;
end;

procedure TDFMComponent.SetPropertyValue(const PropName, Value: string);
begin
  FProperties.AddOrSetValue(PropName, Value);
end;

procedure TDFMComponent.SetPropertyLine(const PropName: string; ALine: Integer);
begin
  FPropertyLines.AddOrSetValue(PropName, ALine);
end;

procedure TDFMComponent.SetEventLine(const EventName: string; ALine: Integer);
begin
  FEventLines.AddOrSetValue(EventName, ALine);
end;

function TDFMComponent.GetPropertyLine(const PropName: string): Integer;
begin
  if not FPropertyLines.TryGetValue(PropName, Result) then
    Result := FOriginalLine;
end;

function TDFMComponent.GetEventLine(const EventName: string): Integer;
begin
  if not FEventLines.TryGetValue(EventName, Result) then
    Result := FOriginalLine;
end;

procedure TDFMComponent.AddChild(Child: TDFMComponent);
begin
  if (Child <> nil) and (FChildren <> nil) then
  begin
    FChildren.Add(Child);
    Child.FParent := FName;
    Child.FParentComponent := Self;
  end;
end;

procedure TDFMComponent.AddCollectionItem(Item: TDFMComponent);
begin
  if (Item <> nil) and (FCollectionItems <> nil) then
  begin
    FCollectionItems.Add(Item);
    Item.FParent := FName;
    Item.FParentComponent := Self;
  end;
end;

{ TDFMParser }

constructor TDFMParser.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
  FComponents := TObjectList<TDFMComponent>.Create(True);
  FSourceLines := TStringList.Create;
  FIndentStack := TStack<Integer>.Create;
  FRecursionDepth := 0;
  FCurrentCollection := nil;
end;

destructor TDFMParser.Destroy;
begin
  FComponents.Free;
  FSourceLines.Free;
  FIndentStack.Free;
  inherited;
end;

function TDFMParser.SafeFindComponent(const AName: string): TDFMComponent;

  function FindInList(List: TObjectList<TDFMComponent>): TDFMComponent;
  var
    Comp: TDFMComponent;
  begin
    if List = nil then
      Exit(nil);

    for Comp in List do
    begin
      if Comp = nil then
        Continue;

      if Comp.Name = AName then
        Exit(Comp);

      if Comp.Children <> nil then
      begin
        Result := FindInList(Comp.Children);
        if Result <> nil then
          Exit;
      end;
    end;
    Result := nil;
  end;

begin
  try
    Result := FindInList(FComponents);
  except
    Result := nil;
  end;
end;

procedure TDFMParser.SafeAddChild(Parent, Child: TDFMComponent);
begin
  if (Parent = nil) or (Child = nil) then
    Exit;

  try
    Parent.AddChild(Child);
  except
    on E: Exception do
      FContext.AddIssue(csError, Format('Failed to add child: %s', [E.Message]));
  end;
end;

function TDFMParser.GetIndentLevel(const Line: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Line) do
  begin
    if (Line[i] = ' ') or (Line[i] = #9) then
      Inc(Result)
    else
      Break;
  end;
end;

function TDFMParser.IsCollectionDeclaration(const Line: string): Boolean;
var
  Trimmed: string;
begin
  Trimmed := Trim(Line);
  Result := (Pos(' = <', Line) > 0) or
            (Trimmed.StartsWith('Columns = <')) or
            (Trimmed.StartsWith('Panels = <')) or
            (Trimmed.StartsWith('Items = <')) or
            (Trimmed.StartsWith('Fields = <'));
end;

function TDFMParser.IsSubComponentDeclaration(const Line: string): Boolean;
var
  Trimmed: string;
begin
  Trimmed := Trim(Line);
  Result := (Trimmed.StartsWith('item')) or
            (Trimmed.StartsWith('column')) or
            (Trimmed.StartsWith('items ')) or
            (Trimmed.StartsWith('TCollectionItem')) or
            (Trimmed.StartsWith('TColumn'));
end;

function TDFMParser.ExtractSubComponentType(const Line: string): string;
var
  Trimmed: string;
begin
  Trimmed := Trim(Line);

  if Trimmed.StartsWith('item') then
    Result := 'TCollectionItem'
  else if Trimmed.StartsWith('column') then
    Result := 'TColumn'
  else if Pos('TCollectionItem', Trimmed) > 0 then
    Result := 'TCollectionItem'
  else if Pos('TColumn', Trimmed) > 0 then
    Result := 'TColumn'
  else
    Result := 'TComponent';
end;

procedure TDFMParser.ParseCollection(const Line: string);
var
  NewCollection: TDFMComponent;
  CollectionName, CollectionType: string;
begin
  CollectionName := Trim(Copy(Line, 1, Pos('=', Line) - 1));
  CollectionType := 'TCollection';

  NewCollection := TDFMComponent.Create;
  NewCollection.Name := CollectionName;
  NewCollection.ComponentClass := CollectionType;
  NewCollection.IsCollection := True;
  NewCollection.IsSubComponent := True;
  NewCollection.OriginalLine := FLineNumber;

  if FIndentStack.Count >= MAX_RECURSION_DEPTH then
  begin
    NewCollection.Free;
    FContext.AddIssue(csError, 'Maximum DFM nesting depth reached at line ' + IntToStr(FLineNumber));
    Exit;
  end;

  if Assigned(FCurrentComponent) then
  begin
    SafeAddChild(FCurrentComponent, NewCollection);
  end;

  FIndentStack.Push(GetIndentLevel(FSourceLines[FLineNumber - 1]));
  FCurrentCollection := NewCollection;
  FCurrentComponent := NewCollection;
  FInObject := True;
end;

procedure TDFMParser.ParseSubComponent(const Line: string);
var
  NewComponent: TDFMComponent;
begin
  if FRecursionDepth >= MAX_RECURSION_DEPTH then
  begin
    FContext.AddIssue(csError, 'Maximum recursion depth reached');
    Exit;
  end;

  if FIndentStack.Count >= MAX_RECURSION_DEPTH then
  begin
    FContext.AddIssue(csError, 'Maximum DFM nesting depth reached at line ' + IntToStr(FLineNumber));
    Exit;
  end;

  Inc(FRecursionDepth);
  try
    NewComponent := TDFMComponent.Create;
    NewComponent.IsSubComponent := True;
    NewComponent.SubComponentType := ExtractSubComponentType(Line);
    NewComponent.Name := '';
    NewComponent.ComponentClass := NewComponent.SubComponentType;
    NewComponent.OriginalLine := FLineNumber;

    if Assigned(FCurrentCollection) then
      FCurrentCollection.AddCollectionItem(NewComponent)
    else if Assigned(FCurrentComponent) then
      SafeAddChild(FCurrentComponent, NewComponent)
    else
      FComponents.Add(NewComponent);

    FIndentStack.Push(GetIndentLevel(FSourceLines[FLineNumber - 1]));
    FCurrentComponent := NewComponent;
    FInObject := True;

  finally
    Dec(FRecursionDepth);
  end;
end;

function TDFMParser.IsBinaryDFM(const AFileName: string): Boolean;
var
  FileStream: TFileStream;
begin
  try
    FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      Result := TestStreamFormat(FileStream) = sofBinary;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // A failed probe must fail closed instead of treating uncertain binary data as text.
      raise;
    end;
  end;
end;

function TDFMParser.ConvertBinaryToText(const AFileName: string): string;
var
  InputStream: TFileStream;
  OutputStream: TStringStream;
  ResourceError: string;
begin
  Result := '';
  try
    InputStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      OutputStream := TStringStream.Create('', TEncoding.UTF8);
      try
        try
          ObjectResourceToText(InputStream, OutputStream);
        except
          on E: Exception do
          begin
            ResourceError := E.Message;
            InputStream.Position := 0;
            OutputStream.Size := 0;
            OutputStream.Position := 0;
            try
              ObjectBinaryToText(InputStream, OutputStream);
            except
              on EBinary: Exception do
                raise EConvertError.CreateFmt(
                  'Resource conversion failed (%s); raw binary conversion failed (%s)',
                  [ResourceError, EBinary.Message]);
            end;
          end;
        end;
        Result := OutputStream.DataString;
      finally
        OutputStream.Free;
      end;
    finally
      InputStream.Free;
    end;
  except
    on E: Exception do
    begin
      FContext.AddIssue(csError, 'Failed to convert binary DFM: ' + E.Message,
        'DFM format detection', '',
        'Save the form as a text DFM in Delphi and rerun the conversion.', -1, True);
    end;
  end;
end;

function TDFMParser.LoadDFM(const AFileName: string): string;
var
  EncodingName: string;
begin
  Result := '';
  try
    if TFile.Exists(AFileName) and
       (TFile.GetSize(AFileName) > VCL2FMX_MAX_TEXT_DFM_BYTES) then
    begin
      FContext.AddIssue(csError,
        'DFM file is too large for safe automatic parsing: ' + AFileName,
        'DFM size guard',
        '',
        'Open this DFM in Delphi and split or simplify the form before reconverting.',
        -1,
        True);
      Exit;
    end;

    if IsBinaryDFM(AFileName) then
      Result := ConvertBinaryToText(AFileName)
    else if not VCL2FMXTryReadTextFile(AFileName, Result, EncodingName) then
      FContext.AddIssue(csError,
        'Failed to load text DFM with supported encodings: ' + AFileName,
        'DFM read failure',
        '',
        'Open the DFM in Delphi, save it as text, and rerun the conversion.',
        -1,
        True);
  except
    on E: Exception do
      FContext.AddIssue(csError, 'Failed to load DFM: ' + E.Message);
  end;
end;
function TDFMParser.NormalizePath(const Value: string): string;
begin
  Result := Value;
  // Replace Windows backslashes with forward slashes
  Result := StringReplace(Result, '\', '/', [rfReplaceAll]);
  // Remove leading ./ or .\
  if Result.StartsWith('./') then
    Result := Copy(Result, 3, Length(Result) - 2);
  if Result.StartsWith('.//') then
    Result := Copy(Result, 4, Length(Result) - 3);
end;

function TDFMParser.CountChar(const Text: string; Ch: Char): Integer;
var
  C: Char;
begin
  Result := 0;
  for C in Text do
    if C = Ch then
      Inc(Result);
end;

function TDFMParser.ReadMultiLinePropertyValue(var LineIndex: Integer;
  const InitialValue: string): string;
var
  TrimmedValue: string;
  OpenCh: Char;
  CloseCh: Char;
  Level: Integer;
  CurrentLine: string;
begin
  Result := InitialValue;
  TrimmedValue := Trim(InitialValue);
  OpenCh := #0;
  CloseCh := #0;

  if TrimmedValue = '' then
  begin
    while (LineIndex < FSourceLines.Count - 1) and
          IsStringContinuationLine(Trim(FSourceLines[LineIndex + 1])) do
    begin
      Inc(LineIndex);
      CurrentLine := TrimRight(FSourceLines[LineIndex]);
      if Result <> '' then
        Result := Result + sLineBreak;
      Result := Result + Trim(CurrentLine);
    end;
    Exit;
  end;

  if IsStringContinuationLine(TrimmedValue) then
  begin
    while (LineIndex < FSourceLines.Count - 1) and
          IsStringContinuationLine(Trim(FSourceLines[LineIndex + 1])) do
    begin
      Inc(LineIndex);
      CurrentLine := TrimRight(FSourceLines[LineIndex]);
      Result := Result + sLineBreak + Trim(CurrentLine);
    end;
  end;

  if TrimmedValue.StartsWith('{') then
  begin
    OpenCh := '{';
    CloseCh := '}';
  end
  else if TrimmedValue.StartsWith('(') then
  begin
    OpenCh := '(';
    CloseCh := ')';
  end;

  if OpenCh = #0 then
    Exit;

  Level := CountChar(Result, OpenCh) - CountChar(Result, CloseCh);
  while (Level > 0) and (LineIndex < FSourceLines.Count - 1) do
  begin
    Inc(LineIndex);
    CurrentLine := TrimRight(FSourceLines[LineIndex]);
    Result := Result + sLineBreak + CurrentLine;
    Level := Level + CountChar(CurrentLine, OpenCh) - CountChar(CurrentLine, CloseCh);
  end;
end;

function TDFMParser.IsStringContinuationLine(const Line: string): Boolean;
var
  T: string;
begin
  T := Trim(Line);
  Result := (T <> '') and
    ((T[1] = '''') or (T[1] = '#') or
     ((T[1] = '+') and (Length(T) > 1) and ((T[2] = '''') or (T[2] = '#'))));
end;

function TDFMParser.DecodeStringExpression(const Expr: string): string;
var
  I: Integer;
  CodeStart: Integer;
  CodeValue: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(Expr) do
  begin
    if Expr[I] = '''' then
    begin
      Inc(I);
      while I <= Length(Expr) do
      begin
        if Expr[I] = '''' then
        begin
          if (I < Length(Expr)) and (Expr[I + 1] = '''') then
          begin
            Result := Result + '''';
            Inc(I, 2);
            Continue;
          end;
          Inc(I);
          Break;
        end;
        Result := Result + Expr[I];
        Inc(I);
      end;
      Continue;
    end;

    if Expr[I] = '#' then
    begin
      Inc(I);
      CodeStart := I;
      while (I <= Length(Expr)) and CharInSet(Expr[I], ['0'..'9']) do
        Inc(I);
      CodeValue := StrToIntDef(Copy(Expr, CodeStart, I - CodeStart), -1);
      if CodeValue >= 0 then
        Result := Result + Char(CodeValue);
      Continue;
    end;

    Inc(I);
  end;
end;

procedure TDFMParser.Parse(const DFMContent: string);
var
  I: Integer;
  Line: string;
  IndentLevel: Integer;
begin
  FComponents.Clear;
  FCurrentComponent := nil;
  FCurrentCollection := nil;
  FInObject := False;
  FIndentStack.Clear;
  FRecursionDepth := 0;

  FSourceLines.Text := DFMContent;

  I := 0;
  while I < FSourceLines.Count do
  begin
    FLineNumber := I + 1;
    Line := FSourceLines[I];

    IndentLevel := GetIndentLevel(Line);
    Line := Trim(Line);

    if Line = '' then
    begin
      Inc(I);
      Continue;
    end;

    while (FIndentStack.Count > 0) and (IndentLevel < FIndentStack.Peek) do
    begin
      FIndentStack.Pop;
      if Assigned(FCurrentComponent) then
      begin
        if Assigned(FCurrentComponent.ParentComponent) then
          FCurrentComponent := FCurrentComponent.ParentComponent
        else
          FCurrentComponent := nil;
      end;
      if (FCurrentCollection <> nil) and (FIndentStack.Count > 0) and
         (IndentLevel <= FIndentStack.Peek) then
        FCurrentCollection := nil;
    end;

    try
      if StartsText('object ', Line) or StartsText('inherited ', Line) then
      begin
        ParseObjectDeclaration(Line);
        Inc(I);
        Continue;
      end
      else if IsCollectionDeclaration(Line) then
      begin
        ParseCollection(Line);
        Inc(I);
        Continue;
      end
      else if IsSubComponentDeclaration(Line) then
      begin
        ParseSubComponent(Line);
        Inc(I);
        Continue;
      end;

      if FInObject and Assigned(FCurrentComponent) then
      begin
        if ParseProperty(I, Line) then
        begin
          Inc(I);
          Continue;
        end;

        if Line = 'end' then
        begin
          ParseEnd(Line);
          Inc(I);
          Continue;
        end;
      end;
    except
      on E: Exception do
      begin
        FContext.AddIssue(csError,
          Format('Error parsing line %d: %s', [FLineNumber, E.Message]));
      end;
    end;

    Inc(I);
  end;
end;

function TDFMParser.ParseObjectDeclaration(const Line: string): Boolean;
var
  ObjName, ObjClass: string;
  NewComponent: TDFMComponent;
  IndentLevel: Integer;
begin
  Result := True;

  if FRecursionDepth >= MAX_RECURSION_DEPTH then
  begin
    FContext.AddIssue(csError, 'Maximum recursion depth reached at line ' + IntToStr(FLineNumber));
    Exit(False);
  end;

  if FIndentStack.Count >= MAX_RECURSION_DEPTH then
  begin
    FContext.AddIssue(csError, 'Maximum DFM nesting depth reached at line ' + IntToStr(FLineNumber));
    Exit(False);
  end;

  Inc(FRecursionDepth);
  try
    ExtractNameAndClass(Line, ObjName, ObjClass);
    IndentLevel := GetIndentLevel(FSourceLines[FLineNumber - 1]);

    NewComponent := TDFMComponent.Create;
    NewComponent.Name := ObjName;
    NewComponent.ComponentClass := ObjClass;
    NewComponent.ObjectName := ObjName;
    NewComponent.ObjectClass := ObjClass;
    NewComponent.OriginalLine := FLineNumber;

    if Assigned(FCurrentComponent) then
    begin
      SafeAddChild(FCurrentComponent, NewComponent);
    end
    else
      FComponents.Add(NewComponent);

    FIndentStack.Push(IndentLevel);
    FCurrentComponent := NewComponent;
    FInObject := True;
  except
    on E: Exception do
    begin
      FContext.AddIssue(csError, 'Failed to parse object declaration: ' + E.Message,
        FLineNumber);
      Result := False;
    end;
  end;
  Dec(FRecursionDepth);
end;

procedure TDFMParser.ExtractNameAndClass(const ObjText: string; var ObjName, ObjClass: string);
var
  Decl: string;
  ColonPos: Integer;
  SpacePos: Integer;
begin
  ObjName := '';
  ObjClass := '';

  Decl := Trim(ObjText);
  if StartsText('object ', Decl) then
    Delete(Decl, 1, Length('object '))
  else if StartsText('inherited ', Decl) then
    Delete(Decl, 1, Length('inherited '));

  ColonPos := Pos(':', Decl);
  if ColonPos > 0 then
  begin
    ObjName := Trim(Copy(Decl, 1, ColonPos - 1));
    ObjClass := Trim(Copy(Decl, ColonPos + 1, MaxInt));
  end
  else
  begin
    SpacePos := Pos(' ', Decl);
    if SpacePos > 0 then
    begin
      ObjName := Trim(Copy(Decl, 1, SpacePos - 1));
      ObjClass := Trim(Copy(Decl, SpacePos + 1, MaxInt));
    end
    else
      ObjName := Decl;
  end;

  if (ObjClass <> '') and not ObjClass.StartsWith('T') then
  begin
    if ObjName = ObjClass then
      ObjClass := 'T' + ObjClass;
  end;

  if ObjClass = '' then
    FContext.AddIssue(csWarning,
      Format('Could not extract class from: %s (name: %s)', [ObjText, ObjName]), FLineNumber);
end;

function TDFMParser.CleanPropertyValue(const Value: string): string;
begin
  Result := Trim(Value);

  Result := VCL2FMXStripLineCommentOutsideString(Result);

  // Remove trailing semicolon
  if Result.EndsWith(';') then
    Result := Result.Substring(0, Result.Length - 1);

  // Normalize paths
  if (Pos('.\', Result) > 0) or (Pos('./', Result) > 0) or (Pos('\', Result) > 0) then
    Result := NormalizePath(Result);

  // Don't strip quotes here - preserve them for QuoteStringValue
  Result := Trim(Result);
end;

function TDFMParser.ParseProperty(var LineIndex: Integer; const Line: string): Boolean;
var
  PropName, PropValue: string;
  EqualPos: Integer;
begin
  Result := False;

  if not Assigned(FCurrentComponent) then
    Exit;

  EqualPos := Pos('=', Line);
  if EqualPos > 0 then
  begin
    PropName := Trim(Copy(Line, 1, EqualPos - 1));
    PropValue := CleanPropertyValue(Copy(Line, EqualPos + 1, Length(Line)));
    PropValue := ReadMultiLinePropertyValue(LineIndex, PropValue);
    PropValue := CleanPropertyValue(PropValue);

    if (not IsStringCollectionPropertyName(PropName)) and
       ((Pos('''', PropValue) > 0) or (Pos('#', PropValue) > 0)) then
      PropValue := DecodeStringExpression(PropValue);

    if PropName.StartsWith('On') then
    begin
      FCurrentComponent.Events.AddOrSetValue(PropName, PropValue);
      FCurrentComponent.SetEventLine(PropName, FLineNumber);
    end
    else
    begin
      FCurrentComponent.Properties.AddOrSetValue(PropName, PropValue);
      FCurrentComponent.SetPropertyLine(PropName, FLineNumber);
    end;

    Result := True;
  end;
end;

function TDFMParser.ParseEnd(const Line: string): Boolean;
var
  ClosingComponent: TDFMComponent;
  ParentComponent: TDFMComponent;
  ClosingCollectionItem: Boolean;
  ClosingCollection: Boolean;
begin
  Result := True;

  if FIndentStack.Count > 0 then
    FIndentStack.Pop;

  ClosingComponent := FCurrentComponent;
  ParentComponent := nil;
  ClosingCollectionItem := False;
  ClosingCollection := False;

  if Assigned(ClosingComponent) then
  begin
    ClosingCollection := ClosingComponent.IsCollection;
    ClosingCollectionItem := Assigned(FCurrentCollection) and
      not ClosingComponent.IsCollection and
      (ClosingComponent.ParentComponent = FCurrentCollection);

    ParentComponent := ClosingComponent.ParentComponent;
  end;

  if Assigned(ClosingComponent) then
  begin
    if ClosingCollectionItem then
      FCurrentComponent := FCurrentCollection
    else
    begin
      if ClosingCollection then
        FCurrentCollection := nil;

      FCurrentComponent := ParentComponent;
    end;
  end;

  if FCurrentComponent = nil then
    FInObject := False;
end;

function TDFMParser.FindComponent(const AName: string): TDFMComponent;
begin
  Result := SafeFindComponent(AName);
end;

function TDFMParser.Convert(AMapper: TComponentMapper = nil): string;
var
  FMXGen: TFMXGenerator;
begin
  FMXGen := TFMXGenerator.Create(FContext, AMapper);
  try
    Result := FMXGen.GenerateFMX(FComponents);
  finally
    FMXGen.Free;
  end;
end;

end.
