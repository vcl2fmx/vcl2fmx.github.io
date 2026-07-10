program GPSTimeSync;

uses
  FMX.Forms,
  SysUtils,
  Winapi.Windows,
  FMX.Dialogs,
  GPSControlPanel in 'GPSControlPanel.pas' {frmGPSControl};

{$R *.res}

var
  LockHandle: THandle;
  ConfigFile: string;
begin

    ReportMemoryLeaksOnShutdown := True;
    // Try to open (or create) a lock file with zero sharing:
    LockHandle := CreateFile(
    PChar(ExtractFilePath(ParamStr(0)) + 'GPSTimeSync.lock'),
    GENERIC_READ or GENERIC_WRITE,
    0,            // dwShareMode = 0 ? exclusive
    nil,          // lpSecurityAttributes
    OPEN_ALWAYS,  // open or create
    FILE_ATTRIBUTE_NORMAL,
    0
  );

  // If INVALID_HANDLE_VALUE, the file is already locked ? another instance is running
  if LockHandle = INVALID_HANDLE_VALUE then
  begin
    ShowMessage('Another instance of this application is running.');
    Exit;
    //Halt;
  end;

  try
    // Check for first-run config file
    ConfigFile := ExtractFilePath(ParamStr(0)) + 'gps_settings.ini';
    if not FileExists(ConfigFile) then
    begin
      // Launch the main form for parameter editing
      Application.Initialize;


      Application.CreateForm(TfrmGPSControl, frmGPSControl);

      Application.Run;
      Exit;
    end;

    Application.Initialize;


    Application.CreateForm(TfrmGPSControl, frmGPSControl);
    Application.Run;
  finally
    // Release the lock on exit
    if LockHandle <> INVALID_HANDLE_VALUE then
      CloseHandle(LockHandle);
  end;
end.

