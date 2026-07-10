unit ContractImagePictureStretch;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractImagePictureStretch = class(TForm) Image1: TImage; procedure Run; end;
implementation
procedure TContractImagePictureStretch.Run;
begin
  Image1.WrapMode := TImageWrapMode.Stretch;
  Image1.WrapMode := TImageWrapMode.Fit;
  Image1.Bitmap.LoadFromFile('x.png');
end;
end.
