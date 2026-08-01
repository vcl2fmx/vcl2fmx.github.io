# VCL2FMXConverter v5.0 Vanguard Maintenance Update

Revision date: August 1, 2026

This maintenance update incorporates field-test feedback from real Delphi projects. The converter now recognizes additional standard VCL controls, including `TBitBtn` and `TTrayIcon`, so they are not incorrectly reported as unknown third-party components. `TBitBtn` receives a conservative FMX `TButton` substitution note, while `TTrayIcon` remains an explicit platform-specific manual-review item because FMX has no direct standard tray-icon component.

The update also preserves the existing protection against false third-party classifications for database field objects, application-owned root forms, and standard VCL controls. The generated report continues to distinguish converted output from items that require manual review.

The current contract suite contains 227 executable expectations. The verification run passed 227 of 227 contracts, and the Win32 and Win64 Release builds were rebuilt from the current source.

Users should report unexpected conversion results with the original source pattern, generated report, and the smallest reproducible sample available. Reports of anomalies help turn real project behavior into reusable, project-independent contracts.
