unit ContractButtonClickSignature;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractButtonClickSignature = class(TForm) Button1: TButton; procedure Button1Click(Sender: TObject); end;
implementation
procedure TContractButtonClickSignature.Button1Click(Sender: TObject);
begin
  Caption := 'clicked';
end;
end.
