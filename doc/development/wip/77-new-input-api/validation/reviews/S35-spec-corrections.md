# S35 — the owner's corrections to the dissolution spec, and what applying them touches

_2026-08-10, session35. The session pivots: Part 1 found the spec sound but incomplete in
places; the owner's reading finds it **wrong** in two, so the task is now to fix it. Corrections
are the owner's, given in-session; the verification, the enumerations and the consequences below
are mine, and every factual claim is checked in code._

---

## Correction 1 — `Key` is what a project consults, not `love.keyboard`

**The owner's correction.** `love.keyboard.isDown` is the low-level API. `Key` sits above it and
already does the left/right folding, so **`Key` is what a project *may* consult**. But projects
are strongly encouraged to reach for **combos and shortcuts first**, so that the hardware check
does not happen *inside* project code at all. There is a ladder, and the rungs are not equal:

1. **Shortcuts / combos** — the intended mechanism. Declarative, listable, one vocabulary.
2. **`Key.ctrl()` / `Key.alt()` / `Key.shift()` inside project code** — permitted, but a
   **symptom of possible technical debt**: it means logic that wanted to be a binding is asking
   the hardware instead.
3. **`love.keyboard.isDown`** — an **even stronger symptom, the method of last resort**. It still
   has a legitimate purpose: reading a key that is not a modifier at all, e.g. **visualising a
   keyboard and which of its caps are pressed**.

**What the spec got wrong.** The project guide's rewritten §"Held keys" teaches rung 3 as *the*
answer — *"For what a combo cannot express, **ask the keyboard**"*, with a worked
`love.keyboard.isDown('lshift', 'rshift')` example. It teaches the last resort as the
recommendation and never mentions `Key` at all. My own Part 1 findings inherited the error: F2
proposed fixing the keyboard example with `love.keyboard.isDown`, and cited turtle and clock as
proof the guide was right when they are in fact the examples that need correcting.

### Verified before writing this down

- **`Key` is reachable from a project and is already the established idiom.** It is a plain
  global (`src/util/key.lua:166`), required at boot (`src/main.lua:14`), and the project env is a
  clone of the application env. Three examples already use it from project code:
  `examples/sapper/main.lua` (four sites), `examples/tixy/main.lua:197`,
  `examples/paint/main.lua:407`. So this correction is not new API — it makes the guide describe
  what the codebase already does.
- **Harmony compatibility holds** (the owner's remark). `Harmony.utils.patch_isDown`
  (`src/harmony/init.lua:242-253`) replaces `love.keyboard.isDown` with a **variadic** wrapper —
  `function(...)` iterating every argument against its own held table and falling through to the
  real `isDown` when unlocked. `Key.ctrl()` calls `isDown('lctrl', 'rctrl')`, which that wrapper
  answers correctly. **Recommending `Key` breaks nothing under harmony.** Worth noting the
  contrast: harmony has been variadic all along, while `tests/mock.lua:30` is not — which is why
  the mock fix is a prerequisite and harmony needs no change.
- **`Key` covers the three modifier pairs and nothing else.** There is no accessor for an
  arbitrary key, so rung 3 is not merely tolerated for the keycap case — it is the **only** way
  to write it. The ladder is therefore honest, not aspirational.

### What applying it touches

- `doc/input_api.md` §"Held keys" — rewritten again: the combo-first advice stays, but the
  fallback is `Key`, the ladder above is stated, and the worked example uses `Key.shift()`. The
  keycap-visualisation case is where `love.keyboard.isDown` is shown, named as the last resort
  and justified by the fact that `Key` has no answer for a non-modifier key.
- `doc/development/internals/user_input.md` §"Key state" — already correct in substance (the
  matcher calls `Key.*`); it should not be left implying that a project's answer is the raw
  device call.
- `doc/development/decisions/input.md` Decision 30 — **rule 3 already says this** (*"`Key.*` at a
  call site remains a smell … should be replaced by the shortcuts mechanism"*). Rule 1's
  parenthetical *"`Key.ctrl()`/`Key.alt()`/`Key.shift()` — i.e. `love.keyboard.isDown`"* is about
  the matcher's source and stays true. The ledger needs no correction here; the **guide** was
  the document that drifted from it.
- **`examples/turtle/main.lua:34` and `:92`** — `love.keyboard.isDown('lshift','rshift')` →
  `Key.shift()`, `love.keyboard.isDown('lctrl','rctrl')` → `Key.ctrl()`. Two sites, not one.
- **`examples/clock/main.lua:68`** — `love.keyboard.isDown('lshift','rshift')` → `Key.shift()`.
- **`examples/keyboard/input.lua`** (the nested repo, and the F2 fix): `modHeld`'s three
  modifier questions become `Key.shift()` / `Key.ctrl()` / `Key.alt()`; `INPUT.held`, which
  exists to light up key caps, is the legitimate rung-3 case and reads
  `love.keyboard.isDown(<capname>)` per cap.
- **Left alone, correctly:** `examples/pong/main.lua:330`, `examples/pong/strategy.lua:35,37`
  and the pong README's snippet all poll arbitrary keys (`up`, `down`, a variable `k`). `Key`
  has nothing to offer them; they are rung 3 by necessity, not by neglect.

---

## Correction 2 — `gui` goes, leaving one line in the debt register

**The owner's correction.** `gui` support **was never requested**. It was added for
symmetry/completeness *with the shape that made it cheap at the time* — a table-driven builder
that folded every held key it was handed — and **that shape is now dissolved**. So it goes: out
of the code, the tests and the docs. The only trace left is a small record in the technical-debt
register saying `gui` is **supportable in principle but purposefully not supported at present**.

**This closes Part 1's F1.** My recommendation was to add `Key.gui()` for symmetry. The owner's
ruling goes the other way and dissolves the question: with the fourth row gone, no helper is
needed, the seventh combo test case is deleted rather than rewritten, and the `PENDING` marker on
the missing helper is answered by removal rather than by an addition. The reasoning is the same
one Decision 30 applies to the tracked set itself — *it was never a requirement, so it is
reverted on that basis* — and it is consistent with the strategic frame: no moving part beyond
the stakeholder ask without a justification.

### Every trace, enumerated

**Code**
- `src/util/key.lua`: `gui_k` (`:10`), the fourth `mod_triples` row (`:20`), `mod_rank.gui`
  (`:28`), `mod_order` (`:30`), and the three comments naming it (`:8-9`, `:14`, `:25`).
- ~~`src/harmony/init.lua`: the `Super` / `Hyper` / `H` token map entries (`:170-172`) and the
  `lgui`/`rgui` held slots (`:182-183`).~~ **[S35 SUPERSEDED, owner 2026-08-10] Harmony is not
  touched.** The later investigation established that these are **pre-existing** — byte-identical
  at PR base `3256aac`, from harmony's own first commit — and that this feature's only obligation
  to harmony is to stay compatible, which it does. They were inert before the feature and stay
  inert under Decision 31. See the plan's §14 and `S27-triage-and-plan.md` §11.4.2's must-nots.

**Tests**
- **[S35 CORRECTION, 2026-08-10] `tests/mock.lua`'s `lgui`/`rgui` slots STAY.** This enumeration
  first listed them for removal; the cold site enumeration
  (`../outcomes/S35-dissolution-site-enumeration.md`) is right that that was wrong. That table
  mocks the **device**, and a real keyboard still has Super keys — Decision 31 removes `gui` from
  the *modifier set*, not from the set of keys that exist. Stripping the slots would leave the
  mock unable to represent a physically-held Super key, which is now an ordinary bindable
  trigger. The same reasoning covers harmony's `held` slots, already left alone for their own
  reason.
- `tests/input/keys_pressed_spec.lua`: the seventh combo case, *"all modifiers: ctrl alt shift
  gui"* — **deleted**, not rewritten.

**Docs**
- `doc/development/internals/user_input.md:264` — the precedence sentence names four rows; it
  becomes three. `:276` — the `gui()` `PENDING` marker is removed with the row it asks about.
- `doc/development/decisions/input.md:392` — **Decision 8 names the precedence order as
  `(ctrl, alt, shift, gui)`**. This is ratified text, so it is corrected in place with a dated
  amendment note, exactly as session34 did for Decision 21 — the decision itself (fold, fixed
  precedence, `+`-joined, trigger last) is unchanged; only the membership of the list moves.
  *Note the code currently mis-cites this:* `src/util/key.lua:25-27` attributes the four-name
  order to Decision 8, which is right today and must move with it.
- `doc/development/technical_debt/input.md:853-871` — the `gui_k` entry stops being *"anticipated,
  revisit at the named point"* and becomes the **record the owner asked for**: `gui` is
  supportable in principle, deliberately unsupported now, and the reason (never requested; added
  for symmetry with a shape that no longer exists).

### One behavioural consequence to record, not to hide

`Key.is_mod` and the `fold_mod` table are derived from `mod_triples`, so removing the row changes
two things beyond serialisation:

- **Registration of a `gui` combo starts failing loudly.** `split_combo` will read `gui` (and
  `lgui`/`rgui`) as a *trigger* rather than a modifier, so `shortcuts.keypressed['gui+s']` hits
  `check_combo`'s "names more than one trigger" error instead of normalising. That is the right
  failure for "purposefully not supported" — a project asking for it is told so — and it belongs
  in the debt entry as the observable shape of the non-support.
- **A Super keypress stops being modifier-shaped.** `find_shortcut` refuses the class fallback
  when `Key.is_mod(trigger)` is true; with the row gone, pressing Super while Ctrl is held would
  dispatch trigger `lgui`, miss `'ctrl+lgui'`, and then **match a registered `'ctrl+*'` class**,
  which it does not today. Nothing in the tree registers a class shortcut that would notice, but
  it is a real difference and the debt entry should say it, so a future reader who re-adds `gui`
  knows what they are restoring.

---

## Consequences for what Part 1 reported

| Part 1 finding | Status after the corrections |
|---|---|
| **F1** — the `gui` row blocks a test case; add `Key.gui()` | **Superseded.** `gui` is removed instead; the test case is deleted and the marker answered by removal |
| **F2** — the platform step crashes `examples/keyboard` | **Stands, with the fix changed:** `Key.*` for the three modifier questions, `love.keyboard.isDown` only for the per-cap read. The crash mechanism and the ordering problem are unchanged |
| **F3** — nothing says whether a modifier's own press still serialises as `alt+lalt` | **Stands, unchanged** |
| **F4** — what a project sees after the field is removed | **Stands, unchanged** |
| **F5** — markers honest; the blanket one over-covers | **Stands**, minus the `gui()` marker, which correction 2 deletes |
| **F6** — `internals/examples/keyboard.md` missed by the sweep | **Stands**, and gains a member: its suggested design should now point at `Key`, not at "the held set" |
| **F7** — `tests.md:73` unmarked | **Stands, unchanged** |
| **F8** — pre-existing citation rot | **Stands, unchanged**; still not this session's work |
| **Clean bill:** *"ask the keyboard is proven in-tree — turtle and clock already do it"* | **Withdrawn.** They do it at the wrong rung; they are work items, not evidence |
