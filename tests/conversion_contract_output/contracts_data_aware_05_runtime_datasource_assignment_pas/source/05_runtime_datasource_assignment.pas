unit ContractRuntimeDataSourceAssignment;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Data.DB, Vcl.DBCtrls;
type TContractRuntimeDataSourceAssignment = class(TForm) DataSource1: TDataSource; DBEdit1: TDBEdit; procedure Run; end;
implementation
procedure TContractRuntimeDataSourceAssignment.Run;
begin
  DBEdit1.DataSource := DataSource1;
  DBEdit1.DataField := 'NAME';
end;
end.

