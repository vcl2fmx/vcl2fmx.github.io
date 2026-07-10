unit GPSControlPanel;
{
  GPSControlPanel.pas
  GPS Time Sync v1.20 02/01/2026
  by Thomas H. Martin
  This application is written for use with a VK-172 GPS dongle.  It looks
  for explicit hardware ID and signature to identify what port the
  dongle is put on.  Auto-detect/plug and play with other dongles will not
  work with the current code and will have to be set by hand by selecting
  one of the COM ports from the dropdown box.
}
interface
uses FMX.Controls, FMX.Dialogs, FMX.Edit, FMX.Forms, FMX.Graphics, FMX.ListBox, FMX.Memo,
  FMX.Objects, FMX.StdCtrls, FMX.Types, System.Classes, System.DateUtils, System.Diagnostics,
  System.Generics.Collections, System.Math, System.StrUtils, System.SyncObjs, System.SysUtils,
  System.TimeSpan, System.Types, System.UIConsts, System.UITypes, System.Variants, System.Win.ComObj,
  Winapi.ActiveX, Winapi.Windows;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
  TfrmGPSControl = class(TForm)
    lblLatLong: TLabel;
    lblFixQuality: TLabel;
    lblFixMode: TLabel;
    lblSatInUse: TLabel;
    lblSatInView: TLabel;
    lblAltitude: TLabel;
    lblBaudRate: TLabel;
    Panel1: TPanel;
    lblHeader: TLabel;
    Label1: TLabel;
    btnHideToTray: TButton;
    btnSave: TButton;
    btnClose: TButton;
    GroupBox1: TGroupBox;
    lblCOMPort: TLabel;
    lblInterval: TLabel;
    lblDriftSeconds: TLabel;
    lblTimeType: TLabel;
    lblEnableLogging: TLabel;
    edtComPort: TComboBox;
    edtSyncInterval: TEdit;
    edtDriftSeconds: TEdit;
    rdoSetUTC: TRadioButton;
    rdoSetLocal: TRadioButton;
    edtEnableLogging: TCheckBox;
    GroupBox2: TGroupBox;
    memLogWindow: TMemo;
    shpLED: TEllipse;
    tmTimeCheck: TTimer;
    tmClock: TTimer;
    LEDFlashTimer: TTimer;
    edtFixQuality: TEdit;
    edtFixMode: TEdit;
    edtSatInUse: TEdit;
    edtSatInView: TEdit;
    txtLatLong: TEdit;
    txtDate: TEdit;
    edtAltitude: TEdit;
    edtBaudRate: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    lblSystemTime: TLabel;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LEDFlashTimerTimer(Sender: TObject);
    procedure tmClockTimer(Sender: TObject);
    procedure tmTimeCheckTimer(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnHideToTrayClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    FComHandle: THandle;
    FInBuf: AnsiString;
    FLastValidSentenceTick: UInt64;
    FGpsUtc: TDateTime;
    FHaveGpsTime: Boolean;
    FLastSatInView: Integer;
    // SIMPLE LED BEHAVIOR (per your request):
    // - red while waiting
    // - green immediately on valid sentence
    // - tmClock forces it back to red each second
    FGreenSinceLastClock: Boolean;
    // Logging paths (restored behavior like v1.17)
    IniFilePath: string;
    GPSLogFilePath: string;
    // Time sync bookkeeping (restored behavior like v1.17)
    FLastLoggedMinute: Word;
    FLastClockSecond: Word;
    // Auto-detected COM port (VK-172)
    VK172ComPort: string;
    procedure PopulateComPorts;
    procedure ComPortChanged(Sender: TObject);
    procedure FindVK172GPSDongle;
    function OpenSerial(const APort: string; ABaud: Integer): Boolean;
    procedure CloseSerial;
    function SerialIsOpen: Boolean;
    function ReadSerialAvailable(out AData: AnsiString): Boolean;
    procedure ProcessIncoming(const AChunk: AnsiString);
    procedure ProcessLine(const ALine: AnsiString);
    function IsValidNMEASentence(const S: AnsiString): Boolean;
    function NMEAChecksumOK(const S: AnsiString): Boolean;
    procedure UpdateLedState;
    procedure UpdateDisplayedTime;
    procedure LogLine(const S: AnsiString);
    procedure AddToLog(const MsgLine: string);
    procedure SyncSystemTime(const GPSTimeUTC: TDateTime);
    // NMEA helpers
    function SplitCSV(const S: AnsiString): TArray<AnsiString>;
    function ParseRMC(const Fields: TArray<AnsiString>): Boolean;
    function ParseGGA(const Fields: TArray<AnsiString>): Boolean;
    function ParseGSV(const Fields: TArray<AnsiString>): Boolean;
    function NmeaCoordToDecimal(const Coord, Hemi: AnsiString; out DecVal: Double): Boolean;
    function NmeaDateTimeToUTC(const TimeHHMMSS, DateDDMMYY: AnsiString; out DT: TDateTime): Boolean;
    function BaudFromEdit: Integer;
    function SelectedComPort: string;
    function WantLocalTime: Boolean;
    // Replace TTimeZone usage (so this compiles everywhere)
    function UTCToLocalDT(const UtcDT: TDateTime): TDateTime;
    function LocalToUTCDT(const LocalDT: TDateTime): TDateTime;
  public
  end;
var
  frmGPSControl: TfrmGPSControl;
implementation
{$R *.fmx}

const
  LED_VALID_WINDOW_MS = 1500;  // kept (used for timestamp), but LED behavior is simplified
  MAX_LOG_LINES       = 500;
procedure TMemo.Clear;
begin
  Lines.Clear;
end;
procedure TfrmGPSControl.AddToLog(const MsgLine: string);
var
  F: TextFile;
  TimeStamp, FinalLine: string;
begin
  if GPSLogFilePath = '' then
    GPSLogFilePath := ExtractFilePath(ParamStr(0)) + 'GPSTimeChange.log';
  TimeStamp := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
  FinalLine := TimeStamp + ' - ' + MsgLine;
  AssignFile(F, GPSLogFilePath);
  if FileExists(GPSLogFilePath) then
    Append(F)
  else
    Rewrite(F);
  try
    Writeln(F, FinalLine);
  finally
    CloseFile(F);
  end;
end;
procedure TfrmGPSControl.SyncSystemTime(const GPSTimeUTC: TDateTime);
var
  Sys: TSystemTime;
  TargetLocal: TDateTime;
  TargetUTC: TDateTime;
  BeforeLocal: TDateTime;
  Msg: string;
begin
  // Match v1.17 style: log "from" system local time to GPS-derived target.
  BeforeLocal := Now;
  if WantLocalTime then
  begin
    TargetLocal := UTCToLocalDT(GPSTimeUTC);
    DateTimeToSystemTime(TargetLocal, Sys);
    if SetLocalTime(Sys) then
      Msg := Format('System time updated by GPS from %s to %s',
        [FormatDateTime('hh:nn:ss', BeforeLocal), FormatDateTime('hh:nn:ss', TargetLocal)])
    else
      Msg := 'ERROR setting local time; run as admin';
    AddToLog(Msg);
  end
  else
  begin
    // User wants to keep clock in UTC
    TargetUTC := GPSTimeUTC;
    DateTimeToSystemTime(TargetUTC, Sys);
    if SetSystemTime(Sys) then
      Msg := Format('System UTC updated by GPS from %s to %s',
        [FormatDateTime('hh:nn:ss', LocalToUTCDT(BeforeLocal)), FormatDateTime('hh:nn:ss', TargetUTC)])
    else
      Msg := 'ERROR setting system UTC; run as admin';
    AddToLog(Msg);
  end;
end;
procedure TfrmGPSControl.FindVK172GPSDongle;
var
  Locator, WMIService, QueryResult, Device: OLEVariant;
  Enum: IEnumVariant;
  Value: Cardinal;
begin
  VK172ComPort := '';
  try
    Locator    := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := Locator.ConnectServer('.', 'root\CIMV2');
    QueryResult := WMIService.ExecQuery(
      'SELECT DeviceID, PNPDeviceID ' +
      'FROM   Win32_SerialPort ' +
      'WHERE  PNPDeviceID LIKE ''%VID_1546&PID_01A7%''' );
    Enum := IUnknown(QueryResult._NewEnum) as IEnumVariant;
    while Enum.Next(1, Device, Value) = 0 do
    begin
      VK172ComPort := VarToStr(Device.DeviceID); // e.g. COM3
      Exit;
    end;
  except
    on E: Exception do
    begin
      VK172ComPort := '';
      AddToLog('Error detecting serial ports: ' + E.Message);
    end;
  end;
end;
procedure TfrmGPSControl.FormCreate(Sender: TObject);
var
  SyncSec: Integer;
  Idx: Integer;
begin
  FComHandle := INVALID_HANDLE_VALUE;
  FInBuf := '';
  FLastValidSentenceTick := 0;
  FHaveGpsTime := False;
  FLastSatInView := 0;
  FGreenSinceLastClock := False;
  IniFilePath    := ExtractFilePath(ParamStr(0)) + 'gps_settings.ini';
  GPSLogFilePath := ExtractFilePath(ParamStr(0)) + 'GPSTimeChange.log';
  FLastLoggedMinute := 61;
  FLastClockSecond := 61;
  // Make the LED round and default red
  // FMX: redundant VCL Shape assignment omitted; shpLED is generated as TEllipse.
  shpLED.Fill.Color := claRed;
  shpLED.Stroke.Color := claRed;
  // Populate COM ports in the combo
  PopulateComPorts;
  // Auto-detect the VK-172 and override selection if found
  FindVK172GPSDongle;
  if VK172ComPort <> '' then
  begin
    Idx := edtComPort.Items.IndexOf(VK172ComPort);
    if Idx < 0 then
      edtComPort.Items.Add(VK172ComPort);
    edtComPort.ItemIndex := edtComPort.Items.IndexOf(VK172ComPort);
  end
  else
  begin
    AddToLog('VK-172 GPS dongle not detected (VID_1546&PID_01A7). Select COM port manually.');
    // keep prior selection; show a one-time message (like v1.17)
    ShowMessage('VK-172 GPS dongle not detected.' + sLineBreak +
                'Select the COM port manually and click Save.');
  end;
  // Hook change handler without touching the DFM
  edtComPort.OnChange := ComPortChanged;
  // Enable the poller (DFM has it disabled)
  LEDFlashTimer.Enabled := True;
  // Keep polling quick (DFM had 150ms already; leave it)
  if LEDFlashTimer.Interval < 50 then
    LEDFlashTimer.Interval := 150;
  // tmClock default is 1000ms if not set; enforce 1 second
  tmClock.Interval := 1000;
  tmClock.Enabled := True;
  // Time check interval (seconds -> ms), default 60
  SyncSec := StrToIntDef(Trim(edtSyncInterval.Text), 60);
  if SyncSec < 1 then
    SyncSec := 60;
  tmTimeCheck.Interval := SyncSec * 1000;
  tmTimeCheck.Enabled := True;
  // Open immediately using current selections
  if not OpenSerial(SelectedComPort, BaudFromEdit) then
    AddToLog('Cannot open COM port ' + SelectedComPort + '. Select it manually and click Save.');
  // Show initial time/date
  UpdateDisplayedTime;
  // Start minimized to tray (simple)
  WindowState := TWindowState.wsMinimized;
  AddToLog('Application started');
end;
procedure TfrmGPSControl.FormDestroy(Sender: TObject);
begin
  CloseSerial;
  AddToLog('Application terminated');
end;
procedure TfrmGPSControl.PopulateComPorts;
var
  I: Integer;
  Existing: TStringList;
begin
  Existing := TStringList.Create;
  try
    for I := 0 to edtComPort.Items.Count - 1 do
      Existing.Add(edtComPort.Items[I]);
    edtComPort.Items.BeginUpdate;
    try
      edtComPort.Items.Clear;
      for I := 1 to 30 do
        edtComPort.Items.Add(Format('COM%d', [I]));
      if Existing.Count > 0 then
      begin
        for I := 0 to Existing.Count - 1 do
          if edtComPort.Items.IndexOf(Existing[I]) < 0 then
            edtComPort.Items.Add(Existing[I]);
      end;
      if edtComPort.ItemIndex < 0 then
      begin
        if edtComPort.Items.IndexOf('COM3') >= 0 then
          edtComPort.ItemIndex := edtComPort.Items.IndexOf('COM3')
        else
          edtComPort.ItemIndex := 0;
      end;
    finally
      edtComPort.Items.EndUpdate;
    end;
  finally
    Existing.Free;
  end;
end;
procedure TfrmGPSControl.ComPortChanged(Sender: TObject);
begin
  CloseSerial;
  if not OpenSerial(SelectedComPort, BaudFromEdit) then
    AddToLog('Cannot open COM port ' + SelectedComPort + '.');
end;
function TfrmGPSControl.BaudFromEdit: Integer;
begin
  Result := StrToIntDef(Trim(edtBaudRate.Text), 9600);
  if Result <= 0 then
    Result := 9600;
end;
function TfrmGPSControl.SelectedComPort: string;
begin
  Result := Trim(edtComPort.Text);
  if Result = '' then
    Result := 'COM3';
end;
function TfrmGPSControl.WantLocalTime: Boolean;
begin
  Result := rdoSetLocal.IsChecked and not rdoSetUTC.IsChecked;
end;
function TfrmGPSControl.SerialIsOpen: Boolean;
begin
  Result := (FComHandle <> INVALID_HANDLE_VALUE) and (FComHandle <> 0);
end;
function TfrmGPSControl.OpenSerial(const APort: string; ABaud: Integer): Boolean;
var
  PortPath: string;
  DCB: TDCB;
  Timeouts: TCOMMTIMEOUTS;
begin
  Result := False;
  CloseSerial;
  PortPath := '\\.\' + APort;
  FComHandle := CreateFile(PChar(PortPath),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    0,
    0);
  if not SerialIsOpen then
    Exit;
  SetupComm(FComHandle, 8192, 8192);
  ZeroMemory(@DCB, SizeOf(DCB));
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FComHandle, DCB) then
  begin
    CloseSerial;
    Exit;
  end;
  DCB.BaudRate := ABaud;
  DCB.ByteSize := 8;
  DCB.Parity := NOPARITY;
  DCB.StopBits := ONESTOPBIT;
  // Raw mode
  DCB.Flags := DCB.Flags or $00000001; // fBinary bit 0
  if not SetCommState(FComHandle, DCB) then
  begin
    CloseSerial;
    Exit;
  end;
  ZeroMemory(@Timeouts, SizeOf(Timeouts));
  Timeouts.ReadIntervalTimeout := 10;
  Timeouts.ReadTotalTimeoutMultiplier := 0;
  Timeouts.ReadTotalTimeoutConstant := 10;
  Timeouts.WriteTotalTimeoutMultiplier := 0;
  Timeouts.WriteTotalTimeoutConstant := 10;
  SetCommTimeouts(FComHandle, Timeouts);
  PurgeComm(FComHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
  // Reflect the active baud rate in the UI
  edtBaudRate.Text := IntToStr(ABaud);
  Result := True;
end;
procedure TfrmGPSControl.CloseSerial;
begin
  if SerialIsOpen then
  begin
    CloseHandle(FComHandle);
    FComHandle := INVALID_HANDLE_VALUE;
  end;
end;
function TfrmGPSControl.ReadSerialAvailable(out AData: AnsiString): Boolean;
var
  Errors: DWORD;
  Stat: TCOMSTAT;
  ToRead, ReadNow: DWORD;
  Buf: TBytes;
begin
  Result := False;
  AData := '';
  if not SerialIsOpen then
    Exit;
  Errors := 0;
  ZeroMemory(@Stat, SizeOf(Stat));
  if not ClearCommError(FComHandle, Errors, @Stat) then
    Exit;
  ToRead := Stat.cbInQue;
  if ToRead = 0 then
    Exit;
  // cap read size
  ToRead := Min(ToRead, DWORD(4096));
  SetLength(Buf, ToRead);
  ReadNow := 0;
  if not ReadFile(FComHandle, Buf[0], ToRead, ReadNow, nil) then
    Exit;
  if ReadNow = 0 then
    Exit;
  SetString(AData, PAnsiChar(@Buf[0]), ReadNow);
  Result := True;
end;
procedure TfrmGPSControl.LEDFlashTimerTimer(Sender: TObject);
var
  Chunk: AnsiString;
begin
  // Poll the serial port frequently
  if ReadSerialAvailable(Chunk) then
    ProcessIncoming(Chunk);
end;
procedure TfrmGPSControl.tmClockTimer(Sender: TObject);
var
  H, M, S, MS: Word;
begin
  // Show time once per second
  UpdateDisplayedTime;
  // SIMPLE LED behavior:
  // - each second, force RED (waiting)
  // - any valid sentence flips it GREEN immediately (in ProcessLine)
  UpdateLedState;
  // Keep v1.17 behavior: update once per second and track last second
  DecodeTime(Now, H, M, S, MS);
  FLastClockSecond := S;
end;
procedure TfrmGPSControl.tmTimeCheckTimer(Sender: TObject);
var
  SystemUTC: TDateTime;
  DriftSec: Integer;
  Delta: Int64;
  H, M, S, MS: Word;
begin
  // Keep the minimal reconnect behavior too
  if not SerialIsOpen then
    OpenSerial(SelectedComPort, BaudFromEdit);
  // Only do drift check when we actually have GPS time
  if not FHaveGpsTime then
    Exit;
  // System UTC computed from local clock
  SystemUTC := LocalToUTCDT(Now);
  DriftSec := StrToIntDef(Trim(edtDriftSeconds.Text), 2);
  if DriftSec < 1 then
    DriftSec := 1;
  Delta := Abs(SecondsBetween(SystemUTC, FGpsUtc));
  // If drift exceeds threshold, sync the system clock and log like v1.17 did
  if Delta >= DriftSec then
    SyncSystemTime(FGpsUtc)
  else
  //Modified this NOT to log each time check; not necessary 02-05.2026 thm
  begin
    {// Optional periodic status logging (once per minute), same spirit as v1.17
    DecodeTime(Now, H, M, S, MS);
    if M <> FLastLoggedMinute then
    begin
      FLastLoggedMinute := M;
      AddToLog(Format('System local: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
      AddToLog(Format('GPS UTC:      %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', FGpsUtc)]));
      AddToLog(Format('Drift:        %d sec', [Delta]));
    end;}
  end;
end;
procedure TfrmGPSControl.UpdateLedState;
begin
  // Force LED to red once per second; green is set immediately on receive.
  shpLED.Fill.Color := claRed;
  shpLED.Stroke.Color := claRed;
  shpLED.Repaint;
  // clear the "green since last clock" marker
  FGreenSinceLastClock := False;
end;
function TfrmGPSControl.UTCToLocalDT(const UtcDT: TDateTime): TDateTime;
var
  STUtc, STLocal: TSystemTime;
begin
  DateTimeToSystemTime(UtcDT, STUtc);
  if SystemTimeToTzSpecificLocalTime(nil, STUtc, STLocal) then
    Result := SystemTimeToDateTime(STLocal)
  else
    Result := UtcDT;
end;
function TfrmGPSControl.LocalToUTCDT(const LocalDT: TDateTime): TDateTime;
var
  STLocal, STUtc: TSystemTime;
begin
  DateTimeToSystemTime(LocalDT, STLocal);
  if TzSpecificLocalTimeToSystemTime(nil, STLocal, STUtc) then
    Result := SystemTimeToDateTime(STUtc)
  else
    Result := LocalDT;
end;
procedure TfrmGPSControl.UpdateDisplayedTime;
var
  ShowDT: TDateTime;
begin
  if FHaveGpsTime then
  begin
    if WantLocalTime then
      ShowDT := UTCToLocalDT(FGpsUtc)
    else
      ShowDT := FGpsUtc;
  end
  else
  begin
    ShowDT := Now;
  end;
  txtDate.Text := FormatDateTime('m/d/yyyy', ShowDT);
  lblSystemTime.Text := FormatDateTime('hh:nn:ss', ShowDT);
end;
procedure TfrmGPSControl.ProcessIncoming(const AChunk: AnsiString);
var
  P: Integer;
  Line: AnsiString;
begin
  FInBuf := FInBuf + AChunk;
  while True do
  begin
    P := Pos(#10, FInBuf);
    if P = 0 then
      Break;
    Line := Copy(FInBuf, 1, P - 1);
    Delete(FInBuf, 1, P);
    Line := AnsiString(StringReplace(string(Line), #13, '', [rfReplaceAll]));
    Line := Trim(Line);
    if Line <> '' then
      ProcessLine(Line);
  end;
end;
procedure TfrmGPSControl.ProcessLine(const ALine: AnsiString);
var
  Fields: TArray<AnsiString>;
begin
  if not IsValidNMEASentence(ALine) then
    Exit;
  // mark receive time (kept)
  FLastValidSentenceTick := GetTickCount64;
  // SIMPLE LED: GREEN immediately on any valid sentence
  shpLED.Fill.Color := claLime;
  shpLED.Stroke.Color := claLime;
  shpLED.Repaint;
  FGreenSinceLastClock := True;
  if edtEnableLogging.IsChecked then
    LogLine(ALine);
  Fields := SplitCSV(ALine);
  if Length(Fields) = 0 then
    Exit;
  if StartsText('$GPRMC', string(Fields[0])) or StartsText('$GNRMC', string(Fields[0])) then
    ParseRMC(Fields)
  else if StartsText('$GPGGA', string(Fields[0])) or StartsText('$GNGGA', string(Fields[0])) then
    ParseGGA(Fields)
  else if StartsText('$GPGSV', string(Fields[0])) or StartsText('$GNGSV', string(Fields[0])) then
    ParseGSV(Fields);
end;
procedure TfrmGPSControl.LogLine(const S: AnsiString);
begin
  memLogWindow.Lines.BeginUpdate;
  try
    memLogWindow.Lines.Add(string(S));
    while memLogWindow.Lines.Count > MAX_LOG_LINES do
      memLogWindow.Lines.Delete(0);
    // FORCE scroll to bottom (extra-safe: caret + SB_BOTTOM)
    memLogWindow.SelStart := Length(memLogWindow.Text);
    memLogWindow.SelLength := 0;
    memLogWindow.GoToTextEnd;
  finally
    memLogWindow.Lines.EndUpdate;
  end;
end;
function TfrmGPSControl.IsValidNMEASentence(const S: AnsiString): Boolean;
begin
  Result := (S <> '') and (S[1] = '$') and (Pos('*', S) > 0) and NMEAChecksumOK(S);
end;
function TfrmGPSControl.NMEAChecksumOK(const S: AnsiString): Boolean;
var
  StarPos: Integer;
  I: Integer;
  CS: Byte;
  HexStr: AnsiString;
  Given: Integer;
begin
  Result := False;
  StarPos := Pos('*', S);
  if (StarPos <= 2) or (StarPos + 2 > Length(S)) then
    Exit;
  CS := 0;
  for I := 2 to StarPos - 1 do
    CS := CS xor Byte(S[I]);
  HexStr := Copy(S, StarPos + 1, 2);
  if Length(HexStr) <> 2 then
    Exit;
  try
    Given := StrToInt('$' + string(HexStr));
  except
    Exit;
  end;
  Result := (Given and $FF) = CS;
end;
function TfrmGPSControl.SplitCSV(const S: AnsiString): TArray<AnsiString>;
var
  Parts: TArray<string>;
  I: Integer;
begin
  Parts := string(S).Split([',']);
  SetLength(Result, Length(Parts));
  for I := 0 to High(Parts) do
    Result[I] := AnsiString(Parts[I]);
end;
function TfrmGPSControl.NmeaCoordToDecimal(const Coord, Hemi: AnsiString; out DecVal: Double): Boolean;
var
  S: string;
  P: Integer;
  Min: Double;
  DegInt: Integer;
begin
  Result := False;
  DecVal := 0;
  S := string(Coord);
  if S = '' then Exit;
  P := Pos('.', S);
  if P = 0 then
    P := Length(S) + 1;
  if P < 3 then Exit;
  try
    DegInt := StrToInt(Copy(S, 1, (P - 1) - 2));
    Min := StrToFloat(Copy(S, (P - 1) - 1, MaxInt), TFormatSettings.Invariant);
  except
    Exit;
  end;
  DecVal := DegInt + (Min / 60.0);
  Result := True;
end;
function TfrmGPSControl.NmeaDateTimeToUTC(const TimeHHMMSS, DateDDMMYY: AnsiString; out DT: TDateTime): Boolean;
var
  TStr, DStr: string;
  HH, NN, SS: Word;
  DD, MM: Word;
  YY: Integer;
begin
  Result := False;
  DT := 0;
  TStr := string(TimeHHMMSS);
  DStr := string(DateDDMMYY);
  if (Length(TStr) < 6) or (Length(DStr) <> 6) then
    Exit;
  try
    HH := StrToInt(Copy(TStr, 1, 2));
    NN := StrToInt(Copy(TStr, 3, 2));
    SS := StrToInt(Copy(TStr, 5, 2));
    DD := StrToInt(Copy(DStr, 1, 2));
    MM := StrToInt(Copy(DStr, 3, 2));
    YY := StrToInt(Copy(DStr, 5, 2));
    if YY < 80 then
      YY := 2000 + YY
    else
      YY := 1900 + YY;
    DT := EncodeDate(YY, MM, DD) + EncodeTime(HH, NN, SS, 0);
    Result := True;
  except
    Exit;
  end;
end;
function TfrmGPSControl.ParseRMC(const Fields: TArray<AnsiString>): Boolean;
var
  Status: AnsiString;
  LatStr, NS, LonStr, EW: AnsiString;
  LatDec, LonDec: Double;
  TimeStr, DateStr: AnsiString;
  DT: TDateTime;
begin
  Result := False;
  if Length(Fields) < 10 then
    Exit;
  TimeStr := Fields[1];
  Status := Fields[2];
  LatStr := Fields[3];
  NS := Fields[4];
  LonStr := Fields[5];
  EW := Fields[6];
  DateStr := Fields[9];
  if NmeaDateTimeToUTC(TimeStr, DateStr, DT) then
  begin
    FGpsUtc := DT;
    FHaveGpsTime := True;
  end;
  if NmeaCoordToDecimal(LatStr, NS, LatDec) and NmeaCoordToDecimal(LonStr, EW, LonDec) then
  begin
    txtLatLong.Text :=
      Format('%.4f° %s, %.4f° %s',
        [Abs(LatDec), string(NS),
         Abs(LonDec), string(EW)]);
  end;
  if SameText(string(Status), 'A') then
    edtFixMode.Text := 'GPS'
  else
    edtFixMode.Text := 'None';
  Result := True;
end;
function TfrmGPSControl.ParseGGA(const Fields: TArray<AnsiString>): Boolean;
var
  FixQ: Integer;
  SatsUsed: Integer;
  AltM: Double;
  AltFt: Double;
begin
  Result := False;
  if Length(Fields) < 11 then
    Exit;
  FixQ := StrToIntDef(string(Fields[6]), 0);
  SatsUsed := StrToIntDef(string(Fields[7]), 0);
  case FixQ of
    0: edtFixQuality.Text := 'None';
    1: edtFixQuality.Text := 'GPS';
    2: edtFixQuality.Text := 'DGPS';
    4: edtFixQuality.Text := 'RTK';
    5: edtFixQuality.Text := 'Float RTK';
  else
    edtFixQuality.Text := 'GPS';
  end;
  edtSatInUse.Text := IntToStr(SatsUsed);
  AltM := StrToFloatDef(string(Fields[9]), 0, TFormatSettings.Invariant);
  AltFt := AltM * 3.28084;
  if AltFt <> 0 then
    edtAltitude.Text := Format('%.1f ft', [AltFt]);
  Result := True;
end;
function TfrmGPSControl.ParseGSV(const Fields: TArray<AnsiString>): Boolean;
var
  TotalInView: Integer;
begin
  Result := False;
  if Length(Fields) < 4 then
    Exit;
  TotalInView := StrToIntDef(string(Fields[3]), 0);
  if TotalInView > 0 then
  begin
    FLastSatInView := TotalInView;
    edtSatInView.Text := IntToStr(FLastSatInView);
  end;
  Result := True;
end;
procedure TfrmGPSControl.btnCloseClick(Sender: TObject);
begin
  Close;
end;
procedure TfrmGPSControl.btnHideToTrayClick(Sender: TObject);
begin
  WindowState := TWindowState.wsMinimized;
end;
procedure TfrmGPSControl.TrayIcon1Click(Sender: TObject);
begin
  Show;
  BringToFront;
end;
procedure TfrmGPSControl.btnSaveClick(Sender: TObject);
var
  SyncSec: Integer;
begin
  // Apply interval changes immediately (matches v1.17 behavior in spirit)
  SyncSec := StrToIntDef(Trim(edtSyncInterval.Text), 60);
  if SyncSec < 1 then
    SyncSec := 60;
  tmTimeCheck.Interval := SyncSec * 1000;
  CloseSerial;
  if not OpenSerial(SelectedComPort, BaudFromEdit) then
  begin
    AddToLog('Cannot open COM port ' + SelectedComPort + '.');
    ShowMessage('Cannot open COM port ' + SelectedComPort + '.');
  end;
  AddToLog('Settings saved');
end;
end.
