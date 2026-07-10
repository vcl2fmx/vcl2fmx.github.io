unit ContractCustomComponentUnknown;
interface
uses System.SysUtils, System.Classes, Vcl.Forms;
type
  TMyLegacyWidget = class(TComponent) end;
  TContractCustomComponentUnknown = class(TForm) MyLegacyWidget1: TMyLegacyWidget; end;
implementation
end.

