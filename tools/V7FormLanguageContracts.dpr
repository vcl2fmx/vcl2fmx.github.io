program V7FormLanguageContracts;
{$APPTYPE CONSOLE}

uses
  System.StartUpCopy, System.Classes, Winapi.Windows,
  System.SysUtils, System.IOUtils, System.Math, System.UITypes, FMX.Controls, DAT.Components.Core,
  FMX.Forms, FMX.StdCtrls, FMX.TextLayout, FMX.Types, FMX.Graphics, FMX.Objects, FMX.Layouts, FMX.TabControl, System.Types,
  MainForm in '..\MainForm.pas' {frmMain},
  Converter.Advanced.CriticalAreas in '..\Converter.Advanced.CriticalAreas.pas',
  Converter.Advanced.DataAware in '..\Converter.Advanced.DataAware.pas',
  Converter.Advanced.ThirdParty in '..\Converter.Advanced.ThirdParty.pas',
  Converter.Advanced.WinAPI in '..\Converter.Advanced.WinAPI.pas',
  Converter.Core.Engine in '..\Converter.Core.Engine.pas',
  Converter.Core.FileManager in '..\Converter.Core.FileManager.pas',
  Converter.Core.Integration in '..\Converter.Core.Integration.pas',
  Converter.Core.Types in '..\Converter.Core.Types.pas',
  Converter.Mapper.Component in '..\Converter.Mapper.Component.pas',
  Converter.Mapper.Catalog in '..\Converter.Mapper.Catalog.pas',
  Converter.Parser.DFM in '..\Converter.Parser.DFM.pas',
  Converter.Generator.FMX in '..\Converter.Generator.FMX.pas',
  Converter.Parser.Pascal in '..\Converter.Parser.Pascal.pas',
  Converter.Project.Generator in '..\Converter.Project.Generator.pas',
  Converter.Reporting.Html in '..\Converter.Reporting.Html.pas',
  Converter.Reporting.Json in '..\Converter.Reporting.Json.pas',
  Converter.Reporting.Model in '..\Converter.Reporting.Model.pas',
  Converter.Reporting.Text in '..\Converter.Reporting.Text.pas',
  Converter.Rewrite.AutoFixes in '..\Converter.Rewrite.AutoFixes.pas',
  Converter.Rewrite.Compatibility in '..\Converter.Rewrite.Compatibility.pas',
  Converter.Rewrite.LiveBindings in '..\Converter.Rewrite.LiveBindings.pas',
  Converter.Rewrite.RuntimeNormalization in '..\Converter.Rewrite.RuntimeNormalization.pas',
  Converter.Rewrite.UsesClause in '..\Converter.Rewrite.UsesClause.pas';


type
  TTextLayoutProbe = class(TText)
  public
    property Layout;
  end;

var
  PackFile, Code, Stage: string;
  WindowWidth, WindowHeight, Checks, ViewportChecks, PageChecks, NavigationFailures,
    TransitionChecks, ScaleChecks: Integer;
  Enabled: Boolean;
  NavigationLabel: TLabel;
  Capture: TBitmap;
  CaptionObject: TFmxObject;
  CaptionControl: TStyledControl;
  RuleCheckBox: TCheckBox;

procedure CheckCaptionFit(const Control: TStyledControl);
var TextObject: TFmxObject;
begin
  TextObject := Control.FindStyleResource('text');
  if TextObject is TText then
    if TTextLayoutProbe(TextObject).Layout.TextHeight > TText(TextObject).Height + 2 then
      raise Exception.CreateFmt('%s: %s caption height %.1f exceeds its styled text box %.1f',
        [Code, Control.Name, TTextLayoutProbe(TextObject).Layout.TextHeight, TText(TextObject).Height]);
end;

procedure CheckInside(const ParentControl: TControl);
var Index: Integer; Child: TControl; AvailableHeight: Single;
begin
  AvailableHeight := ParentControl.Height;
  if ParentControl is TScrollContent then
    AvailableHeight := Max(AvailableHeight, TScrollContent(ParentControl).ScrollBox.ContentBounds.Bottom);
  for Index := 0 to ParentControl.ControlsCount - 1 do
  begin
    Child := ParentControl.Controls[Index];
    if not Child.Visible or (Child.Owner <> frmMain) then Continue;
    if (Child.Position.X < -1) or (Child.Position.Y < -1) or
      (Child.Position.X + Child.Width > ParentControl.Width + 1) or
      (Child.Position.Y + Child.Height > AvailableHeight + 1) then
      raise Exception.CreateFmt('%s: %s overflows %s: %.1f,%.1f %.1fx%.1f in %.1fx%.1f',
        [Code, Child.Name, ParentControl.Name, Child.Position.X, Child.Position.Y,
        Child.Width, Child.Height, ParentControl.Width, ParentControl.Height]);
    if Child.ControlsCount > 0 then CheckInside(Child);
  end;
end;

procedure CheckSummary(const LabelControl: TLabel; const ExpectedLines: Integer);
var
  Layout: TTextLayout;
  ScalePercent: Integer;
  TextScale: Single;
begin
  if (ExpectedLines > 0) and (Length(LabelControl.Text.Split([#10])) <> ExpectedLines) then
    raise Exception.Create(Code + ': lost summary line breaks in ' + LabelControl.Name);
  if (ExpectedLines >= 0) and (LabelControl.TextSettings.VertAlign <> TTextAlign.Leading) then
    raise Exception.Create(Code + ': summary must be top aligned');
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    Layout.Font.Assign(LabelControl.TextSettings.Font);
    Layout.MaxSize := PointF(LabelControl.Width - IfThen(LabelControl.AutoSize, 0, 4), 10000);
    Layout.WordWrap := True;
    Layout.Text := LabelControl.Text;
    Layout.EndUpdate;
    if Layout.TextHeight > LabelControl.Height - IfThen(LabelControl.AutoSize, 0, 2) then
      raise Exception.CreateFmt('%s: %s text height %.1f exceeds box %.1f',
        [Code, LabelControl.Name, Layout.TextHeight, LabelControl.Height]);
    // Stress font shaping and wrapping at proportional text/box scales.
    // This does not change Windows display settings or emulate monitor DPI changes.
    for ScalePercent in [125, 150, 200] do
    begin
      TextScale := ScalePercent / 100;
      Layout.BeginUpdate;
      Layout.Font.Size := LabelControl.TextSettings.Font.Size * TextScale;
      Layout.MaxSize := PointF((LabelControl.Width - IfThen(LabelControl.AutoSize, 0, 4)) * TextScale, 10000);
      Layout.EndUpdate;
      if Layout.TextHeight > (LabelControl.Height + 2) * TextScale then
        raise Exception.CreateFmt('%s: %s text does not fit at %d%% scale',
          [Code, LabelControl.Name, ScalePercent]);
      Inc(ScaleChecks);
    end;
    if not (LabelControl.Parent is TScrollContent) and
      (LabelControl.Position.Y + LabelControl.Height > TControl(LabelControl.Parent).Height) then
      raise Exception.Create(Code + ': summary extends beyond its card');
  finally
    Layout.Free;
  end;
end;

procedure CheckGap(const LeftCard, RightCard: TControl; const Minimum: Single);
var Gap: Single;
begin
  if LeftCard.Position.X <= RightCard.Position.X then
    Gap := RightCard.Position.X - LeftCard.Position.X - LeftCard.Width
  else
    Gap := LeftCard.Position.X - RightCard.Position.X - RightCard.Width;
  if Gap < Minimum - 0.1 then
    raise Exception.CreateFmt('%s width %d: %s / %s gap %.2f < %.2f',
      [Code, WindowWidth, LeftCard.Name, RightCard.Name, Gap, Minimum]);
  Inc(Checks);
end;

procedure CheckRulesViewport;
var Card, Background: TRectangle; Scroll: TVertScrollBox; FirstLabel, LastLabel: TLabel;
  LastBottom: Single; Attempt: Integer;
begin
  Background := frmMain.FindComponent('RulesSheetBackground') as TRectangle;
  for Card in [frmMain.RulesCard, frmMain.RulesSummaryCard] do
  begin
    if (Card.Parent <> Background.Parent) or
      (Card.Position.Y < Background.Position.Y) or
      (Card.Position.Y + Card.Height > Background.Height - 17) or
      (Abs(Card.Height - (Background.Height - 36)) > 1) then
      raise Exception.CreateFmt('%s: %s outside background: parent=%s, y=%.1f height=%.1f background=%.1f tab=%.1f',
        [Code, Card.Name, Card.Parent.ClassName, Card.Position.Y, Card.Height, Background.Height, frmMain.tabRules.Height]);
    CheckInside(Card);
  end;
  for Scroll in [frmMain.RulesScrollBox, frmMain.RulesSummaryScrollBox] do
  begin
    if Scroll = frmMain.RulesScrollBox then
    begin
      FirstLabel := frmMain.lblRulesTitle;
      LastLabel := frmMain.lblWinAPIHint;
    end
    else
    begin
      FirstLabel := frmMain.lblRulesSummaryTitle;
      LastLabel := frmMain.lblRulesSummaryNote;
    end;
    CheckInside(Scroll.Content);
    LastBottom := LastLabel.Position.Y + LastLabel.Height;
    if LastBottom > Scroll.ContentBounds.Bottom + 1 then
      raise Exception.Create(Code + ': Rules text cannot be reached by scrolling');
    Scroll.ViewportPosition := PointF(0, Max(0, Scroll.ContentBounds.Bottom - Scroll.ClientHeight));
    for Attempt := 1 to 50 do
    begin
      Sleep(20);
      Application.ProcessMessages;
      if Abs(Scroll.Content.Position.Y + Scroll.ViewportPosition.Y) < 1 then Break;
    end;
    if LastLabel.AbsoluteRect.Bottom > Scroll.AbsoluteRect.Bottom + 1 then
      raise Exception.Create(Code + ': final Rules paragraph remains below the scroll viewport');
    Scroll.ViewportPosition := PointF(0, 0);
    for Attempt := 1 to 50 do
    begin
      Sleep(20);
      Application.ProcessMessages;
      if Abs(Scroll.Content.Position.Y) < 1 then Break;
    end;
    if Abs(Scroll.ViewportPosition.Y) > 1 then
      raise Exception.Create(Code + ': Rules scroll viewport did not return to the top');
    if FirstLabel.AbsoluteRect.Top < Scroll.AbsoluteRect.Top - 1 then
      raise Exception.CreateFmt('%s: Rules title is above the viewport after reset: title %.1f, viewport %.1f, content %.1f',
        [Code, FirstLabel.AbsoluteRect.Top, Scroll.AbsoluteRect.Top, Scroll.Content.Position.Y]);
  end;
  Inc(ViewportChecks);
end;

procedure CheckAllPageBoundaries;
const Names: array[0..6] of string = ('Dashboard', 'ProjectScan', 'ComponentMap',
  'PropertyMap', 'EventMap', 'Issues', 'Rules');
var PageIndex, ScrollStep, Attempt, SampleIndex: Integer;
  Background: TRectangle; Scroll: TVertScrollBox; Page: TTabItem;
  MaxScroll: Single; Bitmap: TBitmap; Pixels: TBitmapData; Sample: TPointF;
begin
  for PageIndex := 0 to High(Names) do
  begin
    case PageIndex of
      0: Page := frmMain.tabDashboard;
      1: Page := frmMain.tabProjectScan;
      2: Page := frmMain.tabComponentMap;
      3: Page := frmMain.tabPropertyMap;
      4: Page := frmMain.tabEventMap;
      5: Page := frmMain.tabIssues;
    else Page := frmMain.tabRules;
    end;
    frmMain.TabControlMain.ActiveTab := Page;
    Application.ProcessMessages;
    Background := frmMain.FindComponent(Names[PageIndex] + 'SheetBackground') as TRectangle;
    if PageIndex = 6 then CheckRulesViewport
    else
    begin
      Scroll := frmMain.FindComponent(Names[PageIndex] + 'ScrollBox') as TVertScrollBox;
      if (Background.Parent <> Scroll.Parent) or
        (Abs(Background.Height - TControl(Background.Parent).Height) > 1) or
        (Abs(Background.Width - TControl(Background.Parent).Width) > 1) then
        raise Exception.Create(Code + ': ' + Names[PageIndex] + ' background does not fill the fixed page');
      if not Scroll.ClipChildren or
        (Scroll.AbsoluteRect.Bottom > Background.AbsoluteRect.Bottom - 11) or
        (Scroll.AbsoluteRect.Top < Background.AbsoluteRect.Top + 11) then
        raise Exception.Create(Code + ': ' + Names[PageIndex] + ' scrolling can escape the blue page');
      MaxScroll := Max(0, Scroll.ContentBounds.Bottom - Scroll.ClientHeight);
      if PageIndex = 0 then
        if frmMain.DashboardNextCard.Position.X + frmMain.DashboardNextCard.Width > Scroll.Content.Width - 11 then
          raise Exception.CreateFmt('%s: Dashboard workflow card has no right inset: x=%.1f width=%.1f content=%.1f',
            [Code, frmMain.DashboardNextCard.Position.X, frmMain.DashboardNextCard.Width, Scroll.Content.Width]);
      for ScrollStep := 0 to 2 do
      begin
        Scroll.ViewportPosition := PointF(0, MaxScroll * ScrollStep / 2);
        for Attempt := 1 to 50 do
        begin
          Sleep(20);
          Application.ProcessMessages;
          if Abs(Scroll.Content.Position.Y + Scroll.ViewportPosition.Y) < 1 then Break;
        end;
        if (Abs(Background.Position.Y) > 1) or
          (Scroll.AbsoluteRect.Bottom > Background.AbsoluteRect.Bottom - 11) then
          raise Exception.Create(Code + ': ' + Names[PageIndex] + ' blue background moved during scrolling');
      end;
    end;
    Bitmap := frmMain.RootLayout.MakeScreenshot;
    try
      if not Bitmap.Map(TMapAccess.Read, Pixels) then raise Exception.Create('Cannot inspect page pixels');
      try
        for SampleIndex := 1 to 3 do
        begin
          Sample := frmMain.RootLayout.AbsoluteToLocal(Background.LocalToAbsolute(
            PointF(Background.Width * SampleIndex / 4, Background.Height - 6)));
          if Pixels.GetPixel(Round(Sample.X * Bitmap.BitmapScale), Round(Sample.Y * Bitmap.BitmapScale)) <> Background.Fill.Color then
            raise Exception.CreateFmt('%s: %s paints outside the blue page at its bottom edge (%d x %d)',
              [Code, Names[PageIndex], WindowWidth, WindowHeight]);
        end;
      finally Bitmap.Unmap(Pixels); end;
      if (WindowWidth = 1600) and (WindowHeight = 800) and
        ((Code = 'ru-RU') or (Code = 'pt-BR') or (Code = 'en-US')) then
        Bitmap.SaveToFile(System.IOUtils.TPath.Combine(ParamStr(2), Code + '-' + Names[PageIndex] + '-page-bottom.png'));
    finally Bitmap.Free; end;
    if (PageIndex = 1) and (WindowWidth = 1600) and (WindowHeight = 800) then
    begin
      frmMain.ProjectScanScrollBox.ViewportPosition := PointF(0, 0);
      Application.ProcessMessages;
      Bitmap := frmMain.RootLayout.MakeScreenshot;
      try Bitmap.SaveToFile(System.IOUtils.TPath.Combine(ParamStr(2), Code + '-ProjectScan-top.png'));
      finally Bitmap.Free; end;
    end;
    Inc(PageChecks);
  end;
end;

begin
  Checks := 0;
  ViewportChecks := 0;
  PageChecks := 0;
  NavigationFailures := 0;
  TransitionChecks := 0;
  ScaleChecks := 0;
  try
    if ParamCount < 2 then
      raise Exception.Create('Usage: V7FormLanguageContracts <language-packs> <test-workspace>');
    TDirectory.CreateDirectory(System.IOUtils.TPath.Combine(ParamStr(2), 'FormTestPreferences'));
    Winapi.Windows.SetEnvironmentVariable('LOCALAPPDATA',
      PChar(System.IOUtils.TPath.Combine(ParamStr(2), 'FormTestPreferences')));
    Writeln('Initialize'); Flush(Output);
    Application.Initialize;
    Writeln('Create form'); Flush(Output);
    frmMain := TfrmMain.Create(nil);
    // Each test step refreshes explicitly; a timer adds unrelated refreshes during the size matrix.
    frmMain.DATLanguageManager.AutoRefreshDynamicText := False;
    frmMain.WindowState := TWindowState.wsNormal;
    frmMain.Show;
    Application.ProcessMessages;
    Writeln('Form created'); Flush(Output);
    Writeln('Manager configured'); Flush(Output);
    if not frmMain.cmbLanguage.SelectLanguageCode('en-US') then
      raise Exception.Create('Could not select the initial English language');
    for PackFile in TDirectory.GetFiles(ParamStr(1), '*.json') do
    begin
      Code := System.IOUtils.TPath.GetFileNameWithoutExtension(PackFile);
      if (ParamStr(3) <> '') and (ParamStr(3) <> '*') and
        (Pos('|' + Code + '|', '|' + ParamStr(3) + '|') = 0) then Continue;
      Writeln(Code); Flush(Output);
      Stage := 'return to English';
      if not frmMain.cmbLanguage.SelectLanguageCode('en-US') then
        raise Exception.Create('Could not return to English');
      frmMain.DATLanguageManager.RefreshDynamicText;
      Application.ProcessMessages;
      if (Trim(frmMain.lblLanguage.Text) <> 'Language:') or
        (frmMain.BiDiMode <> bdLeftToRight) then
        raise Exception.Create(Code + ': English text or reading direction was not restored');
      Inc(TransitionChecks);
      Stage := 'select language';
      if not frmMain.cmbLanguage.SelectLanguageCode(Code) then
        raise Exception.Create('Could not select ' + Code);
      Application.ProcessMessages;
      if (Code <> 'en-US') and SameText(Trim(frmMain.lblLanguage.Text), 'Language:') then
        raise Exception.Create(Code + ': actual form label was not translated');
      frmMain.DATLanguageManager.RefreshDynamicText;
      Application.ProcessMessages;
      CaptionObject := frmMain.chkWinAPI.FindStyleResource('text');
      if (CaptionObject is TText) and
        (TTextLayoutProbe(CaptionObject).Layout.RightToLeft <>
          (frmMain.BiDiMode = bdRightToLeft)) then
        raise Exception.Create(Code + ': unchanged checkbox caption retained the previous reading direction');
      if (Pos('Atlas', frmMain.Caption) = 0) or
        (frmMain.HeroAtlasGhost.Text <> 'ATLAS') then
        raise Exception.Create(Code + ': Atlas branding was not applied');
      if (Abs(frmMain.HeroAtlasGhost.TextSettings.Font.Size - 112) > 0.1) or
        (Abs(frmMain.HeroAtlasGhost.Width - 700) > 0.1) or
        (frmMain.HeroAtlasGhost.TextSettings.HorzAlign <> TTextAlign.Center) then
        raise Exception.Create(Code + ': Atlas hero branding was resized');
      Writeln(Format('Atlas geometry: %.0f %.0f %.0f %.0f font %.0f', [frmMain.HeroAtlasGhost.Position.X, frmMain.HeroAtlasGhost.Position.Y, frmMain.HeroAtlasGhost.Width, frmMain.HeroAtlasGhost.Height, frmMain.HeroAtlasGhost.TextSettings.Font.Size]));
      for WindowWidth in [1280, 1345, 1600] do
      begin
        if (ParamStr(4) = 'all-pages-languages') and (WindowWidth <> 1600) then Continue;
        frmMain.ClientWidth := WindowWidth;
        if (ParamStr(4) = 'all-pages') or (ParamStr(4) = 'all-pages-languages') then
        begin
          for WindowHeight in [600, 800, 1000] do
          begin
            if (ParamStr(4) = 'all-pages-languages') and (WindowHeight <> 800) then Continue;
            frmMain.ClientHeight := WindowHeight;
            Application.ProcessMessages;
            CheckAllPageBoundaries;
          end;
          Continue;
        end;
        frmMain.TabControlMain.ActiveTab := frmMain.tabRules;
        Application.ProcessMessages;
        for WindowHeight in [600, 800, 1000] do
        begin
          frmMain.ClientHeight := WindowHeight;
          Application.ProcessMessages;
          CheckRulesViewport;
          if (WindowWidth = 1600) and (WindowHeight = 800) and
            ((Code = 'pt-BR') or (Code = 'ru-RU')) then
          begin
            Capture := frmMain.RootLayout.MakeScreenshot;
            try Capture.SaveToFile(System.IOUtils.TPath.Combine(ParamStr(2), Code + '-rules-viewport.png'));
            finally Capture.Free; end;
          end;
        end;
        frmMain.ClientHeight := 800;
        Application.ProcessMessages;
        if ParamStr(4) = 'rules-only' then Continue;
        if WindowWidth = 1600 then CheckAllPageBoundaries;
        frmMain.TabControlMain.ActiveTab := frmMain.tabProjectScan;
        Application.ProcessMessages;
        CheckInside(frmMain.ProjectCard);
        CheckInside(frmMain.ProjectActionCard);
        for CaptionControl in [frmMain.btnBrowseSource, frmMain.btnBrowseTarget,
          frmMain.btnConvert, frmMain.btnReset, frmMain.btnOpenReport,
          frmMain.btnPrintReport, frmMain.btnHelp, frmMain.chkRecursive,
          frmMain.chkDryRunPreview] do CheckCaptionFit(CaptionControl);
        if not ((frmMain.lblSourceCaption.Position.Y < frmMain.SourcePathRow.Position.Y) and
          (frmMain.SourcePathRow.Position.Y + frmMain.SourcePathRow.Height <= frmMain.lblTargetCaption.Position.Y) and
          (frmMain.TargetPathRow.Position.Y + frmMain.TargetPathRow.Height <= frmMain.lblFileTypeCaption.Position.Y)) then
          raise Exception.Create(Code + ': project rows are out of order or overlap');
        if (Code = 'fr-FR') and (WindowWidth = 1600) then
        begin
          Capture := frmMain.RootLayout.MakeScreenshot;
          try Capture.SaveToFile(System.IOUtils.TPath.Combine(ParamStr(2), 'fr-project.png')); finally Capture.Free; end;
        end;
        frmMain.TabControlMain.ActiveTab := frmMain.tabRules;
        Application.ProcessMessages;
        CheckInside(frmMain.RulesCard);
        CheckInside(frmMain.RulesSummaryCard);
        if Abs(frmMain.lblRulesSummaryNote.Position.Y -
          (frmMain.lblRulesSummaryValue.Position.Y + frmMain.lblRulesSummaryValue.Height) - 20) > 2 then
          raise Exception.Create(Code + ': rule summary has an excessive gap');
        if (Code = 'fr-FR') and (WindowWidth = 1600) then
        begin
          Capture := frmMain.RootLayout.MakeScreenshot;
          try Capture.SaveToFile(System.IOUtils.TPath.Combine(ParamStr(2), 'fr-rules.png')); finally Capture.Free; end;
        end;
        Stage := 'component tab and navigation';
        frmMain.ClientWidth := WindowWidth;
        frmMain.TabControlMain.ActiveTab := frmMain.tabComponentMap;
        Application.ProcessMessages;
        for NavigationLabel in [frmMain.lblTabDashboard, frmMain.lblTabProjectScan,
          frmMain.lblTabComponentMap, frmMain.lblTabPropertyMap, frmMain.lblTabEventMap,
          frmMain.lblTabIssues, frmMain.lblTabRules] do
          try
            CheckSummary(NavigationLabel, -1);
          except
            on E: Exception do
            begin
              Writeln('NAVIGATION FAIL: ', E.Message);
              Inc(NavigationFailures);
            end;
          end;
        for Enabled in [False, True] do
        begin
          frmMain.chkCritical.IsChecked := Enabled;
          frmMain.chkDataAware.IsChecked := Enabled;
          frmMain.chkThirdParty.IsChecked := Enabled;
          frmMain.chkWinAPI.IsChecked := Enabled;
          frmMain.chkDryRunPreview.IsChecked := Enabled;
          frmMain.DATLanguageManager.RefreshDynamicText;
          Application.ProcessMessages;
          CheckSummary(frmMain.lblRulesSummaryValue, 5);
          CheckSummary(frmMain.lblDashboardModulesValue, 5);
          CheckSummary(frmMain.lblRulesSummaryNote, 0);
          for RuleCheckBox in [frmMain.chkCritical, frmMain.chkDataAware,
            frmMain.chkThirdParty, frmMain.chkWinAPI, frmMain.chkDryRunPreview] do
            if not frmMain.lblRulesSummaryValue.Text.Contains(RuleCheckBox.Text + ' = ') or
              not frmMain.lblDashboardModulesValue.Text.Contains(RuleCheckBox.Text + ': ') then
              raise Exception.Create(Code + ': summary terminology differs from ' + RuleCheckBox.Name);
          CheckInside(frmMain.RulesCard);
          CheckInside(frmMain.RulesSummaryCard);
          if frmMain.lblRulesSummaryValue.Position.Y + frmMain.lblRulesSummaryValue.Height >
            frmMain.lblRulesSummaryNote.Position.Y then
            raise Exception.Create(Code + ': rule summary overlaps explanatory text');
        end;
        if StringReplace(frmMain.lblHeader.Text, #$00AD, '', [rfReplaceAll]) <> 'VCL to FMX Converter' then
          raise Exception.Create(Code + ': protected product title changed');
        if frmMain.lblHeader.TextSettings.WordWrap then
          raise Exception.Create('Product title must remain on one line');
        if (Code <> 'en-US') and (Pos('Choose a VCL source folder', frmMain.MemoLog.Lines.Text) > 0) then
          raise Exception.Create(Code + ': startup log remains English');
        if Abs(frmMain.ComponentCard.Width - (TControl(frmMain.ComponentCard.Parent).Width - 24)) > 1 then
          raise Exception.CreateFmt('%s: reference card width %.1f, parent %.1f', [Code, frmMain.ComponentCard.Width, TControl(frmMain.ComponentCard.Parent).Width]);
        if frmMain.ComponentMapBrowser.Width < frmMain.ComponentCard.Width - 44 then
          raise Exception.Create(Code + ': reference browser does not fill the card');
        CheckGap(frmMain.ProjectCard, frmMain.ProjectActionCard, 22);
        CheckGap(frmMain.RulesCard, frmMain.RulesSummaryCard, 20);
        CheckGap(frmMain.DashboardStatusCard, frmMain.DashboardModulesCard, 22);
        Stage := 'property tab';
      frmMain.TabControlMain.ActiveTab := frmMain.tabPropertyMap;
      Application.ProcessMessages;
      if Abs(frmMain.PropertyCard.Width - (TControl(frmMain.PropertyCard.Parent).Width - 24)) > 1 then
        raise Exception.Create('Property card does not fill available width');
      if frmMain.PropertyMapBrowser.Width < frmMain.PropertyCard.Width - 44 then
        raise Exception.Create('Property browser does not fill card');
      Stage := 'event tab';
      frmMain.TabControlMain.ActiveTab := frmMain.tabEventMap;
      Application.ProcessMessages;
      if Abs(frmMain.EventCard.Width - (TControl(frmMain.EventCard.Parent).Width - 24)) > 1 then
        raise Exception.Create('Event card does not fill available width');
      if frmMain.EventMapBrowser.Width < frmMain.EventCard.Width - 44 then
        raise Exception.Create('Event browser does not fill card');
      end;
    end;
    if ViewportChecks = 0 then
      raise Exception.Create('No languages were tested; check the language filter');
    if NavigationFailures > 0 then
      raise Exception.CreateFmt('%d navigation fit failures', [NavigationFailures]);
    Writeln('PASS: ', Checks, ' actual FMX card-gap checks across languages and widths.');
    Writeln('PASS: ', TransitionChecks, ' returns to English with restored reading direction.');
    Writeln('PASS: ', ScaleChecks, ' proportional text/box scale checks at 125%, 150% and 200%.');
    Writeln('PASS: ', ViewportChecks, ' Rules viewport/background and final-paragraph scrolling checks.');
    if PageChecks > 0 then Writeln('PASS: ', PageChecks, ' all-page boundary and rendered blue-frame checks.');
    frmMain.Hide;
    Application.ProcessMessages;
    frmMain.Free;
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', Code, ' width ', WindowWidth, ' ', Stage, ': ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
