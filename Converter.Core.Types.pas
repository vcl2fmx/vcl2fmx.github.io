{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Core.Types;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils, System.Math,
  System.Generics.Collections;

const
  VCL2FMX_EXCLUDED_SOURCE_FOLDERS: array[0..11] of string = (
    'backup',
    'backup copy',
    'win32',
    'win64',
    'deploy',
    '__history',
    '__recovery',
    '.git',
    '.svn',
    'recovery_generic',
    'debug',
    'release'
  );
  VCL2FMX_STALE_OUTPUT_FOLDERS: array[0..4] of string = (
    'Win32',
    'Win64',
    'Debug',
    'Release',
    '__history'
  );
  VCL2FMX_RUNTIME_SCORE_HISTORY = 10000;
  VCL2FMX_RUNTIME_SCORE_SOURCE_ROOT = 500;
  VCL2FMX_RUNTIME_SCORE_TRUSTED_SUBFOLDER = 400;
  VCL2FMX_RUNTIME_SCORE_WIN64 = 300;
  VCL2FMX_RUNTIME_SCORE_DEBUG = 150;
  VCL2FMX_RUNTIME_SCORE_NON_RELEASE = 25;
  VCL2FMX_RUNTIME_SCORE_PATH_DEPTH = 10;
  VCL2FMX_MAX_TEXT_DFM_BYTES = 50 * 1024 * 1024;

function VCL2FMXIsBuildArtifactFolder(const AFolderName: string): Boolean;
function VCL2FMXIsValidUTF8Bytes(const Bytes: TBytes): Boolean;
function VCL2FMXDetectTextEncoding(const AFileName: string): TEncoding;
function VCL2FMXTryReadTextFile(const AFileName: string; out Text: string;
  out EncodingName: string): Boolean;
function VCL2FMXStripCommentsForAnalysis(const Code: string): string;
function VCL2FMXStripLineCommentOutsideString(const Value: string): string;

type
  // Conversion result types
  TConversionSeverity = (csInfo, csWarning, csManualReview, csError, csCritical);

  TConversionIssue = class
  private
    FSeverity: TConversionSeverity;
    FMessage: string;
    FLineNumber: Integer;
    FFileName: string;
    FProblemType: string;
    FOriginalCode: string;
    FSuggestedFix: string;
    FIsBlocking: Boolean;
  public
    property Severity: TConversionSeverity read FSeverity write FSeverity;
    property Message: string read FMessage write FMessage;
    property LineNumber: Integer read FLineNumber write FLineNumber;
    property FileName: string read FFileName write FFileName;
    property ProblemType: string read FProblemType write FProblemType;
    property OriginalCode: string read FOriginalCode write FOriginalCode;
    property SuggestedFix: string read FSuggestedFix write FSuggestedFix;
    property IsBlocking: Boolean read FIsBlocking write FIsBlocking;

    constructor Create(ASeverity: TConversionSeverity; const AMessage: string);
  end;

  // Component mapping types
  TPropertyMapping = record
    VCLProp: string;
    FMXProp: string;
    NeedsTransformation: Boolean;
    TransformerFunc: string;
  end;

  TEventMapping = record
    VCLEvent: string;
    FMXEvent: string;
    SignatureMatch: Boolean;
  end;

  TComponentMapping = class
  private
    FVCLClassName: string;
    FFMXClassName: string;
    FMappingType: string;
    FAction: string;
    FConfidence: Integer;
    FPropertyMaps: TList<TPropertyMapping>;
    FEventMaps: TList<TEventMapping>;
    FNotes: string;
    FVendor: string;
    FPackName: string;
    FPackVersion: string;
    FManualReviewReason: string;
    FIsThirdParty: Boolean;
    FMappingSource: string;
  public
    property VCLClassName: string read FVCLClassName write FVCLClassName;
    property FMXClassName: string read FFMXClassName write FFMXClassName;
    property MappingType: string read FMappingType write FMappingType;
    property Action: string read FAction write FAction;
    property Confidence: Integer read FConfidence write FConfidence;
    property PropertyMaps: TList<TPropertyMapping> read FPropertyMaps;
    property EventMaps: TList<TEventMapping> read FEventMaps;
    property Notes: string read FNotes write FNotes;
    property Vendor: string read FVendor write FVendor;
    property PackName: string read FPackName write FPackName;
    property PackVersion: string read FPackVersion write FPackVersion;
    property ManualReviewReason: string read FManualReviewReason write FManualReviewReason;
    property IsThirdParty: Boolean read FIsThirdParty write FIsThirdParty;
    property MappingSource: string read FMappingSource write FMappingSource;

    constructor Create;
    destructor Destroy; override;
  end;

  TMappingPackUsage = class
  private
    FComponentName: string;
    FVCLClassName: string;
    FFMXClassName: string;
    FAction: string;
    FConfidence: Integer;
    FVendor: string;
    FPackName: string;
    FPackVersion: string;
    FSourceFile: string;
    FLineNumber: Integer;
    FNotes: string;
    FGeneratedOutput: Boolean;
  public
    property ComponentName: string read FComponentName write FComponentName;
    property VCLClassName: string read FVCLClassName write FVCLClassName;
    property FMXClassName: string read FFMXClassName write FFMXClassName;
    property Action: string read FAction write FAction;
    property Confidence: Integer read FConfidence write FConfidence;
    property Vendor: string read FVendor write FVendor;
    property PackName: string read FPackName write FPackName;
    property PackVersion: string read FPackVersion write FPackVersion;
    property SourceFile: string read FSourceFile write FSourceFile;
    property LineNumber: Integer read FLineNumber write FLineNumber;
    property Notes: string read FNotes write FNotes;
    property GeneratedOutput: Boolean read FGeneratedOutput write FGeneratedOutput;
  end;

  TFileType = (ftPas, ftDfm, ftBoth);

  TConversionOptions = class
  private
    FSourcePath: string;
    FOutputPath: string;
    FCreateReport: Boolean;
    FProcessSubdirectories: Boolean;
    FFileTypes: TFileType;
    FUserMappingsFile: string;
    FEnableCriticalAreas: Boolean;
    FEnableDataAware: Boolean;
    FEnableThirdParty: Boolean;
    FEnableWinAPI: Boolean;
    FEnableMappingPacks: Boolean;
    FMappingPackFolder: string;
    FDryRunPreview: Boolean;
  public
    property SourcePath: string read FSourcePath write FSourcePath;
    property OutputPath: string read FOutputPath write FOutputPath;
    property CreateReport: Boolean read FCreateReport write FCreateReport;
    property ProcessSubdirectories: Boolean read FProcessSubdirectories write FProcessSubdirectories;
    property FileTypes: TFileType read FFileTypes write FFileTypes;
    property UserMappingsFile: string read FUserMappingsFile write FUserMappingsFile;
    property EnableCriticalAreas: Boolean read FEnableCriticalAreas write FEnableCriticalAreas;
    property EnableDataAware: Boolean read FEnableDataAware write FEnableDataAware;
    property EnableThirdParty: Boolean read FEnableThirdParty write FEnableThirdParty;
    property EnableWinAPI: Boolean read FEnableWinAPI write FEnableWinAPI;
    property EnableMappingPacks: Boolean read FEnableMappingPacks write FEnableMappingPacks;
    property MappingPackFolder: string read FMappingPackFolder write FMappingPackFolder;
    property DryRunPreview: Boolean read FDryRunPreview write FDryRunPreview;

    constructor Create;
  end;

  TConversionContext = class
  private
    FOptions: TConversionOptions;
    FIssues: TObjectList<TConversionIssue>;
    FCurrentFile: string;
    FMappingDatabase: TObjectList<TComponentMapping>;
    FStartTime: TDateTime;
    FFilesProcessed: Integer;
    FFilesConverted: Integer;
    FFilesWithErrors: Integer;
    FLoadedMappingPacks: TStringList;
    FMappingPackUsages: TObjectList<TMappingPackUsage>;
    FSemanticClassIndex: TStringList;
    FSemanticMethodIndex: TStringList;
    FNeedsFMXMessageBridge: Boolean;
  public
    property Options: TConversionOptions read FOptions write FOptions;
    property Issues: TObjectList<TConversionIssue> read FIssues;
    property CurrentFile: string read FCurrentFile write FCurrentFile;
    property MappingDatabase: TObjectList<TComponentMapping> read FMappingDatabase;
    property StartTime: TDateTime read FStartTime write FStartTime;
    property FilesProcessed: Integer read FFilesProcessed write FFilesProcessed;
    property FilesConverted: Integer read FFilesConverted write FFilesConverted;
    property FilesWithErrors: Integer read FFilesWithErrors write FFilesWithErrors;
    property LoadedMappingPacks: TStringList read FLoadedMappingPacks;
    property MappingPackUsages: TObjectList<TMappingPackUsage> read FMappingPackUsages;
    property SemanticClassIndex: TStringList read FSemanticClassIndex;
    property SemanticMethodIndex: TStringList read FSemanticMethodIndex;
    property NeedsFMXMessageBridge: Boolean read FNeedsFMXMessageBridge write FNeedsFMXMessageBridge;

    constructor Create;
    destructor Destroy; override;

    procedure AddIssue(ASeverity: TConversionSeverity; const AMessage: string); overload;
    procedure AddIssue(ASeverity: TConversionSeverity; const AMessage: string; ALine: Integer); overload;
    procedure AddIssue(ASeverity: TConversionSeverity; const AMessage, AProblemType,
      AOriginalCode, ASuggestedFix: string; ALine: Integer = -1;
      AIsBlocking: Boolean = False); overload;
    procedure AddManualReview(const AProblemType, AMessage, AOriginalCode,
      ASuggestedFix: string; ALine: Integer = -1; AIsBlocking: Boolean = False);
    procedure AddIssue(AIssue: TConversionIssue); overload;
    procedure ClearIssues;
    function HasBlockingIssues: Boolean;
    function HasManualReviewIssues: Boolean;
    function CountManualReviewIssues: Integer;
    function CountBlockingIssues: Integer;
  end;

  IConverterEngine = interface
    ['{A1B2C3D4-E5F6-4A5B-8C7D-9E8F7A6B5C4D}']
    function Convert(AContext: TConversionContext): Boolean;
    function CanConvert(const AFileName: string): Boolean;
    procedure Cancel;
  end;

implementation

function VCL2FMXIsBuildArtifactFolder(const AFolderName: string): Boolean;
var
  Excluded: string;
begin
  Result := False;
  for Excluded in VCL2FMX_EXCLUDED_SOURCE_FOLDERS do
    if SameText(AFolderName, Excluded) then
      Exit(True);
end;

function VCL2FMXIsValidUTF8Bytes(const Bytes: TBytes): Boolean;
var
  Index: Integer;
  Need: Integer;
  B: Byte;
  J: Integer;
begin
  Result := True;
  Index := 0;
  while Index < Length(Bytes) do
  begin
    B := Bytes[Index];
    if B < $80 then
    begin
      Inc(Index);
      Continue;
    end;

    if (B and $E0) = $C0 then
      Need := 1
    else if (B and $F0) = $E0 then
      Need := 2
    else if (B and $F8) = $F0 then
      Need := 3
    else
      Exit(False);

    if Index + Need >= Length(Bytes) then
      Exit(False);

    for J := 1 to Need do
      if (Bytes[Index + J] and $C0) <> $80 then
        Exit(False);

    Inc(Index, Need + 1);
  end;
end;

function VCL2FMXDetectTextEncoding(const AFileName: string): TEncoding;
var
  Buffer: TBytes;
  I: Integer;
  HasHighAscii: Boolean;
  HasNulls: Boolean;
begin
  Buffer := TFile.ReadAllBytes(AFileName);

  if (Length(Buffer) >= 3) and (Buffer[0] = $EF) and
     (Buffer[1] = $BB) and (Buffer[2] = $BF) then
    Exit(TEncoding.UTF8);

  if Length(Buffer) >= 2 then
  begin
    if (Buffer[0] = $FF) and (Buffer[1] = $FE) then
      Exit(TEncoding.Unicode);
    if (Buffer[0] = $FE) and (Buffer[1] = $FF) then
      Exit(TEncoding.BigEndianUnicode);
  end;

  HasNulls := False;
  for I := 0 to Min(1000, Length(Buffer) - 1) do
    if Buffer[I] = 0 then
    begin
      HasNulls := True;
      Break;
    end;

  if HasNulls then
    Exit(TEncoding.Unicode);

  HasHighAscii := False;
  for I := 0 to Min(1000, Length(Buffer) - 1) do
    if Buffer[I] > 127 then
    begin
      HasHighAscii := True;
      Break;
    end;

  if HasHighAscii then
  begin
    if VCL2FMXIsValidUTF8Bytes(Buffer) then
      Exit(TEncoding.UTF8);

    try
      Exit(TEncoding.GetEncoding(1252));
    except
      try
        Exit(TEncoding.GetEncoding(28591));
      except
        Exit(TEncoding.ANSI);
      end;
    end;
  end;

  Result := TEncoding.ASCII;
end;

function VCL2FMXTryReadTextFile(const AFileName: string; out Text: string;
  out EncodingName: string): Boolean;
const
  FALLBACK_CODEPAGES: array[0..7] of Integer =
    (1252, 28591, 1250, 1251, 1253, 1254, 1257, 437);
var
  Bytes: TBytes;
  Encoding: TEncoding;
  CodePage: Integer;
begin
  Text := '';
  EncodingName := '';
  SetLength(Bytes, 0);

  try
    Bytes := TFile.ReadAllBytes(AFileName);
  except
    Exit(False);
  end;

  try
    Encoding := VCL2FMXDetectTextEncoding(AFileName);
    if Assigned(Encoding) then
    begin
      Text := Encoding.GetString(Bytes);
      if (Length(Text) > 0) and (Text[1] = #$FEFF) then
        Delete(Text, 1, 1);
      EncodingName := Encoding.EncodingName;
      Exit(True);
    end;
  except
    Text := '';
    EncodingName := '';
  end;

  for CodePage in FALLBACK_CODEPAGES do
  begin
    try
      Encoding := TEncoding.GetEncoding(CodePage);
      Text := Encoding.GetString(Bytes);
      if (Length(Text) > 0) and (Text[1] = #$FEFF) then
        Delete(Text, 1, 1);
      EncodingName := Encoding.EncodingName;
      Exit(True);
    except
    end;
  end;

  try
    Text := TEncoding.Default.GetString(Bytes);
    EncodingName := TEncoding.Default.EncodingName;
    Result := True;
  except
    Result := False;
  end;
end;

function VCL2FMXStripCommentsForAnalysis(const Code: string): string;
type
  TCommentState = (cstNone, cstLine, cstBrace, cstParenStar);
var
  I: Integer;
  State: TCommentState;
  InString: Boolean;
  Ch: Char;

  procedure AppendBlankFor(const AChar: Char);
  begin
    if (AChar = #10) or (AChar = #13) then
      Result := Result + AChar
    else
      Result := Result + ' ';
  end;

begin
  Result := '';
  State := cstNone;
  InString := False;
  I := 1;

  while I <= Length(Code) do
  begin
    Ch := Code[I];

    case State of
      cstLine:
        begin
          AppendBlankFor(Ch);
          if (Ch = #10) or (Ch = #13) then
            State := cstNone;
          Inc(I);
          Continue;
        end;
      cstBrace:
        begin
          AppendBlankFor(Ch);
          if Ch = '}' then
            State := cstNone;
          Inc(I);
          Continue;
        end;
      cstParenStar:
        begin
          if (Ch = '*') and (I < Length(Code)) and (Code[I + 1] = ')') then
          begin
            Result := Result + '  ';
            Inc(I, 2);
            State := cstNone;
            Continue;
          end;
          AppendBlankFor(Ch);
          Inc(I);
          Continue;
        end;
    end;

    if InString then
    begin
      Result := Result + Ch;
      if Ch = '''' then
      begin
        if (I < Length(Code)) and (Code[I + 1] = '''') then
        begin
          Result := Result + Code[I + 1];
          Inc(I, 2);
          Continue;
        end;
        InString := False;
      end;
      Inc(I);
      Continue;
    end;

    if Ch = '''' then
    begin
      InString := True;
      Result := Result + Ch;
      Inc(I);
      Continue;
    end;

    if (Ch = '/') and (I < Length(Code)) and (Code[I + 1] = '/') then
    begin
      State := cstLine;
      Result := Result + '  ';
      Inc(I, 2);
      Continue;
    end;

    if (Ch = '{') and (I < Length(Code)) and (Code[I + 1] = '$') then
    begin
      while I <= Length(Code) do
      begin
        Result := Result + Code[I];
        if Code[I] = '}' then
        begin
          Inc(I);
          Break;
        end;
        Inc(I);
      end;
      Continue;
    end;

    if Ch = '{' then
    begin
      State := cstBrace;
      AppendBlankFor(Ch);
      Inc(I);
      Continue;
    end;

    if (Ch = '(') and (I < Length(Code)) and (Code[I + 1] = '*') then
    begin
      State := cstParenStar;
      Result := Result + '  ';
      Inc(I, 2);
      Continue;
    end;

    Result := Result + Ch;
    Inc(I);
  end;
end;

function VCL2FMXStripLineCommentOutsideString(const Value: string): string;
var
  I: Integer;
  InString: Boolean;
  Ch: Char;
begin
  Result := Value;
  InString := False;
  I := 1;

  while I <= Length(Value) do
  begin
    Ch := Value[I];

    if InString then
    begin
      if Ch = '''' then
      begin
        if (I < Length(Value)) and (Value[I + 1] = '''') then
        begin
          Inc(I, 2);
          Continue;
        end;
        InString := False;
      end;
      Inc(I);
      Continue;
    end;

    if Ch = '''' then
    begin
      InString := True;
      Inc(I);
      Continue;
    end;

    if (Ch = '/') and (I < Length(Value)) and (Value[I + 1] = '/') then
    begin
      Result := Copy(Value, 1, I - 1);
      Exit;
    end;

    Inc(I);
  end;
end;

{ TConversionIssue }

constructor TConversionIssue.Create(ASeverity: TConversionSeverity;
  const AMessage: string);
begin
  FSeverity := ASeverity;
  FMessage := AMessage;
  FLineNumber := -1;
  FProblemType := '';
  FOriginalCode := '';
  FSuggestedFix := '';
  FIsBlocking := False;
end;

{ TComponentMapping }

constructor TComponentMapping.Create;
begin
  FPropertyMaps := TList<TPropertyMapping>.Create;
  FEventMaps := TList<TEventMapping>.Create;
  FConfidence := 100;
  FAction := 'convert';
  FMappingSource := 'built-in';
  FIsThirdParty := False;
end;

destructor TComponentMapping.Destroy;
begin
  FPropertyMaps.Free;
  FEventMaps.Free;
  inherited;
end;

{ TConversionOptions }

constructor TConversionOptions.Create;
begin
  FCreateReport := True;
  FProcessSubdirectories := True;
  FFileTypes := ftBoth;
  FUserMappingsFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'component_mappings.json';
  FEnableCriticalAreas := True;
  FEnableDataAware := True;
  FEnableThirdParty := True;
  FEnableWinAPI := True;
  FEnableMappingPacks := True;
  FDryRunPreview := False;
  FMappingPackFolder := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'mapping_packs';
end;

{ TConversionContext }

constructor TConversionContext.Create;
begin
  FIssues := TObjectList<TConversionIssue>.Create(True);
  FMappingDatabase := TObjectList<TComponentMapping>.Create(True);
  FLoadedMappingPacks := TStringList.Create;
  FMappingPackUsages := TObjectList<TMappingPackUsage>.Create(True);
  FSemanticClassIndex := TStringList.Create;
  FSemanticMethodIndex := TStringList.Create;
  FSemanticClassIndex.CaseSensitive := False;
  FSemanticMethodIndex.CaseSensitive := False;
  FOptions := TConversionOptions.Create;
  FFilesProcessed := 0;
  FFilesConverted := 0;
  FFilesWithErrors := 0;
end;

destructor TConversionContext.Destroy;
begin
  FIssues.Free;
  FMappingDatabase.Free;
  FLoadedMappingPacks.Free;
  FMappingPackUsages.Free;
  FSemanticClassIndex.Free;
  FSemanticMethodIndex.Free;
  FOptions.Free;
  inherited;
end;

procedure TConversionContext.AddIssue(ASeverity: TConversionSeverity;
  const AMessage: string);
begin
  AddIssue(TConversionIssue.Create(ASeverity, AMessage));
end;

procedure TConversionContext.AddIssue(ASeverity: TConversionSeverity;
  const AMessage: string; ALine: Integer);
var
  Issue: TConversionIssue;
begin
  Issue := TConversionIssue.Create(ASeverity, AMessage);
  Issue.LineNumber := ALine;
  AddIssue(Issue);
end;

procedure TConversionContext.AddIssue(ASeverity: TConversionSeverity;
  const AMessage, AProblemType, AOriginalCode, ASuggestedFix: string;
  ALine: Integer; AIsBlocking: Boolean);
var
  Issue: TConversionIssue;
begin
  Issue := TConversionIssue.Create(ASeverity, AMessage);
  Issue.LineNumber := ALine;
  Issue.ProblemType := AProblemType;
  Issue.OriginalCode := AOriginalCode;
  Issue.SuggestedFix := ASuggestedFix;
  Issue.IsBlocking := AIsBlocking;
  AddIssue(Issue);
end;

procedure TConversionContext.AddManualReview(const AProblemType, AMessage,
  AOriginalCode, ASuggestedFix: string; ALine: Integer; AIsBlocking: Boolean);
begin
  AddIssue(csManualReview, AMessage, AProblemType, AOriginalCode, ASuggestedFix,
    ALine, AIsBlocking);
end;

procedure TConversionContext.AddIssue(AIssue: TConversionIssue);
begin
  if not Assigned(AIssue) then
    Exit;
  if AIssue.FileName = '' then
    AIssue.FileName := FCurrentFile;
  if AIssue.LineNumber < -1 then
    AIssue.LineNumber := -1;
  FIssues.Add(AIssue);
end;

procedure TConversionContext.ClearIssues;
begin
  FIssues.Clear;
end;

function TConversionContext.HasBlockingIssues: Boolean;
var
  Issue: TConversionIssue;
begin
  Result := False;
  for Issue in FIssues do
    if Issue.IsBlocking or (Issue.Severity in [csError, csCritical]) then
      Exit(True);
end;

function TConversionContext.HasManualReviewIssues: Boolean;
var
  Issue: TConversionIssue;
begin
  Result := False;
  for Issue in FIssues do
    if Issue.Severity = csManualReview then
      Exit(True);
end;

function TConversionContext.CountManualReviewIssues: Integer;
var
  Issue: TConversionIssue;
begin
  Result := 0;
  for Issue in FIssues do
    if Issue.Severity = csManualReview then
      Inc(Result);
end;

function TConversionContext.CountBlockingIssues: Integer;
var
  Issue: TConversionIssue;
begin
  Result := 0;
  for Issue in FIssues do
    if Issue.IsBlocking or (Issue.Severity in [csError, csCritical]) then
      Inc(Result);
end;

end.
