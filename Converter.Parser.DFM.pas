{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Parser.DFM;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  System.RTTI, System.TypInfo, System.IOUtils, System.Math,
  System.RegularExpressions, System.StrUtils,
  Converter.Core.Types, Converter.Mapper.Component;

type
  TDFMComponent = class
  private
    FName: string;
    FComponentClass: string;
    FParent: string;
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
    function Convert(AMapper: TObject = nil): string;
    function FindComponent(const AName: string): TDFMComponent;
    property Components: TObjectList<TDFMComponent> read FComponents;
  end;

  TFMXGenerator = class
  private
    FContext: TConversionContext;
    FComponentMapper: TObject;
    FIndentLevel: Integer;
    FRootComponent: TDFMComponent;

    function GenerateComponent(Component: TDFMComponent): string;
    function GetIndent: string;
    function TransformColor(const VCLColor: string): string;
    function TransformFontProps(Component: TDFMComponent): string;
    function IsRootComponent(const Component: TDFMComponent): Boolean;
    function SupportsGeneratedFontProps(const CompClass: string): Boolean;
    function SupportsTextAlign(const CompClass: string): Boolean;
    function BuildStyledSettingsLiteral(Component: TDFMComponent; const CompClass: string): string;
    function IsVCLProperty(const PropName: string): Boolean;
    procedure GenerateCollection(Component: TDFMComponent; Lines: TStringList);
    procedure GenerateFields(Component: TDFMComponent; Lines: TStringList);
    procedure GenerateStatusBarPanels(Component: TDFMComponent; Lines: TStringList);
    function GetComponentClass(const Component: TDFMComponent): string;
    function QuoteStringValue(const Value: string): string;
    function NeedsFMXObjects(const Component: TDFMComponent): Boolean;
    function IsNonVisualComponent(const Component: TDFMComponent): Boolean;
    function IsStructuralWrapperPanel(const Component: TDFMComponent): Boolean;
    function IsConnectionProperty(const PropName: string): Boolean;
    function CleanParentheses(const Value: string): string;
    function TryGetMapper(out Mapper: TComponentMapper): Boolean;
    function GetSourceVCLClassName(const Component: TDFMComponent): string;
    function GetTargetFMXClassName(const Component: TDFMComponent): string;
    procedure AddUnsupportedPropertyReview(const Component: TDFMComponent;
      const PropName, PropValue, Recommendation: string; AIsBlocking: Boolean = False);
    procedure AddUnsupportedEventReview(const Component: TDFMComponent;
      const EventName, EventHandler, Recommendation: string; AIsBlocking: Boolean = False);
    function GetMappedComponentClass(const Component: TDFMComponent): string;
    function FindMappedProperty(const Component: TDFMComponent;
      const PropName: string; out PropMap: TPropertyMapping): Boolean;
    function FindMappedEvent(const Component: TDFMComponent;
      const EventName: string; out EventMap: TEventMapping): Boolean;
    function CanUseFillColor(const CompClass: string): Boolean;
    function FormatFMXFloatValue(const Value: string): string;
    function NormalizeAlignLayoutValue(const Value: string): string;
    function NormalizeHexBlob(const Value: string): string;
    function ExtractEmbeddedImageHex(const Value: string; out FormatName,
      HexData: string): Boolean;
    procedure AppendHexBlock(Lines: TStringList; const Prefix, HexData: string);
    procedure HandleImageComponent(Component: TDFMComponent; Lines: TStringList);
    procedure HandleStringCollection(Component: TDFMComponent; const PropName, PropValue: string; Lines: TStringList);
    function FindComponentByName(const AName: string): TDFMComponent;
    function FindParentComponent(const Component: TDFMComponent): TDFMComponent;
    function HasActiveAlign(const Component: TDFMComponent): Boolean;
    procedure ComputeClientAlignedSize(const Component: TDFMComponent;
      out WidthValue, HeightValue: string);
    procedure GetEffectiveComponentSize(const Component: TDFMComponent;
      out WidthValue, HeightValue: Integer);
    procedure NormalizeGeneratedFMX(var Code: string);
  public
    constructor Create(AContext: TConversionContext; AMapper: TObject);
    destructor Destroy; override;

    function GenerateFMX(Components: TObjectList<TDFMComponent>): string;
  end;

implementation

uses
  FMX.Graphics;

function HexToBytes(const HexData: string): TBytes;
var
  CleanHex: string;
  I, ByteCount: Integer;
begin
  CleanHex := '';
  for I := 1 to Length(HexData) do
    if CharInSet(HexData[I], ['0'..'9', 'A'..'F', 'a'..'f']) then
      CleanHex := CleanHex + HexData[I];

  if (CleanHex = '') or Odd(Length(CleanHex)) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  ByteCount := Length(CleanHex) div 2;
  SetLength(Result, ByteCount);
  for I := 0 to ByteCount - 1 do
    Result[I] := StrToInt('$' + Copy(CleanHex, (I * 2) + 1, 2));
end;

function StreamToHex(Stream: TStream): string;
var
  Bytes: TBytes;
  I: Integer;
begin
  Result := '';
  if Stream.Size = 0 then
    Exit;

  SetLength(Bytes, Stream.Size);
  Stream.Position := 0;
  Stream.ReadBuffer(Bytes[0], Length(Bytes));

  for I := 0 to High(Bytes) do
    Result := Result + IntToHex(Bytes[I], 2);
end;

function ConvertImageHexToPngHex(const HexData: string; out PngHex: string;
  out Width, Height: Integer): Boolean;
var
  RawBytes: TBytes;
  InputStream: TMemoryStream;
  OutputStream: TMemoryStream;
  Bitmap: TBitmap;
begin
  Result := False;
  PngHex := '';
  Width := 0;
  Height := 0;

  RawBytes := HexToBytes(HexData);
  if Length(RawBytes) = 0 then
    Exit;

  InputStream := TMemoryStream.Create;
  OutputStream := TMemoryStream.Create;
  Bitmap := TBitmap.Create;
  try
    InputStream.WriteBuffer(RawBytes[0], Length(RawBytes));
    InputStream.Position := 0;

    Bitmap.LoadFromStream(InputStream);
    Width := Round(Bitmap.Width);
    Height := Round(Bitmap.Height);

    Bitmap.SaveToStream(OutputStream);
    PngHex := StreamToHex(OutputStream);
    Result := PngHex <> '';
  finally
    Bitmap.Free;
    OutputStream.Free;
    InputStream.Free;
  end;
end;

function IsStringCollectionPropertyName(const PropName: string): Boolean;
begin
  Result := EndsText('.Strings', Trim(PropName));
end;

{ TDFMComponent }

constructor TDFMComponent.Create;
begin
  FProperties := TDictionary<string, string>.Create;
  FEvents := TDictionary<string, string>.Create;
  FPropertyLines := TDictionary<string, Integer>.Create;
  FEventLines := TDictionary<string, Integer>.Create;
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
  end;
end;

procedure TDFMComponent.AddCollectionItem(Item: TDFMComponent);
begin
  if (Item <> nil) and (FCollectionItems <> nil) then
  begin
    FCollectionItems.Add(Item);
    Item.FParent := FName;
  end;
end;

{ TDFMParser }

constructor TDFMParser.Create(AContext: TConversionContext);
begin
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
  Result := False;
  try
    FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      Result := TestStreamFormat(FileStream) = sofBinary;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      FContext.AddIssue(csError, 'Failed to check DFM format: ' + E.Message);
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
      FContext.AddIssue(csWarning,
        'Binary DFM detected but could not be converted automatically: ' +
        AFileName + ' - ' + E.Message);
      FContext.AddIssue(csError, 'Failed to convert binary DFM: ' + E.Message);
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
        if FCurrentComponent.Parent <> '' then
          FCurrentComponent := SafeFindComponent(FCurrentComponent.Parent)
        else
          FCurrentComponent := nil;
      end;
      if (FCurrentCollection <> nil) and (IndentLevel <= FIndentStack.Count) then
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
      SameText(ClosingComponent.Parent, FCurrentCollection.Name);

    if ClosingComponent.Parent <> '' then
      ParentComponent := SafeFindComponent(ClosingComponent.Parent);
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

function TDFMParser.Convert(AMapper: TObject = nil): string;
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

{ TFMXGenerator }

constructor TFMXGenerator.Create(AContext: TConversionContext; AMapper: TObject);
begin
  FContext := AContext;
  FComponentMapper := AMapper;
  FIndentLevel := 0;
  FRootComponent := nil;
end;

destructor TFMXGenerator.Destroy;
begin
  inherited;
end;

function TFMXGenerator.FindComponentByName(const AName: string): TDFMComponent;
  function FindRecursive(const Root: TDFMComponent; const TargetName: string): TDFMComponent;
  var
    Child: TDFMComponent;
  begin
    Result := nil;
    if Root = nil then
      Exit;

    if SameText(Root.Name, TargetName) then
      Exit(Root);

    for Child in Root.Children do
    begin
      Result := FindRecursive(Child, TargetName);
      if Result <> nil then
        Exit;
    end;
  end;
begin
  if (AName = '') or (FRootComponent = nil) then
    Exit(nil);

  Result := FindRecursive(FRootComponent, AName);
end;

function TFMXGenerator.FindParentComponent(
  const Component: TDFMComponent): TDFMComponent;
begin
  if (Component = nil) or (Component.Parent = '') then
    Exit(nil);

  Result := FindComponentByName(Component.Parent);
end;

function TFMXGenerator.HasActiveAlign(const Component: TDFMComponent): Boolean;
var
  AlignValue: string;
begin
  if Component = nil then
    Exit(False);

  AlignValue := Trim(Component.GetPropertyValue('Align', ''));
  Result := (AlignValue <> '') and
            not SameText(AlignValue, 'alNone') and
            not SameText(AlignValue, 'None');
end;

procedure TFMXGenerator.GetEffectiveComponentSize(const Component: TDFMComponent;
  out WidthValue, HeightValue: Integer);
var
  WidthText: string;
  HeightText: string;
begin
  WidthValue := 0;
  HeightValue := 0;

  if Component = nil then
    Exit;

  if SameText(Component.GetPropertyValue('Align', ''), 'alClient') then
  begin
    ComputeClientAlignedSize(Component, WidthText, HeightText);
    WidthValue := StrToIntDef(WidthText, 0);
    HeightValue := StrToIntDef(HeightText, 0);
    if (WidthValue > 0) or (HeightValue > 0) then
      Exit;
  end;

  WidthValue := StrToIntDef(
    Component.GetPropertyValue('ClientWidth',
      Component.GetPropertyValue('Width', '0')), 0);
  HeightValue := StrToIntDef(
    Component.GetPropertyValue('ClientHeight',
      Component.GetPropertyValue('Height', '0')), 0);
end;

procedure TFMXGenerator.ComputeClientAlignedSize(const Component: TDFMComponent;
  out WidthValue, HeightValue: string);
var
  ParentComp: TDFMComponent;
  Sibling: TDFMComponent;
  BaseWidth: Integer;
  BaseHeight: Integer;
  SiblingSize: Integer;
  SiblingAlign: string;
begin
  WidthValue := '';
  HeightValue := '';

  ParentComp := FindParentComponent(Component);
  if ParentComp = nil then
    Exit;

  GetEffectiveComponentSize(ParentComp, BaseWidth, BaseHeight);
  if (BaseWidth <= 0) or (BaseHeight <= 0) then
    Exit;

  for Sibling in ParentComp.Children do
  begin
    if Sibling = Component then
      Continue;

    if SameText(Sibling.ComponentClass, 'TMainMenu') or
       SameText(GetComponentClass(Sibling), 'TMenuBar') then
    begin
      Dec(BaseHeight, 24);
      Continue;
    end;

    SiblingAlign := Trim(Sibling.GetPropertyValue('Align', ''));
    if SameText(SiblingAlign, 'alTop') or SameText(SiblingAlign, 'alBottom') then
    begin
      SiblingSize := StrToIntDef(Sibling.GetPropertyValue('Height', '0'), 0);
      if SiblingSize > 0 then
        Dec(BaseHeight, SiblingSize);
    end
    else if SameText(SiblingAlign, 'alLeft') or SameText(SiblingAlign, 'alRight') then
    begin
      SiblingSize := StrToIntDef(Sibling.GetPropertyValue('Width', '0'), 0);
      if SiblingSize > 0 then
        Dec(BaseWidth, SiblingSize);
    end;
  end;

  if BaseWidth > 0 then
    WidthValue := IntToStr(BaseWidth);
  if BaseHeight > 0 then
    HeightValue := IntToStr(BaseHeight);
end;

function TFMXGenerator.IsNonVisualComponent(const Component: TDFMComponent): Boolean;
var
  CompClass: string;
begin
  CompClass := Component.ComponentClass;
  Result := CompClass.StartsWith('TFD') or
            CompClass.StartsWith('TId') or
            SameText(CompClass, 'TDataSource') or
            SameText(CompClass, 'TTimer') or
            SameText(CompClass, 'TActionList') or
            SameText(CompClass, 'TImageList') or
            SameText(CompClass, 'TMediaPlayer') or
            SameText(CompClass, 'TOpenDialog') or
            SameText(CompClass, 'TSaveDialog') or
            SameText(CompClass, 'TColorDialog') or
            SameText(CompClass, 'TFontDialog') or
            SameText(CompClass, 'TFindDialog') or
            SameText(CompClass, 'TReplaceDialog');
end;

function TFMXGenerator.IsConnectionProperty(const PropName: string): Boolean;
begin
  Result := (PropName = 'DriverID') or
            (PropName = 'Database') or
            (PropName = 'Server') or
            (PropName = 'UserName') or
            (PropName = 'Password') or
            (PropName = 'Protocol');
end;

function TFMXGenerator.NeedsFMXObjects(const Component: TDFMComponent): Boolean;
begin
  Result := (Component.ComponentClass = 'TImage') or
            (Component.ComponentClass = 'TShape') or
            (Component.ComponentClass = 'TRectangle') or
            (Component.ComponentClass = 'TCircle') or
            (Component.ComponentClass = 'TLine');
end;

function TFMXGenerator.GetIndent: string;
begin
  Result := StringOfChar(' ', FIndentLevel * 2);
end;


function TFMXGenerator.CleanParentheses(const Value: string): string;
begin
  Result := Trim(Value);
  // Remove outer parentheses if they exist
  if Result.StartsWith('(') and Result.EndsWith(')') then
    Result := Copy(Result, 2, Length(Result) - 2);
  // Remove any extra parentheses
  Result := StringReplace(Result, '((' , '(', [rfReplaceAll]);
  Result := StringReplace(Result, '))' , ')', [rfReplaceAll]);
  Result := Trim(Result);
end;

function TFMXGenerator.TryGetMapper(out Mapper: TComponentMapper): Boolean;
begin
  Result := FComponentMapper is TComponentMapper;
  if Result then
    Mapper := TComponentMapper(FComponentMapper)
  else
    Mapper := nil;
end;

function TFMXGenerator.GetSourceVCLClassName(
  const Component: TDFMComponent): string;
begin
  Result := '';
  if Component = nil then
    Exit;

  if IsRootComponent(Component) then
    Exit('TForm');

  Result := Component.ComponentClass;
end;

function TFMXGenerator.GetTargetFMXClassName(
  const Component: TDFMComponent): string;
var
  Mapper: TComponentMapper;
  Mapping: TComponentMapping;
  ShapeKind: string;
begin
  Result := '';
  if Component = nil then
    Exit;

  if IsRootComponent(Component) then
    Exit('TForm');

  if IsStructuralWrapperPanel(Component) then
    Exit('TLayout');

  if SameText(Component.ComponentClass, 'TShape') then
  begin
    ShapeKind := Trim(Component.GetPropertyValue('Shape', ''));
    if SameText(ShapeKind, 'stCircle') or SameText(ShapeKind, 'stEllipse') then
      Exit('TEllipse');
    if SameText(ShapeKind, 'stRoundRect') or SameText(ShapeKind, 'stRoundSquare') then
      Exit('TRoundRect');
    Exit('TRectangle');
  end;

  if TryGetMapper(Mapper) then
  begin
    Mapping := Mapper.EnsureBestMatch(Component.ComponentClass);
    if Assigned(Mapping) and (Mapping.FMXClassName <> '') then
      Exit(Mapping.FMXClassName);
  end;

  Result := Component.ComponentClass;
end;

procedure TFMXGenerator.AddUnsupportedPropertyReview(
  const Component: TDFMComponent; const PropName, PropValue,
  Recommendation: string; AIsBlocking: Boolean);
begin
  if Component = nil then
    Exit;

  FContext.AddManualReview(
    'Unsupported property',
    Format('Property %s on %s (%s) has no safe generic FMX mapping and was omitted from the generated .fmx.',
      [PropName, Component.Name, GetTargetFMXClassName(Component)]),
    Format('%s = %s', [PropName, PropValue]),
    Recommendation,
    Component.GetPropertyLine(PropName),
    AIsBlocking);
end;

procedure TFMXGenerator.AddUnsupportedEventReview(
  const Component: TDFMComponent; const EventName, EventHandler,
  Recommendation: string; AIsBlocking: Boolean);
begin
  if Component = nil then
    Exit;

  FContext.AddManualReview(
    'Unsupported event',
    Format('Event %s on %s (%s) has no safe generic FMX mapping and was omitted from the generated .fmx.',
      [EventName, Component.Name, GetTargetFMXClassName(Component)]),
    Format('%s = %s', [EventName, EventHandler]),
    Recommendation,
    Component.GetEventLine(EventName),
    AIsBlocking);
end;

function TFMXGenerator.GetMappedComponentClass(
  const Component: TDFMComponent): string;
var
  Mapper: TComponentMapper;
  Mapping: TComponentMapping;

  function BuildMappingAssistanceText: string;
  var
    ClassName: string;
  begin
    ClassName := Component.ComponentClass;
    if StartsText('TAdv', ClassName) or StartsText('TTMS', ClassName) or
       StartsText('TFNC', ClassName) then
      Result := 'Likely TMS/FNC component. Review the TMS mapping pack first; if this component appears in multiple screens, add a tested mapping-pack rule with property/event expectations.'
    else if StartsText('Tcx', ClassName) or StartsText('Tdx', ClassName) then
      Result := 'Likely DevExpress component. Review the DevExpress mapping pack first; grids, editors, and ribbon controls usually need manual behavior review even when a visual replacement exists.'
    else if StartsText('TJv', ClassName) then
      Result := 'Likely JVCL component. Review the JVCL mapping pack and prefer a standard FMX replacement when the VCL feature set is simple.'
    else if StartsText('TRz', ClassName) then
      Result := 'Likely Raize/Konopka component. Review the Raize/Konopka mapping pack and confirm style/container behavior in the FMX designer.'
    else if StartsText('TUni', ClassName) or StartsText('TIW', ClassName) then
      Result := 'Likely web framework component. Review the IntraWeb/UniGUI mapping pack; many server/web controls should be redesigned rather than converted as desktop FMX controls.'
    else
      Result := 'No mapping pack matched this component. Search the mapping packs for a related vendor or base class, then add a tested mapping-pack rule if the replacement is reusable.';
  end;
  procedure RecordMappingPackUsage(const AFMXClassName: string;
    AGeneratedOutput: Boolean);
  var
    Usage: TMappingPackUsage;
  begin
    Usage := TMappingPackUsage.Create;
    Usage.ComponentName := Component.Name;
    Usage.VCLClassName := Component.ComponentClass;
    Usage.FMXClassName := AFMXClassName;
    Usage.Action := Mapping.Action;
    Usage.Confidence := Mapping.Confidence;
    Usage.Vendor := Mapping.Vendor;
    Usage.PackName := Mapping.PackName;
    Usage.PackVersion := Mapping.PackVersion;
    Usage.SourceFile := FContext.CurrentFile;
    Usage.LineNumber := Component.OriginalLine;
    Usage.GeneratedOutput := AGeneratedOutput;
    if Trim(Mapping.ManualReviewReason) <> '' then
      Usage.Notes := Mapping.ManualReviewReason
    else
      Usage.Notes := Mapping.Notes;
    FContext.MappingPackUsages.Add(Usage);
  end;
begin
  Result := '';

  if (Component = nil) or not TryGetMapper(Mapper) then
    Exit;

  // The root object is the generated form/datamodule class itself. It is not
  // a child VCL control that needs FMX component matching, so preserving its
  // declared class name avoids false "unsupported component" report entries.
  if IsRootComponent(Component) then
    Exit;

  Mapping := Mapper.EnsureBestMatch(Component.ComponentClass);
  if Assigned(Mapping) and SameText(Mapping.MappingSource, 'pack') then
  begin
    if SameText(Mapping.Action, 'preserve') then
    begin
      RecordMappingPackUsage(
        IfThen(Trim(Mapping.FMXClassName) <> '', Mapping.FMXClassName, Component.ComponentClass),
        True);
      FContext.AddIssue(
        csInfo,
        Format('Mapping pack %s preserved %s (%s) as %s with %d%% confidence.',
          [Mapping.PackName, Component.Name, Component.ComponentClass,
           IfThen(Trim(Mapping.FMXClassName) <> '', Mapping.FMXClassName, Component.ComponentClass),
           Mapping.Confidence]),
        'Mapping pack preserve',
        Format('object %s: %s', [Component.Name, Component.ComponentClass]),
        IfThen(Trim(Mapping.ManualReviewReason) <> '',
          Mapping.ManualReviewReason,
          'Verify that the required third-party package, units, licenses, and target-platform support are available.'),
        Component.OriginalLine,
        False);
    end;

    if SameText(Mapping.Action, 'detect_only') then
    begin
      RecordMappingPackUsage('', False);
      FContext.AddManualReview(
        'Mapping pack detection only',
        Format('Mapping pack %s detected %s (%s), but the rule is detect_only so no FMX replacement was generated.',
          [Mapping.PackName, Component.Name, Component.ComponentClass]),
        Format('object %s: %s', [Component.Name, Component.ComponentClass]),
        IfThen(Trim(Mapping.ManualReviewReason) <> '',
          Mapping.ManualReviewReason,
          'Review this third-party component manually or supply a conversion-capable mapping-pack rule.'),
        Component.OriginalLine,
        False);
      Exit;
    end;

    if SameText(Mapping.Action, 'manual_review') then
    begin
      RecordMappingPackUsage('', False);
      FContext.AddManualReview(
        'Mapping pack manual review',
        Format('Mapping pack %s requires manual review for %s (%s); no automatic FMX replacement was generated.',
          [Mapping.PackName, Component.Name, Component.ComponentClass]),
        Format('object %s: %s', [Component.Name, Component.ComponentClass]),
        IfThen(Trim(Mapping.ManualReviewReason) <> '',
          Mapping.ManualReviewReason,
          'Choose and test the appropriate FMX replacement manually before relying on this screen.'),
        Component.OriginalLine,
        False);
      Exit;
    end;

    if SameText(Mapping.Action, 'partial') then
    begin
      RecordMappingPackUsage(Mapping.FMXClassName, True);
      FContext.AddManualReview(
        'Mapping pack partial conversion',
        Format('Mapping pack %s partially converted %s (%s) to %s with %d%% confidence.',
          [Mapping.PackName, Component.Name, Component.ComponentClass,
           Mapping.FMXClassName, Mapping.Confidence]),
        Format('object %s: %s', [Component.Name, Component.ComponentClass]),
        IfThen(Trim(Mapping.Notes) <> '',
          Mapping.Notes,
          'Verify properties, events, styling, and runtime behavior in the IDE.'),
        Component.OriginalLine,
        False);
    end;

    if (SameText(Mapping.Action, 'convert') or SameText(Mapping.Action, 'partial')) and
       (Mapping.Confidence < 50) then
    begin
      FContext.AddManualReview(
        'Low-confidence mapping pack rule',
        Format('Mapping pack %s rule for %s (%s) is below the automatic conversion threshold at %d%% confidence.',
          [Mapping.PackName, Component.Name, Component.ComponentClass,
           Mapping.Confidence]),
        Format('object %s: %s', [Component.Name, Component.ComponentClass]),
        'Raise the rule confidence after testing or convert this component manually.',
        Component.OriginalLine,
        False);
      Exit;
    end;

    if SameText(Mapping.Action, 'convert') then
      RecordMappingPackUsage(Mapping.FMXClassName, True);
  end;

  if Assigned(Mapping) and SameText(Mapping.MappingType, 'Unmapped') then
    FContext.AddManualReview(
      'Unsupported component',
      Format('Component %s (%s) does not have a direct generic FMX mapping and requires manual handling.',
        [Component.Name, Component.ComponentClass]),
      Format('object %s: %s', [Component.Name, Component.ComponentClass]),
      IfThen(Trim(Mapping.Notes) <> '',
        Mapping.Notes + '. ' + BuildMappingAssistanceText,
        BuildMappingAssistanceText),
      Component.OriginalLine,
      True)
  else if Assigned(Mapping) and SameText(Mapping.MappingType, 'Researched') and
          (Mapping.Confidence < 70) then
    FContext.AddManualReview(
      'Mapping assistance',
      Format('Component %s (%s) was matched to %s by generic research with only %d%% confidence.',
        [Component.Name, Component.ComponentClass, Mapping.FMXClassName,
         Mapping.Confidence]),
      Format('object %s: %s', [Component.Name, Component.ComponentClass]),
      BuildMappingAssistanceText,
      Component.OriginalLine,
      False);
  if Assigned(Mapping) and (Mapping.FMXClassName <> '') then
    Result := Mapping.FMXClassName;
end;

function TFMXGenerator.FindMappedProperty(const Component: TDFMComponent;
  const PropName: string; out PropMap: TPropertyMapping): Boolean;
var
  Mapper: TComponentMapper;
begin
  Result := False;
  if (Component = nil) or not TryGetMapper(Mapper) then
    Exit;

  // The root form/datamodule class is not matched like child controls.
  // Its top-level properties are handled by the generic root-form rewrite
  // rules below, so skipping mapper lookup avoids false unsupported-form
  // research noise in the conversion report.
  if IsRootComponent(Component) then
    Exit;

  Result := Mapper.ResolvePropertyMapping(Component.ComponentClass, PropName, PropMap);
end;

function TFMXGenerator.FindMappedEvent(const Component: TDFMComponent;
  const EventName: string; out EventMap: TEventMapping): Boolean;
var
  Mapper: TComponentMapper;
begin
  Result := False;
  if (Component = nil) or not TryGetMapper(Mapper) then
    Exit;

  if IsRootComponent(Component) then
    Exit;

  Result := Mapper.ResolveEventMapping(Component.ComponentClass, EventName, EventMap);
end;

function TFMXGenerator.CanUseFillColor(const CompClass: string): Boolean;
begin
  Result := SameText(CompClass, 'TForm') or
            SameText(CompClass, 'TShape') or
            SameText(CompClass, 'TRectangle') or
            SameText(CompClass, 'TCircle');
end;

function TFMXGenerator.FormatFMXFloatValue(const Value: string): string;
var
  FloatValue: Double;
  FormatSettings: TFormatSettings;
begin
  Result := Trim(Value);
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';

  if TryStrToFloat(Result, FloatValue, FormatSettings) then
    Result := FormatFloat('0.000000000000000000', FloatValue, FormatSettings);
end;

function TFMXGenerator.NormalizeHexBlob(const Value: string): string;
var
  Ch: Char;
begin
  Result := '';
  for Ch in UpperCase(Value) do
    if CharInSet(Ch, ['0'..'9', 'A'..'F']) then
      Result := Result + Ch;
end;

function TFMXGenerator.ExtractEmbeddedImageHex(const Value: string;
  out FormatName, HexData: string): Boolean;
const
  PNG_SIG = '89504E470D0A1A0A';
  JPG_SIG = 'FFD8FF';
  BMP_SIG = '424D';
var
  Blob: string;
  SigPos: Integer;
begin
  Result := False;
  FormatName := '';
  HexData := '';
  Blob := NormalizeHexBlob(Value);

  SigPos := Pos(PNG_SIG, Blob);
  if SigPos > 0 then
  begin
    FormatName := 'PNG';
    HexData := Copy(Blob, SigPos, MaxInt);
    Exit(True);
  end;

  SigPos := Pos(JPG_SIG, Blob);
  if SigPos > 0 then
  begin
    FormatName := 'JPEG';
    HexData := Copy(Blob, SigPos, MaxInt);
    Exit(True);
  end;

  SigPos := Pos(BMP_SIG, Blob);
  if SigPos > 0 then
  begin
    FormatName := 'BMP';
    HexData := Copy(Blob, SigPos, MaxInt);
    Exit(True);
  end;
end;

procedure TFMXGenerator.AppendHexBlock(Lines: TStringList; const Prefix,
  HexData: string);
const
  CHUNK_SIZE = 64;
var
  Offset: Integer;
  ContinuationIndent: string;
begin
  Lines.Add(Prefix + '{');
  ContinuationIndent := StringOfChar(' ', Length(Prefix));
  Offset := 1;
  while Offset <= Length(HexData) do
  begin
    Lines.Add(ContinuationIndent + Copy(HexData, Offset, CHUNK_SIZE));
    Inc(Offset, CHUNK_SIZE);
  end;
  Lines.Add(ContinuationIndent + '}');
end;

function TFMXGenerator.QuoteStringValue(const Value: string): string;
var
  Normalized: string;
  Parts: TArray<string>;
  I: Integer;
begin
  Result := Trim(Value);

  // If it's empty, return empty string
  if Result = '' then
    Exit(QuotedStr(''));

  // If it's already quoted with single quotes, return as-is
  if (Length(Result) >= 2) and (Result[1] = '''') and (Result[Length(Result)] = '''') then
    Exit;

  // If it's already quoted with double quotes, convert to single quotes
  if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
  begin
    Result := Copy(Result, 2, Length(Result) - 2);
    Result := '''' + Result + '''';
    Exit;
  end;

  // If it's a hex color value, don't quote
  if Result.StartsWith('$') then
    Exit;

  // Encode multiline text as a Delphi string expression instead of embedding
  // raw newlines into the FMX file.
  if (Pos(#13, Result) > 0) or (Pos(#10, Result) > 0) then
  begin
    Normalized := StringReplace(Result, #13#10, #10, [rfReplaceAll]);
    Normalized := StringReplace(Normalized, #13, #10, [rfReplaceAll]);
    Parts := Normalized.Split([#10]);
    Result := '';
    for I := 0 to High(Parts) do
    begin
      if I > 0 then
        Result := Result + '#13#10';
      Result := Result + QuotedStr(Parts[I]);
    end;
    Exit;
  end;

  // Quote string values that need it
  Result := QuotedStr(Result);
end;

function TFMXGenerator.IsVCLProperty(const PropName: string): Boolean;
begin
  Result := (PropName = 'Font.Height') or
            (PropName = 'Font.Style') or
            (PropName = 'Font.Charset') or
            (PropName = 'StyleElements') or
            (PropName = 'KeyPreview') or
            (PropName = 'Menu') or
            (PropName = 'BorderIcons') or
            (PropName = 'ActiveControl') or
            (PropName = 'PrintScale') or
            (PropName = 'TextHeight') or
            (PropName = 'ParentFont') or
            (PropName = 'ParentColor') or
            (PropName = 'ParentShowHint') or
            (PropName = 'ParentCtl3D') or
            (PropName = 'BevelKind') or
            (PropName = 'BevelInner') or
            (PropName = 'BevelOuter') or
            (PropName = 'BevelWidth') or
            (PropName = 'BorderWidth') or
            (PropName = 'Ctl3D') or
            PropName.StartsWith('TitleFont.') or
            PropName.StartsWith('Explicit');
end;

function TFMXGenerator.IsRootComponent(const Component: TDFMComponent): Boolean;
begin
  Result := (Component <> nil) and (Component.Parent = '');
end;

function TFMXGenerator.IsStructuralWrapperPanel(
  const Component: TDFMComponent): Boolean;
var
  SourceClass: string;
  AlignValue: string;
  CaptionValue: string;
  ShowFrameValue: string;
begin
  Result := False;
  if Component = nil then
    Exit;

  SourceClass := Component.ComponentClass;
  if SourceClass = '' then
    SourceClass := Component.ObjectClass;

  if SameText(SourceClass, 'TGroupBox') then
  begin
    CaptionValue := Trim(Component.GetPropertyValue('Caption', ''));
    if CaptionValue <> '' then
      Exit;

    ShowFrameValue := Trim(Component.GetPropertyValue('ShowFrame', ''));
    if not SameText(ShowFrameValue, 'False') then
      Exit;

    Result := True;
    Exit;
  end;

  if not SameText(SourceClass, 'TPanel') then
    Exit;

  AlignValue := Trim(Component.GetPropertyValue('Align', ''));
  if not SameText(AlignValue, 'alClient') then
    Exit;

  if Component.HasProperty('Color') then
    Exit;

  if Component.HasProperty('ParentBackground') and
     SameText(Trim(Component.GetPropertyValue('ParentBackground', '')), 'False') then
    Exit;

  CaptionValue := Trim(Component.GetPropertyValue('Caption', ''));
  if CaptionValue <> '' then
    Exit;

  if Component.HasProperty('BevelInner') or Component.HasProperty('BevelOuter') or
     Component.HasProperty('BevelKind') or Component.HasProperty('BevelWidth') or
     Component.HasProperty('BorderStyle') then
    Exit;

  Result := True;
end;

function TFMXGenerator.SupportsGeneratedFontProps(const CompClass: string): Boolean;
begin
  Result := SameText(CompClass, 'TLabel') or
            SameText(CompClass, 'TButton') or
            SameText(CompClass, 'TSpeedButton') or
            SameText(CompClass, 'TCheckBox') or
            SameText(CompClass, 'TRadioButton') or
            SameText(CompClass, 'TEdit') or
            SameText(CompClass, 'TMemo') or
            SameText(CompClass, 'TListBoxItem') or
            SameText(CompClass, 'TGroupBox');
end;

function TFMXGenerator.SupportsTextAlign(const CompClass: string): Boolean;
begin
  Result := SameText(CompClass, 'TLabel') or
            SameText(CompClass, 'TButton') or
            SameText(CompClass, 'TSpeedButton') or
            SameText(CompClass, 'TCheckBox') or
            SameText(CompClass, 'TRadioButton') or
            SameText(CompClass, 'TEdit') or
            SameText(CompClass, 'TMemo') or
            SameText(CompClass, 'TSpinBox') or
            SameText(CompClass, 'TNumberBox');
end;

function TFMXGenerator.BuildStyledSettingsLiteral(Component: TDFMComponent; const CompClass: string): string;
var
  StyledBits: TStringList;
  HasFontOverride: Boolean;
  NeedsOtherOverride: Boolean;
  SupportsStyledText: Boolean;
begin
  Result := '';
  if Component = nil then
    Exit;

  SupportsStyledText := SupportsGeneratedFontProps(CompClass) or SupportsTextAlign(CompClass);
  if not SupportsStyledText then
    Exit;

  HasFontOverride := Component.Properties.ContainsKey('Font.Name') or
    Component.Properties.ContainsKey('Font.Height') or
    Component.Properties.ContainsKey('Font.Style') or
    Component.Properties.ContainsKey('Font.Color');

  NeedsOtherOverride := (SupportsTextAlign(CompClass) and Component.Properties.ContainsKey('Alignment')) or
    Component.Properties.ContainsKey('WordWrap') or
    (SameText(CompClass, 'TLabel') and HasFontOverride and
     not SameText(Component.GetPropertyValue('WordWrap', 'False'), 'True') and
     not Component.Properties.ContainsKey('AutoSize'));

  if not (HasFontOverride or NeedsOtherOverride) then
    Exit;

  StyledBits := TStringList.Create;
  try
    StyledBits.Add('Family');
    StyledBits.Add('Size');
    StyledBits.Add('Style');
    StyledBits.Add('FontColor');
    StyledBits.Add('Other');

    if Component.Properties.ContainsKey('Font.Name') then
      StyledBits.Delete(StyledBits.IndexOf('Family'));
    if Component.Properties.ContainsKey('Font.Height') then
      StyledBits.Delete(StyledBits.IndexOf('Size'));
    if Component.Properties.ContainsKey('Font.Style') then
      StyledBits.Delete(StyledBits.IndexOf('Style'));
    if Component.Properties.ContainsKey('Font.Color') then
      StyledBits.Delete(StyledBits.IndexOf('FontColor'));
    if NeedsOtherOverride then
      StyledBits.Delete(StyledBits.IndexOf('Other'));

    Result := '[' + StringReplace(Trim(StyledBits.CommaText), ',', ', ', [rfReplaceAll]) + ']';
  finally
    StyledBits.Free;
  end;
end;

function TFMXGenerator.TransformFontProps(Component: TDFMComponent): string;
var
  FontName, FontSize, FontColor, FontStyle: string;
  SizeVal: Integer;
  PointSize: Integer;
  CompClass: string;
begin
  CompClass := GetComponentClass(Component);
  FontName := Component.GetPropertyValue('Font.Name', 'Segoe UI');
  FontSize := Component.GetPropertyValue('Font.Height', '');
  FontStyle := Component.GetPropertyValue('Font.Style', '');
  FontColor := Component.GetPropertyValue('Font.Color', 'clBlack');

  // Favor readable text on light FMX surfaces. Some VCL forms use white
  // caption text on controls that inherit a light background, which makes
  // the converted FMX UI effectively unreadable.
  if SameText(FontColor, 'clWhite') and
     (SameText(CompClass, 'TCheckBox') or
      SameText(CompClass, 'TGroupBox') or
      SameText(CompClass, 'TLabel') or
      SameText(CompClass, 'TButton') or
      SameText(CompClass, 'TSpeedButton')) then
    FontColor := 'clBlack';

  Result := 'TextSettings.Font.Family = ' + QuoteStringValue(FontName);

  if FontSize <> '' then
  begin
    try
      SizeVal := StrToInt(FontSize);
      if SizeVal < 0 then
        // FMX tends to render converted text smaller than the original VCL
        // forms, so bias negative VCL font heights toward their original
        // visual size and keep a readable minimum body size.
        PointSize := Max(12, Round(Abs(SizeVal) * 0.95))
      else
        PointSize := Max(12, SizeVal);

      // Small and medium-sized converted text still tends to look undersized
      // in FMX, while large headings are already visually close.
      if PointSize < 24 then
        Inc(PointSize);

      // Grid content needs a little more help to remain readable at normal
      // desktop viewing distances.
      if SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid') then
        Inc(PointSize, 2);

      Result := Result + #13#10 + GetIndent + 'TextSettings.Font.Size = ' + IntToStr(PointSize);
    except
      // Ignore conversion errors
    end;
  end;

  if FontStyle <> '' then
    Result := Result + #13#10 + GetIndent + 'TextSettings.Font.Style = ' + FontStyle;

  if FontColor <> '' then
    Result := Result + #13#10 + GetIndent + 'TextSettings.FontColor = ' + TransformColor(FontColor);
end;

function TFMXGenerator.GetComponentClass(const Component: TDFMComponent): string;
var
  ShapeKind: string;
  Mapper: TComponentMapper;
  Mapping: TComponentMapping;
begin
  if Component = nil then
    Exit('TComponent');

  if SameText(Component.ComponentClass, 'TTrayIcon') then
    Exit('');

  if IsStructuralWrapperPanel(Component) then
    Exit('TLayout');

  if SameText(Component.ComponentClass, 'TShape') then
  begin
    ShapeKind := Trim(Component.GetPropertyValue('Shape', ''));
    if SameText(ShapeKind, 'stCircle') or SameText(ShapeKind, 'stEllipse') then
      Exit('TEllipse');
    if SameText(ShapeKind, 'stRoundRect') or SameText(ShapeKind, 'stRoundSquare') then
      Exit('TRoundRect');
    Exit('TRectangle');
  end;

  Result := GetMappedComponentClass(Component);
  if Result <> '' then
    Exit;

  if TryGetMapper(Mapper) then
  begin
    Mapping := Mapper.EnsureBestMatch(Component.ComponentClass);
    if Assigned(Mapping) and SameText(Mapping.MappingSource, 'pack') and
       (SameText(Mapping.Action, 'detect_only') or
        SameText(Mapping.Action, 'manual_review') or
        ((SameText(Mapping.Action, 'convert') or SameText(Mapping.Action, 'partial')) and
         (Mapping.Confidence < 50))) then
      Exit('');
  end;

  if Component.ObjectClass <> '' then
    Result := Component.ObjectClass
  else if Component.ComponentClass <> '' then
    Result := Component.ComponentClass
  else
    Result := 'TComponent';

  if not Result.StartsWith('T') then
    Result := 'T' + Result;
end;

procedure TFMXGenerator.HandleImageComponent(Component: TDFMComponent; Lines: TStringList);
var
  ImageFormat: string;
  HexData: string;
  PngHex: string;
  BitmapWidth: Integer;
  BitmapHeight: Integer;
  WrapModeValue: string;
begin
  WrapModeValue := '';

  if Component.HasProperty('Stretch') and SameText(Component.GetPropertyValue('Stretch'), 'True') then
    WrapModeValue := 'Stretch';

  if Component.HasProperty('Proportional') then
  begin
    if SameText(Component.GetPropertyValue('Proportional'), 'True') then
      WrapModeValue := 'Fit'
    else if WrapModeValue = '' then
      WrapModeValue := 'Stretch';
  end;

  if WrapModeValue <> '' then
    Lines.Add(GetIndent + 'WrapMode = ' + WrapModeValue);

  if Component.HasProperty('Picture.Data') and
     ExtractEmbeddedImageHex(Component.GetPropertyValue('Picture.Data', ''),
       ImageFormat, HexData) then
  begin
    if ConvertImageHexToPngHex(HexData, PngHex, BitmapWidth, BitmapHeight) then
    begin
      Lines.Add(GetIndent + 'MultiResBitmap = <');
      FIndentLevel := FIndentLevel + 1;
      Lines.Add(GetIndent + 'item');
      FIndentLevel := FIndentLevel + 1;
      if BitmapWidth > 0 then
        Lines.Add(GetIndent + 'Width = ' + IntToStr(BitmapWidth));
      if BitmapHeight > 0 then
        Lines.Add(GetIndent + 'Height = ' + IntToStr(BitmapHeight));
      AppendHexBlock(Lines, GetIndent + 'PNG = ', PngHex);
      FIndentLevel := FIndentLevel - 1;
      Lines.Add(GetIndent + 'end>');
      FIndentLevel := FIndentLevel - 1;
    end
    else
      FContext.AddIssue(csWarning, Format(
        'Embedded %s image in %s could not be converted to FMX bitmap data',
        [ImageFormat, Component.Name]));
  end
  else if Component.HasProperty('Picture.Data') then
    FContext.AddIssue(csWarning, Format(
      'Embedded image payload in %s could not be identified automatically',
      [Component.Name]));
end;

procedure TFMXGenerator.HandleStringCollection(Component: TDFMComponent; const PropName, PropValue: string; Lines: TStringList);
var
  CleanValue: string;
  RawLines: TStringList;
  RawLine: string;
  Matches: TMatchCollection;
  Match: TMatch;
begin
  CleanValue := CleanParentheses(PropValue);

  if CleanValue = '' then
    Lines.Add(GetIndent + PropName + ' = ()')
  else
  begin
    Matches := TRegEx.Matches(CleanValue, '''(?:''''|[^''])*''');
    if Matches.Count > 0 then
    begin
      Lines.Add(GetIndent + PropName + ' = (');
      FIndentLevel := FIndentLevel + 1;
      for Match in Matches do
        Lines.Add(GetIndent + Match.Value);
      FIndentLevel := FIndentLevel - 1;
      Lines.Add(GetIndent + ')');
    end
    else
    begin
      RawLines := TStringList.Create;
      try
        RawLines.Text := StringReplace(CleanValue, sLineBreak, #13#10, [rfReplaceAll]);
        Lines.Add(GetIndent + PropName + ' = (');
        FIndentLevel := FIndentLevel + 1;
        for RawLine in RawLines do
          if Trim(RawLine) <> '' then
            Lines.Add(GetIndent + QuoteStringValue(Trim(RawLine)));
        FIndentLevel := FIndentLevel - 1;
        Lines.Add(GetIndent + ')');
      finally
        RawLines.Free;
      end;
    end;
  end;
end;

procedure TFMXGenerator.GenerateCollection(Component: TDFMComponent; Lines: TStringList);
var
  Item: TDFMComponent;
  PropName: string;
  PropValue: string;
begin
  if Component.CollectionItems.Count = 0 then
  begin
    Lines.Add(GetIndent + Component.Name + ' = <>');
    Exit;
  end;

  Lines.Add(GetIndent + Component.Name + ' = <');
  FIndentLevel := FIndentLevel + 1;

  for Item in Component.CollectionItems do
  begin
    Lines.Add(GetIndent + 'item');
    FIndentLevel := FIndentLevel + 1;

    for PropName in Item.Properties.Keys do
    begin
      PropValue := Item.Properties[PropName];
      Lines.Add(GetIndent + PropName + ' = ' + PropValue);
    end;

    FIndentLevel := FIndentLevel - 1;
    Lines.Add(GetIndent + 'end');
  end;

  FIndentLevel := FIndentLevel - 1;
  Lines.Add(GetIndent + '>');
end;

procedure TFMXGenerator.GenerateFields(Component: TDFMComponent; Lines: TStringList);
var
  Child: TDFMComponent;
begin
  for Child in Component.Children do
  begin
    if Child.ComponentClass.EndsWith('Field') then
    begin
      FIndentLevel := FIndentLevel + 1;
      Lines.Add(GetIndent + 'object ' + Child.Name + ': ' + Child.ComponentClass);
      FIndentLevel := FIndentLevel + 1;

      if Child.Properties.ContainsKey('FieldName') then
        Lines.Add(GetIndent + 'FieldName = ' + QuoteStringValue(Child.Properties['FieldName']));
      if Child.Properties.ContainsKey('Origin') then
        Lines.Add(GetIndent + 'Origin = ' + QuoteStringValue(Child.Properties['Origin']));
      if Child.Properties.ContainsKey('Required') then
        Lines.Add(GetIndent + 'Required = ' + Child.Properties['Required']);

      FIndentLevel := FIndentLevel - 1;
      Lines.Add(GetIndent + 'end');
      FIndentLevel := FIndentLevel - 1;
    end;
  end;
end;

function TFMXGenerator.GenerateFMX(Components: TObjectList<TDFMComponent>): string;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    FRootComponent := nil;
    if (Components <> nil) and (Components.Count > 0) then
    begin
      FRootComponent := Components[0];
      Lines.Text := GenerateComponent(Components[0]);
    end;

    Result := Lines.Text;
    NormalizeGeneratedFMX(Result);
  finally
    FRootComponent := nil;
    Lines.Free;
  end;
end;

function TFMXGenerator.NormalizeAlignLayoutValue(const Value: string): string;
begin
  Result := Value;

  if SameText(Result, 'alTop') then
    Result := 'Top'
  else if SameText(Result, 'alBottom') then
    Result := 'Bottom'
  else if SameText(Result, 'alLeft') then
    Result := 'Left'
  else if SameText(Result, 'alRight') then
    Result := 'Right'
  else if SameText(Result, 'alClient') then
    Result := 'Client'
  else if SameText(Result, 'alContents') then
    Result := 'Contents'
  else if SameText(Result, 'alCenter') then
    Result := 'Center'
  else if SameText(Result, 'alMostTop') then
    Result := 'MostTop'
  else if SameText(Result, 'alMostBottom') then
    Result := 'MostBottom'
  else if SameText(Result, 'alNone') then
    Result := 'None';
end;

procedure TFMXGenerator.NormalizeGeneratedFMX(var Code: string);
var
  Lines: TStringList;
  I: Integer;
  LineMatch: TMatch;
  OriginalValue: string;
  NormalizedValue: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Code;
    for I := 0 to Lines.Count - 1 do
    begin
      LineMatch := TRegEx.Match(Lines[I], '^(\s*Align\s*=\s*)([A-Za-z0-9_]+)(\s*)$');
      if not LineMatch.Success then
        Continue;

      OriginalValue := LineMatch.Groups[2].Value;
      NormalizedValue := NormalizeAlignLayoutValue(OriginalValue);
      if not SameText(OriginalValue, NormalizedValue) then
        Lines[I] := LineMatch.Groups[1].Value + NormalizedValue + LineMatch.Groups[3].Value;
    end;

    Code := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TFMXGenerator.GenerateStatusBarPanels(Component: TDFMComponent;
  Lines: TStringList);
var
  PanelsCollection: TDFMComponent;
  Item: TDFMComponent;
  Child: TDFMComponent;
  PanelIndex: Integer;
  StatusBarWidth: Integer;
  StatusBarHeight: Integer;
  CurrentX: Integer;
  PanelWidth: Integer;
  RemainingWidth: Integer;
  PanelText: string;
  PanelAlign: string;
  HorzAlign: string;
begin
  if Component = nil then
    Exit;

  PanelsCollection := nil;
  if Component.CollectionItems.Count > 0 then
    PanelsCollection := Component
  else if Component.Children <> nil then
  begin
    for Child in Component.Children do
      if Child.IsCollection and SameText(Child.Name, 'Panels') then
      begin
        PanelsCollection := Child;
        Break;
      end;
  end;

  if (PanelsCollection = nil) or (PanelsCollection.CollectionItems = nil) or
     (PanelsCollection.CollectionItems.Count = 0) then
    Exit;

  StatusBarWidth := StrToIntDef(Component.GetPropertyValue('Width', '0'), 0);
  StatusBarHeight := StrToIntDef(Component.GetPropertyValue('Height', '26'), 26);
  CurrentX := 0;
  PanelIndex := 0;

  for Item in PanelsCollection.CollectionItems do
  begin
    PanelText := Item.GetPropertyValue('Text', '');
    PanelWidth := StrToIntDef(Item.GetPropertyValue('Width', '0'), 0);

    if (PanelIndex = PanelsCollection.CollectionItems.Count - 1) and (StatusBarWidth > 0) then
    begin
      RemainingWidth := StatusBarWidth - CurrentX;
      if RemainingWidth > PanelWidth then
        PanelWidth := RemainingWidth;
    end;

    if PanelWidth <= 0 then
      PanelWidth := 150;

    PanelAlign := Item.GetPropertyValue('Alignment', 'taLeftJustify');
    if SameText(PanelAlign, 'taCenter') then
      HorzAlign := 'Center'
    else if SameText(PanelAlign, 'taRightJustify') then
      HorzAlign := 'Trailing'
    else
      HorzAlign := 'Leading';

    FIndentLevel := FIndentLevel + 1;
    Lines.Add(GetIndent + 'object ' + Component.Name + 'Panel' + IntToStr(PanelIndex) + ': TLabel');
    FIndentLevel := FIndentLevel + 1;
    Lines.Add(GetIndent + 'Position.X = ' + FormatFMXFloatValue(IntToStr(CurrentX + 8)));
    Lines.Add(GetIndent + 'Position.Y = ' + FormatFMXFloatValue('4'));
    Lines.Add(GetIndent + 'Size.Width = ' + FormatFMXFloatValue(IntToStr(Max(24, PanelWidth - 12))));
    Lines.Add(GetIndent + 'Size.Height = ' + FormatFMXFloatValue(IntToStr(Max(18, StatusBarHeight - 8))));
    Lines.Add(GetIndent + 'Text = ' + QuoteStringValue(PanelText));
    Lines.Add(GetIndent + 'StyledSettings = [Family, Size, Style, FontColor]');
    Lines.Add(GetIndent + 'TextSettings.HorzAlign = ' + HorzAlign);
    Lines.Add(GetIndent + 'VertTextAlign = Center');
    Lines.Add(GetIndent + 'HitTest = False');
    Lines.Add(GetIndent + 'Size.PlatformDefault = False');
    FIndentLevel := FIndentLevel - 1;
    Lines.Add(GetIndent + 'end');
    FIndentLevel := FIndentLevel - 1;

    Inc(CurrentX, PanelWidth);
    Inc(PanelIndex);
  end;
end;

function TFMXGenerator.GenerateComponent(Component: TDFMComponent): string;
var
  Lines: TStringList;
  PropName, PropValue: string;
  EventName, EventHandler: string;
  Child: TDFMComponent;
  ChildCode: string;
  CompClass: string;
  FontProps: string;
  ConvertedPropName: string;
  SubPropName: string;
  PropMap: TPropertyMapping;
  EventMap: TEventMapping;
  GridOptionsText: string;
  HasExplicitSize: Boolean;
  HasExplicitWidth: Boolean;
  HasExplicitHeight: Boolean;
  ClientAlignedWidth: string;
  ClientAlignedHeight: string;
  StyledSettingsLiteral: string;
  LabelUsesAutoSize: Boolean;
  LabelUsesWordWrap: Boolean;
  ParentComp: TDFMComponent;
  ParentWidth: Integer;
  ParentHeight: Integer;
  EffectiveHeight: Integer;
  SizeVal: Integer;
  ColumnIndex: Integer;
  ColumnCount: Integer;
  FontHeightVal: Integer;
  LabelCaptionLen: Integer;
  LabelAlignment: string;
  LabelHasManualBreaks: Boolean;
  LabelCaptionText: string;
  LabelLongestWordLen: Integer;
  WrappedWordMinWidth: Integer;
  LabelWidthAdjust: Integer;
  PositionXLineIndex: Integer;
  Mapper: TComponentMapper;
  SourceVCLClass: string;
  TargetFMXClass: string;
  CanValidateTargetClass: Boolean;
  SkipTargetEventValidation: Boolean;
  SkipTargetPropertyValidation: Boolean;
  EventRecommendation: string;
  WordPart: string;

  function UnsupportedEventRecommendation(const AEventName, ATargetEvent, ATargetClass: string): string;
  begin
    if SameText(AEventName, 'OnKeyPress') then
      Exit('FMX does not use the VCL OnKeyPress signature. Move character/text-input logic to OnTyping where available, or adapt it to OnKeyDown/OnKeyUp and review Key/KeyChar handling manually.');

    if SameText(AEventName, 'OnBeforeMonitorDpiChanged') then
      Exit('FMX has no direct OnBeforeMonitorDpiChanged event. Use OnResize, FMX layout scaling, and platform services such as IFMXScreenService when DPI/display changes must be handled explicitly.');

    if SameText(AEventName, 'OnMouseDown') then
      Exit('FMX supports OnMouseDown, but the handler signature differs from VCL. Reconnect the event in the IDE and adapt the parameters to FMX Shift/Button/X/Y types.');

    if SameText(AEventName, 'OnMouseUp') or SameText(AEventName, 'OnMouseMove') then
      Exit('FMX has a related mouse event, but the handler signature and coordinate types may differ. Reconnect the event in the IDE and adapt the parameters.');

    if SameText(AEventName, 'OnKeyDown') or SameText(AEventName, 'OnKeyUp') then
      Exit('FMX has keyboard events, but the handler signature may differ. Reconnect the event in the IDE and adapt Key, KeyChar, and Shift handling.');

    Result := Format('The VCL %s handler signature is not compatible with FMX %s on %s. Reconnect this event manually in the IDE.',
      [AEventName, ATargetEvent, ATargetClass]);
  end;

begin
  if Component = nil then
    Exit('');

  Lines := TStringList.Create;
  try
    CompClass := GetComponentClass(Component);
    if CompClass = '' then
      Exit('');
    HasExplicitSize := False;
    HasExplicitWidth := False;
    HasExplicitHeight := False;
    ClientAlignedWidth := '';
    ClientAlignedHeight := '';
    StyledSettingsLiteral := BuildStyledSettingsLiteral(Component, CompClass);
    LabelAlignment := Component.GetPropertyValue('Alignment', '');
    LabelCaptionText := Component.GetPropertyValue('Caption',
      Component.GetPropertyValue('Text', ''));
    LabelUsesAutoSize := SameText(CompClass, 'TLabel') and
      (SameText(Component.GetPropertyValue('AutoSize', 'False'), 'True') or
       (not SameText(Component.GetPropertyValue('WordWrap', 'False'), 'True') and
        not Component.Properties.ContainsKey('AutoSize')));
    LabelUsesWordWrap := SameText(CompClass, 'TLabel') and
      SameText(Component.GetPropertyValue('WordWrap', 'False'), 'True');
    ParentComp := nil;
    ParentWidth := 0;
    ParentHeight := 0;
    EffectiveHeight := 0;
    FontHeightVal := Abs(StrToIntDef(Component.GetPropertyValue('Font.Height', '0'), 0));
    LabelCaptionLen := Length(Trim(LabelCaptionText));
    LabelHasManualBreaks := Pos('#13#10', LabelCaptionText) > 0;
    LabelLongestWordLen := 0;
    for WordPart in StringReplace(LabelCaptionText, '#13#10', ' ',
      [rfReplaceAll, rfIgnoreCase]).Split([' ', #9]) do
      if Length(Trim(WordPart)) > LabelLongestWordLen then
        LabelLongestWordLen := Length(Trim(WordPart));
    if LabelUsesWordWrap and (LabelLongestWordLen > 0) then
      WrappedWordMinWidth := Round(LabelLongestWordLen *
        Max(6.5, FontHeightVal * 0.68)) + 14
    else
      WrappedWordMinWidth := 0;
    LabelWidthAdjust := 0;
    PositionXLineIndex := -1;
    CanValidateTargetClass := TryGetMapper(Mapper);
    SourceVCLClass := GetSourceVCLClassName(Component);
    TargetFMXClass := GetTargetFMXClassName(Component);
    if CanValidateTargetClass then
      CanValidateTargetClass := Mapper.KnowsFMXClass(TargetFMXClass);

    // Flag for uses clause
    if NeedsFMXObjects(Component) then
      FContext.AddIssue(csInfo, 'NeedsFMXObjects:' + CompClass);

    Lines.Add('object ' + Component.Name + ': ' + CompClass);
    FIndentLevel := FIndentLevel + 1;

    // Special handling for TImage
    if (Component.ComponentClass = 'TImage') or (CompClass = 'TImage') then
      HandleImageComponent(Component, Lines);

    // Handle font properties specially
    if StyledSettingsLiteral <> '' then
      Lines.Add(GetIndent + 'StyledSettings = ' + StyledSettingsLiteral);

    if Component.Properties.ContainsKey('Font.Name') or
       Component.Properties.ContainsKey('Font.Height') or
       Component.Properties.ContainsKey('Font.Color') or
       Component.Properties.ContainsKey('Font.Style') then
    begin
      if SupportsGeneratedFontProps(CompClass) then
      begin
        FontProps := TransformFontProps(Component);
        if FontProps <> '' then
          Lines.Add(GetIndent + FontProps);

      end
      else if SameText(CompClass, 'TFontDialog') then
      begin
        if Component.Properties.ContainsKey('Font.Name') then
          Lines.Add(GetIndent + 'Font.Family = ' +
            QuoteStringValue(Component.GetPropertyValue('Font.Name', 'Segoe UI')));

        if Component.Properties.ContainsKey('Font.Height') then
        begin
          try
            SizeVal := Abs(StrToInt(Component.GetPropertyValue('Font.Height', '0')));
            if SizeVal > 0 then
              Lines.Add(GetIndent + 'Font.Size = ' + IntToStr(SizeVal));
          except
            // Ignore malformed font sizes
          end;
        end;

        if Component.Properties.ContainsKey('Font.Style') then
          Lines.Add(GetIndent + 'Font.Style = ' +
            Component.GetPropertyValue('Font.Style', '[]'));
      end
      else
        FContext.AddIssue(csInfo, Format(
          'Skipped automatic font conversion for %s (%s); review manually in FMX designer',
          [Component.Name, CompClass]));
    end;

    // Preserve typical VCL label sizing behavior in FMX so dynamic runtime
    // captions can grow to fit without truncation, even when the label did
    // not store explicit font properties in the source DFM.
    if SameText(CompClass, 'TLabel') and LabelUsesAutoSize then
    begin
      Lines.Add(GetIndent + 'AutoSize = True');
      Lines.Add(GetIndent + 'WordWrap = False');
    end;

    // Generate regular properties (skip VCL-only and font props)
    for PropName in Component.Properties.Keys do
    begin
      if IsVCLProperty(PropName) then
        Continue;
      if PropName.StartsWith('Font.') then
        Continue;

      PropValue := Component.Properties[PropName];
      ConvertedPropName := PropName;
      SkipTargetPropertyValidation := False;

      if SameText(CompClass, 'TEdit') and SameText(PropName, 'PasswordChar') then
      begin
        ConvertedPropName := 'Password';
        PropValue := BoolToStr(not SameText(Trim(PropValue), '#0') and
                               not SameText(Trim(PropValue), '''''') and
                               (Trim(PropValue) <> ''),
                               True);
        Lines.Add(GetIndent + ConvertedPropName + ' = ' + PropValue);
        Continue;
      end;
      // Skip Position properties for non-visual components
      if IsNonVisualComponent(Component) and
         ((PropName = 'Position.X') or (PropName = 'Position.Y') or
          (PropName = 'Width') or (PropName = 'Height') or
          (PropName = 'Align') or (PropName = 'Anchors') or
          (PropName = 'TabOrder') or (PropName = 'TabStop') or
          (PropName = 'Visible') or (PropName = 'Hint') or
          (PropName = 'ShowHint') or (PropName = 'ParentDoubleBuffered') or
          (PropName = 'DoubleBuffered')) then
        Continue;

      if IsNonVisualComponent(Component) and PropName.Contains('.') and
         not SameText(PropName, 'Params.Strings') and
         not SameText(PropName, 'SQL.Strings') and
         not SameText(PropName, 'FieldOptions.BlobDisplayValue') then
        Continue;

      if not IsNonVisualComponent(Component) and
         (SameText(PropName, 'DataSource') or SameText(PropName, 'DataField') or
          SameText(PropName, 'ListSource') or SameText(PropName, 'ListField') or
          SameText(PropName, 'KeyField')) then
        Continue;

      if (SameText(CompClass, 'TLayout') or SameText(CompClass, 'TPanel') or
          SameText(CompClass, 'TGroupBox')) and
         (SameText(PropName, 'AutoSize') or SameText(PropName, 'ParentBackground') or
          SameText(PropName, 'ShowFrame')) then
        Continue;

      // Converted DB combo controls use TComboEdit and must stay editable so
      // users can pick or type values at runtime.
      if SameText(Component.ComponentClass, 'TDBComboBox') and
         SameText(CompClass, 'TComboEdit') and
         SameText(PropName, 'ReadOnly') then
        Continue;

      if SameText(CompClass, 'TImage') and
         (SameText(PropName, 'AutoSize') or SameText(PropName, 'Proportional') or
          SameText(PropName, 'Center') or SameText(PropName, 'Stretch')) then
        Continue;

      if SameText(CompClass, 'TImageList') and SameText(PropName, 'Bitmap') then
        Continue;
      if SameText(PropName, 'HelpContext') then
      begin
        ConvertedPropName := 'HelpContext';
        SkipTargetPropertyValidation := True;
      end;

      if SameText(CompClass, 'TMemo') and SameText(PropName, 'WantReturns') then
      begin
        if SameText(Trim(PropValue), 'True') then
          Continue;
        AddUnsupportedPropertyReview(
          Component,
          PropName,
          Component.GetPropertyValue(PropName, PropValue),
          'FMX TMemo accepts return keys by default. Review this memo manually if the VCL form intentionally blocked return keys.');
        Continue;
      end;




      if SameText(CompClass, 'TCheckBox') and
         (SameText(PropName, 'ValueChecked') or SameText(PropName, 'ValueUnchecked')) then
        Continue;

      if SameText(PropName, 'IsControl') then
        Continue;

      if SameText(PropName, 'BevelEdges') and SameText(Trim(PropValue), '[]') then
        Continue;

      if SameText(CompClass, 'TPopupMenu') and
         (SameText(PropName, 'Left') or SameText(PropName, 'Top')) then
        Continue;

      if SameText(CompClass, 'TForm') and SameText(PropName, 'PopupMode') then
      begin
        if SameText(Trim(PropValue), 'pmExplicit') and
           not Component.HasProperty('PopupParent') then
          Continue;
        AddUnsupportedPropertyReview(
          Component,
          PropName,
          Component.GetPropertyValue(PropName, PropValue),
          'Review this popup form manually. FMX usually uses TPopup, FormStyle = Popup, or FormStyle = StayOnTop depending on how the VCL form is shown.');
        Continue;
      end;

      if SameText(CompClass, 'TLabel') and
         SameText(PropName, 'Transparent') and SameText(Trim(PropValue), 'True') then
        Continue;

      if SameText(CompClass, 'TToolBar') and
         ((SameText(PropName, 'Wrapable') and SameText(Trim(PropValue), 'False')) or
          (SameText(PropName, 'Transparent') and SameText(Trim(PropValue), 'True')) or
          SameText(PropName, 'Indent') or
          (SameText(PropName, 'ShowCaptions') and SameText(Trim(PropValue), 'True')) or
          (SameText(PropName, 'Caption') and SameText(Trim(PropValue), Component.Name)) or
          (SameText(PropName, 'EdgeInner') and SameText(Trim(PropValue), 'esNone')) or
          (SameText(PropName, 'EdgeOuter') and SameText(Trim(PropValue), 'esNone'))) then
        Continue;

      if SameText(CompClass, 'TButton') and SameText(PropName, 'Grouped') then
        Continue;

      if (SameText(CompClass, 'TButton') or SameText(CompClass, 'TSpeedButton')) and SameText(PropName, 'Wrap') then
      begin
        ConvertedPropName := 'TextSettings.WordWrap';
        PropValue := BoolToStr(SameText(Trim(PropValue), 'True'), True);
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TSpeedButton') and SameText(PropName, 'Flat') and
              SameText(Trim(PropValue), 'True') then
        Continue
      else if SameText(CompClass, 'TSpeedButton') and SameText(PropName, 'GroupIndex') then
      begin
        ConvertedPropName := 'GroupName';
        PropValue := QuoteStringValue('Group' + Trim(PropValue));
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TSpeedButton') and SameText(PropName, 'AllowAllUp') then
      begin
        if SameText(Trim(PropValue), 'True') then
          Lines.Add(GetIndent + 'StaysPressed = True');
        Continue;
      end
      else if SameText(CompClass, 'TAction') and SameText(PropName, 'Category') then
        Continue
      else if SameText(CompClass, 'TAction') and
              (SameText(PropName, 'ImageIndex') or SameText(PropName, 'Tag') or
               SameText(PropName, 'GroupIndex') or SameText(PropName, 'Visible') or
               SameText(PropName, 'Hint') or SameText(PropName, 'HelpContext') or
               SameText(PropName, 'HelpKeyword') or SameText(PropName, 'HelpType')) then
      begin
        ConvertedPropName := PropName;
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TAction') and SameText(PropName, 'ImageName') then
        Continue
      else if SameText(CompClass, 'TActionList') and SameText(PropName, 'Images') then
      begin
        ConvertedPropName := 'Images';
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TListBox') and SameText(PropName, 'ExtendedSelect') then
      begin
        ConvertedPropName := 'MultiSelectStyle';
        if SameText(Trim(PropValue), 'True') then
          PropValue := 'Extended'
        else
          PropValue := 'None';
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TListBox') and SameText(PropName, 'IntegralHeight') then
        Continue
      else if SameText(CompClass, 'TStringGrid') and SameText(PropName, 'DefaultRowHeight') then
      begin
        ConvertedPropName := 'RowHeight';
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TStringGrid') and SameText(PropName, 'ScrollBars') then
      begin
        ConvertedPropName := 'ShowScrollBars';
        PropValue := BoolToStr(not SameText(Trim(PropValue), 'ssNone'), True);
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TStringGrid') and SameText(PropName, 'ColCount') then
        Continue
      else if SameText(CompClass, 'TTabItem') and SameText(PropName, 'TabVisible') then
      begin
        ConvertedPropName := 'Visible';
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TTabControl') and SameText(PropName, 'TabIndex') then
      begin
        ConvertedPropName := 'TabIndex';
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TTabControl') and SameText(PropName, 'Tabs.Strings') then
        Continue
      else if SameText(CompClass, 'TListView') and
              (SameText(PropName, 'Align') or SameText(PropName, 'Width') or
               SameText(PropName, 'Height')) then
      begin
        ConvertedPropName := PropName;
        SkipTargetPropertyValidation := True;
      end
      else if SameText(CompClass, 'TListView') and SameText(PropName, 'Checkboxes') then
      begin
        if SameText(Trim(PropValue), 'True') then
        begin
          Lines.Add(GetIndent + 'EditMode = True');
          Lines.Add(GetIndent + 'ItemEditAppearanceName = ''ImageListItemShowCheck''');
        end;
        Continue;
      end
      else if SameText(Component.ComponentClass, 'TShape') and
              SameText(PropName, 'Shape') and
              (SameText(Trim(PropValue), 'stCircle') or
               SameText(Trim(PropValue), 'stEllipse') or
               SameText(Trim(PropValue), 'stRectangle') or
               SameText(Trim(PropValue), 'stSquare') or
               SameText(Trim(PropValue), 'stRoundRect') or
               SameText(Trim(PropValue), 'stRoundSquare')) then
        Continue
      else if SameText(Component.ComponentClass, 'TShape') and
              SameText(CompClass, 'TRectangle') and SameText(PropName, 'Shape') then
      begin
        if SameText(Trim(PropValue), 'bsFrame') then
        begin
          Lines.Add(GetIndent + 'Fill.Kind = None');
          Lines.Add(GetIndent + 'Stroke.Kind = Solid');
        end;
        Continue;
      end;

      if (SameText(CompClass, 'TButton') or SameText(CompClass, 'TSpeedButton')) and
         (SameText(PropName, 'Style') or SameText(PropName, 'ImageName')) then
      begin
        if SameText(PropName, 'Style') and
           (SameText(Trim(PropValue), 'tbsTextButton') or
            SameText(Trim(PropValue), 'tbsSeparator')) then
          Continue;
        if SameText(PropName, 'Style') and SameText(Trim(PropValue), 'tbsCheck') then
        begin
          Lines.Add(GetIndent + 'StaysPressed = True');
          Continue;
        end;
        if SameText(PropName, 'ImageName') and Component.HasProperty('ImageIndex') then
          Continue;
        AddUnsupportedPropertyReview(
          Component,
          PropName,
          Component.GetPropertyValue(PropName, PropValue),
          'Review this button image/style manually. FMX supports Images and ImageIndex, but this VCL value could not be resolved safely.');
        Continue;
      end;




      if SameText(CompClass, 'TCheckBox') and SameText(PropName, 'AllowGrayed') then
      begin
        if SameText(Trim(PropValue), 'True') and
           SameText(Component.GetPropertyValue('State', ''), 'cbGrayed') then
          AddUnsupportedPropertyReview(
            Component,
            PropName,
            Component.GetPropertyValue(PropName, PropValue),
            'FMX TCheckBox does not safely preserve a VCL grayed state generically. Review this checkbox manually.');
        Continue;
      end;

      if SameText(CompClass, 'TCheckBox') and SameText(PropName, 'State') then
      begin
        if Component.HasProperty('Checked') then
          Continue;
        ConvertedPropName := 'IsChecked';
        if SameText(PropValue, 'cbChecked') then
          PropValue := 'True'
        else if SameText(PropValue, 'cbUnchecked') then
          PropValue := 'False'
        else
        begin
          AddUnsupportedPropertyReview(
            Component,
            PropName,
            Component.GetPropertyValue(PropName, PropValue),
            'VCL grayed checkbox state requires manual review in FMX. The converter did not generate an unsafe value.');
          Continue;
        end;
      end;

      if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
         (SameText(PropName, 'FixedRows') or SameText(PropName, 'FixedCols')) then
      begin
        if StrToIntDef(Trim(PropValue), 0) <> 0 then
          AddUnsupportedPropertyReview(
            Component,
            PropName,
            Component.GetPropertyValue(PropName, PropValue),
            'Review fixed row/column behavior manually. FMX TStringGrid header and column behavior differs from VCL TStringGrid.');
        Continue;
      end;

      if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
         SameText(PropName, 'GridLineWidth') then
      begin
        if StrToIntDef(Trim(PropValue), 0) <> 0 then
          AddUnsupportedPropertyReview(
            Component,
            PropName,
            Component.GetPropertyValue(PropName, PropValue),
            'Review grid line styling manually in FMX. The VCL GridLineWidth property was omitted.');
        Continue;
      end;

      if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
         (SameText(PropName, 'ColCount') or SameText(PropName, 'DefaultRowHeight') or
          SameText(PropName, 'ScrollBars')) then
        Continue;

      if SameText(CompClass, 'TTreeView') and SameText(PropName, 'Indent') then
      begin
        AddUnsupportedPropertyReview(
          Component,
          PropName,
          Component.GetPropertyValue(PropName, PropValue),
          'Review the FMX tree item indentation/style manually. VCL Indent has no safe generic streamed mapping.');
        Continue;
      end;

      if SameText(CompClass, 'TToolBar') and
         (SameText(PropName, 'ButtonWidth') or SameText(PropName, 'ButtonHeight') or
          SameText(PropName, 'Images') or SameText(PropName, 'ShowCaptions') or
          SameText(PropName, 'AutoSize') or SameText(PropName, 'EdgeBorders') or
          SameText(PropName, 'EdgeOuter') or SameText(PropName, 'EdgeInner')) then
      begin
        if SameText(PropName, 'ButtonHeight') then
        begin
          ConvertedPropName := 'Size.Height';
          HasExplicitSize := True;
          HasExplicitHeight := True;
          SkipTargetPropertyValidation := True;
        end
        else
          Continue;
      end;

      if SameText(CompClass, 'TTabControl') and SameText(PropName, 'ActivePage') then
      begin
        ConvertedPropName := 'ActiveTab';
      end
      else if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
         SameText(PropName, 'Options') then
      begin
        GridOptionsText := '';
        if ContainsText(PropValue, 'dgColumnResize') then
          GridOptionsText := GridOptionsText + 'ColumnResize, ';
        if ContainsText(PropValue, 'dgColLines') then
          GridOptionsText := GridOptionsText + 'ColLines, ';
        if ContainsText(PropValue, 'dgRowLines') then
          GridOptionsText := GridOptionsText + 'RowLines, ';
        if ContainsText(PropValue, 'dgRowSelect') then
          GridOptionsText := GridOptionsText + 'RowSelect, ';
        if ContainsText(PropValue, 'dgAlwaysShowSelection') then
          GridOptionsText := GridOptionsText + 'AlwaysShowSelection, ';
        if ContainsText(PropValue, 'dgTitles') then
          GridOptionsText := GridOptionsText + 'Header, ';
        if ContainsText(PropValue, 'dgTitleClick') or ContainsText(PropValue, 'dgTitleHotTrack') then
          GridOptionsText := GridOptionsText + 'HeaderClick, ';

        if (Length(GridOptionsText) >= 2) and
           (Copy(GridOptionsText, Length(GridOptionsText) - 1, 2) = ', ') then
          Delete(GridOptionsText, Length(GridOptionsText) - 1, 2);

        if GridOptionsText <> '' then
          Lines.Add(GetIndent + 'Options = [' + GridOptionsText + ']');

        if not ContainsText(PropValue, 'dgEditing') then
          Lines.Add(GetIndent + 'ReadOnly = True');
        Continue;
      end;

      if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
         SameText(PropName, 'VisibleButtons') then
        Continue;

      if SameText(CompClass, 'TToolBar') and
         (SameText(PropName, 'VisibleButtons') or
          SameText(PropName, 'BeforeAction')) then
        Continue;

      if SameText(CompClass, 'TMediaPlayer') and
         (SameText(PropName, 'ColoredButtons') or SameText(PropName, 'VisibleButtons') or
           SameText(PropName, 'ParentDoubleBuffered') or SameText(PropName, 'DoubleBuffered') or
           SameText(PropName, 'AutoRewind')) then
        Continue;

      if (SameText(CompClass, 'TButton') or SameText(CompClass, 'TSpeedButton')) and
         (SameText(PropName, 'HotImageIndex') or
          SameText(PropName, 'PressedImageIndex') or
          SameText(PropName, 'DisabledImageIndex')) then
        Continue;

      if SameText(CompClass, 'TStatusBar') and SameText(PropName, 'Panels') then
        Continue;

      if SameText(CompClass, 'TTrackBar') and
          (SameText(PropName, 'PositionToolTip') or SameText(PropName, 'LineSize')) then
        Continue;

      if SameText(CompClass, 'TImageList') and SameText(PropName, 'Scaled') then
        Continue;

      if IsRootComponent(Component) and SameText(PropName, 'Scaled') then
        Continue;

      if SameText(CompClass, 'TComboBox') and SameText(PropName, 'Style') and
         SameText(Trim(PropValue), 'csDropDownList') then
        Continue;

      if SameText(CompClass, 'TDateEdit') and
         (SameText(PropName, 'MinDate') or SameText(PropName, 'MaxDate') or
           SameText(PropName, 'Time')) then
        Continue;

      if (SameText(CompClass, 'TNumberBox') or SameText(CompClass, 'TSpinBox')) and
         SameText(PropName, 'MaxLength') then
        Continue;

      if (SameText(Component.ComponentClass, 'TUpDown') or SameText(CompClass, 'TSpinBox')) and
         SameText(PropName, 'Associate') then
        Continue;

      if SameText(CompClass, 'TCheckBox') and SameText(PropName, 'State') and
         Component.HasProperty('Checked') then
        Continue;

      if SameText(PropName, 'Anchors') and LabelUsesAutoSize then
        Continue;

      if PropName.StartsWith('Picture.') or SameText(PropName, 'Picture') then
        Continue;

      if IsRootComponent(Component) and SameText(PropName, 'Anchors') then
        Continue;

      if SameText(PropName, 'DoubleBuffered') or
         SameText(PropName, 'ParentDoubleBuffered') or
         SameText(PropName, 'DesignSize') then
        Continue;

      if IsRootComponent(Component) and SameText(PropName, 'RoundedCorners') then
      begin
        AddUnsupportedPropertyReview(
          Component,
          PropName,
          Component.GetPropertyValue(PropName, PropValue),
          'FMX forms do not expose this VCL form chrome property directly. Review the form appearance manually in the IDE.');
        Continue;
      end;

      if SameText(PropName, 'Layout') and SupportsTextAlign(CompClass) then
      begin
        ConvertedPropName := 'TextSettings.VertAlign';
        if SameText(PropValue, 'tlTop') then
          PropValue := 'Leading'
        else if SameText(PropValue, 'tlCenter') then
          PropValue := 'Center'
        else if SameText(PropValue, 'tlBottom') then
          PropValue := 'Trailing'
        else
        begin
          AddUnsupportedPropertyReview(
            Component,
            PropName,
            Component.GetPropertyValue(PropName, PropValue),
            'Review this vertical text layout setting manually and map it to an FMX text alignment value.');
          Continue;
        end;
      end
      else if SameText(PropName, 'Pen.Style') and
              (SameText(CompClass, 'TShape') or SameText(CompClass, 'TRectangle') or
               SameText(CompClass, 'TRoundRect') or SameText(CompClass, 'TEllipse') or
               SameText(CompClass, 'TCircle')) then
      begin
        ConvertedPropName := 'Stroke.Kind';
        if SameText(Trim(PropValue), 'psClear') then
          PropValue := 'None'
        else
          PropValue := 'Solid';
      end
      else if SameText(CompClass, 'TTrackBar') and SameText(PropName, 'TickStyle') then
      begin
        if SameText(PropValue, 'tsNone') then
          Continue;

        AddUnsupportedPropertyReview(
          Component,
          PropName,
          Component.GetPropertyValue(PropName, PropValue),
          'FMX TTrackBar does not expose the same tick-style property. Review the control styling manually.');
        Continue;
      end;

      // Convert VCL properties to FMX
      if not SameText(PropName, 'Width') and
         not SameText(PropName, 'Height') and
         FindMappedProperty(Component, PropName, PropMap) then
      begin
        ConvertedPropName := PropMap.FMXProp;
        if PropName.StartsWith(PropMap.VCLProp + '.') then
        begin
          SubPropName := Copy(PropName, Length(PropMap.VCLProp) + 2, MaxInt);

          if SameText(PropMap.FMXProp, 'Fill') and SameText(SubPropName, 'Color') then
            ConvertedPropName := 'Fill.Color'
          else if SameText(PropMap.FMXProp, 'Fill') and SameText(SubPropName, 'Style') then
            ConvertedPropName := 'Fill.Kind'
          else if SameText(PropMap.FMXProp, 'Stroke') and SameText(SubPropName, 'Color') then
            ConvertedPropName := 'Stroke.Color'
          else if SameText(PropMap.FMXProp, 'Stroke') and SameText(SubPropName, 'Width') then
            ConvertedPropName := 'Stroke.Thickness'
          else
            ConvertedPropName := PropMap.FMXProp + '.' + SubPropName;
        end;

        if SameText(PropMap.TransformerFunc, 'TransformColor') then
          PropValue := TransformColor(PropValue);
        if ConvertedPropName.Contains('Color') then
          PropValue := TransformColor(PropValue);

        if SameText(ConvertedPropName, 'Stroke.Style') and
           (SameText(CompClass, 'TShape') or SameText(CompClass, 'TRectangle') or
            SameText(CompClass, 'TRoundRect') or SameText(CompClass, 'TEllipse') or
            SameText(CompClass, 'TCircle')) then
        begin
          ConvertedPropName := 'Stroke.Kind';
          if SameText(Trim(PropValue), 'psClear') or SameText(Trim(PropValue), 'None') then
            PropValue := 'None'
          else
            PropValue := 'Solid';
        end;
      end
      else if PropName = 'Left' then
      begin
        if IsRootComponent(Component) then
          ConvertedPropName := 'Left'
        else if IsNonVisualComponent(Component) then
          ConvertedPropName := 'Left'
        else if SameText(CompClass, 'TMenuBar') or SameText(CompClass, 'TStatusBar') or
                HasActiveAlign(Component) then
          Continue
        else
          ConvertedPropName := 'Position.X';
      end
      else if PropName = 'Top' then
      begin
        if IsRootComponent(Component) then
          ConvertedPropName := 'Top'
        else if IsNonVisualComponent(Component) then
          ConvertedPropName := 'Top'
        else if SameText(CompClass, 'TMenuBar') or SameText(CompClass, 'TStatusBar') or
                HasActiveAlign(Component) then
          Continue
        else
          ConvertedPropName := 'Position.Y';
      end
      else if PropName = 'Width' then
      begin
        if IsRootComponent(Component) then
          ConvertedPropName := 'Width'
        else if SameText(CompClass, 'TStatusBar') then
          Continue
        else
        begin
          if LabelUsesAutoSize then
            Continue;
          HasExplicitSize := True;
          HasExplicitWidth := True;
          if SameText(Component.GetPropertyValue('Align', ''), 'alClient') then
            Continue;
          ConvertedPropName := 'Size.Width';
        end;
      end
      else if PropName = 'Height' then
      begin
        if IsRootComponent(Component) then
          ConvertedPropName := 'Height'
        else if SameText(CompClass, 'TStatusBar') then
          Continue
        else
        begin
          if LabelUsesAutoSize then
            Continue;
          HasExplicitSize := True;
          HasExplicitHeight := True;
          if SameText(Component.GetPropertyValue('Align', ''), 'alClient') then
            Continue;
          ConvertedPropName := 'Size.Height';
        end;
      end
      else if PropName = 'Caption' then
      begin
        if IsRootComponent(Component) then
          ConvertedPropName := 'Caption'
        else if SameText(CompClass, 'TPanel') then
          Continue
        else
          ConvertedPropName := 'Text';
      end
      else if SameText(CompClass, 'TEdit') and SameText(PropName, 'PasswordChar') then
      begin
        ConvertedPropName := 'Password';
        PropValue := BoolToStr(not SameText(Trim(PropValue), '#0') and
                               not SameText(Trim(PropValue), '''''') and
                               (Trim(PropValue) <> ''),
                               True);
      end
      else if SameText(CompClass, 'TOpenDialog') and SameText(PropName, 'DefaultFolder') then
        ConvertedPropName := 'InitialDir'
      else if PropName = 'ClientWidth' then
      begin
        if IsRootComponent(Component) then
          ConvertedPropName := 'ClientWidth'
        else
        begin
          if LabelUsesAutoSize then
            Continue;
          ConvertedPropName := 'Size.Width';
          HasExplicitSize := True;
        end;
      end
      else if PropName = 'ClientHeight' then
      begin
        if IsRootComponent(Component) then
          ConvertedPropName := 'ClientHeight'
        else
        begin
          if LabelUsesAutoSize then
            Continue;
          ConvertedPropName := 'Size.Height';
          HasExplicitSize := True;
        end;
      end
      else if PropName = 'Align' then
        PropValue := NormalizeAlignLayoutValue(PropValue)
      else if PropName = 'Position' then
      begin
        if SameText(PropValue, 'poDefault') then
          PropValue := 'Default'
        else if SameText(PropValue, 'poDefaultPosOnly') then
          PropValue := 'DefaultPosOnly'
        else if SameText(PropValue, 'poDefaultSizeOnly') then
          PropValue := 'DefaultSizeOnly'
        else if SameText(PropValue, 'poDesigned') then
          PropValue := 'Designed'
        else if SameText(PropValue, 'poDesktopCenter') then
          PropValue := 'ScreenCenter'
        else if SameText(PropValue, 'poMainFormCenter') then
          PropValue := 'MainFormCenter'
        else if SameText(PropValue, 'poOwnerFormCenter') then
          PropValue := 'OwnerFormCenter'
        else if SameText(PropValue, 'poScreenCenter') then
          PropValue := 'ScreenCenter';
      end
      else if PropName = 'WindowState' then
      begin
        if not IsRootComponent(Component) then
          Continue;
      end
      else if PropName = 'FormStyle' then
      begin
        if not IsRootComponent(Component) then
          Continue;
        if SameText(PropValue, 'fsStayOnTop') then
          PropValue := 'StayOnTop'
        else if SameText(PropValue, 'fsNormal') then
          PropValue := 'Normal';
      end
      else if PropName = 'BorderStyle' then
      begin
        if not IsRootComponent(Component) then
          Continue;
        if SameText(PropValue, 'bsNone') then
          PropValue := 'None'
        else if SameText(PropValue, 'bsSingle') then
          PropValue := 'Single'
        else if SameText(PropValue, 'bsSizeable') then
          PropValue := 'Sizeable'
        else if SameText(PropValue, 'bsToolWindow') then
          PropValue := 'ToolWindow'
        else if SameText(PropValue, 'bsSizeToolWin') then
          PropValue := 'SizeToolWin';
      end
      else if PropName = 'AlphaBlendValue' then
        Continue
      else if PropName = 'AlphaBlend' then
      begin
        if not IsRootComponent(Component) then
          Continue;
        ConvertedPropName := 'Transparency';
        if SameText(PropValue, 'True') then
          PropValue := 'True'
        else
          PropValue := 'False';
      end
      else if PropName = 'Color' then
      begin
        if CanUseFillColor(CompClass) then
        begin
          ConvertedPropName := 'Fill.Color';
          PropValue := TransformColor(PropValue);
        end
        else
        begin
          FContext.AddIssue(csInfo, Format(
            'Skipped VCL color property on %s (%s): %s',
            [Component.Name, CompClass, PropValue]));
          Continue;
        end;
      end
      else if PropName = 'Alignment' then
      begin
        if not SupportsTextAlign(CompClass) then
          Continue;
        ConvertedPropName := 'TextSettings.HorzAlign';
        if SameText(PropValue, 'taLeftJustify') then
          PropValue := 'Leading'
        else if SameText(PropValue, 'taCenter') then
          PropValue := 'Center'
        else if SameText(PropValue, 'taRightJustify') then
          PropValue := 'Trailing';
      end
      else if SameText(CompClass, 'TMemo') and SameText(PropName, 'ScrollBars') then
      begin
        ConvertedPropName := 'ShowScrollBars';
        if SameText(PropValue, 'ssNone') then
          PropValue := 'False'
        else
          PropValue := 'True';
      end
      else if (SameText(CompClass, 'TTrackBar') or
               SameText(CompClass, 'TProgressBar') or
               SameText(CompClass, 'TSpinBox')) and
              SameText(PropName, 'Position') then
        ConvertedPropName := 'Value'
      else if (SameText(CompClass, 'TSpinBox') or SameText(CompClass, 'TNumberBox')) and
              SameText(PropName, 'MinValue') then
        ConvertedPropName := 'Min'
      else if (SameText(CompClass, 'TSpinBox') or SameText(CompClass, 'TNumberBox')) and
              SameText(PropName, 'MaxValue') then
        ConvertedPropName := 'Max'
      else if SameText(CompClass, 'TNumberBox') and SameText(PropName, 'Decimal') then
        ConvertedPropName := 'DecimalDigits'
      else if PropName.Contains('Color') then
        PropValue := TransformColor(PropValue);

      // Handle string collection properties - FIXED
      if IsStringCollectionPropertyName(PropName) then
      begin
        HandleStringCollection(Component, PropName, PropValue, Lines);
        Continue;
      end;

      if CanValidateTargetClass and (ConvertedPropName <> '') and not SkipTargetPropertyValidation then
      begin
        if IsNonVisualComponent(Component) and
           (SameText(ConvertedPropName, 'Left') or SameText(ConvertedPropName, 'Top')) then
        begin
          // TComponent streams design-time Left/Top through DefineProperties,
          // so preserved non-visual FMX components can keep their tray position.
        end
        else if not Mapper.SupportsFMXProperty(TargetFMXClass, ConvertedPropName) then
        begin
          AddUnsupportedPropertyReview(
            Component,
            PropName,
            Component.GetPropertyValue(PropName, PropValue),
            Format('Review the generated project in the IDE and replace %s with an FMX-safe equivalent for %s.',
              [PropName, TargetFMXClass]));
          Continue;
        end;
      end;

      // Quote string values for properties that need it
      if ((ConvertedPropName = 'Text') or
         (ConvertedPropName = 'Caption') or
         (ConvertedPropName = 'Hint') or
         (ConvertedPropName = 'Filter') or
         (ConvertedPropName = 'InitialDir') or
         (ConvertedPropName = 'DefaultExt') or
         (ConvertedPropName = 'FileName') or
         (ConvertedPropName = 'DetailFields') or
         (ConvertedPropName = 'IndexFieldNames') or
         (ConvertedPropName = 'TableName') or
         (ConvertedPropName = 'UpdateTableName') or
         (ConvertedPropName = 'KeyFields') or
         (ConvertedPropName.Contains('Name')) or
         IsConnectionProperty(ConvertedPropName)) and
         not (SameText(CompClass, 'TEdit') and SameText(ConvertedPropName, 'Password')) then
      begin
        PropValue := QuoteStringValue(PropValue);
      end;

      if SameText(ConvertedPropName, 'Position.X') or
         SameText(ConvertedPropName, 'Position.Y') or
         SameText(ConvertedPropName, 'Size.Width') or
         SameText(ConvertedPropName, 'Size.Height') or
         SameText(ConvertedPropName, 'Width') or
         SameText(ConvertedPropName, 'Height') then
      begin
        if SameText(ConvertedPropName, 'Size.Width') or
           SameText(ConvertedPropName, 'Width') then
        begin
          SizeVal := StrToIntDef(Trim(PropValue), 0);
          if SameText(CompClass, 'TLabel') and not LabelUsesAutoSize and (SizeVal > 0) then
          begin
            if LabelUsesWordWrap then
            begin
              if LabelHasManualBreaks then
                PropValue := IntToStr(Max(Max(SizeVal + 28, Round(SizeVal * 1.22)),
                  WrappedWordMinWidth))
              else if LabelCaptionLen >= 40 then
                PropValue := IntToStr(Max(Max(SizeVal + 28, Round(SizeVal * 1.25)),
                  WrappedWordMinWidth))
              else if LabelCaptionLen >= 10 then
                PropValue := IntToStr(Max(Max(SizeVal + 16, Round(SizeVal * 1.14)),
                  WrappedWordMinWidth))
              else
                PropValue := IntToStr(Max(SizeVal + 10, WrappedWordMinWidth));
            end
            else if LabelCaptionLen >= 8 then
              PropValue := IntToStr(Max(SizeVal + 14, Round(SizeVal * 1.15)));

            if SameText(LabelAlignment, 'taRightJustify') then
              LabelWidthAdjust := StrToIntDef(Trim(PropValue), SizeVal) - SizeVal;
          end;
        end;
        if SameText(ConvertedPropName, 'Size.Height') or
           SameText(ConvertedPropName, 'Height') then
        begin
          SizeVal := StrToIntDef(Trim(PropValue), 0);
          if LabelUsesWordWrap and (SizeVal > 0) then
          begin
            // Preserve the original layout more closely for large wrapped
            // headings; FMX already renders them larger after the font-size
            // conversion, so aggressive height inflation causes overlap.
            if FontHeightVal >= 28 then
              PropValue := IntToStr(SizeVal)
            else if LabelHasManualBreaks then
              PropValue := IntToStr(Max(SizeVal + 12, Round(SizeVal * 1.40)))
            else if SameText(LabelAlignment, 'taRightJustify') then
              PropValue := IntToStr(Max(SizeVal + 10, Round(SizeVal * 1.35)))
            else if LabelCaptionLen >= 40 then
              PropValue := IntToStr(Max(SizeVal + 10, Round(SizeVal * 1.24)))
            else
              PropValue := IntToStr(Max(SizeVal + 6, Round(SizeVal * 1.16)));
          end
          else if (SameText(CompClass, 'TCheckBox') or SameText(CompClass, 'TRadioButton')) and (SizeVal > 0) then
            PropValue := IntToStr(Max(24, SizeVal + 8))
          else if (SameText(CompClass, 'TEdit') or SameText(CompClass, 'TComboBox') or
                   SameText(CompClass, 'TComboEdit') or
                   SameText(CompClass, 'TDateEdit') or SameText(CompClass, 'TButton') or
                   SameText(CompClass, 'TSpeedButton')) and (SizeVal > 0) then
            PropValue := IntToStr(Max(32, SizeVal + 4));
        end;
        PropValue := FormatFMXFloatValue(PropValue);
      end;

      Lines.Add(GetIndent + ConvertedPropName + ' = ' + PropValue);
      if SameText(ConvertedPropName, 'Position.X') then
        PositionXLineIndex := Lines.Count - 1;
    end;

    if (LabelWidthAdjust > 0) and (PositionXLineIndex >= 0) then
      Lines[PositionXLineIndex] := TRegEx.Replace(
        Lines[PositionXLineIndex],
        '(\s*Position\.X\s*=\s*)([0-9]+(?:\.[0-9]+)?)',
        '$1' + FormatFMXFloatValue(IntToStr(
          Max(0, StrToIntDef(Component.GetPropertyValue('Left', '0'), 0) - LabelWidthAdjust))),
        [roIgnoreCase]);

    if not IsRootComponent(Component) and SameText(Component.GetPropertyValue('Align', ''), 'alClient') then
    begin
      ComputeClientAlignedSize(Component, ClientAlignedWidth, ClientAlignedHeight);
      if ClientAlignedWidth <> '' then
      begin
        Lines.Add(GetIndent + 'Size.Width = ' + FormatFMXFloatValue(ClientAlignedWidth));
        HasExplicitSize := True;
        HasExplicitWidth := True;
      end;
      if ClientAlignedHeight <> '' then
      begin
        Lines.Add(GetIndent + 'Size.Height = ' + FormatFMXFloatValue(ClientAlignedHeight));
        HasExplicitSize := True;
        HasExplicitHeight := True;
      end;
    end;

    if SameText(CompClass, 'TMenuBar') then
    begin
      ParentComp := FindParentComponent(Component);
      if not HasExplicitWidth then
      begin
        if ParentComp <> nil then
          ParentWidth := StrToIntDef(
            ParentComp.GetPropertyValue('ClientWidth',
              ParentComp.GetPropertyValue('Width', '0')), 0)
        else if FRootComponent <> nil then
          ParentWidth := StrToIntDef(
            FRootComponent.GetPropertyValue('ClientWidth',
              FRootComponent.GetPropertyValue('Width', '0')), 0)
        else
          ParentWidth := 0;

        if ParentWidth > 0 then
        begin
          Lines.Add(GetIndent + 'Size.Width = ' + FormatFMXFloatValue(IntToStr(ParentWidth)));
          HasExplicitSize := True;
          HasExplicitWidth := True;
        end;
      end;

      if not HasExplicitHeight then
      begin
        Lines.Add(GetIndent + 'Size.Height = ' + FormatFMXFloatValue('24'));
        HasExplicitSize := True;
        HasExplicitHeight := True;
      end;
    end;

    if SameText(CompClass, 'TStatusBar') then
    begin
      ParentComp := FindParentComponent(Component);
      if ParentComp <> nil then
      begin
        GetEffectiveComponentSize(ParentComp, ParentWidth, ParentHeight);

        if not HasExplicitWidth and (ParentWidth > 0) then
        begin
          Lines.Add(GetIndent + 'Size.Width = ' + FormatFMXFloatValue(IntToStr(ParentWidth)));
          HasExplicitSize := True;
          HasExplicitWidth := True;
        end;

        EffectiveHeight := StrToIntDef(Component.GetPropertyValue('Height', '26'), 26);
        if not HasExplicitHeight then
        begin
          Lines.Add(GetIndent + 'Size.Height = ' + FormatFMXFloatValue(IntToStr(EffectiveHeight)));
          HasExplicitSize := True;
          HasExplicitHeight := True;
        end;

        if (ParentHeight > 0) and (EffectiveHeight > 0) then
          Lines.Add(GetIndent + 'Position.Y = ' +
            FormatFMXFloatValue(IntToStr(Max(0, ParentHeight - EffectiveHeight))));
      end;
    end;

    if HasExplicitSize and not IsRootComponent(Component) and not IsNonVisualComponent(Component) then
      Lines.Add(GetIndent + 'Size.PlatformDefault = False');

    if IsRootComponent(Component) then
    begin
      if not Component.Properties.ContainsKey('Position') then
        Lines.Add(GetIndent + 'Position = Designed');
      Lines.Add(GetIndent + 'FormFactor.Width = 320');
      Lines.Add(GetIndent + 'FormFactor.Height = 480');
      Lines.Add(GetIndent + 'FormFactor.Devices = [Desktop, iPhone, iPad]');
      Lines.Add(GetIndent + 'DesignerMasterStyle = 0');
    end;

    // Generate events
    for EventName in Component.Events.Keys do
    begin
      ConvertedPropName := EventName;
      EventHandler := Component.Events[EventName];
      SkipTargetEventValidation := False;

      if FindMappedEvent(Component, EventName, EventMap) and (Trim(EventMap.FMXEvent) <> '') then
        ConvertedPropName := EventMap.FMXEvent;

      if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
         SameText(EventName, 'OnDrawColumnCell') then
        ConvertedPropName := 'OnDrawColumnBackground';

      if (SameText(CompClass, 'TComboBox') or SameText(CompClass, 'TComboEdit')) and
             SameText(EventName, 'OnDropDown') then
        ConvertedPropName := 'OnPopup'
      else if SameText(CompClass, 'TDateEdit') and SameText(EventName, 'OnCloseUp') then
        ConvertedPropName := 'OnClosePicker'
      else if SameText(CompClass, 'TToolBar') and SameText(EventName, 'BeforeAction') then
        Continue
      else if SameText(CompClass, 'TMediaPlayer') and SameText(EventName, 'OnNotify') then
        Continue
      else if SameText(EventName, 'OnBeforeMonitorDpiChanged') then
        Continue
      else if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
              SameText(EventName, 'OnDblClick') then
        Continue
      else if IsRootComponent(Component) and SameText(TargetFMXClass, 'TForm') then
      begin
        if SameText(ConvertedPropName, 'OnDblClick') then
        begin
          ConvertedPropName := 'OnMouseUp';
          EventHandler := 'GeneratedRootFormMouseUpDblClick';
          SkipTargetEventValidation := True;
        end
        else if SameText(ConvertedPropName, 'OnMouseMove') then
          SkipTargetEventValidation := True
        else if SameText(ConvertedPropName, 'OnMouseUp') and
                Component.Events.ContainsKey('OnDblClick') then
          Continue;
      end;

      if CanValidateTargetClass and not SkipTargetEventValidation then
      begin
        if Mapper.KnowsVCLClass(SourceVCLClass) and
           not Mapper.AreEventSignaturesCompatible(SourceVCLClass, EventName,
             TargetFMXClass, ConvertedPropName) then
        begin
          EventRecommendation := UnsupportedEventRecommendation(EventName,
            ConvertedPropName, TargetFMXClass);
          AddUnsupportedEventReview(
            Component,
            EventName,
            EventHandler,
            EventRecommendation,
            False);
          Continue;
        end;

        if not Mapper.SupportsFMXEvent(TargetFMXClass, ConvertedPropName) then
        begin
          EventRecommendation := UnsupportedEventRecommendation(EventName,
            ConvertedPropName, TargetFMXClass);
          AddUnsupportedEventReview(
            Component,
            EventName,
            EventHandler,
            EventRecommendation,
            False);
          Continue;
        end;
      end;

      Lines.Add(GetIndent + ConvertedPropName + ' = ' + EventHandler);
    end;

    if SameText(CompClass, 'TStringGrid') then
    begin
      ColumnCount := StrToIntDef(Component.GetPropertyValue('ColCount', '0'), 0);
      for ColumnIndex := 1 to ColumnCount do
      begin
        Lines.Add(GetIndent + 'object ' + Component.Name + 'Column' + IntToStr(ColumnIndex) + ': TStringColumn');
        FIndentLevel := FIndentLevel + 1;
        Lines.Add(GetIndent + 'Header = ' + QuoteStringValue('Column ' + IntToStr(ColumnIndex)));
        Lines.Add(GetIndent + 'Width = ' + FormatFMXFloatValue('80'));
        FIndentLevel := FIndentLevel - 1;
        Lines.Add(GetIndent + 'end');
      end;
    end;

    // Generate collections
    if Component.IsCollection then
      GenerateCollection(Component, Lines);

    // Generate child components
    if Component.Children <> nil then
    begin
      for Child in Component.Children do
      begin
        if Child.ComponentClass.EndsWith('Field') then
          Continue;
        if Child.IsSubComponent and ((Child.SubComponentType = 'TField') or
           (Child.SubComponentType = 'TCollectionItem') or
           (Child.SubComponentType = 'TColumn')) then
           Continue;
        if Child.IsCollection or SameText(Child.ComponentClass, 'TCollection') then
           Continue;
        if SameText(Child.ComponentClass, 'TFontDialog') or
           SameText(Child.ComponentClass, 'TColorDialog') then
          Continue;
        if (SameText(CompClass, 'TGrid') or SameText(CompClass, 'TStringGrid')) and
           Child.IsCollection then
          Continue;
        ChildCode := GenerateComponent(Child);
        if Trim(ChildCode) <> '' then
          Lines.Add(GetIndent + ChildCode);
      end;
    end;

    if SameText(CompClass, 'TStatusBar') then
      GenerateStatusBarPanels(Component, Lines);

    // Generate field definitions (for datasets)
    if CompClass.Contains('TFDQuery') or CompClass.Contains('TFDTable') then
      GenerateFields(Component, Lines);

    FIndentLevel := FIndentLevel - 1;
    Lines.Add(GetIndent + 'end');

    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function TFMXGenerator.TransformColor(const VCLColor: string): string;
var
  ColorStr: string;
  RawValue: Cardinal;
  R, G, B: Cardinal;
  IntValue: Integer;
begin
  ColorStr := Trim(VCLColor);

  if TryStrToInt(ColorStr, IntValue) then
  begin
    RawValue := Cardinal(IntValue);
    B := RawValue and $FF;
    G := (RawValue shr 8) and $FF;
    R := (RawValue shr 16) and $FF;
    Exit(Format('xFF%.2X%.2X%.2X', [R, G, B]));
  end;

  // Handle numeric color values
  if ColorStr.StartsWith('$') then
  begin
    try
      RawValue := StrToInt(ColorStr);
      if RawValue <= $FFFFFF then
      begin
        B := RawValue and $FF;
        G := (RawValue shr 8) and $FF;
        R := (RawValue shr 16) and $FF;
        Result := Format('xFF%.2X%.2X%.2X', [R, G, B]);
      end
      else
        Result := Format('x%.8X', [RawValue]);
      Exit;
    except
      Result := ColorStr;
      Exit;
    end;
  end;

  // Named colors
  if ColorStr = 'clBlack' then
    Result := 'claBlack'
  else if ColorStr = 'clWhite' then
    Result := 'claWhite'
  else if ColorStr = 'clRed' then
    Result := 'claRed'
  else if ColorStr = 'clGreen' then
    Result := 'claGreen'
  else if ColorStr = 'clBlue' then
    Result := 'claBlue'
  else if ColorStr = 'clYellow' then
    Result := 'claYellow'
  else if ColorStr = 'clBtnFace' then
    Result := '$FFF0F0F0'
  else if ColorStr = 'clWindow' then
    Result := 'claWhite'
  else if ColorStr = 'clWindowText' then
    Result := 'claBlack'
  else if ColorStr = 'clHighlight' then
    Result := '$FF0078D7'
  else if ColorStr = 'clIvory' then
    Result := 'claIvory'
  else if ColorStr = 'clCream' then
    Result := '$FFFFFBF0'
  else if ColorStr = 'clMaroon' then
    Result := 'claMaroon'
  else if ColorStr = 'clNavy' then
    Result := 'claNavy'
  else if ColorStr = 'clTeal' then
    Result := 'claTeal'
  else if ColorStr = 'clOlive' then
    Result := 'claOlive'
  else if ColorStr = 'clPurple' then
    Result := 'claPurple'
  else if ColorStr = 'clSilver' then
    Result := 'claSilver'
  else if ColorStr = 'clGray' then
    Result := 'claGray'
  else if ColorStr = 'clMoneyGreen' then
    Result := '$FFC0DCC0'
  else if ColorStr = 'clSkyBlue' then
    Result := '$FF87CEEB'
  else if ColorStr = 'clInfoBk' then
    Result := '$FFFFFFE1'
  else if ColorStr = 'clNone' then
    Result := 'claNull'
  else if ColorStr.StartsWith('cl') then
  begin
    FContext.AddIssue(csManualReview, 'Unknown VCL color constant preserved for manual review: ' + ColorStr);
    Result := 'claBlack';
  end
  else
    Result := ColorStr;
end;

end.









