unit ContractWndProcOverride;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractWndProcOverride = class(TForm)
  protected
  { FMX manual review: procedure WndProc(var Msg: TMessage); override; }
  end;
implementation
  { FMX: WndProc replaced by TMessageManager - see FormCreate for subscriptions }
  { begin }
  { FMX: if Msg.Msg = WM_SIZE then -> use TMessageManager }
  { Caption := 'sized'; }
  { inherited; }
  { end; }
end.
