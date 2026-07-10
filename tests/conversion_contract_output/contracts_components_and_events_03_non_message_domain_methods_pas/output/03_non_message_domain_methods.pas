unit ContractNonMessageDomainMethods;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
