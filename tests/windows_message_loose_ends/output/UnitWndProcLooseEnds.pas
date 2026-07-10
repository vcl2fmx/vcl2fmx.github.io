unit UnitWndProcLooseEnds;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants, Winapi.Messages;
type
  TWndProcLooseEndsForm = class(TForm)
  protected
  { FMX manual review: procedure WndProc(var Msg: TMessage); override; }
  end;
implementation
  { FMX: WndProc replaced by TMessageManager - see FormCreate for subscriptions }
  { begin }
  { case Msg.Msg of }
  { FMX: WM_SIZE: -> use OnResize event handler }
  { inherited; }
  { else }
  { inherited; }
  { end; }
  { end; }
end.
