unit ContractAttributeBeforeMethodBoundary;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
  { FMX: Use property setter or direct method call instead of SendMessage }
  { Original: type TContractAttributeBeforeMethodBoundary = class private FHandle: HWND; public procedure Run; procedure SendMessage(const AText: string); end; }
implementation
procedure TContractAttributeBeforeMethodBoundary.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: SendMessage(FHandle, WM_CLOSE, 0, 0) }
end;
[SomeAttribute]
procedure TContractAttributeBeforeMethodBoundary.SendMessage(const AText: string);
begin
  Writeln(AText);
end;
end.
