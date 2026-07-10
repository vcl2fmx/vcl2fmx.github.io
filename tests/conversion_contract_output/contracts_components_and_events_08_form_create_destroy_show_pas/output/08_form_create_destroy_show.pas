unit ContractFormCreateDestroyShow;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractFormCreateDestroyShow = class(TForm) procedure FormCreate(Sender: TObject); procedure FormDestroy(Sender: TObject); procedure FormShow(Sender: TObject); end;
implementation
procedure TContractFormCreateDestroyShow.FormCreate(Sender: TObject); begin Caption := 'create'; end;
procedure TContractFormCreateDestroyShow.FormDestroy(Sender: TObject); begin end;
procedure TContractFormCreateDestroyShow.FormShow(Sender: TObject); begin Caption := 'show'; end;
end.
