unit PascalStructureMain;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  IPascalStructureWorker = interface
    ['{AA27D6C4-8565-48B6-BC1A-B5402E289B2F}']
    procedure Execute;
  end;
  TPascalStructureState = record
  private
    FCount: Integer;
  public
    procedure Reset;
    property Count: Integer read FCount write FCount;
  end;
  TPascalStructureForm = class(TForm, IPascalStructureWorker)
  private
    Button1: TButton;
    FState: TPascalStructureState;
  // FMX manual review: procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  public
    procedure Execute; overload;
    procedure Execute(const AText: string); overload;
  end;
implementation
{$R *.fmx}

procedure TPascalStructureState.Reset;
begin
  FCount := 0;
end;
procedure TPascalStructureForm.Execute;
  procedure ResetState;
  begin
    FState.Reset;
  end;
begin
  ResetState;
end;
procedure TPascalStructureForm.Execute(const AText: string);
begin
  if AText <> '' then
    Execute;
end;
end.
