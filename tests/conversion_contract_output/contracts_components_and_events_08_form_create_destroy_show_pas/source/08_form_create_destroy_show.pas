unit ContractFormCreateDestroyShow;
interface
uses System.SysUtils, System.Classes, Vcl.Forms;
type TContractFormCreateDestroyShow = class(TForm) procedure FormCreate(Sender: TObject); procedure FormDestroy(Sender: TObject); procedure FormShow(Sender: TObject); end;
implementation
procedure TContractFormCreateDestroyShow.FormCreate(Sender: TObject); begin Caption := 'create'; end;
procedure TContractFormCreateDestroyShow.FormDestroy(Sender: TObject); begin end;
procedure TContractFormCreateDestroyShow.FormShow(Sender: TObject); begin Caption := 'show'; end;
end.

