unit ContractTWMRecordMessageDeclaration;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractTWMRecordMessageDeclaration = class
  private
  // FMX manual review: procedure WMSize(var Message: TWMSize); message WM_SIZE;
  public
    procedure Run;
  end;
implementation
  // FMX manual review: procedure TContractTWMRecordMessageDeclaration.WMSize(var Message: TWMSize);
  // FMX manual review: begin
  // FMX manual review: Writeln(Message.Width);
  // FMX manual review: end;
  // FMX manual review: 
procedure TContractTWMRecordMessageDeclaration.Run;
begin
  Writeln('message declaration');
end;
end.
