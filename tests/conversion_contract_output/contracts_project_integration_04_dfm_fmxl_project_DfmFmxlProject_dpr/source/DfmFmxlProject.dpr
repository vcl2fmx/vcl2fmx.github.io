program DfmFmxlProject;

uses
  Vcl.Forms,
  DfmFmxlMain in 'DfmFmxlMain.pas' {DfmFmxlForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDfmFmxlForm, DfmFmxlForm);
  Application.Run;
end.
