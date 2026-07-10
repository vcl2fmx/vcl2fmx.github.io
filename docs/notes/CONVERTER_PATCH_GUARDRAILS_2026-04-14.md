VCL2FMXConverter V3.0 Patch Guardrails

Purpose
Keep converter fixes grounded in official FMX/VCL behavior and prevent speculative patches.

Required investigation order for every converter patch
1. Identify the exact VCL source API and FMX target API involved.
2. Consult official Embarcadero documentation first, before editing code.
3. Record the documentation conclusion in the tracker or change note before or alongside the patch.
4. If the target API is not documented on the FMX target type, do not emit it into generated FMX output.
5. If the documented FMX equivalent is different, map to the documented equivalent or generate an adapter that uses documented FMX members.
6. If official documentation is silent, say that explicitly and mark the converter logic as an inference rather than a documented fact.

Minimum documentation standard
- Check the target FMX class events/properties page.
- Check the relevant parent class events/properties page.
- Check the source VCL class page if the conversion depends on VCL semantics.
- Prefer Embarcadero DocWiki over assumptions.

Required tracker note for behavior patches
- List the DocWiki pages consulted.
- State what the docs confirm.
- State what remains inference.

Documentation update guardrails
- Do not replace Word-authored guides with stripped-down regenerated documents if that would remove embedded graphics, authored formatting, `==>` markers, or the existing TOC field structure.
- For guide updates, prefer in-place edits to the real `.docx` files or a preserve-format workflow that starts from the last known-good Word-authored document.
- Stage documentation edits on a copy first when practical, then verify that embedded media, TOC fields, and key authored markers still exist before replacing the live guide.
- If a scripted export or rebuild changes the visual structure of the guides, stop and recover the original formatted document before continuing content work.
- Treat guide formatting, embedded graphics, and TOC integrity as release-quality artifacts, not disposable polish.

Current example: root-form OnDblClick
- Consulted DocWiki pages:
  - FMX.Forms.TForm_Events
  - FMX.Forms.TCommonCustomForm_Events
  - FMX.Forms.TFrame.OnDblClick
- FMX TForm and TCommonCustomForm document OnMouseDown, OnMouseMove, OnMouseUp, and OnTap, but not OnDblClick.
- FMX TControl documents OnDblClick for controls.
- Therefore the converter must not emit OnDblClick on FMX forms.
- If VCL form double-click behavior needs to be preserved, the converter should adapt it through documented FMX form mouse events rather than writing an invalid FMX form property.
