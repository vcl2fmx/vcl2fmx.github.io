unit ContractSharedTokenizerStringCommentDirective;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

type
  TContractSharedTokenizerStringCommentDirective = class
  private
    FHandle: HWND;
  public
    procedure Run;
  end;

implementation

procedure TContractSharedTokenizerStringCommentDirective.Run;
begin
  // SendMessage(FHandle, WM_CLOSE, 0, 0);
  Writeln('PostMessage(FHandle, WM_CLOSE, 0, 0)');
  {$IFDEF NEVER_DEFINED}
  SendMessage(FHandle, WM_CLOSE, 0, 0);
  {$ENDIF}
  SendMessage(FHandle, WM_CLOSE, 0, 0);
end;

end.
