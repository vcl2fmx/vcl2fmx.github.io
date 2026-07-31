unit ContractCp1252Source;

interface

uses
  System.SysUtils;

procedure WriteAccentedText;

implementation

procedure WriteAccentedText;
begin
  // café naïve — résumé © 2026
  Writeln('café naïve — résumé ©');
end;

end.
