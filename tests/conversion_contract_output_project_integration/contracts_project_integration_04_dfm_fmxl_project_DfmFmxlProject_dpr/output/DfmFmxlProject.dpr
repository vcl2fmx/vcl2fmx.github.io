program DfmFmxlProject;

uses
  FMX.Forms,
  DfmFmxlMain in 'DfmFmxlMain.pas' {DfmFmxlForm};

begin
  Application.Initialize;

  Application.CreateForm(TDfmFmxlForm, DfmFmxlForm);
  Application.Run;
end.
