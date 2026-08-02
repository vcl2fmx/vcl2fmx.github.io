# VCL2FMXConverter v6.0 E35 Reachability Audit

Last changed: 2026-08-02

## Scope and decision

This audit closes the E35 discrepancy by identifying the original fourteen
public-method candidates and applying the required reachability checks before
removal. The active application source, project source, forms, contracts,
mapping packs, and validation tools were searched. Historical and generated
output folders were not treated as active callers.

All fourteen methods had exactly two active-source references: one class
declaration and one implementation. None was published, assigned as an FMX
event, exposed through an implemented interface, referenced by a method
pointer, invoked by name through RTTI, or exported by the application.
VCL2FMXConverter is an application rather than a reusable package, so these
public declarations were not an external package API.

## Closed candidate list

| Unit | Class | Removed method |
|---|---|---|
| `Converter.Advanced.CriticalAreas` | `TCustomDrawingConverter` | `ConvertOnPaint` |
| `Converter.Advanced.CriticalAreas` | `TMessageHandlerConverter` | `GenerateFMXMessageHandlers` |
| `Converter.Advanced.CriticalAreas` | `TOwnerDrawConverter` | `GenerateDrawHandlers` |
| `Converter.Advanced.CriticalAreas` | `TFormInheritanceConverter` | `ConvertInheritedForms` |
| `Converter.Advanced.CriticalAreas` | `TFormInheritanceConverter` | `GenerateInheritanceHierarchy` |
| `Converter.Advanced.CriticalAreas` | `TCriticalAreasConverter` | `GenerateCriticalAreasReport` |
| `Converter.Advanced.DataAware` | `TLiveBindingConverter` | `GenerateLiveBindings` |
| `Converter.Advanced.DataAware` | `TLiveBindingConverter` | `ConvertDataAwareComponents` |
| `Converter.Advanced.DataAware` | `TDatabaseConverter` | `AnalyzeDatabaseComponents` |
| `Converter.Advanced.DataAware` | `TDatabaseConverter` | `GenerateDatabaseDFM` |
| `Converter.Advanced.DataAware` | `TDatabaseConverter` | `GenerateDatabaseCode` |
| `Converter.Advanced.ThirdParty` | `TThirdPartyHandler` | `GetReplacementCode` |
| `Converter.Advanced.ThirdParty` | `TThirdPartyHandler` | `GenerateVendorNotes` |
| `Converter.Mapper.Component` | `TComponentMapper` | `AddUserMapping` |

## Qualification checks

Each candidate satisfied every removal condition:

- no call site beyond its declaration and implementation;
- public but not `published`;
- no associated `.fmx` or `.dfm` event assignment;
- no implemented interface member;
- no method-pointer assignment;
- no `MethodAddress`, RTTI `GetMethod`, or name-based invocation;
- no project or package export;
- no mapping-pack or contract dependency.

The public-method deletion was limited to the fourteen reconciled candidates.
The first compiler pass then identified private helpers reachable only through
those removed methods. Those orphaned helpers, their unused fields, and the
otherwise unreferenced `TFormInheritanceConverter` and `TDatabaseConverter`
support classes were also removed so the maintenance change remains
warning-clean. No active conversion call path was removed by that support-tree
cleanup.
