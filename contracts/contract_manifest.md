# Contract Manifest

Each sample is intended to become an input fixture with assertions against converter output.

## WinAPI Messages

- `01_single_line_real_sendmessage.pas`: real single-line Windows message call should be converted.
- `02_multiline_real_sendmessage.pas`: real multiline Windows message call should be converted.
- `03_user_defined_sendmessage_call.pas`: domain method named `SendMessage` should not be treated as WinAPI.
- `04_user_defined_getmessage_declaration.pas`: domain method named `GetMessage` should not be treated as WinAPI.
- `05_message_pump_calls.pas`: message pump calls should be removed/commented as FMX event-loop leftovers.
- `06_multiline_postmessage_user_message.pas`: multiline `PostMessage` with `WM_USER` should be reviewed/bridged.
- `07_perform_real_vcl.pas`: VCL `Perform` should be converted or reviewed.

## Uses Clause

- `01_original_winapi_messages_unused.pas`: unused original `Winapi.Messages` should not be retained.
- `02_implementation_only_winapi_units.pas`: implementation-only Winapi units should be dropped or re-added by active need.
- `03_user_defined_message_names_no_winapi.pas`: domain methods should not inject `Winapi.Messages`.
- `04_lowercase_cm_tcm_false_positive.pas`: lowercase/third-party identifiers should not trigger message units.

## Comments And Boundaries

- `01_boundary_after_commented_block.pas`: next routine declaration after a disabled block should not be converted.
- `02_comment_only_lines_inside_continuation.pas`: comment-only lines inside disabled blocks should stay inside the disabled block.
- `03_comments_should_not_trigger_uses.pas`: comments containing message APIs should not affect uses detection.
- `21_unsupported_message_try_except_depth.pas`: unsupported message handlers containing `try..except..end` blocks should keep the full outer routine marked for FMX manual review.

## Colors

- `01_class_should_not_add_uiconsts.pas`: `class`/`declare`/`TClassName` should not trigger `System.UIConsts`.
- `02_real_cla_color_should_add_uiconsts.pas`: real `cla*` FMX color usage should trigger required units.
- `03_vcl_cl_color_conversion.pas`: VCL `cl*` colors should convert/review correctly.

## Components And Events

- `01_message_handler_declaration.pas`: VCL message declarations should convert to FMX-safe handling or review notes.
- `02_wndproc_override.pas`: `WndProc` overrides should convert/review without leaving unsafe message logic silently active.
- `03_non_message_domain_methods.pas`: domain methods named like message pump APIs should not be converted.
- `21_shape_circle_quiet.pas`: VCL `TShape` circle/ellipse cases should generate FMX `TEllipse` output without noisy shape-property manual review.
- `22_numeric_math_div_multiply_chain.pas`: mixed FMX size math with `div` and multiplication should be converted to compile-safe floating-point math.
- `23_numeric_math_simple_div.pas`: simple dotted FMX size `div` expressions should use `/` without unnecessary `Round()`.
- `24_image_picture_assign_save.pas`: `TImage.Picture.Assign`, `SaveToFile`, and `Graphic` usage should convert to `TImage.Bitmap` equivalents with no `.Picture` residue.

## Additional Coverage Added

The expanded contract suite now includes:

- WinAPI message variants through single-line, multiline, qualified, lowercase, assignment, condition, and false-positive domain-method shapes.
- Uses-clause variants for bare units, implementation-only units, conditional units, duplicates, FireDAC wait mapping, and required Winapi/System units.
- Comment/boundary variants for method boundaries, initialization/finalization/end boundaries, string/comment false positives, directives, attributes, constructors, destructors, and class methods.
- Color variants for real `cla*`, false-positive `cla` substrings, VCL `cl*`, theme colors, RGB helpers, dialogs, modal results, and open-dialog enums.
- DFM/PAS pairs for basic controls, image lists, nested panels, menus/toolbars/status bars, page controls, action lists, and unsupported tray icons.
- Data-aware and LiveBindings samples for DB controls, runtime assignments, nested dataset access, existing bindings, grid links, bind sources, and multiple form declarations.
- Components/events samples for common VCL controls, event signatures, paint/draw handlers, media notifications, alpha blending, border/window state, image picture usage, status-bar panels, and unknown components.
- Graphics samples for VCL Canvas and GDI API usage.
- Project samples for DPR startup, resources, conditionals, and `ShowMainForm`.
- Project integration samples for include-file, Windows messaging, protected uses cleanup, DFM/FMXL generation, and real-world report-shape conversion across complete mini projects.
- Encoding/reporting/third-party samples for source robustness, generated issue reporting, and mapping-pack behavior.
