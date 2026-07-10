program PascalStructureProject;

uses
  FMX.Forms,
  PascalStructureMain in 'PascalStructureMain.pas' {PascalStructureForm};

begin
  Application.Initialize;

  Application.CreateForm(TPascalStructureForm, PascalStructureForm);
  Application.Run;
end.
