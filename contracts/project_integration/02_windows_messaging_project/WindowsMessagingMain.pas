unit WindowsMessagingMain;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.Forms, Vcl.StdCtrls;

type
  TWindowsMessagingForm = class(TForm)
    Memo1: TMemo;
  private
    FHandle: HWND;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    procedure Run;
    procedure SendMessage(const AText: string);
  end;

var
  WindowsMessagingForm: TWindowsMessagingForm;

implementation

{$R *.dfm}

procedure TWindowsMessagingForm.Run;
var
  Count: Integer;
  TextValue: string;
begin
  Count := SendMessage(FHandle, LVM_GETITEMCOUNT, 0, 0);
  PostMessage(FHandle, WM_USER + 42, Count, 0);
  Memo1.Perform(EM_SETSEL, 0, -1);
  TextValue := 'SendMessage WM_CLOSE in a string is not active code';
  // PostMessage(FHandle, WM_CLOSE, 0, 0) is a comment only.
  SendMessage(TextValue);
end;

procedure TWindowsMessagingForm.SendMessage(const AText: string);
begin
  Memo1.Lines.Add(AText);
end;

procedure TWindowsMessagingForm.WMSize(var Message: TWMSize);
begin
  inherited;
end;

procedure TWindowsMessagingForm.WndProc(var Message: TMessage);
begin
  inherited;
end;

end.
