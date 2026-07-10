program MemoStringsRegression;

uses
  Vcl.Forms,
  UnitMemoStrings in 'UnitMemoStrings.pas' {frmMemoStrings};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMemoStrings, frmMemoStrings);
  Application.Run;
end.
