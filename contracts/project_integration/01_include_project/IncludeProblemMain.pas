unit IncludeProblemMain;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls;

type
  TIncludeProblemForm = class(TForm)
    Memo1: TMemo;
  public
    procedure Run;
  end;

var
  IncludeProblemForm: TIncludeProblemForm;

implementation

{$R *.dfm}

{$I Includes\NestedA.inc}
{$I MissingContract.inc}
{$I C:\New Delphi Projects\VCL2FMXConverterV5\contracts\project_integration\outside_shared\OutsideProject.inc}
{$I Includes\LoopA.inc}
{$I Includes\Utf8ProjectText.inc}

procedure TIncludeProblemForm.Run;
begin
  Memo1.Lines.Add(ProjectNestedValue);
end;

end.
