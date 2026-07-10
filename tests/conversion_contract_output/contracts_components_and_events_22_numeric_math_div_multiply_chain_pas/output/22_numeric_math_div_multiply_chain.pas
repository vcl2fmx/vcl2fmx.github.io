unit ContractNumericMathDivMultiplyChain;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
  Panel1.Width := Round(Panel2.Width / 2 * 3);
  Panel1.Height := Round(ClientHeight / 3 * 2);
end;
end.
