unit ContractCustomComponentUnknown;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TMyLegacyWidget = class(TComponent) end;
  TContractCustomComponentUnknown = class(TForm) MyLegacyWidget1: TMyLegacyWidget; end;
implementation
end.
