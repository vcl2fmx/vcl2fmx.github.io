{VCL2FMX Â© 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Project.Generator;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.RegularExpressions,
  System.StrUtils,
  System.Types,
  Converter.Core.Types;

type
  TProjectGenerator = class
  private
    FContext: TConversionContext;
    FImportedAssetPaths: TDictionary<string, string>;
    FImportedAssetTargets: TDictionary<string, string>;

    function GetProjectSearchOption: TSearchOption;
    function FindFirstProjectFile(const Pattern: string): string;
    function GetProjectRelativeOutputPath(const SourceFile: string): string;
    function FindOriginalDPR: string;
    function FindOriginalDPROJ: string;
    function NormalizeAssetReference(const RawPath: string): string;
    function ShouldIgnoreAssetReference(const NormalizedPath: string): Boolean;
    function TryGetSourceRelativeAssetPath(const AbsolutePath: string;
      out RelativePath: string): Boolean;
    function GetImportedExternalAssetRelativePath(
      const SourceFile: string): string;
    function TryStageReferencedAsset(const RawPath: string;
      out RewrittenPath: string): Boolean;
    function GetLeadingWhitespace(const Line: string): string;
    function NormalizeNamespaceList(const NamespaceValue: string): string;
    function TryParseCreateForm(const Line: string; out ClassName, InstanceName: string): Boolean;
    function IsFormManuallyCreated(const ClassName, InstanceName: string): Boolean;
    procedure NormalizeDPRStartupLines(ALines: TStrings);
    function FindApplicationRunIndex(ALines: TStrings): Integer;
    function FindSplashStartupSequence(ALines: TStrings; out SplashClassName,
      SplashInstanceName: string; out SplashCreateIdx, SplashShowIdx,
      SplashFreeIdx, SplashCommentIdx: Integer; out SleepLine: string): Boolean;
    procedure StripImmediateCreateFormShows(ALines: TStrings);
    function TransformDPRContent(const SourceCode: string): string;
    function TransformDPROJContent(const SourceCode: string): string;
    function TransformDPKContent(const SourceCode: string): string;
    function TransformDeployProjContent(const SourceCode: string): string;

    procedure CopyDPR;
    procedure CopyDPROJ;
    procedure CopyDPKFiles;
    procedure CopyDeployProj;
    procedure CopyProjectCompanionFiles;
    procedure GenerateFMXMessageBridge;

  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;
    procedure GenerateProject;
  end;

implementation

constructor TProjectGenerator.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
  FImportedAssetPaths := TDictionary<string, string>.Create;
  FImportedAssetTargets := TDictionary<string, string>.Create;
end;

destructor TProjectGenerator.Destroy;
begin
  FImportedAssetTargets.Free;
  FImportedAssetPaths.Free;
  inherited;
end;

function TProjectGenerator.GetProjectSearchOption: TSearchOption;
begin
  if FContext.Options.ProcessSubdirectories then
    Result := TSearchOption.soAllDirectories
  else
    Result := TSearchOption.soTopDirectoryOnly;
end;

function TProjectGenerator.FindFirstProjectFile(const Pattern: string): string;
var
  Files: TStringDynArray;
begin
  Result := '';
  Files := TDirectory.GetFiles(FContext.Options.SourcePath, Pattern, GetProjectSearchOption);
  if Length(Files) > 0 then
    Result := Files[0];
end;

function TProjectGenerator.GetProjectRelativeOutputPath(
  const SourceFile: string): string;
var
  SourceRoot: string;
begin
  SourceRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(FContext.Options.SourcePath));
  Result := ExtractRelativePath(SourceRoot, TPath.GetFullPath(SourceFile));
  Result := StringReplace(Result, '/', PathDelim, [rfReplaceAll]);
  if (Result = '') or TPath.IsPathRooted(Result) or StartsText('..', Result) then
    Result := TPath.GetFileName(SourceFile);
end;

function TProjectGenerator.FindOriginalDPR: string;
begin
  Result := FindFirstProjectFile('*.dpr');
end;

function TProjectGenerator.FindOriginalDPROJ: string;
begin
  Result := FindFirstProjectFile('*.dproj');
end;

function TProjectGenerator.NormalizeAssetReference(const RawPath: string): string;
begin
  Result := Trim(StringReplace(RawPath, '/', PathDelim, [rfReplaceAll]));
end;

function TProjectGenerator.ShouldIgnoreAssetReference(
  const NormalizedPath: string): Boolean;
var
  PathParts: TArray<string>;
  PathPart: string;
  Extension: string;
begin
  Result := True;
  if (NormalizedPath = '') or SameText(NormalizedPath, '(None)') or
     ContainsText(NormalizedPath, '$(') then
    Exit;

  PathParts := NormalizedPath.Split([PathDelim, '/']);
  for PathPart in PathParts do
    if VCL2FMXIsBuildArtifactFolder(PathPart) then
      Exit;

  Extension := LowerCase(TPath.GetExtension(NormalizedPath));
  Result := MatchText(Extension,
    ['.exe', '.dll', '.dcu', '.rsm', '.map', '.identcache', '.local',
     '.pas', '.dfm', '.fmx', '.dpr', '.dproj', '.deployproj', '.groupproj',
     '.res', '.rc', '.inc', '.zip', '.7z', '.rar', '.bak', '.tmp']);
end;

function TProjectGenerator.TryGetSourceRelativeAssetPath(const AbsolutePath: string;
  out RelativePath: string): Boolean;
var
  SourceRoot: string;
begin
  SourceRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(FContext.Options.SourcePath));
  RelativePath := ExtractRelativePath(SourceRoot, TPath.GetFullPath(AbsolutePath));
  RelativePath := StringReplace(RelativePath, '/', '\', [rfReplaceAll]);
  Result := (RelativePath <> '') and
            not TPath.IsPathRooted(RelativePath) and
            not StartsText('..', RelativePath);
end;

function TProjectGenerator.GetImportedExternalAssetRelativePath(
  const SourceFile: string): string;
var
  NormalizedSource: string;
  BaseName: string;
  Extension: string;
  ExistingSource: string;
  Counter: Integer;
begin
  NormalizedSource := TPath.GetFullPath(SourceFile);
  if FImportedAssetPaths.TryGetValue(NormalizedSource, Result) then
    Exit;

  BaseName := TPath.GetFileNameWithoutExtension(NormalizedSource);
  Extension := TPath.GetExtension(NormalizedSource);
  Result := TPath.Combine(TPath.Combine('Assets', 'Imported'),
    BaseName + Extension);
  Counter := 2;

  while FImportedAssetTargets.TryGetValue(LowerCase(Result), ExistingSource) and
        not SameText(ExistingSource, NormalizedSource) do
  begin
    Result := TPath.Combine(TPath.Combine('Assets', 'Imported'),
      Format('%s_%d%s', [BaseName, Counter, Extension]));
    Inc(Counter);
  end;

  FImportedAssetPaths.AddOrSetValue(NormalizedSource, Result);
  FImportedAssetTargets.AddOrSetValue(LowerCase(Result), NormalizedSource);
end;

function TProjectGenerator.TryStageReferencedAsset(const RawPath: string;
  out RewrittenPath: string): Boolean;
var
  SourceFile: string;
  TargetRelativePath: string;
  TargetFile: string;
begin
  Result := False;
  RewrittenPath := NormalizeAssetReference(RawPath);
  if ShouldIgnoreAssetReference(RewrittenPath) then
    Exit;

  if TPath.IsPathRooted(RewrittenPath) then
    SourceFile := TPath.GetFullPath(RewrittenPath)
  else
    SourceFile := TPath.GetFullPath(TPath.Combine(FContext.Options.SourcePath,
      RewrittenPath));

  if not FileExists(SourceFile) then
    Exit;

  if not TryGetSourceRelativeAssetPath(SourceFile, TargetRelativePath) then
    TargetRelativePath := GetImportedExternalAssetRelativePath(SourceFile);

  TargetFile := TPath.Combine(FContext.Options.OutputPath, TargetRelativePath);
  if TPath.GetDirectoryName(TargetFile) <> '' then
    ForceDirectories(TPath.GetDirectoryName(TargetFile));
  if not SameText(SourceFile, TargetFile) then
    TFile.Copy(SourceFile, TargetFile, True);

  RewrittenPath := StringReplace(TargetRelativePath, '/', '\', [rfReplaceAll]);
  Result := True;
end;

function TProjectGenerator.GetLeadingWhitespace(const Line: string): string;
var
  i: Integer;
begin
  i := 1;
  while (i <= Length(Line)) and CharInSet(Line[i], [' ', #9]) do
    Inc(i);
  Result := Copy(Line, 1, i - 1);
end;

function TProjectGenerator.NormalizeNamespaceList(const NamespaceValue: string): string;
const
  FMXNamespaces: array[0..4] of string = (
    'FMX',
    'FMX.Controls',
    'FMX.Forms',
    'FMX.Graphics',
    'FMX.Types'
  );
var
  Parts: TStringList;
  Token: string;
  i: Integer;
begin
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ';';
    Parts.DelimitedText := StringReplace(NamespaceValue, #13#10, ';', [rfReplaceAll]);

    for Token in FMXNamespaces do
      if Parts.IndexOf(Token) = -1 then
        Parts.Insert(0, Token);

    // Remove all VCL-prefixed namespaces and empty duplicates.
    for i := Parts.Count - 1 downto 0 do
    begin
      Token := Trim(Parts[i]);
      if (Token = '') or SameText(Token, '$(DCC_Namespace)') then
      begin
        Parts.Delete(i);
        Continue;
      end;
      if StartsText('Vcl', Token) then
      begin
        Parts.Delete(i);
        Continue;
      end;
      if Parts.IndexOf(Token) <> i then
        Parts.Delete(i)
      else
        Parts[i] := Token;
    end;

    Result := '';
    for i := 0 to Parts.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ';';
      Result := Result + Parts[i];
    end;
    if Result <> '' then
      Result := Result + ';$(DCC_Namespace)'
    else
      Result := '$(DCC_Namespace)';
  finally
    Parts.Free;
  end;
end;

function TProjectGenerator.TryParseCreateForm(const Line: string; out ClassName,
  InstanceName: string): Boolean;
var
  TrimmedLine: string;
  OpenPos: Integer;
  CommaPos: Integer;
  ClosePos: Integer;
begin
  Result := False;
  ClassName := '';
  InstanceName := '';

  TrimmedLine := Trim(Line);
  if not StartsText('Application.CreateForm(', TrimmedLine) then
    Exit;

  OpenPos := Pos('(', TrimmedLine);
  CommaPos := Pos(',', TrimmedLine);
  ClosePos := LastDelimiter(')', TrimmedLine);
  if (OpenPos = 0) or (CommaPos = 0) or (ClosePos = 0) or (CommaPos <= OpenPos) or
     (ClosePos <= CommaPos) then
    Exit;

  ClassName := Trim(Copy(TrimmedLine, OpenPos + 1, CommaPos - OpenPos - 1));
  InstanceName := Trim(Copy(TrimmedLine, CommaPos + 1, ClosePos - CommaPos - 1));
  Result := (ClassName <> '') and (InstanceName <> '');
end;

function TProjectGenerator.IsFormManuallyCreated(const ClassName,
  InstanceName: string): Boolean;
begin
  // A generic converter should preserve the source DPR auto-create list as
  // written. Inferring that a later Class.Create(...) call means "remove this
  // form from Application.CreateForm" is too aggressive and can break apps
  // that intentionally keep startup-created singleton forms.
  Result := False;
end;

procedure TProjectGenerator.NormalizeDPRStartupLines(ALines: TStrings);
var
  i: Integer;
  Line: string;
begin
  if not Assigned(ALines) then
    Exit;

  for i := 0 to ALines.Count - 1 do
  begin
    Line := ALines[i];
    Line := StringReplace(Line, 'Vcl.Forms', 'FMX.Forms', [rfReplaceAll, rfIgnoreCase]);
    Line := StringReplace(Line, 'Vcl.Dialogs', 'FMX.Dialogs', [rfReplaceAll, rfIgnoreCase]);

    if ContainsText(Line, 'Application.MainFormOnTaskbar') or
       ContainsText(Line, 'Application.ShowMainForm') then
      ALines[i] := ''
    else
      ALines[i] := Line;
  end;
end;

function TProjectGenerator.FindApplicationRunIndex(ALines: TStrings): Integer;
var
  i: Integer;
begin
  Result := -1;
  if not Assigned(ALines) then
    Exit;

  for i := 0 to ALines.Count - 1 do
    if SameText(Trim(ALines[i]), 'Application.Run;') then
      Exit(i);
end;

function TProjectGenerator.FindSplashStartupSequence(ALines: TStrings;
  out SplashClassName, SplashInstanceName: string; out SplashCreateIdx,
  SplashShowIdx, SplashFreeIdx, SplashCommentIdx: Integer;
  out SleepLine: string): Boolean;
var
  i: Integer;
  TrimmedLine: string;
  ClassName: string;
  InstanceName: string;
  ApplicationRunIdx: Integer;
  HasSplashIndicator: Boolean;
  HasOnlyAllowedInterveningLines: Boolean;

  function IsAllowedSplashInterveningLine(const ALine: string): Boolean;
  begin
    Result := (ALine = '') or StartsText('//', ALine) or
      StartsText('Sleep(', ALine) or
      SameText(ALine, 'Application.ProcessMessages;') or
      SameText(ALine, 'Application.HandleMessage;') or
      SameText(ALine, SplashInstanceName + '.Update;') or
      SameText(ALine, SplashInstanceName + '.Refresh;') or
      SameText(ALine, SplashInstanceName + '.Repaint;') or
      SameText(ALine, SplashInstanceName + '.BringToFront;');
  end;
begin
  SplashClassName := '';
  SplashInstanceName := '';
  SplashCreateIdx := -1;
  SplashShowIdx := -1;
  SplashFreeIdx := -1;
  SplashCommentIdx := -1;
  SleepLine := '';
  HasOnlyAllowedInterveningLines := True;

  if not Assigned(ALines) then
    Exit(False);

  ApplicationRunIdx := FindApplicationRunIndex(ALines);

  for i := 0 to ALines.Count - 1 do
  begin
    TrimmedLine := Trim(ALines[i]);
    if EndsText('.Show;', TrimmedLine) and not StartsText('Application.', TrimmedLine) then
    begin
      SplashInstanceName := Copy(TrimmedLine, 1, Pos('.Show;', TrimmedLine) - 1);
      SplashShowIdx := i;
      if (i > 0) and StartsText('//', Trim(ALines[i - 1])) and
         ContainsText(ALines[i - 1], 'splash') then
        SplashCommentIdx := i - 1;
      Break;
    end;
  end;

  if SplashShowIdx < 0 then
    Exit(False);

  for i := SplashShowIdx + 1 to ALines.Count - 1 do
  begin
    if (ApplicationRunIdx >= 0) and (i >= ApplicationRunIdx) then
      Break;

    TrimmedLine := Trim(ALines[i]);
    if StartsText(SplashInstanceName + '.Free;', TrimmedLine) then
    begin
      SplashFreeIdx := i;
      Break;
    end;
    if StartsText('Sleep(', TrimmedLine) then
      SleepLine := ALines[i];
    if not IsAllowedSplashInterveningLine(TrimmedLine) then
      HasOnlyAllowedInterveningLines := False;
  end;

  for i := SplashShowIdx - 1 downto 0 do
    if TryParseCreateForm(ALines[i], ClassName, InstanceName) and
       SameText(InstanceName, SplashInstanceName) then
    begin
      SplashCreateIdx := i;
      SplashClassName := ClassName;
      Break;
    end;

  HasSplashIndicator := (SplashCommentIdx >= 0) or
    ContainsText(SplashInstanceName, 'splash') or
    ContainsText(SplashClassName, 'splash') or
    (SleepLine <> '');

  Result := (SplashCreateIdx >= 0) and (SplashShowIdx >= 0) and
    (SplashFreeIdx >= 0) and
    ((ApplicationRunIdx < 0) or ((SplashShowIdx < ApplicationRunIdx) and
      (SplashFreeIdx < ApplicationRunIdx))) and
    HasSplashIndicator and HasOnlyAllowedInterveningLines;
end;

procedure TProjectGenerator.StripImmediateCreateFormShows(ALines: TStrings);
var
  i: Integer;
  ClassName: string;
  InstanceName: string;
  RecentCreateFormInstance: string;
begin
  if not Assigned(ALines) then
    Exit;

  RecentCreateFormInstance := '';
  for i := 0 to ALines.Count - 1 do
  begin
    if TryParseCreateForm(ALines[i], ClassName, InstanceName) then
    begin
      RecentCreateFormInstance := InstanceName;
      Continue;
    end;

    if (RecentCreateFormInstance <> '') and
       SameText(Trim(ALines[i]), RecentCreateFormInstance + '.Show;') then
    begin
      ALines[i] := '';
      RecentCreateFormInstance := '';
      Continue;
    end;

    if Trim(ALines[i]) <> '' then
      RecentCreateFormInstance := '';
  end;
end;

function TProjectGenerator.TransformDPRContent(const SourceCode: string): string;
var
  Lines: TStringList;
  OutputLines: TStringList;
  DeferredCreateForms: TStringList;
  AutoCreateInstances: TStringList;
  PostProcessLines: TStringList;
  i: Integer;
  ClassName: string;
  InstanceName: string;
  SplashClassName: string;
  SplashInstanceName: string;
  SplashCreateIdx: Integer;
  SplashShowIdx: Integer;
  SplashFreeIdx: Integer;
  SplashCommentIdx: Integer;
  ApplicationRunIdx: Integer;
  BlockStartIdx: Integer;
  SleepLine: string;
  Indent: string;
  IsDeferredCreateForm: Boolean;
  IsManualCreateForm: Boolean;
  DeferredIdx: Integer;
begin
  Lines := TStringList.Create;
  OutputLines := TStringList.Create;
  DeferredCreateForms := TStringList.Create;
  AutoCreateInstances := TStringList.Create;
  PostProcessLines := TStringList.Create;
  try
    Lines.Text := SourceCode;
    NormalizeDPRStartupLines(Lines);
    ApplicationRunIdx := FindApplicationRunIndex(Lines);

    if FindSplashStartupSequence(Lines, SplashClassName, SplashInstanceName,
         SplashCreateIdx, SplashShowIdx, SplashFreeIdx, SplashCommentIdx,
         SleepLine) then
    begin
      for i := 0 to SplashShowIdx - 1 do
        if (i <> SplashCreateIdx) and TryParseCreateForm(Lines[i], ClassName, InstanceName) then
          if not IsFormManuallyCreated(ClassName, InstanceName) then
          begin
            DeferredCreateForms.Add(Lines[i]);
            AutoCreateInstances.Add(InstanceName);
          end;

      BlockStartIdx := SplashShowIdx;
      if SplashCommentIdx >= 0 then
        BlockStartIdx := SplashCommentIdx;

      Indent := GetLeadingWhitespace(Lines[SplashShowIdx]);

      for i := 0 to Lines.Count - 1 do
      begin
        if i = ApplicationRunIdx then
        begin
          if DeferredCreateForms.Count > 0 then
          begin
            OutputLines.AddStrings(DeferredCreateForms);
            OutputLines.Add('');
          end;
        end;

        if (i >= BlockStartIdx) and (i <= SplashFreeIdx) then
        begin
          if i = BlockStartIdx then
          begin
            if SplashCommentIdx >= 0 then
              OutputLines.Add(Lines[SplashCommentIdx]);
            OutputLines.Add(Indent + SplashInstanceName + ' := ' + SplashClassName + '.Create(nil);');
            OutputLines.Add(Indent + 'try');
            OutputLines.Add(Indent + '  ' + SplashInstanceName + '.Show;');
            OutputLines.Add(Indent + '  Application.ProcessMessages;');
            OutputLines.Add(Indent + '  Application.HandleMessage;');
            if SleepLine <> '' then
              OutputLines.Add(SleepLine);
            OutputLines.Add(Indent + 'finally');
            OutputLines.Add(Indent + '  ' + SplashInstanceName + '.Free;');
            OutputLines.Add(Indent + '  ' + SplashInstanceName + ' := nil;');
            OutputLines.Add(Indent + 'end;');
          end;
          Continue;
        end;

        if i = SplashCreateIdx then
          Continue;

        IsDeferredCreateForm := (i < SplashShowIdx) and TryParseCreateForm(Lines[i], ClassName, InstanceName);
        IsManualCreateForm := IsDeferredCreateForm and IsFormManuallyCreated(ClassName, InstanceName);
        if IsDeferredCreateForm or IsManualCreateForm then
          Continue;

        if TryParseCreateForm(Lines[i], ClassName, InstanceName) and
           not SameText(InstanceName, SplashInstanceName) and
           not IsFormManuallyCreated(ClassName, InstanceName) and
           (AutoCreateInstances.IndexOf(InstanceName) = -1) then
          AutoCreateInstances.Add(InstanceName);

        OutputLines.Add(Lines[i]);
      end;

      if DeferredCreateForms.Count > 0 then
      begin
        ApplicationRunIdx := -1;
        for i := 0 to OutputLines.Count - 1 do
          if SameText(Trim(OutputLines[i]), 'Application.Run;') then
          begin
            ApplicationRunIdx := i;
            Break;
          end;

        if ApplicationRunIdx >= 0 then
          for DeferredIdx := DeferredCreateForms.Count - 1 downto 0 do
            if OutputLines.IndexOf(DeferredCreateForms[DeferredIdx]) = -1 then
              OutputLines.Insert(ApplicationRunIdx, DeferredCreateForms[DeferredIdx]);
      end;

      Result := OutputLines.Text;
    end
    else
      Result := Lines.Text;

    PostProcessLines.Text := Result;
    StripImmediateCreateFormShows(PostProcessLines);
    Result := PostProcessLines.Text;
    Result := TRegEx.Replace(Result,
      '^\s*Vcl\.(Themes|Styles)\s*,\s*\r?\n',
      '',
      [roIgnoreCase, roMultiLine]);
    Result := TRegEx.Replace(Result,
      '^(\s*)Vcl\.(Themes|Styles)\s*;\s*$',
      '$1;',
      [roIgnoreCase, roMultiLine]);
    Result := TRegEx.Replace(Result,
      ',\s*(\r?\n\s*;)',
      '$1',
      [roIgnoreCase]);

    // If the FMX message bridge is needed, inject it into the DPR uses clause.
    // This makes the unit available to all forms in the project automatically.
    // The injection is idempotent - safe to run on a project that already has it.
    if FContext.NeedsFMXMessageBridge and
       not ContainsText(Result, 'FMXMessageBridge') then
    begin
      // Find the closing semicolon of the uses block and insert before it.
      // Handles both:  "  SomeUnit in 'SomeUnit.pas';" and "  SomeUnit;"
      Result := TRegEx.Replace(Result,
        '(\buses\b(?:[^;]|\r|\n)*?)(\s*;)',
        '$1,' + sLineBreak + '  FMXMessageBridge in ''FMXMessageBridge.pas''$2',
        [roIgnoreCase, roSingleLine]);
    end;
  finally
    PostProcessLines.Free;
    AutoCreateInstances.Free;
    DeferredCreateForms.Free;
    OutputLines.Free;
    Lines.Free;
  end;
end;
function TProjectGenerator.TransformDPROJContent(const SourceCode: string): string;
var
  Matches: TMatchCollection;
  Match: TMatch;
  OldText: string;
  NewText: string;
  OldPath: string;
  NewPath: string;
begin
  Result := SourceCode;
  Result := StringReplace(Result,
    '.dfm',
    '.fmx',
    [rfReplaceAll, rfIgnoreCase]);

  Result := TRegEx.Replace(Result,
    '<FrameworkType>\s*[^<]+\s*</FrameworkType>',
    '<FrameworkType>FMX</FrameworkType>',
    [roIgnoreCase]);
  Result := TRegEx.Replace(Result,
    '<FormType>\s*[^<]+\s*</FormType>',
    '<FormType>fmx</FormType>',
    [roIgnoreCase]);

  Matches := TRegEx.Matches(Result,
    '<DCCReference\b[^>]*>.*?</DCCReference>',
    [roIgnoreCase, roSingleLine]);
  for Match in Matches do
  begin
    OldText := Match.Value;
    if ContainsText(OldText, '<Form>') and
       not ContainsText(OldText, '<FormType>') then
    begin
      NewText := TRegEx.Replace(OldText,
        '(</Form>)',
        '$1' + sLineBreak + '            <FormType>fmx</FormType>',
        [roIgnoreCase]);
      if OldText <> NewText then
        Result := StringReplace(Result, OldText, NewText, [rfReplaceAll]);
    end;
  end;

  Matches := TRegEx.Matches(Result,
    '<DCC_Namespace>(.*?)</DCC_Namespace>',
    [roIgnoreCase, roSingleLine]);
  for Match in Matches do
  begin
    OldText := Match.Value;
    NewText := '<DCC_Namespace>' + NormalizeNamespaceList(Match.Groups[1].Value) + '</DCC_Namespace>';
    if OldText <> NewText then
      Result := StringReplace(Result, OldText, NewText, [rfReplaceAll]);
  end;

  Matches := TRegEx.Matches(Result,
    '<(Icon_MainIcon|Manifest_File|UWP_DelphiLogo44|UWP_DelphiLogo150)>([^<]+)</(Icon_MainIcon|Manifest_File|UWP_DelphiLogo44|UWP_DelphiLogo150)>',
    [roIgnoreCase, roSingleLine]);
  for Match in Matches do
  begin
    if not SameText(Match.Groups[1].Value, Match.Groups[3].Value) then
      Continue;

    OldPath := Match.Groups[2].Value;
    NewPath := OldPath;
    if TryStageReferencedAsset(OldPath, NewPath) and
       not SameText(NewPath, OldPath) then
    begin
      OldText := Match.Value;
      NewText := '<' + Match.Groups[1].Value + '>' + NewPath + '</' +
        Match.Groups[3].Value + '>';
      Result := StringReplace(Result, OldText, NewText, [rfReplaceAll]);
    end;
  end;

  Matches := TRegEx.Matches(Result,
    '(DeployFile\s+LocalName=")([^"]+)(")',
    [roIgnoreCase]);
  for Match in Matches do
  begin
    OldPath := Match.Groups[2].Value;
    NewPath := OldPath;
    if TryStageReferencedAsset(OldPath, NewPath) and
       not SameText(NewPath, OldPath) then
    begin
      OldText := Match.Value;
      NewText := Match.Groups[1].Value + NewPath + Match.Groups[3].Value;
      Result := StringReplace(Result, OldText, NewText, [rfReplaceAll]);
    end;
  end;

  while ContainsText(Result, ';;') do
    Result := StringReplace(Result, ';;', ';', [rfReplaceAll]);
end;

function TProjectGenerator.TransformDPKContent(const SourceCode: string): string;
begin
  Result := SourceCode;
  Result := StringReplace(Result, '.dfm', '.fmx', [rfReplaceAll, rfIgnoreCase]);
  Result := TRegEx.Replace(Result, '(^\s*)vcl(\s*[,;])',
    '$1fmx$2', [roIgnoreCase, roMultiLine]);
  Result := StringReplace(Result, 'Vcl.', 'FMX.', [rfReplaceAll, rfIgnoreCase]);
end;

function TProjectGenerator.TransformDeployProjContent(const SourceCode: string): string;
var
  Matches: TMatchCollection;
  Match: TMatch;
  OldText: string;
  OldPath: string;
  NewPath: string;
begin
  Result := StringReplace(SourceCode,
    '.dfm',
    '.fmx',
    [rfReplaceAll, rfIgnoreCase]);

  Matches := TRegEx.Matches(Result,
    '(DeployFile\s+LocalName=")([^"]+)(")',
    [roIgnoreCase]);
  for Match in Matches do
  begin
    OldPath := Match.Groups[2].Value;
    NewPath := OldPath;
    if TryStageReferencedAsset(OldPath, NewPath) and
       not SameText(NewPath, OldPath) then
    begin
      OldText := Match.Value;
      Result := StringReplace(Result, OldText,
        Match.Groups[1].Value + NewPath + Match.Groups[3].Value,
        [rfReplaceAll]);
    end;
  end;
end;

procedure TProjectGenerator.CopyDPR;
var
  SourceDPR: string;
  TargetDPR: string;
  SourceCode: string;
  EncodingName: string;
begin
  SourceDPR := FindOriginalDPR;
  if SourceDPR = '' then Exit;

  try
    TargetDPR := TPath.Combine(FContext.Options.OutputPath,
                  TPath.GetFileName(SourceDPR));
    if not VCL2FMXTryReadTextFile(SourceDPR, SourceCode, EncodingName) then
      raise Exception.Create('Could not read DPR with supported encodings: ' + SourceDPR);
    SourceCode := TransformDPRContent(SourceCode);
    TFile.WriteAllText(TargetDPR, SourceCode, TEncoding.UTF8);
  except
    on E: Exception do
      FContext.AddIssue(csError, 'Failed to generate DPR: ' + E.Message);
  end;
end;

procedure TProjectGenerator.CopyDPROJ;
var
  SourceProj: string;
  TargetProj: string;
  SourceCode: string;
  EncodingName: string;
begin
  SourceProj := FindOriginalDPROJ;
  if SourceProj = '' then Exit;

  try
    TargetProj := TPath.Combine(FContext.Options.OutputPath,
                   TPath.GetFileName(SourceProj));
    if not VCL2FMXTryReadTextFile(SourceProj, SourceCode, EncodingName) then
      raise Exception.Create('Could not read DPROJ with supported encodings: ' + SourceProj);
    SourceCode := TransformDPROJContent(SourceCode);
    TFile.WriteAllText(TargetProj, SourceCode, TEncoding.UTF8);
  except
    on E: Exception do
      FContext.AddIssue(csError, 'Failed to generate DPROJ: ' + E.Message);
  end;
end;

procedure TProjectGenerator.CopyDPKFiles;
var
  SourceFiles: TStringDynArray;
  SourceFile: string;
  TargetFile: string;
  SourceCode: string;
  EncodingName: string;
begin
  SourceFiles := TDirectory.GetFiles(FContext.Options.SourcePath, '*.dpk',
    GetProjectSearchOption);
  for SourceFile in SourceFiles do
  begin
    try
      TargetFile := TPath.Combine(FContext.Options.OutputPath,
        GetProjectRelativeOutputPath(SourceFile));
      if TPath.GetDirectoryName(TargetFile) <> '' then
        ForceDirectories(TPath.GetDirectoryName(TargetFile));
      if not VCL2FMXTryReadTextFile(SourceFile, SourceCode, EncodingName) then
        raise Exception.Create('Could not read DPK with supported encodings: ' + SourceFile);
      SourceCode := TransformDPKContent(SourceCode);
      TFile.WriteAllText(TargetFile, SourceCode, TEncoding.UTF8);
      FContext.AddIssue(csInfo,
        'Delphi package file generated for FMX output: ' +
        GetProjectRelativeOutputPath(SourceFile));
    except
      on E: Exception do
        FContext.AddIssue(csError, 'Failed to generate DPK: ' + E.Message);
    end;
  end;
end;

procedure TProjectGenerator.CopyDeployProj;
var
  Source: string;
  Target: string;
  SourceCode: string;
  EncodingName: string;
begin
  Source := FindFirstProjectFile('*.deployproj');
  if Source = '' then
    Exit;

  try
    Target := TPath.Combine(FContext.Options.OutputPath,
               TPath.GetFileName(Source));
    if not VCL2FMXTryReadTextFile(Source, SourceCode, EncodingName) then
      raise Exception.Create('Could not read DEPLOYPROJ with supported encodings: ' + Source);
    SourceCode := TransformDeployProjContent(SourceCode);
    TFile.WriteAllText(Target, SourceCode, TEncoding.UTF8);
  except
    on E: Exception do
      FContext.AddIssue(csError, 'Failed to generate DEPLOYPROJ: ' + E.Message);
  end;
end;

procedure TProjectGenerator.CopyProjectCompanionFiles;
const
  CompanionExtensions: array[0..4] of string = ('.res', '.ico', '.manifest', '.png', '.bmp');
  RuntimeInventoryExtensions: array[0..3] of string = ('.exe', '.dll', '.lib', '.sf2');
  StageableRuntimeExtensions: array[0..2] of string = ('.exe', '.dll', '.sf2');
var
  SourceFiles: TStringDynArray;
  RuntimeFiles: TStringDynArray;
  SourceFile: string;
  TargetFile: string;
  Extension: string;
  SourceProj: string;
  SourceDPR: string;
  SourceCode: string;
  EncodingName: string;
  Matches: TMatchCollection;
  Match: TMatch;
  ReportedMissingAssets: TDictionary<string, Boolean>;
  ReportedCompanionNotes: TDictionary<string, Boolean>;
  PrimaryProjectExecutables: TStringList;
  StagedRuntimeCandidates: TDictionary<string, string>;

  function RelativeToSource(const APath: string): string;
  var
    SourceRoot: string;
  begin
    SourceRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(FContext.Options.SourcePath));
    Result := ExtractRelativePath(SourceRoot, TPath.GetFullPath(APath));
    Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
    if Result = '' then
      Result := TPath.GetFileName(APath);
  end;

  function IsBuildArtifactPath(const APath: string): Boolean;
  var
    PathParts: TArray<string>;
    PathPart: string;
  begin
    Result := False;
    PathParts := TPath.GetFullPath(APath).Split([PathDelim, '/']);
    for PathPart in PathParts do
      if VCL2FMXIsBuildArtifactFolder(PathPart) then
        Exit(True);
  end;

  function IsSourceRootFile(const APath: string): Boolean;
  begin
    Result := SameText(
      ExcludeTrailingPathDelimiter(TPath.GetDirectoryName(TPath.GetFullPath(APath))),
      ExcludeTrailingPathDelimiter(TPath.GetFullPath(FContext.Options.SourcePath)));
  end;

  function IsSourceSubfolderRuntimePath(const APath: string): Boolean;
  begin
    Result := not IsSourceRootFile(APath) and not IsBuildArtifactPath(APath);
  end;

  function IsTrustedSourceSubfolderRuntimePath(const APath: string): Boolean;
  var
    RelativePath: string;
    PathParts: TArray<string>;
    PathPart: string;
  begin
    Result := False;
    if not IsSourceSubfolderRuntimePath(APath) then
      Exit;

    RelativePath := LowerCase(RelativeToSource(APath));
    PathParts := ExtractFileDir(RelativePath).Split([PathDelim, '/']);
    for PathPart in PathParts do
    begin
      if SameText(PathPart, 'runtime') or
         SameText(PathPart, 'runtimes') or
         SameText(PathPart, 'support') or
         SameText(PathPart, 'bin') or
         SameText(PathPart, 'bins') or
         SameText(PathPart, 'tool') or
         SameText(PathPart, 'tools') or
         SameText(PathPart, 'asset') or
         SameText(PathPart, 'assets') or
         SameText(PathPart, 'dll') or
         SameText(PathPart, 'dlls') or
         SameText(PathPart, 'plugin') or
         SameText(PathPart, 'plugins') or
         SameText(PathPart, 'codec') or
         SameText(PathPart, 'codecs') or
         SameText(PathPart, 'soundfont') or
         SameText(PathPart, 'soundfonts') or
         SameText(PathPart, 'sf2') then
        Exit(True);
    end;
  end;

  function IsRuntimeBesideSourceCode(const APath: string): Boolean;
  var
    Folder: string;
    FolderFiles: TStringDynArray;
    FolderFile: string;
    SourceExtension: string;
  begin
    Result := False;
    if IsBuildArtifactPath(APath) then
      Exit;

    Folder := TPath.GetDirectoryName(TPath.GetFullPath(APath));
    if Folder = '' then
      Exit;

    FolderFiles := TDirectory.GetFiles(Folder, '*.*', TSearchOption.soTopDirectoryOnly);
    for FolderFile in FolderFiles do
    begin
      if SameText(TPath.GetFullPath(FolderFile), TPath.GetFullPath(APath)) then
        Continue;

      SourceExtension := LowerCase(TPath.GetExtension(FolderFile));
      if MatchText(SourceExtension,
        ['.pas', '.dfm', '.fmx', '.dpr', '.dproj', '.dpk']) then
        Exit(True);
    end;
  end;

  procedure AddReportedIssue(ASeverity: TConversionSeverity; const AMessage,
    AProblemType, AFileName, AOriginalCode, ASuggestedFix: string);
  var
    Issue: TConversionIssue;
  begin
    Issue := TConversionIssue.Create(ASeverity, AMessage);
    Issue.FileName := AFileName;
    Issue.ProblemType := AProblemType;
    Issue.OriginalCode := AOriginalCode;
    Issue.SuggestedFix := ASuggestedFix;
    FContext.AddIssue(Issue);
  end;

  procedure AddCompanionNote(const AKey: string; ASeverity: TConversionSeverity;
    const AMessage, AProblemType, AFileName, AOriginalCode, ASuggestedFix: string);
  var
    NormalizedKey: string;
  begin
    NormalizedKey := LowerCase(Trim(AKey));
    if (NormalizedKey = '') or ReportedCompanionNotes.ContainsKey(NormalizedKey) then
      Exit;

    ReportedCompanionNotes.Add(NormalizedKey, True);
    AddReportedIssue(ASeverity, AMessage, AProblemType, AFileName,
      AOriginalCode, ASuggestedFix);
  end;

  procedure AddMissingAssetWarning(const NormalizedPath: string);
  var
    Key: string;
  begin
    Key := LowerCase(NormalizedPath);
    if ReportedMissingAssets.ContainsKey(Key) then
      Exit;

    ReportedMissingAssets.Add(Key, True);
    FContext.AddIssue(csWarning,
      'Referenced project asset could not be copied into the FMX output: ' + NormalizedPath,
      'Project companion asset warning',
      NormalizedPath,
      'Confirm the asset exists and is reachable, or move it into the source project tree before reconverting.');
  end;

  procedure CopyReferencedAsset(const RawPath: string);
  var
    NormalizedPath: string;
    RewrittenPath: string;
  begin
    NormalizedPath := NormalizeAssetReference(RawPath);
    if ShouldIgnoreAssetReference(NormalizedPath) then
      Exit;

    RewrittenPath := NormalizedPath;
    if TryStageReferencedAsset(NormalizedPath, RewrittenPath) then
      Exit;

    AddMissingAssetWarning(NormalizedPath);
  end;

  function IsRuntimeInventoryExtension(const AExtension: string): Boolean;
  var
    NormalizedExtension: string;
  begin
    NormalizedExtension := LowerCase(AExtension);
    Result := MatchText(NormalizedExtension, RuntimeInventoryExtensions);
  end;

  function IsStageableRuntimeExtension(const AExtension: string): Boolean;
  var
    NormalizedExtension: string;
  begin
    NormalizedExtension := LowerCase(AExtension);
    Result := MatchText(NormalizedExtension, StageableRuntimeExtensions);
  end;

  function IsPrimaryProjectExecutable(const APath: string): Boolean;
  begin
    Result := PrimaryProjectExecutables.IndexOf(LowerCase(TPath.GetFileName(APath))) <> -1;
  end;

  procedure ConsiderRuntimeStage(const RuntimeFile: string);
  var
    RuntimeName: string;
  begin
    if not IsStageableRuntimeExtension(TPath.GetExtension(RuntimeFile)) then
      Exit;
    if IsPrimaryProjectExecutable(RuntimeFile) then
      Exit;

    RuntimeName := LowerCase(TPath.GetFileName(RuntimeFile));
    StagedRuntimeCandidates.AddOrSetValue(RuntimeName, RuntimeFile);
  end;

  procedure ReportRuntimeInventory(const RuntimeFile, LocationLabel,
    ProblemType, Recommendation: string; ASeverity: TConversionSeverity = csInfo);
  begin
    AddCompanionNote(LocationLabel + '|' + LowerCase(TPath.GetFullPath(RuntimeFile)), ASeverity,
      LocationLabel + ': ' + RelativeToSource(RuntimeFile),
      ProblemType,
      RuntimeFile,
      RelativeToSource(RuntimeFile),
      Recommendation);
  end;

  procedure ScanRuntimeInventory;
  var
    RuntimeIndex: Integer;
    RuntimeFile: string;
  begin
    RuntimeFiles := TDirectory.GetFiles(FContext.Options.SourcePath, '*.*',
      TSearchOption.soTopDirectoryOnly);
    for RuntimeIndex := 0 to Length(RuntimeFiles) - 1 do
    begin
      RuntimeFile := RuntimeFiles[RuntimeIndex];
      Extension := LowerCase(TPath.GetExtension(RuntimeFile));
      if not IsRuntimeInventoryExtension(Extension) then
        Continue;
      if IsPrimaryProjectExecutable(RuntimeFile) then
        Continue;

      if IsSourceRootFile(RuntimeFile) then
      begin
        if IsStageableRuntimeExtension(Extension) then
          ConsiderRuntimeStage(RuntimeFile);
        Continue;
      end;
    end;
  end;

  procedure StageRuntimeCompanions;
  var
    RuntimePair: TPair<string, string>;
    RuntimeFile: string;
  begin
    for RuntimePair in StagedRuntimeCandidates do
    begin
      RuntimeFile := RuntimePair.Value;
      TargetFile := TPath.Combine(FContext.Options.OutputPath,
        TPath.GetFileName(RuntimeFile));
      if not SameText(RuntimeFile, TargetFile) then
        TFile.Copy(RuntimeFile, TargetFile, True);

      AddCompanionNote('staged-runtime|' + LowerCase(TPath.GetFileName(RuntimeFile)), csInfo,
        'Runtime companion copied from source folder to FMX output directory: ' + TPath.GetFileName(RuntimeFile),
        'Runtime companion copied',
        RuntimeFile,
        RelativeToSource(RuntimeFile),
        'Only the source-folder copy was used; duplicate copies in subfolders are ignored.');
    end;
  end;
begin
  ReportedMissingAssets := TDictionary<string, Boolean>.Create;
  ReportedCompanionNotes := TDictionary<string, Boolean>.Create;
  PrimaryProjectExecutables := TStringList.Create;
  StagedRuntimeCandidates := TDictionary<string, string>.Create;
  try
    try
      PrimaryProjectExecutables.CaseSensitive := False;
      PrimaryProjectExecutables.Sorted := False;
      PrimaryProjectExecutables.Duplicates := dupIgnore;

      SourceDPR := FindOriginalDPR;
      if SourceDPR <> '' then
        PrimaryProjectExecutables.Add(LowerCase(
          TPath.GetFileNameWithoutExtension(SourceDPR) + '.exe'));

      SourceFiles := TDirectory.GetFiles(FContext.Options.SourcePath, '*.*', TSearchOption.soTopDirectoryOnly);
      for SourceFile in SourceFiles do
      begin
        Extension := LowerCase(TPath.GetExtension(SourceFile));
        if not MatchText(Extension, CompanionExtensions) then
          Continue;

        TargetFile := TPath.Combine(FContext.Options.OutputPath, TPath.GetFileName(SourceFile));
        if not SameText(SourceFile, TargetFile) then
          TFile.Copy(SourceFile, TargetFile, True);
      end;

      SourceProj := FindOriginalDPROJ;
      if SourceProj <> '' then
      begin
        if not VCL2FMXTryReadTextFile(SourceProj, SourceCode, EncodingName) then
          raise Exception.Create('Could not read DPROJ companion asset metadata: ' + SourceProj);

        Matches := TRegEx.Matches(SourceCode,
          '<(?:Icon_MainIcon|Manifest_File|UWP_DelphiLogo44|UWP_DelphiLogo150)>([^<]+)</(?:Icon_MainIcon|Manifest_File|UWP_DelphiLogo44|UWP_DelphiLogo150)>',
          [roIgnoreCase, roSingleLine]);
        for Match in Matches do
          CopyReferencedAsset(Match.Groups[1].Value);

        Matches := TRegEx.Matches(SourceCode,
          'DeployFile\s+LocalName="([^"]+)"',
          [roIgnoreCase]);
        for Match in Matches do
          CopyReferencedAsset(Match.Groups[1].Value);

        PrimaryProjectExecutables.Add(LowerCase(
          TPath.GetFileNameWithoutExtension(SourceProj) + '.exe'));
      end;

      ScanRuntimeInventory;
      StageRuntimeCompanions;
    except
      on E: Exception do
        FContext.AddIssue(csWarning,
          'Project companion file copy pass encountered an error: ' + E.Message,
          'Project companion copy warning',
          '',
          'Review the generated project files, confirm icons, manifests, and related assets exist in the FMX output, and copy any missing companion files manually if needed.');
    end;
  finally
    StagedRuntimeCandidates.Free;
    PrimaryProjectExecutables.Free;
    ReportedCompanionNotes.Free;
    ReportedMissingAssets.Free;
  end;
end;

procedure TProjectGenerator.GenerateProject;
begin
  CopyDPR;
  CopyDPROJ;
  CopyDPKFiles;
  CopyDeployProj;
  CopyProjectCompanionFiles;

  if FContext.NeedsFMXMessageBridge then
    GenerateFMXMessageBridge;

  FContext.AddIssue(csInfo, 'Delphi project files generated for FMX output');
end;

procedure TProjectGenerator.GenerateFMXMessageBridge;
var
  BridgePath: string;
  Content: TStringList;
begin
  BridgePath := TPath.Combine(FContext.Options.OutputPath, 'FMXMessageBridge.pas');
  if TFile.Exists(BridgePath) then
    Exit; // Never overwrite if user has already customised it

  Content := TStringList.Create;
  try
    Content.Add('{VCL2FMX © 2026 echurchsites.wixsite.com');
    Content.Add(' FMXMessageBridge.pas — Cross-platform message bridge');
    Content.Add(' Generated by VCL2FMX Converter v4.1');
    Content.Add(' Replaces Windows WM_USER messaging with TMessageManager.}');
    Content.Add('');
    Content.Add('unit FMXMessageBridge;');
    Content.Add('');
    Content.Add('{ PURPOSE');
    Content.Add('  This unit provides a cross-platform alternative to Windows WM_USER');
    Content.Add('  messaging. It uses Embarcadero''s TMessageManager (System.Messaging)');
    Content.Add('  which works identically on Windows, macOS, iOS, and Android.');
    Content.Add('');
    Content.Add('  QUICK START');
    Content.Add('  1. Define a typed message for each WM_USER + N you had:');
    Content.Add('       type TMyCustomMsg = class(TMessage<Integer>) end;');
    Content.Add('');
    Content.Add('  2. In FormCreate, subscribe:');
    Content.Add('       TMessageManager.DefaultManager.SubscribeToMessage(TMyCustomMsg,');
    Content.Add('         procedure(const Sender: TObject; const M: TMessage)');
    Content.Add('         begin');
    Content.Add('           HandleMyCustomMsg(M as TMyCustomMsg);');
    Content.Add('         end);');
    Content.Add('');
    Content.Add('  3. To send (replaces PostMessage/SendMessage):');
    Content.Add('       TMessageManager.DefaultManager.SendMessage(Self,');
    Content.Add('         TMyCustomMsg.Create(YourIntegerValue));');
    Content.Add('');
    Content.Add('  4. In FormDestroy, unsubscribe:');
    Content.Add('       TMessageManager.DefaultManager.Unsubscribe(TMyCustomMsg);');
    Content.Add('');
    Content.Add('  NOTE: TMessage<T> is generic. Use any payload type:');
    Content.Add('    TMessage<string>, TMessage<TObject>, TMessage<Integer>, etc.');
    Content.Add('    Or define a payload record for complex data.}');
    Content.Add('');
    Content.Add('interface');
    Content.Add('');
    Content.Add('uses');
    Content.Add('  System.Messaging,');
    Content.Add('  System.SysUtils,');
    Content.Add('  System.Classes;');
    Content.Add('');
    Content.Add('type');
    Content.Add('  { Base class for all converted WM_USER messages.');
    Content.Add('    Subclass this for each distinct message type. }');
    Content.Add('  TFMXUserMessage = class(TMessage<Integer>)');
    Content.Add('  public');
    Content.Add('    constructor Create(const AValue: Integer = 0); reintroduce;');
    Content.Add('  end;');
    Content.Add('');
    Content.Add('  { Generic helper: send a message to all subscribers. }');
    Content.Add('  procedure FMXSendMessage(AMsgClass: TClass; AValue: Integer = 0);');
    Content.Add('');
    Content.Add('  { Generic helper: post a message asynchronously via main thread. }');
    Content.Add('  procedure FMXPostMessage(AMsgClass: TClass; AValue: Integer = 0);');
    Content.Add('');
    Content.Add('implementation');
    Content.Add('');
    Content.Add('constructor TFMXUserMessage.Create(const AValue: Integer = 0);');
    Content.Add('begin');
    Content.Add('  inherited Create(AValue);');
    Content.Add('end;');
    Content.Add('');
    Content.Add('procedure FMXSendMessage(AMsgClass: TClass; AValue: Integer = 0);');
    Content.Add('begin');
    Content.Add('  TMessageManager.DefaultManager.SendMessage(nil,');
    Content.Add('    TFMXUserMessage.Create(AValue));');
    Content.Add('end;');
    Content.Add('');
    Content.Add('procedure FMXPostMessage(AMsgClass: TClass; AValue: Integer = 0);');
    Content.Add('begin');
    Content.Add('  TThread.Queue(nil,');
    Content.Add('    procedure');
    Content.Add('    begin');
    Content.Add('      TMessageManager.DefaultManager.SendMessage(nil,');
    Content.Add('        TFMXUserMessage.Create(AValue));');
    Content.Add('    end);');
    Content.Add('end;');
    Content.Add('');
    Content.Add('end.');

    TFile.WriteAllText(BridgePath, Content.Text, TEncoding.UTF8);
    FContext.AddIssue(csInfo,
      'FMXMessageBridge.pas generated in output folder. ' +
      'Add it to your project and use TMessageManager to replace WM_USER messaging.');
  finally
    Content.Free;
  end;
end;

end.
