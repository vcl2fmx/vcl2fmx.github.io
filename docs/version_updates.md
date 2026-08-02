# VCL2FMXConverter Post-Coding Release Checklist

Use this checklist after application coding is complete and before declaring a
new VCL2FMXConverter version ready for release.

The release is not complete until a clean clone, fork, or extracted source
distribution contains everything required to build, validate, document, and
brand the application.

## 1. Release identity

- [ ] Confirm the final product name, version, release name, and build number.
- [ ] Confirm the final release date and time.
- [ ] Update the designer-owned version badge in the FMX form.
- [ ] Update the main form caption.
- [ ] Update source-file version headers.
- [ ] Update `.dproj` file and product-version metadata.
- [ ] Confirm Win32 and Win64 executables report the correct version.
- [ ] Search active files for stale build numbers, release names, Vanguard
      references, and previous-version paths.
- [ ] Confirm the displayed product name remains Navigator for v6.

## 2. Repository completeness and fork readiness

- [ ] Ensure every required logo, icon, screenshot, banner, and source graphic
      is stored in the repository.
- [ ] Include original editable graphic sources where available, not only
      flattened PNG or JPG exports.
- [ ] Include all Windows, FMX, UWP, application, and deployment icon sizes
      referenced by the `.dproj`.
- [ ] Verify every image path referenced by `.fmx`, `.dproj`, documentation,
      help, and website files exists.
- [ ] Include required FMX style files, resources, manifests, templates, and
      embedded assets.
- [ ] Include all mapping packs and their schema information.
- [ ] Include contracts, fixture inputs, expectations, includes, resources, and
      other files required by the contract runner.
- [ ] Include sample source needed to demonstrate or validate the application.
- [ ] Include the build and validation scripts needed to reproduce the release.
- [ ] Include the Apache License 2.0 text and required third-party attribution.
- [ ] Document the required RAD Studio version and toolchain.
- [ ] Document optional third-party dependencies separately from required
      dependencies.
- [ ] Eliminate dependencies on personal, temporary, backup, or external-drive
      files.
- [ ] Replace unnecessary machine-specific paths with project-relative paths.
- [ ] Search active source and project files for references to `C:\Users`,
      temporary directories, prior workspaces, and external drives.
- [ ] Confirm the project opens in RAD Studio with all units and resources
      visible in the Project Manager.
- [ ] Test Win32 and Win64 Release builds from a clean clone, fork, or extracted
      source distribution.
- [ ] Run the validation tools from that clean location.
- [ ] Confirm missing optional assets produce clear instructions instead of
      unexplained failures.
- [ ] Maintain an asset inventory recording each artifact's purpose, repository
      path, source format, and license.
- [ ] Record hashes for critical release graphics and embedded resources when
      useful.

## 3. Final validation

- [ ] Make the required pre-release backup under
      `D:\VCL2FMXConverterV6 Backup`.
- [ ] Build Win32 Release.
- [ ] Build Win64 Release.
- [ ] Run mapping-pack validation.
- [ ] Run the negative mapping-pack schema tests.
- [ ] Run all conversion contracts with coverage enforcement.
- [ ] Compile every eligible generated contract fixture.
- [ ] Run all regression guards.
- [ ] Run the complete acceptance gate.
- [ ] Run timing-sensitive contracts under isolated conditions.
- [ ] Test representative real Delphi projects.
- [ ] Test dry-run and normal conversion modes.
- [ ] Inspect plain-text, HTML, and JSON reports.
- [ ] Confirm validation tools do not modify tracked fixtures or goldens.
- [ ] Confirm the Git working tree contains no unexpected generated changes.
- [ ] Record executable and distribution SHA-256 hashes.

## 4. Application graphics

- [ ] Capture a new full application screenshot showing the final build badge.
- [ ] Replace screenshots containing an obsolete build number.
- [ ] Verify the Navigator name and orange coloring.
- [ ] Verify badge centering, length, date, and time.
- [ ] Verify hero alignment at every supported window size.
- [ ] Update website screenshot assets.
- [ ] Update screenshot captions and alternative text.
- [ ] Verify application icons at every required size.
- [ ] Confirm splash, logo, icon, and promotional graphics use final branding.
- [ ] Remove obsolete Vanguard or previous-build graphics from active release
      materials.

## 5. Word documentation

Preserve the established formatting and layout. Do not redesign existing guides
while performing version updates.

- [ ] Update the User Guide `.docx`.
- [ ] Update the Engineering Guide `.docx`.
- [ ] Update the Contract System Overview `.docx`.
- [ ] Update the Runtime Flow document.
- [ ] Update the Mapping Pack Reference.
- [ ] Update the Rules Reference.
- [ ] Update component, property, and event mapping references.
- [ ] Update the Known Limits document.
- [ ] Update release notes and validation totals.
- [ ] Replace screenshots without changing their established placement or
      sizing.
- [ ] Update titles, headers, footers, build numbers, dates, and last-changed
      fields.
- [ ] Update tables of contents through Microsoft Word.
- [ ] Check page breaks, tables, captions, headings, and cross-references.
- [ ] Visually inspect every rendered page.
- [ ] Do not use LibreOffice.

## 6. PDF documentation

- [ ] Export every changed Word guide through Microsoft Word using
      `ExportAsFixedFormat`.
- [ ] Place companion PDFs in `docs\pdf`.
- [ ] Confirm PDF titles, metadata, page counts, and text extraction.
- [ ] Render PDFs to images and inspect every page.
- [ ] Confirm there are no clipped elements, missing images, blank pages,
      broken tables, or font substitutions.
- [ ] Verify every PDF matches its corresponding DOCX.

## 7. Help system

- [ ] Update help topics for changed features and behavior.
- [ ] Update version and build information.
- [ ] Update screenshots and navigation.
- [ ] Update contract, mapping-pack, dry-run, reporting, and validation topics.
- [ ] Rebuild using the Help Doc Creator-compatible workflow.
- [ ] Test contents, index, search, context links, and internal hyperlinks.
- [ ] Confirm no previous-version branding remains.

## 8. Website

- [ ] Update the home page to the final release and build.
- [ ] Update the downloads page.
- [ ] Update validation totals and major features.
- [ ] Update the release notice.
- [ ] Add the final validation-record link.
- [ ] Replace the application screenshot.
- [ ] Update screenshot alternative text.
- [ ] Update download filenames, sizes, and SHA-256 hashes.
- [ ] Preserve the GTranslate floating widget.
- [ ] Preserve `notranslate` and `translate="no"` protection for product names.
- [ ] Verify `assets/translation-selector.js`.
- [ ] Check desktop and mobile layouts.
- [ ] Test every download and documentation link.
- [ ] Check metadata, Open Graph data, structured data, sitemap, and robots file.
- [ ] Do not publish until expressly authorized.

## 9. Source distribution

- [ ] Generate the final source-distribution ZIP.
- [ ] Include source, mapping packs, license, README, and required project
      resources.
- [ ] Include contracts when required by the selected distribution policy.
- [ ] Exclude private tools, unintended tests, build output, DCUs, EXEs,
      temporary files, and repository metadata.
- [ ] Verify all bundled mapping packs are included.
- [ ] Verify no obsolete mapping-pack filenames are present.
- [ ] Extract the ZIP into a new clean temporary directory.
- [ ] Confirm the extracted project opens and builds.
- [ ] Confirm required graphics and resources are present in the extracted copy.
- [ ] Record the ZIP filename, size, entry count, and SHA-256 hash.
- [ ] Place the ZIP in `Source Distributions`.

## 10. Release documentation and review handoff

- [ ] Create the final validation record.
- [ ] Create final release notes.
- [ ] Summarize changes since the previous public build.
- [ ] List known limitations and manual-review requirements.
- [ ] Record contract, regression, acceptance, and mapping-pack totals.
- [ ] Record Win32 and Win64 build results.
- [ ] Record artifact names, sizes, hashes, and the commit identifier.
- [ ] Prepare a concise Claude review handoff.
- [ ] Have Claude review the final source with contracts included.
- [ ] Correct only confirmed issues.
- [ ] Repeat all affected validation after any correction.

## 11. Repository preparation

- [ ] Review Git status.
- [ ] Preserve unrelated user files.
- [ ] Confirm no generated validation output is tracked accidentally.
- [ ] Confirm no credentials, private data, temporary files, binaries, or
      private tools are staged unintentionally.
- [ ] Stage only intended release files.
- [ ] Create a clear local release commit.
- [ ] Make a verified full post-release backup on `D:\`.
- [ ] Confirm the backup contains the final commit, documentation, binaries,
      graphics, Claude reports, and source distribution.
- [ ] Do not push to GitHub until expressly instructed.

## 12. GitHub release — only when authorized

- [ ] Confirm which public and private repositories must be updated.
- [ ] Push the final branch and commit.
- [ ] Create the release tag.
- [ ] Create the GitHub release.
- [ ] Upload approved source distributions and binaries.
- [ ] Include release notes, requirements, limitations, hashes, and
      documentation links.
- [ ] Update both public and private repositories as directed.
- [ ] Verify GitHub downloads match the local SHA-256 hashes.
- [ ] Verify the public website and GitHub release agree on version and download
      information.

## 13. Final release sign-off

- [ ] Install or run the release from a clean location.
- [ ] Confirm the displayed build identity.
- [ ] Perform a smoke conversion.
- [ ] Open every report format.
- [ ] Test dry-run preview.
- [ ] Verify mapping packs load without warnings.
- [ ] Confirm documentation and help open correctly.
- [ ] Confirm all public links and downloads work.
- [ ] Confirm backups are readable.
- [ ] Record final approval and release date.
- [ ] Preserve the completed checklist as part of the release record.
