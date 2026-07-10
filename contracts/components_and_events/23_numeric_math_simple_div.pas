unit ContractNumericMathSimpleDiv;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;

type
  TContractNumericMathSimpleDiv = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
  public
    procedure Run;
  end;

implementation

procedure TContractNumericMathSimpleDiv.Run;
begin
  Panel1.Width := Panel2.Width div 2;
  Panel1.Height := ClientHeight div 2;
end;

end.
