{VCL2FMX (c) 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Rewrite.Compatibility;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  System.StrUtils,
  Converter.Core.Types;

type
  TCompatibilityInjector = class
  private
    FContext: TConversionContext;
  public
    constructor Create(AContext: TConversionContext);
    procedure InjectClasses(var Code: string);
    procedure InjectLifecycleFixes(var Code: string);
  end;

implementation

constructor TCompatibilityInjector.Create(AContext: TConversionContext);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('Conversion context is not assigned');
  FContext := AContext;
end;

procedure TCompatibilityInjector.InjectClasses(var Code: string);
const
  RadioGroupTypeCode =
    '  TRadioGroup = class(TGroupBox)' + sLineBreak +
    '  private' + sLineBreak +
    '    FItems: TStringList;' + sLineBreak +
    '    FItemIndex: Integer;' + sLineBreak +
    '    FColumns: Integer;' + sLineBreak +
    '    FUpdatingButtons: Integer;' + sLineBreak +
    '    FInternalGroupName: string;' + sLineBreak +
    '    procedure ItemsChanged(Sender: TObject);' + sLineBreak +
    '    procedure SetItems(const Value: TStrings);' + sLineBreak +
    '    procedure SetItemIndex(const Value: Integer);' + sLineBreak +
    '    procedure SetColumns(const Value: Integer);' + sLineBreak +
    '    procedure RebuildButtons;' + sLineBreak +
    '    procedure LayoutButtons;' + sLineBreak +
    '    procedure RadioButtonChanged(Sender: TObject);' + sLineBreak +
    '  protected' + sLineBreak +
    '    procedure Loaded; override;' + sLineBreak +
    '    procedure Resize; override;' + sLineBreak +
    '  public' + sLineBreak +
    '    constructor Create(AOwner: TComponent); override;' + sLineBreak +
    '    destructor Destroy; override;' + sLineBreak +
    '  published' + sLineBreak +
    '    property Items: TStrings read FItems write SetItems;' + sLineBreak +
    '    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;' + sLineBreak +
    '    property Columns: Integer read FColumns write SetColumns default 1;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak;
  RadioGroupImplCode =
    'constructor TRadioGroup.Create(AOwner: TComponent);' + sLineBreak +
    'begin' + sLineBreak +
    '  inherited Create(AOwner);' + sLineBreak +
    '  FItems := TStringList.Create;' + sLineBreak +
    '  FItems.OnChange := ItemsChanged;' + sLineBreak +
    '  FItemIndex := -1;' + sLineBreak +
    '  FColumns := 1;' + sLineBreak +
    '  FInternalGroupName := ''RadioGroup_'' + IntToHex(NativeInt(Self), SizeOf(Pointer) * 2);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'destructor TRadioGroup.Destroy;' + sLineBreak +
    'begin' + sLineBreak +
    '  FItems.Free;' + sLineBreak +
    '  inherited Destroy;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.ItemsChanged(Sender: TObject);' + sLineBreak +
    'begin' + sLineBreak +
    '  if csLoading in ComponentState then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  RebuildButtons;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.SetItems(const Value: TStrings);' + sLineBreak +
    'begin' + sLineBreak +
    '  FItems.Assign(Value);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.SetColumns(const Value: Integer);' + sLineBreak +
    'begin' + sLineBreak +
    '  if Value < 1 then' + sLineBreak +
    '    FColumns := 1' + sLineBreak +
    '  else' + sLineBreak +
    '    FColumns := Value;' + sLineBreak +
    '  LayoutButtons;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.SetItemIndex(const Value: Integer);' + sLineBreak +
    'var' + sLineBreak +
    '  NewValue: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  if FItems.Count = 0 then' + sLineBreak +
    '    NewValue := -1' + sLineBreak +
    '  else if (Value < 0) or (Value >= FItems.Count) then' + sLineBreak +
    '    NewValue := -1' + sLineBreak +
    '  else' + sLineBreak +
    '    NewValue := Value;' + sLineBreak +
    '  if FItemIndex <> NewValue then' + sLineBreak +
    '  begin' + sLineBreak +
    '    FItemIndex := NewValue;' + sLineBreak +
    '    LayoutButtons;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.RebuildButtons;' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    '  Button: TRadioButton;' + sLineBreak +
    'begin' + sLineBreak +
    '  Inc(FUpdatingButtons);' + sLineBreak +
    '  try' + sLineBreak +
    '    for I := ChildrenCount - 1 downto 0 do' + sLineBreak +
    '      if Children[I] is TRadioButton then' + sLineBreak +
    '        Children[I].Free;' + sLineBreak +
    '    if FItems.Count = 0 then' + sLineBreak +
    '      FItemIndex := -1' + sLineBreak +
    '    else if (FItemIndex < 0) or (FItemIndex >= FItems.Count) then' + sLineBreak +
    '      FItemIndex := 0;' + sLineBreak +
    '    for I := 0 to FItems.Count - 1 do' + sLineBreak +
    '    begin' + sLineBreak +
    '      Button := TRadioButton.Create(Self);' + sLineBreak +
    '      Button.Parent := Self;' + sLineBreak +
    '      Button.GroupName := FInternalGroupName;' + sLineBreak +
    '      Button.Text := FItems[I];' + sLineBreak +
    '      Button.OnChange := RadioButtonChanged;' + sLineBreak +
    '      Button.IsChecked := I = FItemIndex;' + sLineBreak +
    '    end;' + sLineBreak +
    '  finally' + sLineBreak +
    '    Dec(FUpdatingButtons);' + sLineBreak +
    '  end;' + sLineBreak +
    '  LayoutButtons;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.LayoutButtons;' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    '  ButtonIndex: Integer;' + sLineBreak +
    '  ColumnCount: Integer;' + sLineBreak +
    '  CellWidth: Single;' + sLineBreak +
    '  TopOffset: Single;' + sLineBreak +
    '  Button: TRadioButton;' + sLineBreak +
    'begin' + sLineBreak +
    '  if FColumns < 1 then' + sLineBreak +
    '    ColumnCount := 1' + sLineBreak +
    '  else' + sLineBreak +
    '    ColumnCount := FColumns;' + sLineBreak +
    '  CellWidth := Width - 16;' + sLineBreak +
    '  if ColumnCount > 0 then' + sLineBreak +
    '    CellWidth := CellWidth / ColumnCount;' + sLineBreak +
    '  if CellWidth < 80 then' + sLineBreak +
    '    CellWidth := 80;' + sLineBreak +
    '  TopOffset := 28;' + sLineBreak +
    '  ButtonIndex := 0;' + sLineBreak +
    '  Inc(FUpdatingButtons);' + sLineBreak +
    '  try' + sLineBreak +
    '    for I := 0 to ChildrenCount - 1 do' + sLineBreak +
    '      if Children[I] is TRadioButton then' + sLineBreak +
    '      begin' + sLineBreak +
    '        Button := TRadioButton(Children[I]);' + sLineBreak +
    '        Button.GroupName := FInternalGroupName;' + sLineBreak +
    '        Button.Position.X := 8 + ((ButtonIndex mod ColumnCount) * CellWidth);' + sLineBreak +
    '        Button.Position.Y := TopOffset + ((ButtonIndex div ColumnCount) * 24);' + sLineBreak +
        '        Button.Width := CellWidth - 8;' + sLineBreak +
    '        Button.Height := 22;' + sLineBreak +
    '        Button.IsChecked := ButtonIndex = FItemIndex;' + sLineBreak +
    '        Inc(ButtonIndex);' + sLineBreak +
    '      end;' + sLineBreak +
    '  finally' + sLineBreak +
    '    Dec(FUpdatingButtons);' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.RadioButtonChanged(Sender: TObject);' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    '  ButtonIndex: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  if FUpdatingButtons > 0 then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if (Sender = nil) or not (Sender is TRadioButton) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if not TRadioButton(Sender).IsChecked then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  ButtonIndex := -1;' + sLineBreak +
    '  for I := 0 to ChildrenCount - 1 do' + sLineBreak +
    '    if Children[I] is TRadioButton then' + sLineBreak +
    '    begin' + sLineBreak +
    '      Inc(ButtonIndex);' + sLineBreak +
    '      if Children[I] = Sender then' + sLineBreak +
    '      begin' + sLineBreak +
    '        if FItemIndex <> ButtonIndex then' + sLineBreak +
    '        begin' + sLineBreak +
    '          FItemIndex := ButtonIndex;' + sLineBreak +
    '          if Assigned(OnClick) then' + sLineBreak +
    '            OnClick(Self);' + sLineBreak +
    '        end;' + sLineBreak +
    '        Break;' + sLineBreak +
    '      end;' + sLineBreak +
    '    end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.Loaded;' + sLineBreak +
    'begin' + sLineBreak +
    '  inherited Loaded;' + sLineBreak +
    '  RebuildButtons;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TRadioGroup.Resize;' + sLineBreak +
    'begin' + sLineBreak +
    '  inherited Resize;' + sLineBreak +
    '  LayoutButtons;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  FontDialogTypeCode =
    '  TFontDialog = class(TFmxObject)' + sLineBreak +
    '  private' + sLineBreak +
    '    FFont: TFont;' + sLineBreak +
    '    procedure SetFont(const Value: TFont);' + sLineBreak +
    '  public' + sLineBreak +
    '    constructor Create(AOwner: TComponent); override;' + sLineBreak +
    '    destructor Destroy; override;' + sLineBreak +
    '    function Execute: Boolean; virtual;' + sLineBreak +
    '  published' + sLineBreak +
    '    property Font: TFont read FFont write SetFont;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak;
  MemoCompatTypeCode =
    '  TMemo = class(FMX.Memo.TMemo)' + sLineBreak +
    '  public' + sLineBreak +
    '    procedure Clear; reintroduce;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak;
  MemoCompatImplCode =
    'procedure TMemo.Clear;' + sLineBreak +
    'begin' + sLineBreak +
    '  Lines.Clear;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  TrackBarCompatTypeCode =
    '  TTrackBar = class(FMX.StdCtrls.TTrackBar)' + sLineBreak +
    '  private' + sLineBreak +
    '    function GetPosition: Integer;' + sLineBreak +
    '    procedure SetPosition(const AValue: Integer);' + sLineBreak +
    '  published' + sLineBreak +
    '    property Position: Integer read GetPosition write SetPosition;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak;
  TrackBarCompatImplCode =
    'function TTrackBar.GetPosition: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := Round(Value);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TTrackBar.SetPosition(const AValue: Integer);' + sLineBreak +
    'begin' + sLineBreak +
    '  Value := AValue;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  ProgressBarCompatTypeCode =
    '  TProgressBar = class(FMX.StdCtrls.TProgressBar)' + sLineBreak +
    '  private' + sLineBreak +
    '    function GetPosition: Integer;' + sLineBreak +
    '    procedure SetPosition(const AValue: Integer);' + sLineBreak +
    '  published' + sLineBreak +
    '    property Position: Integer read GetPosition write SetPosition;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak;
  ProgressBarCompatImplCode =
    'function TProgressBar.GetPosition: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := Round(Value);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TProgressBar.SetPosition(const AValue: Integer);' + sLineBreak +
    'begin' + sLineBreak +
    '  Value := AValue;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  SpinBoxCompatTypeCode =
    '  TSpinBox = class(FMX.SpinBox.TSpinBox)' + sLineBreak +
    '  private' + sLineBreak +
    '    function GetPosition: Integer;' + sLineBreak +
    '    procedure SetPosition(const AValue: Integer);' + sLineBreak +
    '  published' + sLineBreak +
    '    property Position: Integer read GetPosition write SetPosition;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak;
  SpinBoxCompatImplCode =
    'function TSpinBox.GetPosition: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := Round(Value);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TSpinBox.SetPosition(const AValue: Integer);' + sLineBreak +
    'begin' + sLineBreak +
    '  Value := AValue;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  FontDialogImplCode =
    'constructor TFontDialog.Create(AOwner: TComponent);' + sLineBreak +
    'begin' + sLineBreak +
    '  inherited Create(AOwner);' + sLineBreak +
    '  FFont := TFont.Create;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'destructor TFontDialog.Destroy;' + sLineBreak +
    'begin' + sLineBreak +
    '  FFont.Free;' + sLineBreak +
    '  inherited Destroy;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TFontDialog.SetFont(const Value: TFont);' + sLineBreak +
    'begin' + sLineBreak +
    '  FFont.Assign(Value);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function TFontDialog.Execute: Boolean;' + sLineBreak +
    'var' + sLineBreak +
    '  Dlg: TForm;' + sLineBreak +
    '  FamilyLabel: TLabel;' + sLineBreak +
    '  SizeLabel: TLabel;' + sLineBreak +
    '  FamilyBox: TComboBox;' + sLineBreak +
    '  SizeBox: TSpinBox;' + sLineBreak +
    '  BoldBox: TCheckBox;' + sLineBreak +
    '  ItalicBox: TCheckBox;' + sLineBreak +
    '  UnderlineBox: TCheckBox;' + sLineBreak +
    '  OkButton: TButton;' + sLineBreak +
    '  CancelButton: TButton;' + sLineBreak +
    '  FamilyName: string;' + sLineBreak +
    '  NewStyle: TFontStyles;' + sLineBreak +
    '  CurrentSize: Single;' + sLineBreak +
    '  procedure AddFamily(const AName: string);' + sLineBreak +
    '  begin' + sLineBreak +
    '    if Trim(AName) = '''' then' + sLineBreak +
    '      Exit;' + sLineBreak +
    '    if FamilyBox.Items.IndexOf(AName) = -1 then' + sLineBreak +
    '      FamilyBox.Items.Add(AName);' + sLineBreak +
    '  end;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := False;' + sLineBreak +
    '  Dlg := TForm.CreateNew(nil);' + sLineBreak +
    '  try' + sLineBreak +
    '    Dlg.Caption := ''Select Font'';' + sLineBreak +
    '    Dlg.Position := TFormPosition.ScreenCenter;' + sLineBreak +
    '    Dlg.Width := 420;' + sLineBreak +
    '    Dlg.Height := 250;' + sLineBreak +
    '    FamilyLabel := TLabel.Create(Dlg);' + sLineBreak +
    '    FamilyLabel.Parent := Dlg;' + sLineBreak +
    '    FamilyLabel.Position.X := 20;' + sLineBreak +
    '    FamilyLabel.Position.Y := 20;' + sLineBreak +
    '    FamilyLabel.Text := ''Font family:'';' + sLineBreak +
    '    FamilyBox := TComboBox.Create(Dlg);' + sLineBreak +
    '    FamilyBox.Parent := Dlg;' + sLineBreak +
    '    FamilyBox.Position.X := 20;' + sLineBreak +
    '    FamilyBox.Position.Y := 44;' + sLineBreak +
    '    FamilyBox.Width := 260;' + sLineBreak +
    '    SizeLabel := TLabel.Create(Dlg);' + sLineBreak +
    '    SizeLabel.Parent := Dlg;' + sLineBreak +
    '    SizeLabel.Position.X := 300;' + sLineBreak +
    '    SizeLabel.Position.Y := 20;' + sLineBreak +
    '    SizeLabel.Text := ''Size:'';' + sLineBreak +
    '    SizeBox := TSpinBox.Create(Dlg);' + sLineBreak +
    '    SizeBox.Parent := Dlg;' + sLineBreak +
    '    SizeBox.Position.X := 300;' + sLineBreak +
    '    SizeBox.Position.Y := 44;' + sLineBreak +
    '    SizeBox.Width := 80;' + sLineBreak +
    '    SizeBox.Min := 6;' + sLineBreak +
    '    SizeBox.Max := 144;' + sLineBreak +
    '    BoldBox := TCheckBox.Create(Dlg);' + sLineBreak +
    '    BoldBox.Parent := Dlg;' + sLineBreak +
    '    BoldBox.Position.X := 20;' + sLineBreak +
    '    BoldBox.Position.Y := 88;' + sLineBreak +
    '    BoldBox.Text := ''Bold'';' + sLineBreak +
    '    ItalicBox := TCheckBox.Create(Dlg);' + sLineBreak +
    '    ItalicBox.Parent := Dlg;' + sLineBreak +
    '    ItalicBox.Position.X := 120;' + sLineBreak +
    '    ItalicBox.Position.Y := 88;' + sLineBreak +
    '    ItalicBox.Text := ''Italic'';' + sLineBreak +
    '    UnderlineBox := TCheckBox.Create(Dlg);' + sLineBreak +
    '    UnderlineBox.Parent := Dlg;' + sLineBreak +
    '    UnderlineBox.Position.X := 220;' + sLineBreak +
    '    UnderlineBox.Position.Y := 88;' + sLineBreak +
    '    UnderlineBox.Text := ''Underline'';' + sLineBreak +
    '    OkButton := TButton.Create(Dlg);' + sLineBreak +
    '    OkButton.Parent := Dlg;' + sLineBreak +
    '    OkButton.Position.X := 220;' + sLineBreak +
    '    OkButton.Position.Y := 170;' + sLineBreak +
    '    OkButton.Width := 80;' + sLineBreak +
    '    OkButton.Text := ''OK'';' + sLineBreak +
    '    OkButton.ModalResult := mrOk;' + sLineBreak +
    '    CancelButton := TButton.Create(Dlg);' + sLineBreak +
    '    CancelButton.Parent := Dlg;' + sLineBreak +
    '    CancelButton.Position.X := 310;' + sLineBreak +
    '    CancelButton.Position.Y := 170;' + sLineBreak +
    '    CancelButton.Width := 80;' + sLineBreak +
    '    CancelButton.Text := ''Cancel'';' + sLineBreak +
    '    CancelButton.ModalResult := mrCancel;' + sLineBreak +
    '    FamilyName := Trim(FFont.Family);' + sLineBreak +
    '    if FamilyName = '''' then' + sLineBreak +
    '      FamilyName := ''Segoe UI'';' + sLineBreak +
    '    AddFamily(FamilyName);' + sLineBreak +
    '    AddFamily(''Segoe UI'');' + sLineBreak +
    '    AddFamily(''Arial'');' + sLineBreak +
    '    AddFamily(''Tahoma'');' + sLineBreak +
    '    AddFamily(''Calibri'');' + sLineBreak +
    '    AddFamily(''Verdana'');' + sLineBreak +
    '    AddFamily(''Times New Roman'');' + sLineBreak +
    '    AddFamily(''Georgia'');' + sLineBreak +
    '    AddFamily(''Courier New'');' + sLineBreak +
    '    AddFamily(''Consolas'');' + sLineBreak +
    '    FamilyBox.ItemIndex := FamilyBox.Items.IndexOf(FamilyName);' + sLineBreak +
    '    if (FamilyBox.ItemIndex = -1) and (FamilyBox.Items.Count > 0) then' + sLineBreak +
    '      FamilyBox.ItemIndex := 0;' + sLineBreak +
    '    CurrentSize := FFont.Size;' + sLineBreak +
    '    if CurrentSize <= 0 then' + sLineBreak +
    '      CurrentSize := 12;' + sLineBreak +
    '    SizeBox.Value := CurrentSize;' + sLineBreak +
    '    BoldBox.IsChecked := TFontStyle.fsBold in FFont.Style;' + sLineBreak +
    '    ItalicBox.IsChecked := TFontStyle.fsItalic in FFont.Style;' + sLineBreak +
    '    UnderlineBox.IsChecked := TFontStyle.fsUnderline in FFont.Style;' + sLineBreak +
    '    Result := Dlg.ShowModal = mrOk;' + sLineBreak +
    '    if Result then' + sLineBreak +
    '    begin' + sLineBreak +
    '      if (FamilyBox.ItemIndex >= 0) and' + sLineBreak +
    '         (Trim(FamilyBox.Items[FamilyBox.ItemIndex]) <> '''') then' + sLineBreak +
    '        FFont.Family := FamilyBox.Items[FamilyBox.ItemIndex];' + sLineBreak +
    '      FFont.Size := SizeBox.Value;' + sLineBreak +
    '      NewStyle := [];' + sLineBreak +
    '      if BoldBox.IsChecked then' + sLineBreak +
    '        Include(NewStyle, TFontStyle.fsBold);' + sLineBreak +
    '      if ItalicBox.IsChecked then' + sLineBreak +
    '        Include(NewStyle, TFontStyle.fsItalic);' + sLineBreak +
    '      if UnderlineBox.IsChecked then' + sLineBreak +
    '        Include(NewStyle, TFontStyle.fsUnderline);' + sLineBreak +
    '      FFont.Style := NewStyle;' + sLineBreak +
    '    end;' + sLineBreak +
    '  finally' + sLineBreak +
    '    Dlg.Free;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  ColorDialogTypeCode =
    '  TColorDialog = class(TComponent)' + sLineBreak +
    '  private' + sLineBreak +
    '    FColor: TAlphaColor;' + sLineBreak +
    '  public' + sLineBreak +
    '    constructor Create(AOwner: TComponent); override;' + sLineBreak +
    '    function Execute: Boolean; virtual;' + sLineBreak +
    '  published' + sLineBreak +
    '    property Color: TAlphaColor read FColor write FColor;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak;
  ColorDialogImplCode =
    'constructor TColorDialog.Create(AOwner: TComponent);' + sLineBreak +
    'begin' + sLineBreak +
    '  inherited Create(AOwner);' + sLineBreak +
    '  FColor := claWhite;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function TColorDialog.Execute: Boolean;' + sLineBreak +
    'var' + sLineBreak +
    '  Dlg: TForm;' + sLineBreak +
    '  PromptLabel: TLabel;' + sLineBreak +
    '  ColorBox: TColorListBox;' + sLineBreak +
    '  OkButton: TButton;' + sLineBreak +
    '  CancelButton: TButton;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := False;' + sLineBreak +
    '  Dlg := TForm.CreateNew(nil);' + sLineBreak +
    '  try' + sLineBreak +
    '    Dlg.Width := 360;' + sLineBreak +
    '    Dlg.Height := 360;' + sLineBreak +
    '    Dlg.Position := TFormPosition.ScreenCenter;' + sLineBreak +
    '    Dlg.Caption := ''Select Color'';' + sLineBreak +
    '    PromptLabel := TLabel.Create(Dlg);' + sLineBreak +
    '    PromptLabel.Parent := Dlg;' + sLineBreak +
    '    PromptLabel.Text := ''Color:'';' + sLineBreak +
    '    PromptLabel.Position.X := 16;' + sLineBreak +
    '    PromptLabel.Position.Y := 20;' + sLineBreak +
    '    ColorBox := TColorListBox.Create(Dlg);' + sLineBreak +
    '    ColorBox.Parent := Dlg;' + sLineBreak +
    '    ColorBox.Position.X := 16;' + sLineBreak +
    '    ColorBox.Position.Y := 44;' + sLineBreak +
    '    ColorBox.Width := 320;' + sLineBreak +
    '    ColorBox.Height := 240;' + sLineBreak +
    '    ColorBox.Color := FColor;' + sLineBreak +
    '    OkButton := TButton.Create(Dlg);' + sLineBreak +
    '    OkButton.Parent := Dlg;' + sLineBreak +
    '    OkButton.Text := ''OK'';' + sLineBreak +
    '    OkButton.Position.X := 168;' + sLineBreak +
    '    OkButton.Position.Y := 300;' + sLineBreak +
    '    OkButton.ModalResult := mrOk;' + sLineBreak +
    '    CancelButton := TButton.Create(Dlg);' + sLineBreak +
    '    CancelButton.Parent := Dlg;' + sLineBreak +
    '    CancelButton.Text := ''Cancel'';' + sLineBreak +
    '    CancelButton.Position.X := 252;' + sLineBreak +
    '    CancelButton.Position.Y := 300;' + sLineBreak +
    '    CancelButton.ModalResult := mrCancel;' + sLineBreak +
    '    Result := Dlg.ShowModal = mrOk;' + sLineBreak +
    '    if Result then' + sLineBreak +
    '      FColor := ColorBox.Color;' + sLineBreak +
    '  finally' + sLineBreak +
    '    Dlg.Free;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  BlockLines: TStringList;
  NeedRadioGroup: Boolean;
  NeedFontDialog: Boolean;
  NeedColorDialog: Boolean;
  NeedMemoCompat: Boolean;
  NeedTrackBarCompat: Boolean;
  NeedProgressBarCompat: Boolean;
  NeedSpinBoxCompat: Boolean;
  TypeInsertIdx: Integer;
  ResourceInsertIdx: Integer;
  I: Integer;
  DialogFieldMap: TStringList;
  OriginalCode: string;
  AnalysisCode: string;

  procedure InsertBlock(const AIndex: Integer; const ABlock: string);
  var
    J: Integer;
  begin
    BlockLines.Text := ABlock;
    for J := BlockLines.Count - 1 downto 0 do
      Lines.Insert(AIndex, BlockLines[J]);
  end;

  procedure MoveGeneratedDialogFieldsToPrivate;
  var
    J: Integer;
    ClassIdx: Integer;
    PrivateIdx: Integer;
    FirstVisibilityIdx: Integer;
    EndClassIdx: Integer;
    InsertIdx: Integer;
    TrimmedLine: string;
    Match: TMatch;
    DialogFieldLines: TStringList;
    FieldName: string;
    FieldType: string;
  begin
    DialogFieldLines := TStringList.Create;
    try
      ClassIdx := -1;
      PrivateIdx := -1;
      FirstVisibilityIdx := -1;
      EndClassIdx := -1;
      J := 0;
      while J < Lines.Count do
      begin
        TrimmedLine := Trim(Lines[J]);
        if TRegEx.IsMatch(TrimmedLine,
          '^[A-Za-z_][A-Za-z0-9_]*\s*=\s*class\s*\(', [roIgnoreCase]) then
        begin
          ClassIdx := J;
          Inc(J);
          Continue;
        end;

        if ClassIdx = -1 then
        begin
          Inc(J);
          Continue;
        end;

        if (PrivateIdx = -1) and
           (SameText(TrimmedLine, 'private') or SameText(TrimmedLine, 'strict private')) then
          PrivateIdx := J;

        if (FirstVisibilityIdx = -1) and
           (SameText(TrimmedLine, 'protected') or
            SameText(TrimmedLine, 'strict protected') or
            SameText(TrimmedLine, 'public') or
            SameText(TrimmedLine, 'published')) then
          FirstVisibilityIdx := J;

        Match := TRegEx.Match(Lines[J],
          '^(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(TFontDialog|TColorDialog)\s*;\s*$',
          [roIgnoreCase]);
        if Match.Success then
        begin
          FieldName := Match.Groups[2].Value;
          FieldType := Match.Groups[3].Value;
          if DialogFieldLines.IndexOf('    ' + FieldName + ': ' + FieldType + ';') = -1 then
            DialogFieldLines.Add('    ' + FieldName + ': ' + FieldType + ';');
          if DialogFieldMap.IndexOfName(FieldName) = -1 then
            DialogFieldMap.Values[FieldName] := FieldType;
          Lines.Delete(J);
          Continue;
        end;

        if SameText(TrimmedLine, 'end;') then
        begin
          EndClassIdx := J;
          Break;
        end;

        Inc(J);
      end;

      if DialogFieldLines.Count = 0 then
        Exit;

      if PrivateIdx <> -1 then
        InsertIdx := PrivateIdx + 1
      else if FirstVisibilityIdx <> -1 then
      begin
        Lines.Insert(FirstVisibilityIdx, '  private');
        InsertIdx := FirstVisibilityIdx + 1;
      end
      else if EndClassIdx <> -1 then
      begin
        Lines.Insert(EndClassIdx, '  private');
        InsertIdx := EndClassIdx + 1;
      end
      else
        Exit;

      for J := DialogFieldLines.Count - 1 downto 0 do
        Lines.Insert(InsertIdx, DialogFieldLines[J]);
    finally
      DialogFieldLines.Free;
    end;
  end;

  procedure EnsureGeneratedDialogsCreatedInFormCreate;
  var
    J: Integer;
    BeginIdx: Integer;
    FieldName: string;
  begin
    BeginIdx := -1;
    J := 0;
    while J < Lines.Count do
    begin
      if TRegEx.IsMatch(TrimLeft(Lines[J]),
        '^procedure\s+[A-Za-z0-9_\.]+\.FormCreate\s*\(', [roIgnoreCase]) then
      begin
        Inc(J);
        while J < Lines.Count do
        begin
          if SameText(Trim(Lines[J]), 'begin') then
          begin
            BeginIdx := J;
            Break;
          end;
          Inc(J);
        end;
        Break;
      end;
      Inc(J);
    end;

    if BeginIdx = -1 then
      Exit;

    for J := 0 to DialogFieldMap.Count - 1 do
    begin
      FieldName := DialogFieldMap.Names[J];
      if (FieldName = '') or ContainsText(Lines.Text, FieldName + ' := ' +
         DialogFieldMap.ValueFromIndex[J] + '.Create(Self);') then
        Continue;
      Lines.Insert(BeginIdx + 1, '  if not Assigned(' + FieldName + ') then');
      Lines.Insert(BeginIdx + 2, '    ' + FieldName + ' := ' +
        DialogFieldMap.ValueFromIndex[J] + '.Create(Self);');
      Inc(BeginIdx, 2);
    end;
  end;

  function FindTypeInsertIdx: Integer;
  var
    J: Integer;
  begin
    Result := -1;
    for J := 0 to AnalysisLines.Count - 1 do
    begin
      if SameText(Trim(AnalysisLines[J]), 'implementation') then
        Break;
      if SameText(Trim(AnalysisLines[J]), 'type') then
      begin
        Result := J + 1;
        Exit;
      end;
    end;
  end;

  function FindResourceInsertIdx: Integer;
  var
    J: Integer;
    ImplIdx: Integer;
    UsesIdx: Integer;
    CandidateIdx: Integer;

    function IsImplementationBoundary(const ALine: string): Boolean;
    var
      S: string;
    begin
      S := Trim(ALine);
      Result := StartsText('procedure ', S) or
                StartsText('function ', S) or
                StartsText('constructor ', S) or
                StartsText('destructor ', S) or
                SameText(S, 'initialization') or
                SameText(S, 'finalization') or
                SameText(S, 'end.');
    end;

    function AdvancePastDeclarationBlocks(AIndex: Integer): Integer;
    var
      K: Integer;
      S: string;
      TypeDepth: Integer;

      function IsDeclarationSection(const ALine: string): Boolean;
      begin
        Result := SameText(ALine, 'const') or SameText(ALine, 'var') or
                  SameText(ALine, 'type') or SameText(ALine, 'resourcestring');
      end;
    begin
      Result := AIndex;
      K := AIndex;
      while K < AnalysisLines.Count do
      begin
        S := Trim(AnalysisLines[K]);
        if (S = '') or StartsText('{$', S) then
        begin
          Inc(K);
          Result := K;
          Continue;
        end;

        if SameText(S, 'const') or SameText(S, 'var') or
           SameText(S, 'resourcestring') then
        begin
          Inc(K);
          while K < AnalysisLines.Count do
          begin
            S := Trim(AnalysisLines[K]);
            if (S = '') or StartsText('{$', S) then
            begin
              Inc(K);
              Continue;
            end;
            if IsDeclarationSection(S) then
              Break;
            if IsImplementationBoundary(S) then
            begin
              Result := K;
              Exit;
            end;
            Inc(K);
          end;
          Result := K;
          Continue;
        end;

        if SameText(S, 'type') then
        begin
          TypeDepth := 0;
          Inc(K);
          while K < AnalysisLines.Count do
          begin
            S := Trim(AnalysisLines[K]);
            if (S = '') or StartsText('{$', S) then
            begin
              Inc(K);
              Continue;
            end;
            if (TypeDepth = 0) and IsDeclarationSection(S) then
              Break;
            if (TypeDepth = 0) and IsImplementationBoundary(S) then
            begin
              Result := K;
              Exit;
            end;
            if TRegEx.IsMatch(S, '=\s*(class|record|object|interface)\b',
                 [roIgnoreCase]) then
              Inc(TypeDepth);
            if (TypeDepth > 0) and
               TRegEx.IsMatch(S, '^end\s*;', [roIgnoreCase]) then
              Dec(TypeDepth);
            Inc(K);
          end;
          Result := K;
          Continue;
        end;

        Result := K;
        Exit;
      end;
    end;
  begin
    Result := -1;
    ImplIdx := -1;
    for J := 0 to AnalysisLines.Count - 1 do
      if SameText(Trim(AnalysisLines[J]), 'implementation') then
      begin
        ImplIdx := J;
        Break;
      end;

    if ImplIdx = -1 then
      Exit;

    CandidateIdx := ImplIdx + 1;
    UsesIdx := -1;
    for J := ImplIdx + 1 to AnalysisLines.Count - 1 do
    begin
      if Trim(AnalysisLines[J]) = '' then
        Continue;
      if SameText(Trim(AnalysisLines[J]), 'uses') or
         StartsText('uses ', TrimLeft(AnalysisLines[J])) then
      begin
        UsesIdx := J;
        Break;
      end;
      Break;
    end;

    if UsesIdx <> -1 then
    begin
      J := UsesIdx;
      while J < AnalysisLines.Count do
      begin
        if Pos(';', AnalysisLines[J]) > 0 then
        begin
          CandidateIdx := J + 1;
          Break;
        end;
        Inc(J);
      end;
    end;

    for J := CandidateIdx to Lines.Count - 1 do
    begin
      if TRegEx.IsMatch(Trim(Lines[J]), '^\{\$R\s+\*\.(?:dfm|fmx)\}$', [roIgnoreCase]) then
        Exit(AdvancePastDeclarationBlocks(J + 1));
      if SameText(Trim(AnalysisLines[J]), 'initialization') or
         SameText(Trim(AnalysisLines[J]), 'finalization') or
         SameText(Trim(AnalysisLines[J]), 'end.') then
        Break;
    end;

    Result := AdvancePastDeclarationBlocks(CandidateIdx);
  end;
begin
  Assert(Assigned(FContext));

  OriginalCode := Code;
  AnalysisCode := VCL2FMXStripCommentsForAnalysis(Code);
  NeedRadioGroup := ContainsText(AnalysisCode, 'TRadioGroup');
  NeedFontDialog := ContainsText(AnalysisCode, 'TFontDialog');
  NeedColorDialog := ContainsText(AnalysisCode, 'TColorDialog');
  NeedMemoCompat := ContainsText(AnalysisCode, 'TMemo') and
    not ContainsText(AnalysisCode, 'FMX.Memo');
  NeedTrackBarCompat := ContainsText(AnalysisCode, 'TTrackBar') and
    not ContainsText(AnalysisCode, 'FMX.StdCtrls') and
    not ContainsText(AnalysisCode, 'TTrackBar = class(FMX.StdCtrls.TTrackBar)') and
    not TRegEx.IsMatch(AnalysisCode, '\buses\b[^;]*\bAudioManager\b', [roIgnoreCase, roSingleLine]);
  NeedProgressBarCompat := ContainsText(AnalysisCode, 'TProgressBar') and
    not ContainsText(AnalysisCode, 'FMX.StdCtrls') and
    not ContainsText(AnalysisCode, 'TProgressBar = class(FMX.StdCtrls.TProgressBar)') and
    not TRegEx.IsMatch(AnalysisCode, '\buses\b[^;]*\bAudioManager\b', [roIgnoreCase, roSingleLine]);
  NeedSpinBoxCompat := (ContainsText(AnalysisCode, 'TSpinEdit') or
    ContainsText(AnalysisCode, 'TUpDown')) and
    not ContainsText(AnalysisCode, 'FMX.SpinBox') and
    not ContainsText(AnalysisCode, 'TSpinBox = class(FMX.SpinBox.TSpinBox)');
  if not NeedRadioGroup and not NeedFontDialog and not NeedColorDialog and
     not NeedMemoCompat and not NeedTrackBarCompat and
     not NeedProgressBarCompat and not NeedSpinBoxCompat then
  begin
    // Even when no wrapper injection is needed, files that import a unit which
    // provides a TTrackBar/TProgressBar/TSpinBox compat wrapper must have their
    // bare type references rewritten to the fully-qualified base type. Otherwise
    // field declarations like 'TrackBar1: TTrackBar' resolve to the imported
    // wrapper type and cause E2010 incompatible type errors at the call site.
    if ContainsText(AnalysisCode, 'TTrackBar') and
       TRegEx.IsMatch(AnalysisCode, '\buses\b[^;]*\bAudioManager\b', [roIgnoreCase, roSingleLine]) then
    begin
      Code := TRegEx.Replace(Code,
        '(:\s*)TTrackBar(\s*[;,\)\s])',
        '$1FMX.StdCtrls.TTrackBar$2',
        [roIgnoreCase, roMultiLine]);
    end;
    Exit;
  end;

  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  BlockLines := TStringList.Create;
  DialogFieldMap := TStringList.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);
    MoveGeneratedDialogFieldsToPrivate;

    TypeInsertIdx := FindTypeInsertIdx;
    if TypeInsertIdx <> -1 then
    begin
      if NeedMemoCompat and not ContainsText(AnalysisCode, 'TMemo = class(FMX.Memo.TMemo)') then
        InsertBlock(TypeInsertIdx, MemoCompatTypeCode);
      if NeedTrackBarCompat and not ContainsText(AnalysisCode, 'TTrackBar = class(FMX.StdCtrls.TTrackBar)') then
        InsertBlock(TypeInsertIdx, TrackBarCompatTypeCode);
      if NeedProgressBarCompat and not ContainsText(AnalysisCode, 'TProgressBar = class(FMX.StdCtrls.TProgressBar)') then
        InsertBlock(TypeInsertIdx, ProgressBarCompatTypeCode);
      if NeedSpinBoxCompat and not ContainsText(AnalysisCode, 'TSpinBox = class(FMX.SpinBox.TSpinBox)') then
        InsertBlock(TypeInsertIdx, SpinBoxCompatTypeCode);
      if NeedRadioGroup and not ContainsText(AnalysisCode, 'TRadioGroup = class(') then
        InsertBlock(TypeInsertIdx, RadioGroupTypeCode);
      if NeedFontDialog and not ContainsText(AnalysisCode, 'TFontDialog = class(') then
        InsertBlock(TypeInsertIdx, FontDialogTypeCode);
      if NeedColorDialog and not ContainsText(AnalysisCode, 'TColorDialog = class(') then
        InsertBlock(TypeInsertIdx, ColorDialogTypeCode);
    end;

    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Lines.Text);
    ResourceInsertIdx := FindResourceInsertIdx;
    if ResourceInsertIdx <> -1 then
    begin
      if NeedMemoCompat and not ContainsText(AnalysisCode, 'procedure TMemo.Clear;') then
        InsertBlock(ResourceInsertIdx, MemoCompatImplCode);
      if NeedTrackBarCompat and not ContainsText(AnalysisCode, 'function TTrackBar.GetPosition') then
        InsertBlock(ResourceInsertIdx, TrackBarCompatImplCode);
      if NeedProgressBarCompat and not ContainsText(AnalysisCode, 'function TProgressBar.GetPosition') then
        InsertBlock(ResourceInsertIdx, ProgressBarCompatImplCode);
      if NeedSpinBoxCompat and not ContainsText(AnalysisCode, 'function TSpinBox.GetPosition') then
        InsertBlock(ResourceInsertIdx, SpinBoxCompatImplCode);
      if NeedRadioGroup and not ContainsText(AnalysisCode, 'constructor TRadioGroup.Create') then
        InsertBlock(ResourceInsertIdx, RadioGroupImplCode);
      if NeedFontDialog and not ContainsText(AnalysisCode, 'constructor TFontDialog.Create') then
        InsertBlock(ResourceInsertIdx, FontDialogImplCode);
      if NeedColorDialog and not ContainsText(AnalysisCode, 'constructor TColorDialog.Create') then
        InsertBlock(ResourceInsertIdx, ColorDialogImplCode);
    end;

    EnsureGeneratedDialogsCreatedInFormCreate;

    // RegisterFmxClasses is intentionally NOT injected for compat wrapper classes
    // (TMemo, TTrackBar, TProgressBar, TSpinBox, TRadioGroup). These wrappers are
    // Pascal-only shims for property compatibility and are never stored in .fmx
    // DFM stream files. Injecting RegisterFmxClasses causes runtime error 217 at
    // startup when multiple units each register the same class name.

    // Rewrite public constructor/method parameters that use the local compat wrapper
    // types to use the fully-qualified base types. This prevents cross-unit type
    // incompatibility when another unit passes a base-typed value to these methods.
    // Covers: implementation headers, interface declarations, and field declarations.
    if NeedTrackBarCompat then
    begin
      for I := 0 to Lines.Count - 1 do
      begin
        if ContainsText(Lines[I], 'TTrackBar') and
           not ContainsText(Lines[I], 'TTrackBar = class') then
          Lines[I] := TRegEx.Replace(Lines[I],
            '(:\s*)TTrackBar(\s*[;,\)\s])',
            '$1FMX.StdCtrls.TTrackBar$2',
            [roIgnoreCase]);
      end;
    end;
    if NeedProgressBarCompat then
    begin
      for I := 0 to Lines.Count - 1 do
      begin
        if ContainsText(Lines[I], 'TProgressBar') and
           not ContainsText(Lines[I], 'TProgressBar = class') then
          Lines[I] := TRegEx.Replace(Lines[I],
            '(:\s*)TProgressBar(\s*[;,\)\s])',
            '$1FMX.StdCtrls.TProgressBar$2',
            [roIgnoreCase]);
      end;
    end;
    if NeedSpinBoxCompat then
    begin
      for I := 0 to Lines.Count - 1 do
      begin
        if ContainsText(Lines[I], 'TSpinBox') and
           not ContainsText(Lines[I], 'TSpinBox = class') then
          Lines[I] := TRegEx.Replace(Lines[I],
            '(:\s*)TSpinBox(\s*[;,\)\s])',
            '$1FMX.SpinBox.TSpinBox$2',
            [roIgnoreCase]);
      end;
    end;

    Code := Lines.Text;
  finally
    DialogFieldMap.Free;
    BlockLines.Free;
    AnalysisLines.Free;
    Lines.Free;
  end;

  if Code <> OriginalCode then
  begin
    if NeedMemoCompat then
      FContext.AddIssue(csInfo, 'Injected TMemo compatibility helper.');
    if NeedTrackBarCompat then
      FContext.AddIssue(csInfo, 'Injected TTrackBar compatibility helper.');
    if NeedProgressBarCompat then
      FContext.AddIssue(csInfo, 'Injected TProgressBar compatibility helper.');
    if NeedSpinBoxCompat then
      FContext.AddIssue(csInfo, 'Injected TSpinBox compatibility helper.');
    if NeedRadioGroup then
      FContext.AddIssue(csInfo, 'Injected TRadioGroup compatibility helper.');
    if NeedFontDialog then
      FContext.AddIssue(csInfo, 'Injected TFontDialog compatibility helper.');
    if NeedColorDialog then
      FContext.AddIssue(csInfo, 'Injected TColorDialog compatibility helper.');
  end;
end;

procedure TCompatibilityInjector.InjectLifecycleFixes(var Code: string);
const
  FillAndStrokeEllipseHelperCode =
    'procedure FillAndStrokeEllipse(ACanvas: TCanvas; const R: TRectF);' + sLineBreak +
    'begin' + sLineBreak +
    '  ACanvas.FillEllipse(R, 1);' + sLineBreak +
    '  ACanvas.DrawEllipse(R, 1);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  CanvasCompatHelperCode =
    'var' + sLineBreak +
    '  GeneratedCanvasCurrentPointCanvas: TCanvas;' + sLineBreak +
    '  GeneratedCanvasCurrentPoint: TPointF;' + sLineBreak +
    '  GeneratedCapturedGradientCanvas: TCanvas;' + sLineBreak +
    '  GeneratedCapturedGradientRect: TRectF;' + sLineBreak +
    '  GeneratedCapturedGradientTopY: Single;' + sLineBreak +
    '  GeneratedCapturedGradientBottomY: Single;' + sLineBreak +
    '  GeneratedCapturedGradientTopColor: TAlphaColor;' + sLineBreak +
    '  GeneratedCapturedGradientBottomColor: TAlphaColor;' + sLineBreak +
    '  GeneratedCapturedGradientValid: Boolean;' + sLineBreak +
    '  GeneratedLastFillCanvas: TCanvas;' + sLineBreak +
    '  GeneratedLastFillRect: TRectF;' + sLineBreak +
    '  GeneratedLastFillColor: TAlphaColor;' + sLineBreak +
    '  GeneratedLastFillValid: Boolean;' + sLineBreak + sLineBreak +
    'function GeneratedClientRect(const AObject: TObject): TRect;' + sLineBreak +
    'begin' + sLineBreak +
    '  if AObject is TControl then' + sLineBreak +
    '    Result := Rect(0, 0, Round(TControl(AObject).Width), Round(TControl(AObject).Height))' + sLineBreak +
    '  else if AObject is TCommonCustomForm then' + sLineBreak +
    '    Result := Rect(0, 0, Round(TCommonCustomForm(AObject).ClientWidth), Round(TCommonCustomForm(AObject).ClientHeight))' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := Rect(0, 0, 0, 0);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedRectF(const R: TRect): TRectF;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := TRectF.Create(R.Left, R.Top, R.Right, R.Bottom);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedCanvasFillRect(ACanvas: TCanvas; const R: TRect);' + sLineBreak +
    'var' + sLineBreak +
    '  RF: TRectF;' + sLineBreak +
    'begin' + sLineBreak +
    '  RF := GeneratedRectF(R);' + sLineBreak +
    '  GeneratedLastFillCanvas := ACanvas;' + sLineBreak +
    '  GeneratedLastFillRect := RF;' + sLineBreak +
    '  GeneratedLastFillColor := ACanvas.Fill.Color;' + sLineBreak +
    '  GeneratedLastFillValid := True;' + sLineBreak +
    '  ACanvas.Fill.Kind := TBrushKind.Solid;' + sLineBreak +
    '  ACanvas.FillRect(RF, 0, 0, AllCorners, 1);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedCanvasMoveTo(ACanvas: TCanvas; const X, Y: Single);' + sLineBreak +
    'begin' + sLineBreak +
    '  GeneratedCanvasCurrentPointCanvas := ACanvas;' + sLineBreak +
    '  GeneratedCanvasCurrentPoint := PointF(X, Y);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedCanvasLineTo(ACanvas: TCanvas; const X, Y: Single);' + sLineBreak +
    'var' + sLineBreak +
    '  P1: TPointF;' + sLineBreak +
    '  L: Single;' + sLineBreak +
    '  R: Single;' + sLineBreak +
    'begin' + sLineBreak +
    '  if GeneratedCanvasCurrentPointCanvas = ACanvas then' + sLineBreak +
    '    P1 := GeneratedCanvasCurrentPoint' + sLineBreak +
    '  else' + sLineBreak +
    '    P1 := PointF(X, Y);' + sLineBreak +
    '  ACanvas.Stroke.Kind := TBrushKind.Solid;' + sLineBreak +
    '  ACanvas.DrawLine(P1, PointF(X, Y), 1);' + sLineBreak +
    '  if Abs(P1.Y - Y) <= 0.5 then' + sLineBreak +
    '  begin' + sLineBreak +
    '    if P1.X <= X then' + sLineBreak +
    '    begin' + sLineBreak +
    '      L := P1.X;' + sLineBreak +
    '      R := X;' + sLineBreak +
    '    end' + sLineBreak +
    '    else' + sLineBreak +
    '    begin' + sLineBreak +
    '      L := X;' + sLineBreak +
    '      R := P1.X;' + sLineBreak +
    '    end;' + sLineBreak +
    '    if (not GeneratedCapturedGradientValid) or (GeneratedCapturedGradientCanvas <> ACanvas) then' + sLineBreak +
    '    begin' + sLineBreak +
    '      GeneratedCapturedGradientCanvas := ACanvas;' + sLineBreak +
    '      GeneratedCapturedGradientRect := TRectF.Create(L, Y, R, Y);' + sLineBreak +
    '      GeneratedCapturedGradientTopY := Y;' + sLineBreak +
    '      GeneratedCapturedGradientBottomY := Y;' + sLineBreak +
    '      GeneratedCapturedGradientTopColor := ACanvas.Stroke.Color;' + sLineBreak +
    '      GeneratedCapturedGradientBottomColor := ACanvas.Stroke.Color;' + sLineBreak +
    '      GeneratedCapturedGradientValid := True;' + sLineBreak +
    '    end' + sLineBreak +
    '    else' + sLineBreak +
    '    begin' + sLineBreak +
    '      if L < GeneratedCapturedGradientRect.Left then' + sLineBreak +
    '        GeneratedCapturedGradientRect.Left := L;' + sLineBreak +
    '      if R > GeneratedCapturedGradientRect.Right then' + sLineBreak +
    '        GeneratedCapturedGradientRect.Right := R;' + sLineBreak +
    '      if Y < GeneratedCapturedGradientTopY then' + sLineBreak +
    '      begin' + sLineBreak +
    '        GeneratedCapturedGradientTopY := Y;' + sLineBreak +
    '        GeneratedCapturedGradientTopColor := ACanvas.Stroke.Color;' + sLineBreak +
    '      end;' + sLineBreak +
    '      if Y > GeneratedCapturedGradientBottomY then' + sLineBreak +
    '      begin' + sLineBreak +
    '        GeneratedCapturedGradientBottomY := Y;' + sLineBreak +
    '        GeneratedCapturedGradientBottomColor := ACanvas.Stroke.Color;' + sLineBreak +
    '      end;' + sLineBreak +
    '      if Y < GeneratedCapturedGradientRect.Top then' + sLineBreak +
    '        GeneratedCapturedGradientRect.Top := Y;' + sLineBreak +
    '      if Y > GeneratedCapturedGradientRect.Bottom then' + sLineBreak +
    '        GeneratedCapturedGradientRect.Bottom := Y;' + sLineBreak +
    '    end;' + sLineBreak +
    '  end;' + sLineBreak +
    '  GeneratedCanvasCurrentPointCanvas := ACanvas;' + sLineBreak +
    '  GeneratedCanvasCurrentPoint := PointF(X, Y);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedCanvasRoundRect(ACanvas: TCanvas; const Left, Top, Right, Bottom, RadiusX, RadiusY: Single);' + sLineBreak +
    'var' + sLineBreak +
    '  RoundRectF: TRectF;' + sLineBreak +
    '  OriginalFillKind: TBrushKind;' + sLineBreak +
    '  OriginalFillColor: TAlphaColor;' + sLineBreak +
    'begin' + sLineBreak +
    '  RoundRectF := TRectF.Create(Left, Top, Right, Bottom);' + sLineBreak +
    '  OriginalFillKind := ACanvas.Fill.Kind;' + sLineBreak +
    '  OriginalFillColor := ACanvas.Fill.Color;' + sLineBreak +
    '  if GeneratedLastFillValid and (GeneratedLastFillCanvas = ACanvas) and' + sLineBreak +
    '     (Abs(GeneratedLastFillRect.Left - (Left - 1)) <= 2) and' + sLineBreak +
    '     (Abs(GeneratedLastFillRect.Top - (Top - 1)) <= 2) and' + sLineBreak +
    '     (Abs(GeneratedLastFillRect.Right - (Right + 1)) <= 2) and' + sLineBreak +
    '     (Abs(GeneratedLastFillRect.Bottom - (Bottom + 1)) <= 2) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    ACanvas.Fill.Kind := TBrushKind.Solid;' + sLineBreak +
    '    ACanvas.Fill.Color := GeneratedLastFillColor;' + sLineBreak +
    '    ACanvas.FillRect(GeneratedLastFillRect, 0, 0, AllCorners, 1);' + sLineBreak +
    '    ACanvas.Fill.Kind := OriginalFillKind;' + sLineBreak +
    '    ACanvas.Fill.Color := OriginalFillColor;' + sLineBreak +
    '  end;' + sLineBreak +
    '  if (OriginalFillKind = TBrushKind.None) and GeneratedCapturedGradientValid and' + sLineBreak +
    '     (GeneratedCapturedGradientCanvas = ACanvas) and' + sLineBreak +
    '     (Abs(GeneratedCapturedGradientRect.Left - (Left - 1)) <= 2) and' + sLineBreak +
    '     (Abs(GeneratedCapturedGradientRect.Top - (Top - 1)) <= 2) and' + sLineBreak +
    '     (Abs(GeneratedCapturedGradientRect.Right - (Right + 1)) <= 2) and' + sLineBreak +
    '     (Abs(GeneratedCapturedGradientRect.Bottom - (Bottom + 1)) <= 2) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    ACanvas.Fill.Kind := TBrushKind.Gradient;' + sLineBreak +
    '    ACanvas.Fill.Gradient.Style := TGradientStyle.Linear;' + sLineBreak +
    '    ACanvas.Fill.Gradient.Points[0].Color := GeneratedCapturedGradientTopColor;' + sLineBreak +
    '    ACanvas.Fill.Gradient.Points[0].Offset := 0;' + sLineBreak +
    '    ACanvas.Fill.Gradient.Points[1].Color := GeneratedCapturedGradientBottomColor;' + sLineBreak +
    '    ACanvas.Fill.Gradient.Points[1].Offset := 1;' + sLineBreak +
    '    ACanvas.Fill.Gradient.StartPosition.Point := PointF(0, 0);' + sLineBreak +
    '    ACanvas.Fill.Gradient.StopPosition.Point := PointF(0, 1);' + sLineBreak +
    '    ACanvas.FillRect(RoundRectF, RadiusX, RadiusY, AllCorners, 1);' + sLineBreak +
    '    ACanvas.Fill.Kind := OriginalFillKind;' + sLineBreak +
    '    ACanvas.Fill.Color := OriginalFillColor;' + sLineBreak +
    '    GeneratedCapturedGradientValid := False;' + sLineBreak +
    '  end;' + sLineBreak +
    '  if (OriginalFillKind <> TBrushKind.None) and not GeneratedCapturedGradientValid then' + sLineBreak +
    '  begin' + sLineBreak +
    '    ACanvas.Fill.Kind := OriginalFillKind;' + sLineBreak +
    '    ACanvas.Fill.Color := OriginalFillColor;' + sLineBreak +
    '    ACanvas.FillRect(RoundRectF, RadiusX, RadiusY, AllCorners, 1);' + sLineBreak +
    '  end;' + sLineBreak +
    '  GeneratedLastFillValid := False;' + sLineBreak +
    '  ACanvas.Stroke.Kind := TBrushKind.Solid;' + sLineBreak +
    '  ACanvas.DrawRect(RoundRectF, RadiusX, RadiusY, AllCorners, 1);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSetVerticalGradientFill(ACanvas: TCanvas; const R: TRect; const TopColor, BottomColor: TAlphaColor);' + sLineBreak +
    'begin' + sLineBreak +
    '  ACanvas.Fill.Kind := TBrushKind.Gradient;' + sLineBreak +
    '  ACanvas.Fill.Gradient.Style := TGradientStyle.Linear;' + sLineBreak +
    '  ACanvas.Fill.Gradient.Points[0].Color := TopColor;' + sLineBreak +
    '  ACanvas.Fill.Gradient.Points[0].Offset := 0;' + sLineBreak +
    '  ACanvas.Fill.Gradient.Points[1].Color := BottomColor;' + sLineBreak +
    '  ACanvas.Fill.Gradient.Points[1].Offset := 1;' + sLineBreak +
    '  ACanvas.Fill.Gradient.StartPosition.Point := PointF(0, 0);' + sLineBreak +
    '  ACanvas.Fill.Gradient.StopPosition.Point := PointF(0, 1);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedCanvasStretchDraw(ACanvas: TCanvas; const R: TRect; const Bitmap: FMX.Graphics.TBitmap);' + sLineBreak +
    'begin' + sLineBreak +
    '  if Assigned(Bitmap) and not Bitmap.IsEmpty then' + sLineBreak +
    '    ACanvas.DrawBitmap(Bitmap, TRectF.Create(0, 0, Bitmap.Width, Bitmap.Height), GeneratedRectF(R), 1);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedRGB(const R, G, B: Integer): TAlphaColor;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := TAlphaColor($FF000000 or ((Cardinal(R) and $FF) shl 16) or' + sLineBreak +
    '    ((Cardinal(G) and $FF) shl 8) or (Cardinal(B) and $FF));' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedColorToRGB(const Color: TAlphaColor): Cardinal;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := Cardinal(TAlphaColorRec(Color).R) or (Cardinal(TAlphaColorRec(Color).G) shl 8) or' + sLineBreak +
    '    (Cardinal(TAlphaColorRec(Color).B) shl 16);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedGetRValue(const Color: Cardinal): Byte;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (Color and $FF000000) <> 0 then' + sLineBreak +
    '    Result := TAlphaColorRec(TAlphaColor(Color)).R' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := GetRValue(Color);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedGetGValue(const Color: Cardinal): Byte;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (Color and $FF000000) <> 0 then' + sLineBreak +
    '    Result := TAlphaColorRec(TAlphaColor(Color)).G' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := GetGValue(Color);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedGetBValue(const Color: Cardinal): Byte;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (Color and $FF000000) <> 0 then' + sLineBreak +
    '    Result := TAlphaColorRec(TAlphaColor(Color)).B' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := GetBValue(Color);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSetCanvasTextColor(ATarget: TObject; const AColor: TAlphaColor);' + sLineBreak +
    'var' + sLineBreak +
    '  LTextSettings: ITextSettings;' + sLineBreak +
    'begin' + sLineBreak +
    '  if ATarget is TCanvas then' + sLineBreak +
    '  begin' + sLineBreak +
    '    TCanvas(ATarget).Fill.Kind := TBrushKind.Solid;' + sLineBreak +
    '    TCanvas(ATarget).Fill.Color := AColor;' + sLineBreak +
    '  end' + sLineBreak +
    '  else if Supports(ATarget, ITextSettings, LTextSettings) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    LTextSettings.StyledSettings := LTextSettings.StyledSettings - [TStyledSetting.FontColor];' + sLineBreak +
    '    LTextSettings.TextSettings.FontColor := AColor;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSyncAutoSizeTextHeight(ATarget: TObject; const ASize: Single);' + sLineBreak +
    'var' + sLineBreak +
    '  LLabel: TLabel;' + sLineBreak +
    '  LDesiredHeight: Single;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (ASize <= 0) or not (ATarget is TLabel) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  LLabel := TLabel(ATarget);' + sLineBreak +
    '  if not LLabel.AutoSize then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if LLabel.WordWrap then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  LDesiredHeight := ASize * 1.38;' + sLineBreak +
    '  if LLabel.Height < LDesiredHeight then' + sLineBreak +
    '    LLabel.Height := LDesiredHeight;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSetCanvasFontPixelHeight(ATarget: TObject; const APixels: Integer);' + sLineBreak +
    'var' + sLineBreak +
    '  LTextSettings: ITextSettings;' + sLineBreak +
    '  LFontSize: Single;' + sLineBreak +
    'begin' + sLineBreak +
    '  if APixels <= 0 then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  LFontSize := APixels * 72 / 96;' + sLineBreak +
    '  if ATarget is TCanvas then' + sLineBreak +
    '    TCanvas(ATarget).Font.Size := LFontSize' + sLineBreak +
    '  else if Supports(ATarget, ITextSettings, LTextSettings) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    LTextSettings.StyledSettings := LTextSettings.StyledSettings - [TStyledSetting.Size];' + sLineBreak +
    '    LTextSettings.TextSettings.Font.Size := LFontSize;' + sLineBreak +
    '  end;' + sLineBreak +
    '  GeneratedSyncAutoSizeTextHeight(ATarget, LFontSize);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSetCanvasFontSize(ATarget: TObject; const ASize: Single);' + sLineBreak +
    'var' + sLineBreak +
    '  LTextSettings: ITextSettings;' + sLineBreak +
    'begin' + sLineBreak +
    '  if ASize <= 0 then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if ATarget is TCanvas then' + sLineBreak +
    '    TCanvas(ATarget).Font.Size := ASize' + sLineBreak +
    '  else if Supports(ATarget, ITextSettings, LTextSettings) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    LTextSettings.StyledSettings := LTextSettings.StyledSettings - [TStyledSetting.Size];' + sLineBreak +
    '    LTextSettings.TextSettings.Font.Size := ASize;' + sLineBreak +
    '  end;' + sLineBreak +
    '  GeneratedSyncAutoSizeTextHeight(ATarget, ASize);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedDrawText(ACanvas: TCanvas; const AText: string; var ARect: TRect; const AFlags: Cardinal);' + sLineBreak +
    'var' + sLineBreak +
    '  RF: TRectF;' + sLineBreak +
    '  WordWrap: Boolean;' + sLineBreak +
    '  CalcRect: Boolean;' + sLineBreak +
    '  HAlign: TTextAlign;' + sLineBreak +
    '  VAlign: TTextAlign;' + sLineBreak +
    'begin' + sLineBreak +
    '  RF := GeneratedRectF(ARect);' + sLineBreak +
    '  WordWrap := (AFlags and DT_WORDBREAK) <> 0;' + sLineBreak +
    '  CalcRect := (AFlags and DT_CALCRECT) <> 0;' + sLineBreak +
    '  if (AFlags and DT_CENTER) <> 0 then' + sLineBreak +
    '    HAlign := TTextAlign.Center' + sLineBreak +
    '  else if (AFlags and DT_RIGHT) <> 0 then' + sLineBreak +
    '    HAlign := TTextAlign.Trailing' + sLineBreak +
    '  else' + sLineBreak +
    '    HAlign := TTextAlign.Leading;' + sLineBreak +
    '  if (AFlags and DT_VCENTER) <> 0 then' + sLineBreak +
    '    VAlign := TTextAlign.Center' + sLineBreak +
    '  else if (AFlags and DT_BOTTOM) <> 0 then' + sLineBreak +
    '    VAlign := TTextAlign.Trailing' + sLineBreak +
    '  else' + sLineBreak +
    '    VAlign := TTextAlign.Leading;' + sLineBreak +
    '  if CalcRect then' + sLineBreak +
    '  begin' + sLineBreak +
    '    ACanvas.MeasureText(RF, AText, WordWrap, [], HAlign, VAlign);' + sLineBreak +
    '    ARect := Rect(Trunc(RF.Left), Trunc(RF.Top), Round(RF.Right), Round(RF.Bottom));' + sLineBreak +
    '  end' + sLineBreak +
    '  else' + sLineBreak +
    '    ACanvas.FillText(RF, AText, WordWrap, 1, [], HAlign, VAlign);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
var
  OriginalCode: string;
  AnalysisCode: string;

  function MatchesGeneratedColorExtract(const Line, FuncName, SourceVar: string): Boolean;
  begin
    Result := TRegEx.IsMatch(Line,
      '^\s*[A-Za-z_][A-Za-z0-9_]*\s*:=\s*' + FuncName + '\(\s*' + SourceVar + '\s*\)\s*;\s*$',
      [roIgnoreCase]);
  end;

  function ReplaceGeneratedVerticalGradientLoops(const ACode: string): string;
  var
    Lines: TStringList;
    I: Integer;
    J: Integer;
    DeleteIndex: Integer;
    LineMatch: TMatch;
    MoveMatch: TMatch;
    LineToMatch: TMatch;
    FoundMove: Boolean;
    FoundLineTo: Boolean;
    Indent: string;
    TopColorVar: string;
    BottomColorVar: string;
    RectVar: string;
    CanvasVar: string;
    EndIndex: Integer;
    FillNoneIndex: Integer;
    MaxScanIndex: Integer;
    FillKindIndex: Integer;
    RoundRectIndex: Integer;
  begin
    Lines := TStringList.Create;
    try
      Lines.Text := ACode;
      I := 0;
      while I <= Lines.Count - 19 do
      begin
        LineMatch := TRegEx.Match(Lines[I],
          '^(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*HexToColor\(',
          [roIgnoreCase]);
        if not LineMatch.Success then
        begin
          Inc(I);
          Continue;
        end;

        Indent := LineMatch.Groups[1].Value;
        TopColorVar := LineMatch.Groups[2].Value;

        LineMatch := TRegEx.Match(Lines[I + 1],
          '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*HexToColor\(',
          [roIgnoreCase]);
        if not LineMatch.Success then
        begin
          Inc(I);
          Continue;
        end;
        BottomColorVar := LineMatch.Groups[1].Value;

        if not MatchesGeneratedColorExtract(Lines[I + 2], 'GeneratedGetRValue', TopColorVar) or
           not MatchesGeneratedColorExtract(Lines[I + 3], 'GeneratedGetGValue', TopColorVar) or
           not MatchesGeneratedColorExtract(Lines[I + 4], 'GeneratedGetBValue', TopColorVar) or
           not MatchesGeneratedColorExtract(Lines[I + 5], 'GeneratedGetRValue', BottomColorVar) or
           not MatchesGeneratedColorExtract(Lines[I + 6], 'GeneratedGetGValue', BottomColorVar) or
           not MatchesGeneratedColorExtract(Lines[I + 7], 'GeneratedGetBValue', BottomColorVar) then
        begin
          Inc(I);
          Continue;
        end;

        LineMatch := TRegEx.Match(Lines[I + 8],
          '^\s*for\s+[A-Za-z_][A-Za-z0-9_]*\s*:=\s*0\s+to\s+([A-Za-z_][A-Za-z0-9_]*)\.Height\s+do\s*$',
          [roIgnoreCase]);
        if not LineMatch.Success then
        begin
          Inc(I);
          Continue;
        end;
        RectVar := LineMatch.Groups[1].Value;

        if not TRegEx.IsMatch(Lines[I + 9], '^\s*begin\s*$', [roIgnoreCase]) then
        begin
          Inc(I);
          Continue;
        end;

        LineMatch := TRegEx.Match(Lines[I + 10],
          '^\s*([A-Za-z_][A-Za-z0-9_\.]*)\.Stroke\.Color\s*:=\s*GeneratedRGB\(\s*$',
          [roIgnoreCase]);
        if not LineMatch.Success then
        begin
          Inc(I);
          Continue;
        end;
        CanvasVar := LineMatch.Groups[1].Value;

        EndIndex := -1;
        FillNoneIndex := -1;
        FillKindIndex := -1;
        RoundRectIndex := -1;
        FoundMove := False;
        FoundLineTo := False;
        MaxScanIndex := I + 25;
        if MaxScanIndex > Lines.Count - 1 then
          MaxScanIndex := Lines.Count - 1;
        for J := I + 11 to MaxScanIndex do
        begin
          MoveMatch := TRegEx.Match(Lines[J],
            '^\s*GeneratedCanvasMoveTo\(\s*([A-Za-z_][A-Za-z0-9_\.]*)\s*,\s*([A-Za-z_][A-Za-z0-9_]*)\.Left\s*,\s*\2\.Top\s*\+\s*[A-Za-z_][A-Za-z0-9_]*\s*\)\s*;\s*$',
            [roIgnoreCase]);
          if MoveMatch.Success then
          begin
            CanvasVar := MoveMatch.Groups[1].Value;
            RectVar := MoveMatch.Groups[2].Value;
            FoundMove := True;
          end;

          LineToMatch := TRegEx.Match(Lines[J],
            '^\s*GeneratedCanvasLineTo\(\s*' + CanvasVar + '\s*,\s*' + RectVar + '\.Right\s*,\s*' + RectVar + '\.Top\s*\+\s*[A-Za-z_][A-Za-z0-9_]*\s*\)\s*;\s*$',
            [roIgnoreCase]);
          if LineToMatch.Success then
            FoundLineTo := True;
          if TRegEx.IsMatch(Lines[J], '^\s*end;\s*$', [roIgnoreCase]) then
            EndIndex := J
          else if (EndIndex <> -1) and
                  TRegEx.IsMatch(Lines[J],
                    '^\s*' + CanvasVar + '\.Fill\.Kind\s*:=\s*TBrushKind\.None\s*;\s*$',
                    [roIgnoreCase]) then
          begin
            FillNoneIndex := J;
            Break;
          end;
        end;

        if (EndIndex = -1) or (FillNoneIndex = -1) or not FoundMove or not FoundLineTo then
        begin
          for J := I + 8 to MaxScanIndex do
          begin
            if TRegEx.IsMatch(Lines[J],
              '^\s*' + CanvasVar + '\.Fill\.Kind\s*:=\s*TBrushKind\.None\s*;\s*$',
              [roIgnoreCase]) then
              FillKindIndex := J;

            if (FillKindIndex <> -1) and TRegEx.IsMatch(Lines[J],
              '^\s*GeneratedCanvasRoundRect\(\s*' + CanvasVar + '\s*,\s*' + RectVar + '\.Left\s*\+\s*1\s*,\s*' +
              RectVar + '\.Top\s*\+\s*1\s*,\s*$',
              [roIgnoreCase]) then
            begin
              RoundRectIndex := J;
              Break;
            end;
          end;

          if (FillKindIndex <> -1) and (RoundRectIndex <> -1) then
          begin
            if (RoundRectIndex = 0) or not ContainsText(Lines[RoundRectIndex - 1], 'GeneratedSetVerticalGradientFill(') then
            begin
              Lines.Insert(RoundRectIndex,
                Indent + 'GeneratedSetVerticalGradientFill(' + CanvasVar + ', ' + RectVar + ', ' +
                TopColorVar + ', ' + BottomColorVar + ');');
              Inc(I, 3);
              Continue;
            end;
          end;

          Inc(I);
          Continue;
        end;

        for DeleteIndex := FillNoneIndex downto I + 2 do
          Lines.Delete(DeleteIndex);
        Lines.Insert(I + 2,
          Indent + 'GeneratedSetVerticalGradientFill(' + CanvasVar + ', ' + RectVar + ', ' +
          TopColorVar + ', ' + BottomColorVar + ');');
        Lines.Insert(I + 3, Indent + CanvasVar + '.Fill.Kind := TBrushKind.None;');
        Inc(I, 4);
      end;

      Result := Lines.Text;
    finally
      Lines.Free;
    end;
end;

  procedure InsertGeneratedHelperBlock(const HelperCode: string);
  var
    Lines: TStringList;
    I: Integer;
    Inserted: Boolean;
  begin
    if Trim(HelperCode) = '' then
      Exit;

    Lines := TStringList.Create;
    try
      Lines.Text := Code;
      Inserted := False;
      for I := Lines.Count - 1 downto 0 do
        if TRegEx.IsMatch(Lines[I], '^\s*\{\$R\s+\*\.(?:dfm|fmx)\}\s*$',
          [roIgnoreCase]) then
        begin
          Lines.Insert(I + 1, HelperCode);
          Inserted := True;
          Break;
        end;

      if not Inserted then
        for I := Lines.Count - 1 downto 0 do
          if SameText(Trim(Lines[I]), 'implementation') then
          begin
            Lines.Insert(I + 1, HelperCode);
            Inserted := True;
            Break;
          end;

      if Inserted then
        Code := Lines.Text;
    finally
      Lines.Free;
    end;
  end;

begin
  Assert(Assigned(FContext));

  OriginalCode := Code;
  AnalysisCode := VCL2FMXStripCommentsForAnalysis(OriginalCode);

  Code := StringReplace(Code,
    '  Dlg := TForm.Create(nil);',
    '  Dlg := TForm.CreateNew(nil);',
    []);

  Code := TRegEx.Replace(Code,
    '\bCenterX\s*:=\s*Round\(\s*[A-Za-z_][A-Za-z0-9_]*\.Width\s*/\s*2\s*\)',
    'CenterX := Round(ClientWidth / 2)',
    [roIgnoreCase]);
  Code := TRegEx.Replace(Code,
    '\bCenterY\s*:=\s*Round\(\s*[A-Za-z_][A-Za-z0-9_]*\.Height\s*/\s*2\s*\)',
    'CenterY := Round(ClientHeight / 2)',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '([A-Za-z_][A-Za-z0-9_\.]*)\.FillEllipse\s*\(\s*(System\.Types\.RectF\(.+?\))\s*,\s*1\s*\)\s*;',
    'FillAndStrokeEllipse($1, $2);',
    [roIgnoreCase, roSingleLine]);

  if ContainsText(Code, 'FillAndStrokeEllipse(') and
     not ContainsText(Code, 'procedure FillAndStrokeEllipse(') then
    InsertGeneratedHelperBlock(FillAndStrokeEllipseHelperCode);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*procedure\s+[A-Za-z_][A-Za-z0-9_\.]*Paint\s*\(\s*Sender\s*:\s*TObject)\s*\);',
    '$1; Canvas: TCanvas);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '\b([A-Za-z_][A-Za-z0-9_]*)\.Canvas(\s*,\s*GeneratedClientRect\(\1\))',
    'Canvas$2',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '\b([A-Za-z_][A-Za-z0-9_]*)\.Canvas(\s*,\s*\1\.ClientRect\b)',
    'Canvas$2',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '\bTPngImage\b',
    'FMX.Graphics.TBitmap',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '(^\s*[A-Za-z_][A-Za-z0-9_,\s]*:\s*)TBitmap(\s*[;=,\)])',
    '$1FMX.Graphics.TBitmap$2',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(?<![\.\w])TBitmap\.Create\b',
    'FMX.Graphics.TBitmap.Create',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '\bColorToRGB\s*\(',
    'GeneratedColorToRGB(',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '\bGetRValue\s*\(',
    'GeneratedGetRValue(',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '\bGetGValue\s*\(',
    'GeneratedGetGValue(',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '\bGetBValue\s*\(',
    'GeneratedGetBValue(',
    [roIgnoreCase]);

  Code := ReplaceGeneratedVerticalGradientLoops(Code);

  Code := TRegEx.Replace(Code,
    '((?:\.Fill\.Color|\.Stroke\.Color|\.TextSettings\.FontColor|\.FontColor|\.Color)\s*:=\s*)RGB\(',
    '$1GeneratedRGB(',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '(^\s*Result\s*:=\s*)RGB\(',
    '$1GeneratedRGB(',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '^[ \t]*[A-Za-z_][A-Za-z0-9_\.]*\.Transparent\s*:=\s*True\s*;\s*\r?\n?',
    '',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '\b([A-Za-z_][A-Za-z0-9_]*)\.ClientRect\b',
    'GeneratedClientRect($1)',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.Brush\.Style\s*:=\s*bsClear\s*;',
    '$1$2$3.Fill.Kind := TBrushKind.None;',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.Brush\.Color\s*:=\s*([^;\r\n]+)\s*;',
    '$1$2$3.Fill.Kind := TBrushKind.Solid;' + sLineBreak + '$1$2$3.Fill.Color := $4;',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.Pen\.Color\s*:=\s*([^;\r\n]+)\s*;',
    '$1$2$3.Stroke.Color := $4;',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.Pen\.Width\s*:=\s*([^;\r\n]+)\s*;',
    '$1$2$3.Stroke.Thickness := $4;',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.Font\.Color\s*:=\s*([^;\r\n]+)\s*;',
    '$1$2GeneratedSetCanvasTextColor($3, $4);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.TextSettings\.FontColor\s*:=\s*([^;\r\n]+)\s*;',
    '$1$2GeneratedSetCanvasTextColor($3, $4);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.Font\.Height\s*:=\s*-?MulDiv\(\s*([^,]+)\s*,\s*Screen\.PixelsPerInch\s*,\s*96\s*\)\s*;',
    '$1$2GeneratedSetCanvasFontPixelHeight($3, $4);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.Font\.Size\s*:=\s*([^;\r\n]+)\s*;',
    '$1$2GeneratedSetCanvasFontSize($3, $4);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)(//\s*FMX manual review:\s*)?([A-Za-z_][A-Za-z0-9_\.]*)\.TextSettings\.Font\.Size\s*:=\s*([^;\r\n]+)\s*;',
    '$1$2GeneratedSetCanvasFontSize($3, $4);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '^[ \t]*//\s*GeneratedSetCanvasFontPixelHeight\(([^)]+)\);\s*- FMX uses automatic DPI scaling\s*$',
    '  GeneratedSetCanvasFontPixelHeight($1);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '([A-Za-z_][A-Za-z0-9_\.]*)\.FillRect\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)\s*;',
    'GeneratedCanvasFillRect($1, $2);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '([A-Za-z_][A-Za-z0-9_\.]*)\.MoveTo\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)\s*;',
    'GeneratedCanvasMoveTo($1, $2, $3);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '([A-Za-z_][A-Za-z0-9_\.]*)\.LineTo\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)\s*;',
    'GeneratedCanvasLineTo($1, $2, $3);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '([A-Za-z_][A-Za-z0-9_\.]*)\.RoundRect\s*\(\s*([\s\S]+?)\s*\)\s*;',
    'GeneratedCanvasRoundRect($1, $2);',
    [roIgnoreCase, roSingleLine]);

  Code := TRegEx.Replace(Code,
    '([A-Za-z_][A-Za-z0-9_\.]*)\.StretchDraw\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*([A-Za-z_][A-Za-z0-9_\.]*)\s*\)\s*;',
    'GeneratedCanvasStretchDraw($1, $2, $3);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    'DrawText\(\s*([A-Za-z_][A-Za-z0-9_\.]*)\.Handle\s*,\s*PChar\((.*?)\)\s*,\s*-1\s*,\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*(.*?)\)\s*;',
    'GeneratedDrawText($1, $2, $3, $4);',
    [roIgnoreCase, roSingleLine]);

  Code := TRegEx.Replace(Code,
    '\bx([0-9A-Fa-f]{8})\b',
    '$$$1',
    [roIgnoreCase]);

  if (ContainsText(Code, 'GeneratedClientRect(') or
      ContainsText(Code, 'GeneratedCanvasFillRect(') or
      ContainsText(Code, 'GeneratedCanvasMoveTo(') or
      ContainsText(Code, 'GeneratedCanvasLineTo(') or
      ContainsText(Code, 'GeneratedCanvasRoundRect(') or
      ContainsText(Code, 'GeneratedCanvasStretchDraw(') or
      ContainsText(Code, 'GeneratedSetCanvasTextColor(') or
      ContainsText(Code, 'GeneratedSetCanvasFontPixelHeight(') or
      ContainsText(Code, 'GeneratedSetCanvasFontSize(') or
     ContainsText(Code, 'GeneratedDrawText(')) and
     not ContainsText(Code, 'function GeneratedClientRect(') then
  begin
    InsertGeneratedHelperBlock(CanvasCompatHelperCode);
  end;

  if Code <> OriginalCode then
  begin
    FContext.AddIssue(csInfo,
      'Runtime compatibility rewrites applied for FMX conversion support.');
    if (not ContainsText(OriginalCode, 'procedure FillAndStrokeEllipse(')) and
       ContainsText(Code, 'procedure FillAndStrokeEllipse(') then
      FContext.AddIssue(csInfo, 'Injected FillAndStrokeEllipse canvas helper.');
    if (not ContainsText(OriginalCode, 'function GeneratedClientRect(')) and
       ContainsText(Code, 'function GeneratedClientRect(') then
      FContext.AddIssue(csInfo, 'Injected generated canvas compatibility helpers.');
    if ContainsText(AnalysisCode, 'TPngImage') then
      FContext.AddIssue(csWarning,
        'TPngImage references were rewritten to FMX.Graphics.TBitmap; review PNG load/save behavior.');
    if TRegEx.IsMatch(AnalysisCode,
       '(^[ \t]*procedure\s+[A-Za-z_][A-Za-z0-9_\.]*Paint\s*\(\s*Sender\s*:\s*TObject)\s*\);',
       [roIgnoreCase, roMultiLine]) then
      FContext.AddIssue(csWarning,
        'Paint handler signatures were adapted for FMX canvas handling; review event wiring in the generated form.');
  end;

end;

end.
