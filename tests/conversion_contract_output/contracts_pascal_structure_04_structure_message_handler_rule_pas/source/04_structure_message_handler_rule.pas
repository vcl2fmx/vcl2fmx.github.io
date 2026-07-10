unit ContractPascalStructureMessageHandlerRule;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Vcl.Forms;

type
  TContractPascalStructureMessageHandlerRule = class(TForm)
  private
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  end;

implementation

end.
