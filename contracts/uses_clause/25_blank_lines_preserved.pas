unit ContractUsesBlankLinesPreserved;

interface

uses
  System.SysUtils,
  Vcl.Forms;

type
  TContractUsesBlankLinesPreserved = class
  public
    procedure First;
    procedure Second;
  end;

implementation

procedure TContractUsesBlankLinesPreserved.First;
begin
  Writeln('first');
end;

procedure TContractUsesBlankLinesPreserved.Second;
begin
  Writeln('second');
end;

end.
