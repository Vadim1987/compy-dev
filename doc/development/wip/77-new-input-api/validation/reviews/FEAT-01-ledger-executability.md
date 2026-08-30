# `FEAT-01` — is the ledger executable? A cold implementer's reading

**Session57, 2026-08-30.** Scoped revalidation of `OP-01`'s output, per `session57/prompt.md`. The
cold review of session56's work already ran and is not repeated
([`../outcomes/session56-input-work-cold-review.md`](../outcomes/session56-input-work-cold-review.md),
*sound with corrections*); it audited **fidelity to the owner's input**. This one asks the other
question: **can `FEAT-01` be built from Decisions 36 and 37 alone**, and does the corrected text hang
together. Everything below was verified in code at HEAD `02cc51f9`, suite **1011 / 0 / 0 / 10**.

---

## 1. Decision 37 — the payload split: **executable, with one correction**

**The mechanics are fully specified.** The change is one argument at
`userInputController.lua:446` — `run_callback(self, 'on_text_entered', lines)` becomes the joined
string. The decision names `string.unlines` itself, which is `string.join(strs, '\n')`
(`util/string/string.lua:292`) — newline-separated, no trailing newline. `after_submit(lines)` at
`:447` is unchanged, and the guide already documents it that way (`doc/input_api.md:212`). Nothing
has to be guessed.

**The consumer census is correct as corrected.** Re-verified all seven independently:

| consumer | site | shape |
|---|---|---|
| `maze` `submit_program` | `examples/maze/core_editor.lua:46-47` | `string.unlines(lines)` first statement |
| `tixy` `submit_body` | `examples/tixy/main.lua:176-177` | `string.unlines(text)` first statement |
| `balloons` `deliver` | `examples/balloons/terminal.lua:14-15` | `string.unlines(lines)` first statement |
| `repl` | `examples/repl/main.lua:10` | `print(string.unlines(lines))` |
| `turtle` | `examples/turtle/main.lua:93-94` | `eval(lines[1])` |
| `valid` | `examples/valid/main.lua:87` | `print(lines[1])` |
| `guess` | `examples/guess/main.lua:54` | `check(tonumber(lines[1]))` |

The corrected `maze` claim is right — it does the join itself, like the other three.

### The correction: the migration is optional for four and **mandatory for three**

Decision 37's consequence paragraph reads as though all seven merely *simplify*. They do not, and the
asymmetry runs the opposite way to the sentence's emphasis:

- **`string.unlines` is idempotent over a string.** `string.join` returns its argument unchanged when
  handed a string (`string.lua:284-286`). So the four consumers that join keep working **untouched**
  under the split — their migration is cleanup, which is exactly what `FEAT-01-07` is for, and
  `wontfix` on any of them costs nothing.
- **The three `lines[1]` consumers break, and break silently.** Indexing a Lua string with `[1]`
  yields `nil` — no raise. `turtle` would `eval(nil)`, `valid` would `print(nil)`, `guess` would
  `tonumber(nil)`. These are not cleanup; they are the migration, and they must land **with**
  `FEAT-01-04`, not after it.
- **Both separate-repo consumers are in the safe group** (`maze`, `balloons`), and all three
  mandatory sites are in-tree. So the breaking half of this change needs no cross-repo coordination
  — a fact worth having when `CHG-01`'s migration note is written, and worth having *early*, because
  it is the opposite of what "two of them live in other repos" would lead a planner to assume.

**A second, smaller behaviour change the ledger does not name.** The payloads are identical only
while the widget holds one line. Shift+Enter is a line feed in any widget
(`userInputController.lua:658-664`), so for `turtle`/`valid`/`guess` the split changes *what they
receive* in the multi-line case — the whole text instead of its first line. That is arguably a
latent-bug fix rather than a regression, but it is a behaviour change on three shipped examples and
belongs in the migration note rather than being discovered by a reader.

## 2. Decision 36 — `oneshot`: **executable except for one edge, plus an unnamed consequence**

**What the decision does specify, and specifies well.** Its anchor — *the flag replaces
`after_submit = function() compy.input.hide() end`* — is a precise specification, not a motivating
analogy, and it settles four questions without stating them:

- **What "closes" means:** `hide()`, not `cancel_flow` — the boilerplate's own call.
- **Exactly when:** wherever `after_submit` fires (`:447`), so a `before_submit` veto, the empty
  guard and a validator rejection each suppress the close for free (`:439-445`). "After a
  *successful* submit" needs no separate rule.
- **Ordering:** after the project's own `after_submit`, as the recommended edge states.
- **Non-sticky ⇒ seated unconditionally at activation**, so a later bare `show()` clears it; and
  **show-only ⇒** an entry in `SHOW_ONLY_KEYS` (`consoleController.lua:595-599`), which buys the
  refusal-at-`configure` message with no extra rule.

### The hole: *"it closes even if a callback raised"* is not implementable as written

The decision grounds this edge on *"the submit chain runs under an error boundary"*. **The boundary
is real but it is nowhere near the submit chain.** `with_canvas_and_errors` wraps the *route entry*
(`controller.lua:161`, installed at `:238`) — deliberately, and the comment at `:152-157` says why.
`run_callback` calls the callback directly (`userInputController.lua:427-431`), so a raise in
`on_text_entered` unwinds straight out of `submit_flow`; **today it already skips `after_submit`.**

So appending `if self.oneshot then self:hide() end` after the callbacks does **not** honour this
edge. Honouring it needs one of:

1. a protected call around the callback pair inside `submit_flow`, hide, then re-raise so the route
   boundary still suspends the project as it does today; or
2. hide *before* running the callbacks — cheaper, but it reorders an observable: a callback would
   then see `is_shown() == false` for its own submit.

That is a shape choice with a visible consequence, and a sub-question rides on it (**if
`on_text_entered` raises, should `after_submit` still run?** — today it does not, and this edge is
not a reason to change that). **It belongs in the `FEAT-01-01` ruling sheet**, not in the
implementer's judgement at `FEAT-01-02`. This is the one place where building from the ledger alone
would have meant guessing.

### The unnamed consequence: `oneshot` is the first show-only key that outlives its call

`text` and `cursor` are seated into the model during activation; `force` is consumed inside `show`
and never stored. **`oneshot` must be remembered from activation until a later submit** — a new
per-widget store. Three notes, none blocking:

- It is **compatible with `ARC-01`**: a per-run widget means the flag dies with the run, which is the
  lifetime it wants.
- It does **not** resurrect `state.pending`, which `ARC-02-05` deleted — that store lived on the
  *surface* and buffered configuration for a widget that was not up yet. This one lives on the
  widget and is only readable while it is.
- But it means Decision 35's show-only category now contains two kinds of key: *seated-and-spent*
  and *remembered-for-this-session*. The ruling sheet should say so, because "same side of the
  boundary as `text`, `cursor` and `force`" is true of where the key may be *passed* and not of what
  happens to it afterwards.

## 3. Verdict

**Decision 37: build it.** The one correction above sharpens the migration; it does not change the
ruling.

**Decision 36: two items for `FEAT-01-01`** beyond ratifying the four recommended edges — the
*mechanism* for the raised-callback edge (which is a ruling, because option 2 changes what a
callback observes), and an acknowledgement that the flag introduces a remembered show-only key.
Everything else in Decision 36 is executable as written.

**The instrument worked.** Both findings are things a warm session would have supplied from memory
without noticing the ledger never said them.
