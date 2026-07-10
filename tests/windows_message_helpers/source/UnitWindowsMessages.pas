unit UnitWindowsMessages;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.StdCtrls;

type
  TWindowsMessageFixture = class
  private
    Memo1: TMemo;
    MemImpPre: TMemo;
    ListBox1: TListBox;
  public
    procedure Exercise(Sender: TObject);
  end;

implementation

procedure TWindowsMessageFixture.Exercise(Sender: TObject);
var
  Line: Integer;
  IndexVerbe: Integer;
  wStr: string;
begin
  MemImpPre.perform(em_linescroll, 0, 0);
  Memo1.Perform(EM_LINESCROLL, 0, -3);
  Line := Memo1.Perform(EM_LINEFROMCHAR, Memo1.SelStart, 0);
  Line := (Sender As TMemo).Perform(
    EM_LINEFROMCHAR,
    (Sender As TMemo).SelStart,
    0);
  SendMessage(Memo1.Handle, WM_VSCROLL, SB_TOP, 0);
  SendMessage((Sender As TMemo).Handle, WM_VSCROLL, SB_LINEDOWN, 0);
  wStr := 'abc';
  IndexVerbe := ListBox1.Perform(LB_SELECTSTRING, WPARAM(-1), LongInt(@wStr));
end;

end.
