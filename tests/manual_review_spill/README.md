# Manual Review Spill Regression Fixture

This fixture covers unsupported VCL/WinAPI message handlers and non-English comments.

Run the converter against `tests\manual_review_spill\source`, write output to `tests\manual_review_spill\output`, then run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\manual_review_spill\run_manual_review_spill_guard.ps1
```

The guard fails if generated output comments normal unit structure such as `public`, `var`, `implementation`, `uses`, resource directives, or the final `end.`.
