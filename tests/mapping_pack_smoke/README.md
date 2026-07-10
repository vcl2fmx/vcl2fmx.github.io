# Mapping Pack Smoke Test Harness

This folder is self-contained and can be deleted when the v4.1 mapping-pack tests are no longer needed.

Delete this folder to remove the test harness:

```text
C:\New Delphi Projects\VCL2FMXConverterV4\tests\mapping_pack_smoke
```

## Purpose

These fixtures test mapping-pack infrastructure without requiring DevExpress to be installed.

The source DFM uses DevExpress class names as plain text:

- `TcxButton`
- `TcxTextEdit`
- `TcxMemo`
- `TcxMaskEdit`
- `TcxGrid`
- `TdxRibbon`

The converter should load the sample DevExpress mapping pack from:

```text
C:\New Delphi Projects\VCL2FMXConverterV4\mapping_packs\DevExpress_MappingPack_v1.json
```

## How To Run

1. Build or run the current v4.1 executable. If you are testing the IDE Release build, use:

```text
C:\New Delphi Projects\VCL2FMXConverterV4\Win32\Release\VCL2FMXConverter.exe
```

2. In the converter UI, use:

```text
Source: C:\New Delphi Projects\VCL2FMXConverterV4\tests\mapping_pack_smoke\source
Output: C:\New Delphi Projects\VCL2FMXConverterV4\tests\mapping_pack_smoke\output
File type: Both PAS and DFM
```

3. Run conversion.

4. Inspect:

```text
C:\New Delphi Projects\VCL2FMXConverterV4\tests\mapping_pack_smoke\output\UnitDevExpressMock.fmx
C:\New Delphi Projects\VCL2FMXConverterV4\tests\mapping_pack_smoke\output\VCL_to_FMX_Conversion_Report.html
```

## Expected Results

In the generated `.fmx`:

- `cxButton1: TButton`
- `Text = 'Click Me'`
- `cxTextEdit1: TEdit`
- `cxMemo1: TMemo`
- `cxMaskEdit1: TEdit`
- no `cxGrid1: TcxGrid`
- no `dxRibbon1: TdxRibbon`

In the report:

- `Mapping packs loaded: 11`
- `DevExpress_MappingPack_v1`
- `Mapping pack partial conversion`
- `TcxMaskEdit`
- `Mapping pack detection only`
- `TcxGrid`
- `TdxRibbon`

The generated mock project is not expected to compile as an application. This test verifies converter behavior, not DevExpress runtime compatibility.
