program StringGridEventOrderRegression;

uses
  Vcl.Forms,
  UnitStringGridEvents in 'UnitStringGridEvents.pas' {frmStringGridEvents};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmStringGridEvents, frmStringGridEvents);
  Application.Run;
end.
