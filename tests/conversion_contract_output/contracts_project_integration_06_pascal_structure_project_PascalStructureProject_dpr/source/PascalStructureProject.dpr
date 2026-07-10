program PascalStructureProject;

uses
  Vcl.Forms,
  PascalStructureMain in 'PascalStructureMain.pas' {PascalStructureForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPascalStructureForm, PascalStructureForm);
  Application.Run;
end.
