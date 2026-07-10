unit UnitStringGridEvents;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Grids;

type
  TfrmStringGridEvents = class(TForm)
    sgTestAc: TStringGrid;
    procedure sgTestAcDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure sgTestAcSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure sgTestAcDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure sgTestAcMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgTestKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

var
  frmStringGridEvents: TfrmStringGridEvents;

implementation

{$R *.dfm}

procedure TfrmStringGridEvents.sgTestAcDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := True;
end;

procedure TfrmStringGridEvents.sgTestAcSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
end;

procedure TfrmStringGridEvents.sgTestAcDragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
end;

procedure TfrmStringGridEvents.sgTestAcMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TfrmStringGridEvents.sgTestKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
end;

end.
