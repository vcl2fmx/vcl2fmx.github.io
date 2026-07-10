unit ContractNestedBeginEndAfterDisabledCall;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractNestedBeginEndAfterDisabledCall = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractNestedBeginEndAfterDisabledCall.Run;
begin
  if True then
  begin
  // FMX manual review: SendMessage(
  // FMX manual review: FHandle,
  // FMX manual review: WM_USER + 1,
  // FMX manual review: 0,
  // FMX manual review: 0);
    Writeln('after');
  end;
end;
end.
