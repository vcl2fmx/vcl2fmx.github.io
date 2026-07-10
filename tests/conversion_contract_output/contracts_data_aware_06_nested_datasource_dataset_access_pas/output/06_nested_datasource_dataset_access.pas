unit ContractNestedDataSourceDataSetAccess;
interface
uses Data.DB, FMX.Controls, FMX.Edit, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes,
  System.SysUtils, System.Variants;
type TContractNestedDataSourceDataSetAccess = class(TForm) DataSource1: TDataSource; DBEdit1: TEdit; procedure Run; end;
implementation
procedure TContractNestedDataSourceDataSetAccess.Run;
begin
  // FMX manual review: DBEdit1.DataSource.DataSet.First;
end;
end.
