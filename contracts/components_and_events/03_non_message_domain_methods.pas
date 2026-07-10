unit ContractNonMessageDomainMethods;

interface

uses
  System.SysUtils, System.Classes;

type
  TContractNonMessageDomainMethods = class
  public
    procedure DispatchMessage(const AName: string);
    procedure TranslateMessage(const AName: string);
    procedure PeekMessage(const AName: string);
  end;

implementation

procedure TContractNonMessageDomainMethods.DispatchMessage(const AName: string);
begin
  Writeln(AName);
end;

procedure TContractNonMessageDomainMethods.TranslateMessage(const AName: string);
begin
  Writeln(AName);
end;

procedure TContractNonMessageDomainMethods.PeekMessage(const AName: string);
begin
  Writeln(AName);
end;

end.

