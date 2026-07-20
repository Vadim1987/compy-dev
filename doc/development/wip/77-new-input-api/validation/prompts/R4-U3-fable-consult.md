# R4/U3 — Fable oracle consult: submit/cancel callback plumbing + overlay scoping

**You (Fable) authored the delta-design + delta-spec for the #77 input-API redesign.**
Session17 (Opus) is executing R4. U1 (widget-method factory) and U2 (surface reshape into
frozen shortcuts/hooks/callbacks; hooks seeding; guard) are landed and green (819/0/0/4).
U3 is the coupled behavioral unit: §2 free-function dispatch + tier-1 removal + §3 widget
submit/cancel defaults + default-flip/veto/shadowability + §6 console patch (AC1-7, AC10).

Two design questions surfaced that your §3/§6 pseudocode does not fully pin down, and being
wrong is costly (it's the core of the redesign). I've verified every code fact below against
the current tree. Please rule on the intended model, and flag anything I've misread.

## Verified code facts (current tree, post-U2)
1. **Overlay widget = boot singleton.** `main.lua:381` sets `love.state.user_input_controller
   = UserInputController(ui_m, nil, true)` once at boot. This one instance IS the project
   overlay widget.
2. **Console/editor have SEPARATE UIC instances.** `consoleController.lua:44
   UserInputController(M.input)`; `editorController.lua:12/16` two more. None is the overlay.
3. **Console/editor call their own `IC:keypressed` DIRECTLY, not via the project dispatch.**
   `ConsoleController:keypressed` → `input:keypressed(k)` (input = console's own IC) for
   editing, then separately `if Key.is_enter(k) then self:evaluate_input()`. Editor has its
   own `submit()` local and only calls `input:keypressed(k)` on passthrough.
4. **Old submit/cancel lived at the project ROUTE's tier-1** (`framework_submit`/
   `framework_cancel` on ProjectInputController), so it NEVER touched console/editor. Their
   own `UIC:keypressed` has an escape→`model:cancel()` (clear-only, no hide) local for their
   own routes; the project overlay's escape was intercepted by tier-1 before reaching the
   widget.
5. **Outputs vs lifecycle callbacks reach the widget by DIFFERENT paths today:**
   - outputs (on_text_entered, on_limit_reached, validator, highlighter): via
     `merge_output_keys` → show/configure cfg → `apply_config` → flat widget fields
     (`self.on_text_entered` etc.), sticky across shows (doc/input_api.md "Sticky callbacks").
     Your delta-design D5 says outputs are "unaffected in substance."
   - submit/cancel four (before/after submit/cancel): were read LIVE off `compy_input` by the
     route's `run_hook` each event — never on the widget.
6. **`compy.input.callbacks` is a per-project-env store** (built in `get_compy_input`), a leaf
   proxy over `state.callbacks`. The overlay widget (boot singleton) has no reference to it.
7. `is_shown()`/`_is_hidden_overlay()` already key on `self == love.state.user_input_controller`.

## Q1 — Callback storage/plumbing (how do project callbacks reach the widget's self.callbacks?)
§3 reads `self.callbacks.validator` and `run_callback(self, 'before_submit', ...)`; §6 sets
`console_widget.callbacks.on_limit_reached`. So the widget has a `self.callbacks`. What is the
intended single model?
- (a) Does every UIC get ONE `self.callbacks` table holding all 8 (outputs + lifecycle), or
  do outputs stay as today's flat sticky fields and only the submit/cancel four move onto the
  widget?
- (b) For the project overlay, is `self.callbacks` fed by **sharing** `compy.input.callbacks`
  by reference (live — matching the old live-read of submit/cancel), or by **copying** at
  show() (sticky — matching today's outputs)? Where is that wire established (activate? show?)?
- (c) Is the documented sticky-output delivery preserved, or intentionally replaced by live?
  (Your delta-design frames D5 as "unaffected in substance" — I read that as: keep outputs'
  delivery as-is. Confirm or correct.)

My lean: minimal — keep outputs exactly as today (flat, sticky, apply_config), give the widget
a `self.callbacks` for the four lifecycle fns, and wire the overlay's `self.callbacks =
compy_input.callbacks` (live, by reference) at `ProjectInputController:activate`. Console sets
its own IC's `self.callbacks.on_limit_reached` directly (§6). But this leaves on_limit_reached
inconsistent (flat for overlay, callbacks.* for console) — which bothers me. Rule on the clean
intended shape.

## Q2 — Scoping submit/cancel to the overlay (avoid console/editor contamination)
§3 puts `_submit_default`/`_cancel_default` in `Widget:keypressed` triggered by return/escape.
But console/editor call their own `IC:keypressed` directly (fact 3), so a return-check inside
`UIC:keypressed` would fire submit on console's enter (which must go to `evaluate_input`) —
contamination the old route-level tier-1 avoided. Note: escape is naturally safe (both old and
new default = clear-only-stay-open), only submit-on-return contaminates. How should submit be
scoped to the project overlay ONLY, while console/editor keep their own enter-handling until
they migrate?
- (i) gate the submit/cancel-default on overlay identity (`self == love.state.user_input_
  controller`), reusing the existing `_is_hidden_overlay` pattern;
- (ii) a constructor flag on the overlay UIC;
- (iii) the project ROUTE (dispatch) invokes `widget:_submit_default()` for return/escape
  explicitly, rather than the widget self-checking `k` inside keypressed — keeping console/
  editor (which never go through this dispatch) untouched.

My lean: (iii) or (i). (iii) keeps "context/route owns lifecycle trigger, widget owns the
default behavior" — which echoes your delta-design's own "widget owns detection, context owns
lifecycle" framing — and keeps console/editor provably untouched without a new flag. But it
deviates from §3's literal "Widget:keypressed checks k=='return'". Which did you intend?

## Deliverable
A crisp ruling on Q1(a/b/c) and Q2, in enough detail to implement directly, plus any
correction to my facts. Being concrete about the exact table wiring and the exact trigger site
is what I need. Keep it focused.
