unit ContractImagePictureAssignSave;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractImagePictureAssignSave = class(TForm)
    Image1: TImage;
    Image2: TImage;
    procedure Run;
  end;
implementation
procedure TContractImagePictureAssignSave.Run;
begin
  Image1.Bitmap.Assign(Image2.Bitmap);
  Image1.Bitmap.SaveToFile('out.png');
  Image1.Bitmap.Assign(Image2.Bitmap);
end;
end.
