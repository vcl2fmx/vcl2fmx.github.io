program Utf8AccentRegression;

uses
  FMX.Forms,
  UnitUtf8Accents in 'UnitUtf8Accents.pas' {frmUtf8Accents};

{$R *.res}

begin
  Application.Initialize;

  Application.CreateForm(TfrmUtf8Accents, frmUtf8Accents);
  Application.Run;
end.
