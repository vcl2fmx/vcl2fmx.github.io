$ErrorActionPreference = 'Stop'

function Convert-MappedString {
  param([string]$Value)
  if ($null -eq $Value) { return '' }
  return $Value.Replace("''", "'")
}

function Get-ParserPolicyFromMapping {
  param(
    [string]$MappingType,
    [string]$FMXClass
  )

  if ([string]::IsNullOrWhiteSpace($FMXClass)) { return 'manual_review_only' }

  switch -Regex ($MappingType) {
    '^Direct$' { return 'stream_direct_target' }
    '^Preserved$' { return 'preserve_component_as_is' }
    '^Substitute$' { return 'substitute_target_class' }
    '^Researched$' { return 'inventory_guided_substitute' }
    default { return 'substitute_target_class' }
  }
}

function Get-PropertyClassification {
  param(
    [string]$VCLProperty,
    [string]$FMXProperty,
    [bool]$NeedsTransformation
  )

  if ([string]::IsNullOrWhiteSpace($FMXProperty)) { return 'manual_review' }
  if ($NeedsTransformation) { return 'transform' }
  if ($VCLProperty -ieq $FMXProperty) { return 'direct' }
  return 'rename'
}

function Get-EventClassification {
  param(
    [string]$VCLEvent,
    [string]$FMXEvent,
    [bool]$SignatureCompatible
  )

  if ([string]::IsNullOrWhiteSpace($FMXEvent)) { return 'manual_review' }
  if (-not $SignatureCompatible) { return 'incompatible_signature' }
  if ($VCLEvent -ieq $FMXEvent) { return 'direct' }
  return 'rename'
}

function Parse-MapperSourceFallback {
  param([string]$ProjectRoot)

  $mapperPath = Join-Path $ProjectRoot 'Converter.Mapper.Component.pas'
  if (-not (Test-Path $mapperPath)) {
    throw "Mapper source not found: $mapperPath"
  }

  $lines = Get-Content -LiteralPath $mapperPath
  $classRows = New-Object System.Collections.Generic.List[object]
  $propertyRows = New-Object System.Collections.Generic.List[object]
  $eventRows = New-Object System.Collections.Generic.List[object]

  $current = $null
  $currentProp = $null
  $currentEvent = $null

  foreach ($rawLine in $lines) {
    $line = [string]$rawLine
    $trimmed = $line.Trim()

    if ($trimmed -match '^Mapping := TComponentMapping\.Create;') {
      if ($null -ne $current -and -not [string]::IsNullOrWhiteSpace($current.vcl_class)) {
        $current.parser_policy = Get-ParserPolicyFromMapping -MappingType $current.mapping_type -FMXClass $current.fmx_class
        $classRows.Add([pscustomobject]$current)
      }
      $current = [ordered]@{
        vcl_class    = ''
        fmx_class    = ''
        mapping_type = ''
        confidence   = 0
        notes        = ''
        parser_policy = ''
      }
      $currentProp = $null
      $currentEvent = $null
      continue
    }

    if ($null -eq $current) {
      continue
    }

    if ($trimmed -match "^Mapping\.VCLClassName := '((?:''|[^'])*)';") {
      $current.vcl_class = Convert-MappedString $matches[1]
      continue
    }
    if ($trimmed -match "^Mapping\.FMXClassName := '((?:''|[^'])*)';") {
      $current.fmx_class = Convert-MappedString $matches[1]
      continue
    }
    if ($trimmed -match "^Mapping\.MappingType := '((?:''|[^'])*)';") {
      $current.mapping_type = Convert-MappedString $matches[1]
      continue
    }
    if ($trimmed -match '^Mapping\.Confidence := (\d+);') {
      $current.confidence = [int]$matches[1]
      continue
    }
    if ($trimmed -match "^Mapping\.Notes := '((?:''|[^'])*)';") {
      $current.notes = Convert-MappedString $matches[1]
      continue
    }

    if ($trimmed -match "^PropMap\.VCLProp := '((?:''|[^'])*)';") {
      $currentProp = [ordered]@{
        vcl_class             = $current.vcl_class
        vcl_property          = Convert-MappedString $matches[1]
        fmx_property          = ''
        classification        = ''
        rule_source           = 'built_in_source_parser'
        needs_transformation  = $false
        transformer           = ''
        notes                 = ''
      }
      continue
    }
    if ($null -ne $currentProp) {
      if ($trimmed -match "^PropMap\.FMXProp := '((?:''|[^'])*)';") {
        $currentProp.fmx_property = Convert-MappedString $matches[1]
        continue
      }
      if ($trimmed -match '^PropMap\.NeedsTransformation := (True|False);') {
        $currentProp.needs_transformation = [bool]::Parse($matches[1])
        continue
      }
      if ($trimmed -match "^PropMap\.TransformerFunc := '((?:''|[^'])*)';") {
        $currentProp.transformer = Convert-MappedString $matches[1]
        continue
      }
      if ($trimmed -match '^Mapping\.PropertyMaps\.Add\(PropMap\);') {
        $currentProp.classification = Get-PropertyClassification -VCLProperty $currentProp.vcl_property -FMXProperty $currentProp.fmx_property -NeedsTransformation ([bool]$currentProp.needs_transformation)
        $propertyRows.Add([pscustomobject]$currentProp)
        $currentProp = $null
        continue
      }
    }

    if ($trimmed -match "^EventMap\.VCLEvent := '((?:''|[^'])*)';") {
      $currentEvent = [ordered]@{
        vcl_class             = $current.vcl_class
        vcl_event             = Convert-MappedString $matches[1]
        fmx_event             = ''
        classification        = ''
        signature_compatible  = $true
        rule_source           = 'built_in_source_parser'
        notes                 = ''
      }
      continue
    }
    if ($null -ne $currentEvent) {
      if ($trimmed -match "^EventMap\.FMXEvent := '((?:''|[^'])*)';") {
        $currentEvent.fmx_event = Convert-MappedString $matches[1]
        continue
      }
      if ($trimmed -match '^EventMap\.SignatureMatch := (True|False);') {
        $currentEvent.signature_compatible = [bool]::Parse($matches[1])
        continue
      }
      if ($trimmed -match '^Mapping\.EventMaps\.Add\(EventMap\);') {
        $currentEvent.classification = Get-EventClassification -VCLEvent $currentEvent.vcl_event -FMXEvent $currentEvent.fmx_event -SignatureCompatible ([bool]$currentEvent.signature_compatible)
        $eventRows.Add([pscustomobject]$currentEvent)
        $currentEvent = $null
        continue
      }
    }

    if ($trimmed -match '^FMappingDatabase\.Add\(Mapping\);') {
      $current.parser_policy = Get-ParserPolicyFromMapping -MappingType $current.mapping_type -FMXClass $current.fmx_class
      $classRows.Add([pscustomobject]$current)
      $current = $null
      $currentProp = $null
      $currentEvent = $null
      continue
    }
  }

  if ($null -ne $current -and -not [string]::IsNullOrWhiteSpace($current.vcl_class)) {
    $current.parser_policy = Get-ParserPolicyFromMapping -MappingType $current.mapping_type -FMXClass $current.fmx_class
    $classRows.Add([pscustomobject]$current)
  }

  return [pscustomobject]@{
    SourceMode    = 'mapper_source_fallback'
    ClassRows     = @($classRows.ToArray())
    PropertyRows  = @($propertyRows.ToArray())
    EventRows     = @($eventRows.ToArray())
  }
}

function Get-ReferenceMatrixData {
  param([string]$ProjectRoot)

  $candidateRoots = @(
    (Join-Path $ProjectRoot 'Win32\Release'),
    (Join-Path $ProjectRoot 'Win32\Debug')
  )

  foreach ($candidate in $candidateRoots) {
    $classPath = Join-Path $candidate 'class_mapping_matrix.json'
    $propertyPath = Join-Path $candidate 'property_mapping_matrix.json'
    $eventPath = Join-Path $candidate 'event_mapping_matrix.json'

    if ((Test-Path $classPath) -and (Test-Path $propertyPath) -and (Test-Path $eventPath)) {
      return [pscustomobject]@{
        SourceMode    = 'matrix_artifacts'
        ClassRows     = @(Get-Content $classPath -Raw | ConvertFrom-Json)
        PropertyRows  = @(Get-Content $propertyPath -Raw | ConvertFrom-Json)
        EventRows     = @(Get-Content $eventPath -Raw | ConvertFrom-Json)
      }
    }
  }

  return Parse-MapperSourceFallback -ProjectRoot $ProjectRoot
}
