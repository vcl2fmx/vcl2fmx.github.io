# French beta regression fixture

This fixture covers the June 2026 beta report: nonempty FMX generation,
case-insensitive DFM roots, conditional uses clauses, comments containing VCL
unit names or code, compatibility helper placement, initialization safety,
color arrays, theme-dependent colors, and commented WinAPI calls.
It also creates a genuine Delphi binary DFM with `convert.exe`, converts it
through the normal engine, and verifies that the resulting FMX is nonempty.
