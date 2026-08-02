# VCL2FMXConverter v6.0 Mapping-Pack Schema

Last changed: 2026-08-02

VCL2FMXConverter v6.0 Navigator uses schema identifier
`vcl2fmx.mapping-pack.v1`. A pack’s own `version` is independent from the
schema version and must use `major.minor.patch`.

## Required pack fields

- `schema`: exactly `vcl2fmx.mapping-pack.v1`
- `pack_name`: human-readable pack name
- `pack_id`: stable, globally unique identifier
- `vendor`: component vendor or family
- `version`: semantic `major.minor.patch`
- `description`: scope and safety description
- `mode`: `conservative` or `detection`
- `rules`: non-empty array

## Required rule fields

- `vcl_class`: valid Delphi class identifier; unique across enabled packs
- `action`: `convert`, `partial`, `manual_review`, `detect_only`, or `preserve`
- `confidence`: integer from 0 through 100

`fmx_class`, `notes`, `manual_review_reason`, `properties`, and `events` add
the target and review detail. Property rows use `vcl` and `fmx`; event rows use
the same keys and may add `signature_match`.

## Validation

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  "tools\validate_mapping_packs.ps1" -ProjectRoot "."
```

The command validates schema metadata, supported values, semantic versions,
confidence ranges, JSON structure, unique pack IDs, and unique VCL classes.
It writes a detailed report beneath the user temporary folder unless
`-ReportPath` is supplied.

## Authoring workflow

When conversion identifies reusable mapping gaps,
`MappingPack_Authoring_Suggestions.json` is emitted as a complete v1 starter
pack. Replace placeholder targets, review each action and confidence value,
remove source-only evidence if desired, add focused conversion contracts, and
run the validation command before placing the pack in `mapping_packs`.
