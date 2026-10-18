program V7HelpServerContracts;
{$APPTYPE CONSOLE}

uses
  System.StartUpCopy, Winapi.Windows, IdHTTP, IdTCPClient,
  System.SysUtils, System.IOUtils, System.Math, System.UITypes, FMX.Controls, DAT.Components.Core,
  FMX.Forms, FMX.StdCtrls, FMX.TextLayout, FMX.Types, System.Types,
  MainForm in '..\MainForm.pas' {frmMain},
  Converter.Advanced.CriticalAreas in '..\Converter.Advanced.CriticalAreas.pas',
  Converter.Advanced.DataAware in '..\Converter.Advanced.DataAware.pas',
  Converter.Advanced.ThirdParty in '..\Converter.Advanced.ThirdParty.pas',
  Converter.Advanced.WinAPI in '..\Converter.Advanced.WinAPI.pas',
  Converter.Core.Engine in '..\Converter.Core.Engine.pas',
  Converter.Core.FileManager in '..\Converter.Core.FileManager.pas',
  Converter.Core.Integration in '..\Converter.Core.Integration.pas',
  Converter.Core.Types in '..\Converter.Core.Types.pas',
  Converter.Mapper.Component in '..\Converter.Mapper.Component.pas',
  Converter.Mapper.Catalog in '..\Converter.Mapper.Catalog.pas',
  Converter.Parser.DFM in '..\Converter.Parser.DFM.pas',
  Converter.Generator.FMX in '..\Converter.Generator.FMX.pas',
  Converter.Parser.Pascal in '..\Converter.Parser.Pascal.pas',
  Converter.Project.Generator in '..\Converter.Project.Generator.pas',
  Converter.Reporting.Html in '..\Converter.Reporting.Html.pas',
  Converter.Reporting.Json in '..\Converter.Reporting.Json.pas',
  Converter.Reporting.Model in '..\Converter.Reporting.Model.pas',
  Converter.Reporting.Text in '..\Converter.Reporting.Text.pas',
  Converter.Rewrite.AutoFixes in '..\Converter.Rewrite.AutoFixes.pas',
  Converter.Rewrite.Compatibility in '..\Converter.Rewrite.Compatibility.pas',
  Converter.Rewrite.LiveBindings in '..\Converter.Rewrite.LiveBindings.pas',
  Converter.Rewrite.RuntimeNormalization in '..\Converter.Rewrite.RuntimeNormalization.pas',
  Converter.Rewrite.UsesClause in '..\Converter.Rewrite.UsesClause.pas';


var
  Client: TIdHTTP;
  Socket: TIdTCPClient;
  Port: Integer;
  Base, Content, Pack, Stage: string;
  CheckCount: Integer;

procedure Check(Condition: Boolean; const Description: string);
begin
  if not Condition then raise Exception.Create(Description);
  Inc(CheckCount);
end;

procedure CheckRaw(const Method, Path, Host: string; ExpectedStatus: Integer);
var Status: string;
begin
  Stage := Method + ' ' + Path;
  Socket.Connect;
  try
    Socket.IOHandler.Write(Method + ' ' + Path + ' HTTP/1.1'#13#10 +
      'Host: ' + Host + #13#10'Connection: close'#13#10#13#10);
    Status := Socket.IOHandler.ReadLn;
    Check(Status.Contains(' ' + IntToStr(ExpectedStatus) + ' '), Method + ' ' + Path + ': ' + Status);
  finally
    Socket.Disconnect;
    Socket.IOHandler.InputBuffer.Clear;
  end;
end;

begin
  try
    Stage := 'Application initialization';
    Application.Initialize;
    Stage := 'Form creation';
    frmMain := TfrmMain.Create(nil);
    try
      Check(not frmMain.HelpServer.Active, 'Help listener starts inactive');
      Check(frmMain.HelpServer.Bindings.Count = 1, 'One loopback binding');
      Check(frmMain.HelpServer.Bindings[0].IP = '127.0.0.1', 'Loopback binding only');
      Stage := 'Start listener';
      frmMain.HelpServer.Active := True;
      Port := frmMain.HelpServer.Bindings[0].Port;
      Check(Port > 0, 'Operating system assigned a port');
      Base := 'http://127.0.0.1:' + IntToStr(Port);
      Client := TIdHTTP.Create(nil);
      Socket := TIdTCPClient.Create(nil);
      try
        Client.ReadTimeout := 5000;
        Socket.Host := '127.0.0.1';
        Socket.Port := Port;
        Socket.ReadTimeout := 5000;
        for Pack in TDirectory.GetFiles(ParamStr(1), '*.json') do
        begin
          Stage := 'Request ' + Pack;
          Content := Client.Get(Base + '/index.html?lang=' + TPath.GetFileNameWithoutExtension(Pack));
          Check(Content.Contains('assets/help-translation.js'), 'Help script served for ' + Pack);
          Check(Client.Response.CharSet = 'utf-8', 'UTF-8 response');
        end;
        Stage := 'Script request';
        Content := Client.Get(Base + '/assets/help-translation.js');
        Check(Content.Contains('doGTranslate'), 'Automatic widget selection served');
        Check(not Content.Contains('vcl2fmx.github.io'), 'No live-site dependency');
        Content := Client.Get(Base + '/topics/purpose-and-audience.html?lang=de-DE');
        Check(Content.Contains('../assets/help-translation.js'), 'Each topic translates');
        Stage := 'HEAD request';
        Client.Head(Base + '/style.css');
        Check(Client.ResponseCode = 200, 'HEAD supported');
        CheckRaw('GET', '/%2e%2e/MainForm.pas', '127.0.0.1:' + IntToStr(Port), 403);
        CheckRaw('GET', '/C:%5cWindows%5cwin.ini', '127.0.0.1:' + IntToStr(Port), 403);
        CheckRaw('GET', '/missing.html', '127.0.0.1:' + IntToStr(Port), 404);
        CheckRaw('POST', '/index.html', '127.0.0.1:' + IntToStr(Port), 405);
        CheckRaw('GET', '/index.html', 'unrelated.example', 403);
      finally
        Socket.Free;
        Client.Free;
      end;
      frmMain.HelpServer.Active := False;
      Check(not frmMain.HelpServer.Active, 'Listener stops cleanly');
    finally
      frmMain.Free;
    end;
    Writeln('PASS: ', CheckCount, ' actual local Help HTTP/component checks; no browser or translation provider used.');
  except
    on E: Exception do
    begin
      Writeln(Stage, ': ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
