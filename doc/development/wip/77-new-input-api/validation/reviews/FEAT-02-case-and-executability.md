# `FEAT-02` — does the case hold, and is the attestation executable?

**session58, 2026-08-30.** The scoped revalidation `agents/rules/revalidation.md` asks for, narrowed
by the session58 prompt to the two things the `FEAT-01` peer review could not cover: the sprint did
not exist when that review ran. **The peer review is not repeated.**

Written by a reader who did not argue for `FEAT-01`'s Q1 — the ruling this sprint overturns.

---

## 1. Does the case for `FEAT-02` hold up?

**Yes, on all three of its grounds, and the load-bearing one is understated.**

### 1a. The live defect — verified, and worse than the ledger says

The claim: *disarming a `oneshot` today costs the user's draft*. Traced end to end:

| step | site |
|---|---|
| `oneshot` is a show-only key | `SHOW_ONLY_KEYS`, `consoleController.lua:599-604` |
| so `configure{oneshot}` raises, naming `show()` | `check_keys` / `bad_key_message`, `:634-646`, via `api_configure` `:775` |
| pinned | `configure raises on oneshot, naming show()`, `input_widget_control_spec.lua:162` |
| the only other route is `show`, and over a live widget it needs `force` | `UserInputController:show`, `userInputController.lua:359-364` |
| a forced `show` is a full re-setup: no `text` → `clear_input()` | `reset_content`, `:304-310` (Decision 35, statement 4) |
| and `clear_input` drops more than text — selection, custom status, history index | same comment, `:296-301` |
| pinned | `force without text clears the content` |

**The escape hatch named in the debt entry and the attestation does not exist.** Both say the cost
is the draft *"or an exact hand re-supply of `text` and `cursor`"*. A project cannot re-supply it:
the widget surface is `show / hide / is_shown / get_cursor / set_cursor / set_text / configure /
clear` (`build_widget_api`, `consoleController.lua:811-876`) — **there is no text getter**, and a
project's `love` is a sandboxed clone, so the model is unreachable (Decision 18). `get_cursor`
exists; a content read does not.

So the true statement is stronger: **disarming a live `oneshot` destroys a draft the project has no
way to read back.** The user retypes, or the project does not disarm. That is a defect on any
reading, and it is the strongest single argument for the change.

> Correction owed: `technical_debt/input.md`, `T-ONESHOT-SCOPE`, **State** — the "or an exact hand
> re-supply" clause is false and should go. The attestation's closing section carries the same
> clause; it is a record of a discussion, so the correction belongs in the debt entry and in
> `FEAT-02-01`'s amended text, not in a rewrite of the note.

### 1b. The principle — it survives contact with the code

The category's stated reason is that the three remaining members are not the project's to set at
`configure`, and the code agrees for each:

- `text` / `cursor` — the **user's** content; `reset_content` is activation-only for exactly that
  reason, and `set_text` / `set_cursor` / `clear` are the live writes.
- `force` — answers *"replace the widget already up"*, a question `configure` never faces. Not
  protected from `configure`; **meaningless** there.
- `oneshot` — neither. It is machinery: a field on the widget read by `submit_flow`'s last line.

**Admitted on a resemblance to two keys it does not resemble** is a fair description of Decision
36's edge 1, not a rhetorical one.

**Nothing the category protects is touched by the move.** `UserInputController:configure` runs
`configure_core` + `update_view` and nothing else (`:387-390`); `configure_core` writes the prompt
label and the callback table (`:285-294`). Adding a widget field there reaches no content path.
Arming or disarming while **hidden** is coherent for the same reason `prompt` is: the fields are
written onto the widget and the widget outlives its own visibility.

### 1c. What the sprint knowingly accepts — stated, not re-litigated

Decision 36's edge 1 argued against stickiness on a real ground: *"a later bare `show()` would close
on submit for reasons written elsewhere"*. **`FEAT-02` accepts that astonishment** and pays for it
twice — with the **name** (`auto_hide` reads as a mode; `oneshot` reads as one-off) and with the
**guide line** that says persistence out loud. That is a trade the owner made explicitly, with the
counter-argument on the record: `validator` persists the same way and surprises nobody, because that
*is* the documented rule.

Worth noting only because a cold reader should see it named rather than discover it: after `-03`,
`it is spent by its own show` inverts, and that inversion **is** the astonishment. It is priced.

### 1d. Verdict

**The case survives an independent reading.** I found nothing that argues for keeping `oneshot`
show-only. The defect is real, the principle is sound, the cost is known and paid for.

---

## 2. Is the attestation executable on its own?

**Not quite — two rows of the ledger cite things that were withdrawn the same day.** Both are the
hazard `agents/rules/roadmap.md` §5 names: not a dangling reference, but one that **still resolves**
to something that no longer means what it did.

### Defect A — `FEAT-02-04` still says the rename is off the table

`ROADMAP.md:457` (row `FEAT-02-04`, notes):

> *"Renaming is off the table (Decision 36 grounds the flag on being a restoration of that exact
> name, asked for by an outside developer), and whether the replaced API's `oneshot` self-cleared is
> **not checkable in this repo**, so a migrating author's expectation is unknown."*

Both halves were overturned on 2026-08-30, in the same pass that inserted `FEAT-02-02`:

- the rename **is** the sprint's second row;
- the base check ran ([`../notes/oneshot-at-the-pr-base.md`](../notes/oneshot-at-the-pr-base.md))
  and showed there is no migrating author to be familiar with the name.

An executor working `-04` literally would write a guide warning about the ambiguity of a key that
no longer exists, and would restate a false claim. **The row's second obligation — say the
persistence plainly — stands; its justification paragraph is stale.**

*(The same stale sentence rode into the session58 prompt's third bullet. Prompts are immutable;
recorded here so it is not read as a live instruction.)*

### Defect B — `FEAT-02-05` wires a test to the withdrawn row

`ROADMAP.md:458`:

> *"`it is spent by its own show` becomes **the going-down rule**"*

The going-down rule is `disarmed when the widget goes down` — **withdrawn by the owner**, and the
prompt's own third warning is *do not re-file the clearing rule*. Executed as written, `-05`
re-files it in a test, which is the most durable place to put it.

The correct inversion under the settled reading: **the flag persists across a later bare `show()`,
and `auto_hide = false` disarms it** — the same shape as `validator`'s persistence.

### Defect C (minor) — the attestation's ruling list contradicts itself once

`owner-attestation-oneshot-widget-property.md`, *What was ruled*, item 1 closes on the owner's quote
*"`oneshot` should be a widget property, **cleared on consumption**"*. Items 2, 2a and 2c supersede
it — persistence, no clearing rule, and the rename — but item 1 carries no marker, and a reader who
takes the numbered list as the spec gets consumption semantics.

The quote is a record of what was said and should not be rewritten. **Proposed:** a parenthetical
marker on item 1 pointing at 2a, in the note's own editorial voice.

### What is executable, and is not in doubt

Everything else in the sprint reads cleanly against the code: the ledger gate's two amendments, the
key's move into `configure_core` and out of `SHOW_ONLY_KEYS`, `false`-as-unset arriving free from
Decision 35 statement 3, the no-getter line, the persistence obligation on both `-01` and `-04`, and
the instruction not to touch the flag's read placement in `submit_flow`.

### Rename blast radius — checked before it bites

`oneshot` is **not** one token in this tree. Do not rename:

- **the profiler** — `controller/profiler.lua:15,18,44,60`, `controller.lua:842,1080-1082`, and the
  pending reserved-combo case at `input_global_shortcuts_spec.lua:338`;
- **`src/lib/metalua/`** — unrelated vendored code;
- **two historical comments** — `userInputView.lua:290` and `userInputModel.lua:436-439` say
  *"oneshot is gone"* about the **base's** model constructor argument, not about this key. Renaming
  them would make them false.

Rename: `types.lua:197`, `consoleController.lua:595,603`, `userInputController.lua:328-332,450,473,
476`, and the eight test occurrences in `input_widget_callbacks_spec.lua` and
`input_widget_control_spec.lua`.

---

## 3. Recommendation

Proceed with `FEAT-02` as filed, with three corrections folded into the passes that own them:

1. `-01` corrects `T-ONESHOT-SCOPE`'s **State** (drop the false re-supply clause) — the ledger pass
   already touches the debt entry.
2. `-01` also repairs `ROADMAP.md:457` and `:458`, since a retirement takes its citations with it
   and `FEAT-02` is the pass that owns them.
3. The attestation gets one editorial marker on ruling 1; the owner's words stay as spoken.
