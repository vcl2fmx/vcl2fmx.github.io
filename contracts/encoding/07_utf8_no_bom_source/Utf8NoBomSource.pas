unit ContractUtf8NoBomSource;

interface

procedure WriteUtf8NoBomText;

implementation

procedure WriteUtf8NoBomText;
begin
  // café naïve — résumé © 2026
  Writeln('café naïve — résumé ©');
end;

end.
