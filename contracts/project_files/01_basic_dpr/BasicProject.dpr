program BasicProject;
uses
  Vcl.Forms,
  UnitBasicForm in 'UnitBasicForm.pas' {BasicForm};
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TBasicForm, BasicForm);
  Application.Run;
end.

