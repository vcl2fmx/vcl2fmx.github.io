VCL2FMXConverter v7.0 Atlas

INSTALLATION
Download the Win32 or Win64 application ZIP and extract the entire ZIP into its own writable folder before starting VCL2FMXConverter.exe. Win64 needs 64-bit Windows. Keep the Win32 and Win64 editions in separate folders. Do not run from inside the ZIP or copy only the executable. RAD Studio is needed to build Delphi projects, not to run the downloaded converter.

Keep this layout together: VCL2FMXConverter.exe and WebView2Loader.dll in the same folder; Localization\Languages containing all 35 JSON language packs; mapping_packs containing the 22 supplied JSON packs; docs\Help containing the complete Help tree and guides; and the supplied licenses and README.txt. These are relative paths beneath the executable folder, not folders beside the ZIP.

Localization\Languages is required for interface and report translations. Preserve the English en-US.json pack as well as the other supplied languages. A missing or unreadable selected report language pack can stop a conversion with "The selected report language pack could not be loaded." Restore the complete folder from the same release ZIP and restart the converter.

WebView2Loader.dll must be directly beside VCL2FMXConverter.exe and match the executable architecture: x86 for Win32, x64 for Win64, even when running Win32 on 64-bit Windows. Use the DLL supplied in that edition of the release ZIP. The loader supports the embedded mapping browsers; it is not the WebView2 Runtime.

Install or update Microsoft Edge WebView2 Evergreen Runtime if it is absent. Obtain it from https://developer.microsoft.com/microsoft-edge/webview2/ under Download the WebView2 Runtime. The Evergreen Bootstrapper needs Internet access; use the appropriate Evergreen Standalone Installer for an offline computer. Having the Microsoft Edge browser installed is not a substitute for the Runtime. Do not download replacement DLLs from third-party DLL sites.

The embedded browsers use Edge when available and may fall back to an older browser engine if WebView2 is unavailable. A window that opens is therefore not proof of correct WebView2 deployment. If mapping views are blank or render incorrectly, check the loader location and architecture, then the Runtime installation. Close and reopen the converter after correcting the installation.

Keep mapping_packs with the application even when mapping-pack support is not currently enabled. Missing packs remove that optional conversion coverage. Preserve docs\Help and all its subfolders; missing Help files prevent Help from opening. Help opens in your default browser. Keep the converter running while using its local Help URL; English Help is available offline, while automatic Help translation needs Internet access.

Use a writable output folder separate from both the original VCL project and the converter installation. Keep an independent backup of the original project. The signed-in Windows account also needs access to its local application-data folder for language settings and browser data. Before replacing an installation, close the converter and back up customized language or mapping packs. Extract a fresh complete release rather than mixing files from different releases.

Before the first conversion, verify that the Language selector lists the supplied languages, the mapping views display, and Help opens. Review the conversion report, then compile and test the generated project in Delphi. Successful conversion does not remove the need to review unsupported components and manual changes.

LANGUAGES AND HELP
Choose from 35 bundled language packs using the Language selector. The interface
packs work offline. Help opens in the selected language; automatic Help
translation requires an Internet connection. English Help is available offline.
Keep the converter running while browsing Help.

The language packs contain machine-generated translations that have not been
reviewed by native speakers. Translations and glossaries can be edited using
the Delphi App Translation Studio: https://delphitranslate.github.io/
Download its manuals and guides with the software.

TRANSLATION EDITING AND ADDING LANGUAGES
Read docs/Help/topics/using-and-maintaining-translations.html for the complete
procedure. PDF and editable DOCX editions are in docs/Help/guides.
Use the Delphi App Translation Studio with the matching V7 complete source
workspace and its Localization/Development catalogs. Open the converter project,
open the required catalog, scan, edit and save, run Validation, then Export
Runtime Pack. Install the exported locale JSON in Localization/Languages beside
the executable and restart Atlas. Back up customized packs before replacing them.
For a new language, start a fresh catalog from a scan and select the new target
locale; do not relabel an existing translation. The guide covers glossary changes,
placeholders, layout checks, rollback and the additional Help language mapping.
Interface packs work offline. Help uses separate online translation; editing a
pack or glossary does not change Help's translations. PDF and DOCX guides are
English documents. Source code and canonical JSON reports are not translated.

TRANSLATION FEEDBACK
For a correction, email churchesite@gmail.com with the converter version,
language and locale, screen or Help topic, current wording and suggested wording.
For clipping, include window size and display scaling. Remove private details
from screenshots. The Languages and reports Help topic includes a message template.

CONVERSION
Review the conversion report and resolve blocking and manual-review findings.
Compile and test the generated project in Delphi before using its output.
RAD Studio is required to build Delphi projects, but not to run the converter.
Generated source code and Delphi identifiers are not translated into natural
languages. JSON reports retain the canonical English schema.

V7 OPERATING SAFEGUARDS
Select one original VCL project and a separate output folder. V7 resolves paths before conversion, checks project selection before output cleanup, rejects ambiguous or mismatched DPR/DPROJ selections, and blocks empty input and unreadable source files. Scanned directory links and reparse points, and hard-linked output files, are rejected. Dry-run preview may write reports and create the output directory, but does not write converted source or remove existing build/history folders. Report actions use only paths produced by the current run.

Input text detection supports UTF-8, UTF-16 and explicit supported Pascal code-page directives. Without a byte-order mark or directive, valid UTF-8 is preferred; other legacy bytes use Windows-1252. Convert other legacy encodings to UTF-8 in Delphi before conversion. Generated Pascal output is UTF-8, and active code-page directives are normalized to {$CODEPAGE UTF8}. This can change generated text without changing the intended conversion rule.

BUILDING FROM SOURCE
Open VCL2FMXConverter.dproj in RAD Studio. Select Release and Win32 or Win64.
Source builds use RAD Studio 13 (37.0). The project build target copies the matching loader from dependencies\WebView2\Win32 or Win64, its license files, language packs, mapping packs and Help into the selected build output folder. Keep those dependency files in the source workspace. The release packager validates executable/loader architecture and includes these files in both application editions and the source package.
The bundled translation dependency is under dependencies/DelphiAppTranslation.

LICENSE
See LICENSE and LICENSE.txt. The bundled translation dependency has its own
license under licenses (application package) or dependencies (source package).
