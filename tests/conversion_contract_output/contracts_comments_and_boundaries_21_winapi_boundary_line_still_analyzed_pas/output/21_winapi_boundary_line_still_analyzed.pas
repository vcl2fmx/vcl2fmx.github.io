unit ContractWinApiBoundaryLineStillAnalyzed;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractWinApiBoundaryLineStillAnalyzed = class
  private
    FHandle: THandle;
  public
    procedure DisableUnsupportedBlock;
    procedure CloseHandleAfterBoundary;
  end;
implementation
procedure TContractWinApiBoundaryLineStillAnalyzed.DisableUnsupportedBlock;
begin
  // FMX: Use TFile, TStream, or TPath from System.IOUtils after manual review
  // Original: CreateFile('legacy.txt',
  // GENERIC_READ,
  // 0,
  // nil,
  // OPEN_EXISTING,
  // FILE_ATTRIBUTE_NORMAL,
  // 0);
end;
procedure TContractWinApiBoundaryLineStillAnalyzed.CloseHandleAfterBoundary;
begin
  CloseHandle(FHandle);
end;
end.
