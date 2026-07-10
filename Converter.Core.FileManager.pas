{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Core.FileManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.IOUtils, System.Types,
  Converter.Core.Types;

type
  TFileManager = class
  private
    FContext: TConversionContext;
    FFiles: TStringList;
    FIndex: Integer;
    procedure AddFileIfEligible(const FileName, NormalizedOutput: string);
    procedure CollectMatchingFiles(const DirectoryPath, NormalizedOutput: string);
    function GetFileCount: Integer;
    function IsSameOrChildPath(const CandidatePath, RootPath: string): Boolean;
    function MatchesSelectedFileTypes(const FileName: string): Boolean;
    function IsExcludedSourceFile(const FileName: string): Boolean;
    function BuildOutputFileName(const OriginalFile: string): string;
    function SanitizeOutputText(const Text: string): string;
    procedure SaveTextPreservingSourceEncoding(const OriginalFile, OutputFile,
      Text: string);

  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    procedure Reset;
    function PrepareOutput: Boolean;
    function HasMoreFiles: Boolean;
    function GetNextFile: string;
    property FileCount: Integer read GetFileCount;
    function SaveConvertedFile(const OriginalFile, Code: string): Boolean;
  end;

implementation

constructor TFileManager.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
  FFiles := TStringList.Create;
end;

destructor TFileManager.Destroy;
begin
  FFiles.Free;
  inherited;
end;

procedure TFileManager.Reset;
var
  NormalizedOutput: string;
begin
  FFiles.Clear;
  FIndex := 0;

  if not DirectoryExists(FContext.Options.SourcePath) then
  begin
    FContext.AddIssue(csError, 'Source directory does not exist: ' + FContext.Options.SourcePath);
    Exit;
  end;

  try
    if FContext.Options.OutputPath <> '' then
      NormalizedOutput := ExcludeTrailingPathDelimiter(ExpandFileName(FContext.Options.OutputPath))
    else
      NormalizedOutput := '';

    CollectMatchingFiles(ExpandFileName(FContext.Options.SourcePath), NormalizedOutput);
    FFiles.Sort;
  except
    on E: Exception do
      FContext.AddIssue(csError, 'Error scanning directory: ' + E.Message);
  end;
end;

procedure TFileManager.AddFileIfEligible(const FileName, NormalizedOutput: string);
var
  ExpandedFile: string;
begin
  ExpandedFile := ExpandFileName(FileName);
  if IsSameOrChildPath(ExpandedFile, NormalizedOutput) then
    Exit;
  if IsExcludedSourceFile(ExpandedFile) then
    Exit;
  if MatchesSelectedFileTypes(ExpandedFile) then
    FFiles.Add(ExpandedFile);
end;

procedure TFileManager.CollectMatchingFiles(const DirectoryPath,
  NormalizedOutput: string);
var
  SearchRec: TSearchRec;
  EntryPath: string;
begin
  if not DirectoryExists(DirectoryPath) then
    Exit;

  if IsSameOrChildPath(DirectoryPath, NormalizedOutput) or
     IsExcludedSourceFile(DirectoryPath) then
    Exit;

  if FindFirst(TPath.Combine(DirectoryPath, '*'), faAnyFile, SearchRec) <> 0 then
    Exit;
  try
    repeat
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;

      EntryPath := TPath.Combine(DirectoryPath, SearchRec.Name);
      if (SearchRec.Attr and faDirectory) <> 0 then
      begin
        if FContext.Options.ProcessSubdirectories then
          CollectMatchingFiles(EntryPath, NormalizedOutput);
      end
      else
        AddFileIfEligible(EntryPath, NormalizedOutput);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

function TFileManager.GetFileCount: Integer;
begin
  Result := FFiles.Count;
end;

function TFileManager.IsSameOrChildPath(const CandidatePath, RootPath: string): Boolean;
var
  ExpandedCandidate: string;
  NormalizedRoot: string;
begin
  if RootPath = '' then
    Exit(False);

  ExpandedCandidate := ExcludeTrailingPathDelimiter(ExpandFileName(CandidatePath));
  NormalizedRoot := ExcludeTrailingPathDelimiter(ExpandFileName(RootPath));

  Result := SameText(ExpandedCandidate, NormalizedRoot) or
    StartsText(NormalizedRoot + PathDelim, ExpandedCandidate + PathDelim);
end;

function TFileManager.IsExcludedSourceFile(const FileName: string): Boolean;
var
  RelativePath: string;
  SourceRoot: string;
  Parts: TArray<string>;
  Part: string;
begin
  Result := False;

  RelativePath := ExpandFileName(FileName);
  SourceRoot := IncludeTrailingPathDelimiter(ExpandFileName(FContext.Options.SourcePath));
  if StartsText(SourceRoot, RelativePath) then
    RelativePath := Copy(RelativePath, Length(SourceRoot) + 1, MaxInt);

  Parts := RelativePath.Split(['\', '/']);
  for Part in Parts do
  begin
    if Part = '' then
      Continue;
    if VCL2FMXIsBuildArtifactFolder(Part) then
      Exit(True);
  end;
end;

function TFileManager.PrepareOutput: Boolean;
var
  FolderName: string;
  FolderPath: string;
begin
  Result := True;

  if FContext.Options.OutputPath = '' then
  begin
    FContext.AddIssue(csError, 'Output directory not specified');
    Exit(False);
  end;

  try
    if not DirectoryExists(FContext.Options.OutputPath) then
      ForceDirectories(FContext.Options.OutputPath);

    for FolderName in VCL2FMX_STALE_OUTPUT_FOLDERS do
    begin
      FolderPath := TPath.Combine(FContext.Options.OutputPath, FolderName);
      if DirectoryExists(FolderPath) then
        TDirectory.Delete(FolderPath, True);
    end;
  except
    on E: Exception do
    begin
      FContext.AddIssue(csError, 'Cannot create output directory: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TFileManager.HasMoreFiles: Boolean;
begin
  Result := FIndex < FFiles.Count;
end;

function TFileManager.GetNextFile: string;
begin
  if FIndex < FFiles.Count then
  begin
    Result := FFiles[FIndex];
    Inc(FIndex);
  end
  else
    Result := '';
end;

function TFileManager.MatchesSelectedFileTypes(const FileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  case FContext.Options.FileTypes of
    ftPas:
      Result := Ext = '.pas';
    ftDfm:
      Result := Ext = '.dfm';
  else
    Result := (Ext = '.pas') or (Ext = '.dfm');
  end;
end;

function TFileManager.BuildOutputFileName(const OriginalFile: string): string;
var
  RelativePath: string;
begin
  RelativePath := ExtractRelativePath(
    IncludeTrailingPathDelimiter(FContext.Options.SourcePath),
    OriginalFile
  );

  if RelativePath = '' then
    RelativePath := ExtractFileName(OriginalFile);

  if SameText(ExtractFileExt(RelativePath), '.dfm') then
    RelativePath := ChangeFileExt(RelativePath, '.fmx');

  Result := TPath.Combine(FContext.Options.OutputPath, RelativePath);
end;

function TFileManager.SanitizeOutputText(const Text: string): string;
var
  i, OutIndex: Integer;
  Ch: Char;
begin
  SetLength(Result, Length(Text));
  OutIndex := 0;

  for i := 1 to Length(Text) do
  begin
    Ch := Text[i];
    if (Ord(Ch) >= 32) or CharInSet(Ch, [#9, #10, #13]) then
    begin
      Inc(OutIndex);
      Result[OutIndex] := Ch;
    end;
  end;

  SetLength(Result, OutIndex);
end;

procedure TFileManager.SaveTextPreservingSourceEncoding(const OriginalFile,
  OutputFile, Text: string);
var
  SourceBytes: TBytes;
  OutputBytes: TBytes;
  Preamble: TBytes;
  Combined: TBytes;
  i: Integer;
begin
  if SameText(ExtractFileExt(OutputFile), '.fmx') then
  begin
    Preamble := TEncoding.UTF8.GetPreamble;
    OutputBytes := TEncoding.UTF8.GetBytes(Text);
    SetLength(Combined, Length(Preamble) + Length(OutputBytes));
    for i := 0 to High(Preamble) do
      Combined[i] := Preamble[i];
    for i := 0 to High(OutputBytes) do
      Combined[Length(Preamble) + i] := OutputBytes[i];
    TFile.WriteAllBytes(OutputFile, Combined);
    Exit;
  end;

  SetLength(SourceBytes, 0);
  if TFile.Exists(OriginalFile) then
    SourceBytes := TFile.ReadAllBytes(OriginalFile);

  SetLength(Preamble, 0);

  if (Length(SourceBytes) >= 3) and
     (SourceBytes[0] = $EF) and
     (SourceBytes[1] = $BB) and
     (SourceBytes[2] = $BF) then
  begin
    Preamble := TEncoding.UTF8.GetPreamble;
    OutputBytes := TEncoding.UTF8.GetBytes(Text);
  end
  else if (Length(SourceBytes) >= 2) and
          (SourceBytes[0] = $FF) and
          (SourceBytes[1] = $FE) then
  begin
    Preamble := TEncoding.Unicode.GetPreamble;
    OutputBytes := TEncoding.Unicode.GetBytes(Text);
  end
  else if (Length(SourceBytes) >= 2) and
          (SourceBytes[0] = $FE) and
          (SourceBytes[1] = $FF) then
  begin
    Preamble := TEncoding.BigEndianUnicode.GetPreamble;
    OutputBytes := TEncoding.BigEndianUnicode.GetBytes(Text);
  end
  else if (Length(SourceBytes) > 0) and VCL2FMXIsValidUTF8Bytes(SourceBytes) then
    OutputBytes := TEncoding.UTF8.GetBytes(Text)
  else
    OutputBytes := TEncoding.ANSI.GetBytes(Text);

  if Length(Preamble) > 0 then
  begin
    SetLength(Combined, Length(Preamble) + Length(OutputBytes));
    for i := 0 to High(Preamble) do
      Combined[i] := Preamble[i];
    for i := 0 to High(OutputBytes) do
      Combined[Length(Preamble) + i] := OutputBytes[i];
    TFile.WriteAllBytes(OutputFile, Combined);
  end
  else
    TFile.WriteAllBytes(OutputFile, OutputBytes);
end;

function TFileManager.SaveConvertedFile(const OriginalFile, Code: string): Boolean;
var
  OutputFile: string;
  OutputDir: string;
  SanitizedCode: string;
begin
  Result := False;
  if FContext.Options.OutputPath = '' then
  begin
    FContext.AddIssue(csError, 'Cannot save file - output directory not specified');
    Exit;
  end;

  try
    OutputFile := BuildOutputFileName(OriginalFile);
    if FContext.Options.DryRunPreview then
    begin
      FContext.AddIssue(csInfo,
        'Dry-run preview: would save ' + ExtractRelativePath(
          IncludeTrailingPathDelimiter(FContext.Options.OutputPath), OutputFile),
        'Dry-run preview',
        OriginalFile,
        'Preview mode did not write the converted artifact. Run conversion again with dry-run disabled to create output files.',
        -1,
        False);
      Exit(True);
    end;

    OutputDir := ExtractFileDir(OutputFile);
    if (OutputDir <> '') and not DirectoryExists(OutputDir) then
      ForceDirectories(OutputDir);
    SanitizedCode := SanitizeOutputText(Code);
    SaveTextPreservingSourceEncoding(OriginalFile, OutputFile, SanitizedCode);
    FContext.AddIssue(csInfo, 'Saved: ' + ExtractRelativePath(
      IncludeTrailingPathDelimiter(FContext.Options.OutputPath), OutputFile));
    Result := True;
  except
    on E: Exception do
      FContext.AddIssue(csError, 'Failed to save ' + OriginalFile + ': ' + E.Message);
  end;
end;

end.
