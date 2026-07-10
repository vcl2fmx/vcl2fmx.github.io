unit ContractRuntimeDataSourceAssignment;
interface
uses Data.DB, FMX.Controls, FMX.Edit, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes,
  System.SysUtils, System.Variants;
type TContractRuntimeDataSourceAssignment = class(TForm) DataSource1: TDataSource; DBEdit1: TEdit; procedure Run; end;
implementation
procedure TContractRuntimeDataSourceAssignment.Run;
begin
  // FMX manual review: DBEdit1.DataSource := DataSource1;
  // FMX manual review: DBEdit1.DataField := 'NAME';
end;
end.
