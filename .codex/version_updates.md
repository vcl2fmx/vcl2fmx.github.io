# VCL2FMXConverter Post-Coding Release Checklist

Codex will use this checklist after application coding is complete and before declaring a
new VCL2FMXConverter version ready for release. Codex will do all items that may be done
by him and request manual assistance from the developer, when appropriate.

The release is not complete until a clean clone, fork, or extracted source
distribution contains everything required to build, validate, document, and
brand the application.

## 1. Release identity

- [ ] Confirm the final product name, version, and release name.
- [ ] Confirm the current application and website build identity separately
      from the build-neutral documentation identity.
- [ ] Confirm the final release date and time.
- [ ] Update the designer-owned version badge in the FMX form.
- [ ] Update the main form caption.
- [ ] Update source-file version headers.
- [ ] Update `.dproj` file and product-version metadata.
- [ ] Confirm Win32 and Win64 executables report the correct version.
- [ ] Search active documentation for numeric build identifiers, stale release
      names, Vanguard references, and previous-version paths.
- [ ] Confirm the displayed product name remains Navigator for v6.

## 2. Repository completeness and fork readiness

- [ ] Ensure every required logo, icon, screenshot, banner, and source
      graphic is stored in the repository, including original editable
      sources where available.
- [ ] Include all Windows, FMX, UWP, application, and deployment icon sizes
      referenced by the `.dproj`, and verify every image path referenced by
      `.fmx`, `.dproj`, documentation, help, and website files exists.
- [ ] Include required FMX style files, resources, manifests, templates, and
      embedded assets.
- [ ] Include all mapping packs and their schema information.
- [ ] Include contracts, fixture inputs, expectations, includes, resources,
      sample source, and other files required by the contract runner or
      needed to demonstrate or validate the application.
- [ ] Include the build and validation scripts needed to reproduce the
      release.
- [ ] Include the Apache License 2.0 text and required third-party
      attribution, and document the required RAD Studio version, toolchain,
      and any optional third-party dependencies.
- [ ] Eliminate dependencies on personal, temporary, backup, or
      external-drive files; replace machine-specific paths with
      project-relative ones; search active source and project files for
      `C:\Users`, temporary directories, prior workspaces, and external
      drives.
- [ ] Confirm the project opens in RAD Studio with all units and resources
      visible in the Project Manager.
- [ ] Test Win32 and Win64 Release builds from a clean clone, fork, or
      extracted source distribution, and run the validation tools from that
      clean location.

## 3. Final validation

- [ ] Make the required pre-release backup under `D:\VCL2FMXConverterV6 Backup`.
- [ ] Build Win32 Release.
- [ ] Build Win64 Release.
- [ ] Run mapping-pack validation.
- [ ] Run the negative mapping-pack schema tests.
- [ ] Run all conversion contracts with coverage enforcement.
- [ ] Compile every eligible generated contract fixture.
- [ ] Run all regression guards.
- [ ] Run the complete acceptance gate.
- [ ] Run timing-sensitive contracts with no other build, compile, or
      heavy background process running concurrently; a busy machine can trip a
      duration budget that passes cleanly in isolation. Re-run once alone
      before treating a duration failure as a real regression.
- [ ] Silently test representative real Delphi projects by name: Carillon, GPS Control,
      RealTimeClock, and any other project previously used for field
      validation. Record which named projects were actually run against the
      current build, not only that "real projects" were tested in general. If any
      errors occur that need attention, stop this validation and request assistance
      from the developer. This would include Pascal and Delphi errors that must be
      resolved.
- [ ] Confirm any document titled as a field-trial or real-project validation
      record actually contains output, findings, or behavior from a named real
      project — not a restatement of contract, guard, or acceptance-suite
      totals under a field-trial title.
- [ ] Test dry-run and normal conversion modes.
- [ ] Inspect plain-text, HTML, and JSON reports.
- [ ] Confirm validation tools do not modify tracked fixtures or goldens.
- [ ] Confirm the Git working tree contains no unexpected generated changes.
- [ ] Confirm report and contract goldens remain valid if the repository is
      built from a different absolute path (for example after a mapping-pack
      or fixture rename); re-normalize and regenerate goldens if any embedded
      absolute path changed.
- [ ] Record executable and distribution SHA-256 hashes from the exact
      binaries that will ship. Delphi builds are not guaranteed
      byte-reproducible between runs, so do not rebuild after recording a
      hash without re-recording it — record hashes last, after all other
      validation is complete.

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
- [ ] Update titles, headers, footers, dates, and last-changed fields while
      keeping documentation build-neutral.
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
- [ ] Update screenshots and navigation. Retake screen shots to update to current look.
- [ ] Update contract, mapping-pack, dry-run, reporting, and validation topics.
- [ ] Rebuild using the Help Doc Creator-compatible workflow.
- [ ] Test contents, index, search, context links, and internal hyperlinks.
- [ ] Confirm no previous-version branding remains.

## 8. Website

- [ ] Locate and back up the authoritative website source, including all HTML,
      CSS, JavaScript, images, downloadable files, and GitHub Pages settings. The
      working copies of this are in the project root directory and are named
      index.html and downloads.html.  All changes to the web pages should be done
      to them, verified and they then be readied for later push to GitHub.
- [ ] Perform a complete line-by-line version review of `index.html`, not only
      the visible release heading.
- [ ] Perform a complete line-by-line version review of `downloads.html`,
      including every download card, button, filename, link, requirement, and
      checksum.
- [ ] Review every other HTML page and shared header, navigation, footer, and
      template fragment for version-dependent content.
- [ ] Search the complete website source for obsolete version numbers, build
      numbers, release dates, release names, Vanguard references, old download
      filenames, and stale repository or documentation links.
- [ ] Retain v5 or earlier references only where they are intentionally part of
      release history or an explicitly supported older download.
- [ ] Update the `index.html` hero title, Navigator release name, version,
      build number, release date, badge, primary call to action, and release
      announcement.
- [ ] Update home-page feature summaries to match the released behavior without
      overstating automatic conversion coverage.
- [ ] Update contract, compiled-fixture, regression, acceptance, mapping-pack,
      and mapping-rule totals everywhere they appear.
- [ ] Update the release highlights, known limitations, manual-review
      expectations, system requirements, supported RAD Studio version, and
      Apache 2.0 license references.
- [ ] Add or update links to release notes, validation results, user guides,
      engineering documentation, mapping-pack references, and known limits.
- [ ] Replace the application screenshot and any hero, promotional, or
      download-page graphics that display an obsolete UI, badge, version, or
      build.
- [ ] Confirm all website graphics and their editable source assets are present
      in the website repository so a clean fork can reproduce the site.
- [ ] Optimize changed images for web delivery while retaining readable text
      and appropriate resolution.
- [ ] Update image filenames, dimensions, captions, alternative text, and
      references in HTML, CSS, metadata, and structured data.
- [ ] Remove or archive obsolete website graphics so stale images cannot be
      selected accidentally during a later release.
- [ ] Update every `downloads.html` artifact entry with the approved filename,
      version, build, platform, file type, file size, SHA-256 hash, and
      publication date.
- [ ] Confirm downloads are clearly distinguished as source, Win32, Win64,
      documentation, samples, or other approved artifacts.
- [ ] Verify the downloads page states prerequisites, installation or
      extraction instructions, license, known limitations, and whether manual
      review is required.
- [ ] Verify every download button points to the intended final artifact rather
      than a prior release, local path, draft file, or unavailable GitHub tag.
- [ ] Confirm the website, GitHub release, release tag, filenames, hashes, and
      validation record all describe the same build.
- [ ] Decide explicitly whether v5 remains downloadable; if retained, label it
      as an older release and keep it visually separate from v6 Navigator.
- [ ] Review site-wide navigation, page titles, breadcrumbs, footer version
      text, copyright year, license link, contact links, and external project
      links.
- [ ] Update HTML `<title>` elements, meta descriptions, canonical URLs, Open
      Graph data, social-preview data, and any version-bearing page metadata.
- [ ] Update structured data such as `SoftwareApplication` name, version,
      release date, operating-system information, license, download URL, and
      offer information where present.
- [ ] Update `sitemap.xml` URLs and `lastmod` values for changed public pages,
      then verify `robots.txt` references the correct sitemap.
- [ ] Review favicons, web-app manifests, social-card images, browser theme
      colors, and pinned-site assets for current branding.
- [ ] Update asset cache-busting query strings, generated asset manifests, or
      service-worker cache lists if the site uses them.
- [ ] Preserve the GTranslate floating widget.
- [ ] Preserve `class="notranslate"` and `translate="no"` protection for
      VCL2FMXConverter, Navigator, version badges, filenames, hashes, code,
      command lines, and other text that must remain exact.
- [ ] Verify `assets/translation-selector.js` still adds bilingual language
      labels, sorts the language list alphabetically, and works on every page.
- [ ] Test translated layouts for clipping, overlap, hidden controls, and
      broken navigation.
- [ ] Validate HTML and CSS and review browser-console output for JavaScript,
      resource-loading, mixed-content, and security errors.
- [ ] Check heading order, landmarks, keyboard navigation, visible focus,
      contrast, link purpose, form labels, and meaningful alternative text.
- [ ] Check the complete site at desktop, tablet, and phone widths, including
      the hero, badge, menus, download cards, tables, code blocks, and footer.
- [ ] Crawl and test every internal link, anchor, download link, documentation
      link, email link, and relevant external link.
- [ ] Confirm all public resources use HTTPS and that filenames and URL casing
      work on GitHub Pages.
- [ ] Test the 404 page and any redirects from older download or documentation
      URLs.
- [ ] Check page loading, image sizes, layout shifts, and obvious performance
      regressions.
- [ ] Confirm analytics, privacy, cookie, and external-widget behavior remains
      appropriate and that no credentials or private configuration are present.
- [ ] Preview the complete website locally from a clean checkout and compare it
      with the current public site before deployment.
- [ ] After authorized deployment, hard-refresh and test the public
      `index.html` and `downloads.html` from an uncached browser session.
- [ ] After authorized deployment, verify GitHub Pages status, custom-domain or
      canonical settings, HTTPS, sitemap access, translation loading, every
      download, and the public page source.
- [ ] Capture final desktop and mobile screenshots for the release record.
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
- [ ] Treat the Claude review as iterative, not a single pass: after
      corrections, have Claude re-review the specific changes made and
      independently re-run (not just re-read) the validation it can execute,
      until a round produces no new findings.

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

- [ ] Confirm explicitly with the developer that a push to the public
      `origin` repository is intended to replace the currently live public
      release, not just add alongside it, before pushing anything.
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
