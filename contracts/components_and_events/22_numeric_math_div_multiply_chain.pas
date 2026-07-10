unit ContractNumericMathDivMultiplyChain;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;

type
  TContractNumericMathDivMultiplyChain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
  public
    procedure Run;
  end;

implementation

procedure TContractNumericMathDivMultiplyChain.Run;
begin
  Panel1.Width := Panel2.Width div 2 * 3;
  Panel1.Height := ClientHeight div 3 * 2;
end;

end.
