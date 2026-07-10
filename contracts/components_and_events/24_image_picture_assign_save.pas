unit ContractImagePictureAssignSave;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;

type
  TContractImagePictureAssignSave = class(TForm)
    Image1: TImage;
    Image2: TImage;
    procedure Run;
  end;

implementation

procedure TContractImagePictureAssignSave.Run;
begin
  Image1.Picture.Assign(Image2.Picture);
  Image1.Picture.SaveToFile('out.png');
  Image1.Picture.Graphic.Assign(Image2.Picture.Graphic);
end;

end.
