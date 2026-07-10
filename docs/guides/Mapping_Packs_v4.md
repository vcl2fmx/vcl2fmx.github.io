# VCL2FMXConverter v5.0 Mapping Packs

Mapping packs are optional JSON files that add transparent component mapping rules without baking third-party commercial-library assumptions into the converter core.

Default folder:

```text
mapping_packs
```

Each pack declares metadata and a `rules` array. The formal v1 schema is in:

```text
docs/mapping-pack-schema-v1.json
```

## Actions

`convert` generates the declared FMX target when confidence is high enough.

`partial` generates the declared FMX target and adds a manual-review report item describing limitations.

`manual_review` reports the component and does not generate an automatic FMX replacement.

`detect_only` identifies the vendor/component and does not generate an automatic FMX replacement.

`preserve` is reserved for components that can safely remain as-is, usually nonvisual or cross-platform components.

## Guardrails

Malformed packs are skipped with a warning.

Duplicate rules are deterministic: later loaded pack rules replace earlier rules for the same VCL class.

Rules below 50 percent confidence do not automatically convert.

Mapping-pack usage is reported in the conversion report so third-party behavior is visible to the user.

## Beta Release Notes

The v5.0 distribution includes the same 22 starter mapping packs released with v4.1.8 for common Delphi third-party libraries. These packs are intentionally conservative: simple controls may convert, approximate controls may convert with review notes, and complex controls are usually report-only.

Revision date: June 25, 2026

Mapping packs are extension data, not vendor runtimes. They do not install or replace commercial component libraries. Always review the generated report and test the converted FMX project in Delphi.
