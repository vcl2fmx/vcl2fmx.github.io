program BasicProject;
uses
  FMX.Forms,
  UnitBasicForm in 'UnitBasicForm.pas' {BasicForm};
begin
  Application.Initialize;

  Application.CreateForm(TBasicForm, BasicForm);
  Application.Run;
end.

