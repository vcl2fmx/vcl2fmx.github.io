unit ContractStatusBarPanels;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractStatusBarPanels = class(TForm) StatusBar1: TStatusBar; procedure Run; end;
implementation
function FindNamedChild(const Root: TFmxObject; const AName: string): TFmxObject;
var
  I: Integer;
  Child: TFmxObject;
begin
  Result := nil;
  if Root = nil then
    Exit;
  if SameText(Root.Name, AName) then
    Exit(Root);
  for I := 0 to Root.ChildrenCount - 1 do
  begin
    Child := FindNamedChild(Root.Children[I], AName);
    if Child <> nil then
      Exit(Child);
  end;
end;
procedure SetStatusBarPanelText(const AStatusBar: TStatusBar; const AIndex: Integer; const AText: string);
var
  Obj: TFmxObject;
begin
  if AStatusBar = nil then
    Exit;
  Obj := FindNamedChild(AStatusBar, AStatusBar.Name + 'Panel' + IntToStr(AIndex));
  if Obj is TLabel then
    TLabel(Obj).Text := AText;
end;
function GetStatusBarPanelText(const AStatusBar: TStatusBar; const AIndex: Integer): string;
var
  Obj: TFmxObject;
begin
  Result := '';
  if AStatusBar = nil then
    Exit;
  Obj := FindNamedChild(AStatusBar, AStatusBar.Name + 'Panel' + IntToStr(AIndex));
  if Obj is TLabel then
    Result := TLabel(Obj).Text;
end;
procedure TContractStatusBarPanels.Run;
begin
  // FMX manual review: SetStatusBarPanelText(StatusBar1, 0, 'ready');
end;
end.
