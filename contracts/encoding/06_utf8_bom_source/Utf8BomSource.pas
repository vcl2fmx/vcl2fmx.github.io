unit ContractUtf8BomSource;

interface

procedure WriteUtf8BomText;

implementation

procedure WriteUtf8BomText;
begin
  // café naïve — résumé © 2026
  Writeln('café naïve — résumé ©');
end;

end.
