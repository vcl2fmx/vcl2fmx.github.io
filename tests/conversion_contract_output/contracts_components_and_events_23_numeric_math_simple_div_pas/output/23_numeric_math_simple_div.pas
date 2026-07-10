unit ContractNumericMathSimpleDiv;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
  Panel1.Width := Panel2.Width / 2;
  Panel1.Height := ClientHeight / 2;
end;
end.
