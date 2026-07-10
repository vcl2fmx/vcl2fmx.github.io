unit ContractMessageHandlerDeclaration;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Vcl.Forms;

type
  TContractMessageHandlerDeclaration = class(TForm)
  private
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure CMDialogChar(var Msg: TCMDialogChar); message CM_DIALOGCHAR;
  end;

implementation

end.

