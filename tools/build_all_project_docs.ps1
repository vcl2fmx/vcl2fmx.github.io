$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')
& (Join-Path $PSScriptRoot 'build_generic_rules_reference_html.ps1') -OutputPath $GenericRulesReferenceHtmlPath
& (Join-Path $PSScriptRoot 'rebuild_rules_reference_docx.ps1')
& (Join-Path $PSScriptRoot 'build_component_mapping_reference_docx.ps1') -OutputPath $ComponentMappingReferencePath
& (Join-Path $PSScriptRoot 'build_final_engineering_guide_docx.ps1') -OutputPath $EngineeringGuidePath
& (Join-Path $PSScriptRoot 'build_user_guide_docx.ps1') -OutputPath $UserGuidePath
Write-Output 'DOC_BUILD_COMPLETE'

