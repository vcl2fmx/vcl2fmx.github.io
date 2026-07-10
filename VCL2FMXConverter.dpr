program VCL2FMXConverter;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  Converter.Advanced.CriticalAreas in 'Converter.Advanced.CriticalAreas.pas',
  Converter.Advanced.DataAware in 'Converter.Advanced.DataAware.pas',
  Converter.Advanced.ThirdParty in 'Converter.Advanced.ThirdParty.pas',
  Converter.Advanced.WinAPI in 'Converter.Advanced.WinAPI.pas',
  Converter.Core.Engine in 'Converter.Core.Engine.pas',
  Converter.Core.FileManager in 'Converter.Core.FileManager.pas',
  Converter.Core.Integration in 'Converter.Core.Integration.pas',
  Converter.Core.Types in 'Converter.Core.Types.pas',
  Converter.Mapper.Component in 'Converter.Mapper.Component.pas',
  Converter.Parser.DFM in 'Converter.Parser.DFM.pas',
  Converter.Parser.Pascal in 'Converter.Parser.Pascal.pas',
  Converter.Project.Generator in 'Converter.Project.Generator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
