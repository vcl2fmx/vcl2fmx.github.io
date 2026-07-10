unit ContractRecordMethodAfterDisabledCall;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractRecordMethodAfterDisabledCall = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractRecordMethodAfterDisabledCall.Run;
begin
  // FMX manual review: SendMessage(
  // FMX manual review: FHandle,
  // FMX manual review: WM_CLOSE,
  // FMX manual review: 0,
  // FMX manual review: 0)
end;
procedure HelperAfterBoundary;
begin
  Writeln('boundary');
end;
end.
