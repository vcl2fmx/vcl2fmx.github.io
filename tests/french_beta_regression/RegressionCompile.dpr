program RegressionCompile;

uses
  System.StartUpCopy,
  FMX.Forms,
  RegressionForm in 'output\RegressionForm.pas' {RegressionForm},
  ImageOnly in 'output\ImageOnly.pas' {ImageOnlyForm};

var
  RegressionFormInstance: TRegressionForm;
  ImageOnlyFormInstance: TImageOnlyForm;

begin
  Application.Initialize;
  Application.CreateForm(TRegressionForm, RegressionFormInstance);
  Application.CreateForm(TImageOnlyForm, ImageOnlyFormInstance);
  Application.Run;
end.
