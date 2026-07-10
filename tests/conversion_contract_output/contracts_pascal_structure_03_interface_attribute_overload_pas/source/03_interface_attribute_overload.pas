unit ContractPascalStructureInterfaceAttributeOverload;

interface

uses
  System.SysUtils, System.Classes;

type
  IContractWorker = interface
    ['{D73C74B4-9F6E-4BB6-832C-47F59C716F3E}']
    procedure Execute;
  end;

  TContractWorker = class(TInterfacedObject, IContractWorker)
  public
    [Obsolete('contract attribute boundary')]
    procedure Execute; overload;
    procedure Execute(const AText: string); overload;
  end;

implementation

procedure TContractWorker.Execute;
begin
end;

procedure TContractWorker.Execute(const AText: string);
begin
  if AText <> '' then
    Execute;
end;

end.
