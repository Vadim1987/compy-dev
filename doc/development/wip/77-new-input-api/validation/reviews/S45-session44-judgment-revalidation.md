# S45 — revalidation of session44's two judgment artifacts

Scope: `S44-W9a-ledger-prune-verdicts.md` (five verdicts, executed as
`4add9897`) and `S44-decisions-33-34-revalidation.md` §6 (seven resolutions,
executed as `b52e217f`). Not in scope: the code and prose session44 wrote with
the owner in the loop turn by turn — what is checked here is what no one outside
that session has read.

Instrument, per the commissioning prompt:
`grep -rn 'Decision 6\|Decision 7\|Decision 12\|Decision 15\|Decision 16' src/ tests/`,
plus the code the claims rest on.

## 1. Intent

W9(a): apply the owner's test — *behaviour the platform always had was never a
decision* — to five challenged ledger entries, and retire or compress each
without breaking the 179 comments that cite decisions by number. §6: resolve
seven inconsistencies found while revalidating Decisions 33 and 34.

## 2. Verdict

**Both sound.** Every executed claim I could check against code or against the
tree checks out, including the ones a reader would simply have trusted. Four
findings, all small: one factually wrong identifier repeated in three persistent
docs (corrected here), one arithmetic slip in the record, one overclaim, and two
editorial residues that belong to P11's sweep.

## 3. What is clean — checked, not assumed

**The tombstones say what the ledger now says.**

- **Decision 12** — the tombstone's reason for existing is its citations, and
  all **seven** resolve: `controller.lua:639`, `main.lua:360`,
  `input_route_lifecycle_spec.lua:16,34,304,320`,
  `input_widget_control_spec.lua:660`. Each cites the *behaviour* (inspect is the
  console route over the project's env; a suspended project's widget goes
  unhonoured), which the tombstone keeps in full. The ledger's own two internal
  references (`:484`, `:660`) still read correctly against the retained text.
  Its pointer — "the narrative belongs to `internals/user_input.md`" — resolves:
  `internals/user_input.md:242` carries the mechanism, `get_user_input()`
  returning `nil` under `inspect` and `suspend()` swapping the handlers back.
- **Decision 16** — "nothing in `src/` or `tests/` cites it" is **true**: zero
  hits. Its two supersession claims hold in the corpus, not just in the ledger:
  `hooks.singleclick` is documented project-facing surface
  (`doc/input_api.md:331`, and in the migration table at `:596`), and the
  routing half it says is *still* deferred is Decision 1's, which stands.

**Decisions 6, 7 and 15 still carry every claim their citations rest on.** I
read all 26 citing comments (13 for Decision 6, 10 for 7, 3 for 15) and matched
each claim to the compressed text:

- Decision 6 — the two flow diagrams, the veto (both sides), auto-close OFF and
  the no-op `after_*`, shadowability with the withdrawn guarantee and the power
  keys as the real escape hatch, one path per instance, `hide()` fires no cancel
  flow: all present, all cited, none orphaned.
- Two claims in citing comments are **not** in Decision 6 and never were —
  "every project callback receives the widget's native line array"
  (`input_widget_callbacks_spec.lua:307`) and the `force=true` reconfigure firing
  no cancel (`:578`). Both stand on the code and on the part of the comment that
  does not cite the decision, so nothing was broken by the compression.
- The one detail the compression genuinely dropped — the editor handling plain
  and Ctrl+Enter and plain/Shift Escape, with Alt+Enter falling through — is in
  the persistent corpus at `internals/user_input.md:388` and `:420`, and the
  submit breadth is Decision 14's contract, which is what
  `input_widget_callbacks_spec.lua:1019` cites alongside Decision 6. **This is
  the standing rule working as intended:** the rationale a compaction removes
  already existed elsewhere.
- Decision 7 — the frozen container and sub-table identities, writable leaves,
  the eight `callbacks` members, the metatable one level down, "loudly, never a
  silent swallow", and the Decision 8 invariant the freeze protects: all present.
  `consoleController.lua:856` cites "Decision 7's first clause", which is still
  the first clause.
- Decision 15 — `check_keys` / `bad_key_message` exist
  (`consoleController.lua:594`, `:615`, called at `:674` and `:759`) and cite the
  decision back at `:604`, so the corrected status line is accurate. The dropped
  "why it was revised" argued against a warn-and-ignore form that never shipped;
  the surviving **Why** carries the case against warning on its own.

**§6's seven resolutions all landed, and are factually right.**

| # | Verified |
|---|---|
| F1 | The amend-in-place blockquote is at Decision 30 point 3's gate paragraph (`decisions/input.md:1217-1224`) and does say the table **is built**, the separateness requirement stands as a build instruction, and the predicate cascade is gone |
| F2 | "the first **three** become the project's, and the **fourth** stops firing `restart` and `reset`" (`:1426-1427`) |
| F3 | The decision cites the framework-shortcuts suite by path (`:1417`); the debt register's P15 reference is gone |
| F4 | The `quickswitch` clause is dropped; the poll form survives as the illustration (`:1400-1401`) |
| F5 | "three of its own, **or six** when the exact combo misses" (`:1495-1496`) |
| F6 | The truthy/falsy entry is re-grounded on **exactly** the six live splice sites — `editorController.lua:466,470,772,776`, `searchController.lua:101,105` — and a grep for a seventh finds only `editorController.lua:522`, which tests rather than splices. "No site in the tree compares a modifier read today" holds |
| F7 | `internals/user_input.md:199` enumerates `RESERVED` entry for entry against `controller.lua:850-867`, including the profiler pair, bare `f10`, and `ctrl+escape` alone on the release side. The per-entry state conditions (playback, profiling build) match the code |

**Arithmetic.** The ledger's `REMARK` count was **30** before the prune and is
**24** now — the six answered markers did go out with the work.

## 4. Findings

### S45-1 — `allow_modify` is not the flag's name (factual; CORRECTED here)

The constructor parameter and field are **`allow_duplicate_line`**
(`userInputController.lua:27-29`, stored at `:33`, read at `:685`; the editor
constructs with it at `editorController.lua:12`, and the tests set it by name at
`input_widget_callbacks_spec.lua:993`). Three persistent docs called it
`allow_modify`, one of them stating a **wrong constructor signature** a reader
would copy:

- `decisions/input.md:302` — inside the compressed Decision 6;
- `internals/user_input.md:406-407` — the signature;
- `technical_debt/input.md:1373, 1379`.

Pre-existing, not minted by session44 — but the compression rewrote the sentence
that carries it in Decision 6 and kept the error, and W9(a)'s claim was that
every claim the citations rest on survived. **Corrected in all four places.**
`modify`, the local function it gates, keeps its name.

### S45-2 — the prune was 1567 → 1500, not 1556 → 1500 (record; CORRECTED)

`4add9897`'s parent (`9090085d`) has a **1567-line** ledger. The 1556 figure was
a real measurement taken earlier in session44, before `b52e217f` added the F1–F7
resolutions to the same file, so the recorded range mixes two baselines. The
prune removed **67** lines, not 56. Corrected in the verdicts doc and in plan
§17.3; the commit message keeps the figure it was written with.

### S45-3 — "no wip path remains in the persistent corpus" is an overclaim (RAISED)

§6's F3 row ends with that sentence. Two remain, and both rot when `wip/77` is
deleted:

- `technical_debt/input.md:1577` → `../wip/77-new-input-api/validation/notes/S43-ctrl-shift-escape-probe.lua`
- `internals/examples/keyboard.md:241` → `doc/development/wip/77-new-input-api/validation/reviews/P-18-00-keyboard-deepfix-design.md`

F3's own scope was the decision and the debt register's P15 line, both of which
are clean — it is the closing generalisation that is wrong. Neither is a code
comment, so neither is caught by the P11 gate; they need dispositions before the
tree is deleted. Listed for the P11 inventory rather than fixed here, since the
second is an example-repo-facing doc and the first cites a probe script that may
be worth promoting rather than dropping.

### S45-4 — two editorial residues of the compression (RAISED, P11's)

- **`consoleController.lua:519` and `:803-804` say "Decision 7 revised" and
  "Decision 10 revised".** Neither entry carries a revision marker in the ledger,
  and for Decision 7 the history that made "revised" meaningful is exactly what
  W9(a) removed. Both comments state their content in place, so nothing is
  unresolvable — the word is now history narration with no referent, which
  `agents/rules/commenting.md` prohibits anyway.
- **`technical_debt/input.md:1561-1563`** still anchors the pre-fix gate by line
  number (`:882-890`, `:766-864`) into a `controller.lua` Decision 34 rewrote.
  It is explicitly labelled as the state before the fix, so it misleads nobody
  about today's behaviour, but the anchors are dead — the same defect F7 fixed by
  replacing anchors with symbol names.

## 5. Calibration

Neither artifact is over-done. The compressions cut history, an allowlist that
never shipped and a per-context walkthrough — the four payloads survive in every
case I checked, and the one dropped detail had a home in the corpus already. The
tombstones are the minimum that keeps the numbers resolving, which is what the
hard constraint asked for. Nothing is under-done: the entries left uncompressed
were not in W9(a)'s scope.
