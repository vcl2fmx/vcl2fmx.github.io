unit IncludeProblemMain;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Memo, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
  TIncludeProblemForm = class(TForm)
    Memo1: TMemo;
  public
    procedure Run;
  end;
var
  IncludeProblemForm: TIncludeProblemForm;
implementation
{$R *.fmx}
{$I Includes\NestedA.inc}
{$I MissingContract.inc}
{$I C:\New Delphi Projects\VCL2FMXConverterV5\contracts\project_integration\outside_shared\OutsideProject.inc}
{$I Includes\LoopA.inc}
{$I Includes\Utf8ProjectText.inc}
procedure TMemo.Clear;
begin
  Lines.Clear;
end;
procedure TIncludeProblemForm.Run;
begin
  Memo1.Lines.Add(ProjectNestedValue);
end;
end.
