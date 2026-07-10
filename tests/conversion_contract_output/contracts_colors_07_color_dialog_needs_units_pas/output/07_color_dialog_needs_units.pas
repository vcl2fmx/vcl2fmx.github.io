unit ContractColorDialogNeedsUnits;
interface
uses FMX.Colors, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes,
  System.SysUtils, System.UIConsts, System.UITypes, System.Variants;
type TContractColorDialogNeedsUnits = class private ColorDialog1: TColorDialog; public procedure Run; end;
implementation
constructor TColorDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := claWhite;
end;
function TColorDialog.Execute: Boolean;
var
  Dlg: TForm;
  PromptLabel: TLabel;
  ColorBox: TColorListBox;
  OkButton: TButton;
  CancelButton: TButton;
begin
  Result := False;
  Dlg := TForm.CreateNew(nil);
  try
    Dlg.Width := 360;
    Dlg.Height := 360;
    Dlg.Position := TFormPosition.ScreenCenter;
    Dlg.Caption := 'Select Color';
    PromptLabel := TLabel.Create(Dlg);
    PromptLabel.Parent := Dlg;
    PromptLabel.Text := 'Color:';
    PromptLabel.Position.X := 16;
    PromptLabel.Position.Y := 20;
    ColorBox := TColorListBox.Create(Dlg);
    ColorBox.Parent := Dlg;
    ColorBox.Position.X := 16;
    ColorBox.Position.Y := 44;
    ColorBox.Width := 320;
    ColorBox.Height := 240;
    ColorBox.Color := FColor;
    OkButton := TButton.Create(Dlg);
    OkButton.Parent := Dlg;
    OkButton.Text := 'OK';
    OkButton.Position.X := 168;
    OkButton.Position.Y := 300;
    OkButton.ModalResult := mrOk;
    CancelButton := TButton.Create(Dlg);
    CancelButton.Parent := Dlg;
    CancelButton.Text := 'Cancel';
    CancelButton.Position.X := 252;
    CancelButton.Position.Y := 300;
    CancelButton.ModalResult := mrCancel;
    Result := Dlg.ShowModal = mrOk;
    if Result then
      FColor := ColorBox.Color;
  finally
    Dlg.Free;
  end;
end;
procedure TContractColorDialogNeedsUnits.Run;
begin
  if ColorDialog1.Execute then Writeln('ok');
end;
end.
