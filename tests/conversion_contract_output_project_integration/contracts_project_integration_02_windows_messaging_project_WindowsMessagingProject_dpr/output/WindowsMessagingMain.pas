unit WindowsMessagingMain;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Memo, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants, Winapi.Windows;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
  TWindowsMessagingForm = class(TForm)
    Memo1: TMemo;
  private
    FHandle: HWND;
  // FMX manual review: procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
  { FMX manual review: procedure WndProc(var Message: TMessage); override; }
  public
    procedure Run;
    procedure SendMessage(const AText: string);
  end;
var
  WindowsMessagingForm: TWindowsMessagingForm;
implementation
{$R *.fmx}

procedure TMemo.Clear;
begin
  Lines.Clear;
end;
procedure TWindowsMessagingForm.Run;
var
  Count: Integer;
  TextValue: string;
begin
  { FMX: LVM_GETITEMCOUNT - Use FMX list view, tree view, tab control, or adapter APIs instead of common-control messages. }
  { Original: Count := SendMessage(FHandle, LVM_GETITEMCOUNT, 0, 0); }
  { FMX: WM_USER - Use System.Messaging with a typed TMessage descendant for custom application messages. }
  { FMX: Preserve async behavior with TThread.Queue only if the original timing matters. }
  { Original: PostMessage(FHandle, WM_USER + 42, Count, 0); }
  { TThread.Queue(nil, procedure begin TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); end); }
  { FMX: EM_SETSEL - Use FMX edit/memo text, selection, caret, and clipboard APIs instead of edit control messages. }
  { Original: Memo1.Perform(EM_SETSEL, 0, -1); }
  TextValue := 'SendMessage WM_CLOSE in a string is not active code';
  // PostMessage(FHandle, WM_CLOSE, 0, 0) is a comment only.
  SendMessage(TextValue);
end;
procedure TWindowsMessagingForm.SendMessage(const AText: string);
begin
  Memo1.Lines.Add(AText);
end;
  // FMX manual review: procedure TWindowsMessagingForm.WMSize(var Message: TWMSize);
  // FMX manual review: begin
  // FMX manual review: inherited;
  // FMX manual review: end;
  // FMX manual review: 
  // FMX manual review: { FMX: WndProc replaced by TMessageManager - see FormCreate for subscriptions }
  // FMX manual review: { begin }
  // FMX manual review: { inherited; }
  // FMX manual review: { end; }
  // FMX manual review: 
end.
