unit ContractNestedDataSourceDataSetAccess;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Data.DB, Vcl.DBCtrls;
type TContractNestedDataSourceDataSetAccess = class(TForm) DataSource1: TDataSource; DBEdit1: TDBEdit; procedure Run; end;
implementation
procedure TContractNestedDataSourceDataSetAccess.Run;
begin
  DBEdit1.DataSource.DataSet.First;
end;
end.

