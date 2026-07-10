unit ContractImagePictureStretch;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;
type TContractImagePictureStretch = class(TForm) Image1: TImage; procedure Run; end;
implementation
procedure TContractImagePictureStretch.Run;
begin
  Image1.Stretch := True;
  Image1.Proportional := True;
  Image1.Picture.LoadFromFile('x.png');
end;
end.

