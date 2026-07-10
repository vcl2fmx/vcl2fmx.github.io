unit ContractWinApiBoundaryLineStillAnalyzed;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

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
  CreateFile('legacy.txt',
    GENERIC_READ,
    0,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);
end;

procedure TContractWinApiBoundaryLineStillAnalyzed.CloseHandleAfterBoundary;
begin
  CloseHandle(FHandle);
end;

end.
