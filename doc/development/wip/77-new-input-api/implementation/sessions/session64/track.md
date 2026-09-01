# session64 — track

## Boot — 2026-09-01

- HEAD `c8e149c7`; branch `feature/77-newapi-analysis-s20260615`.
- Working tree: only the known untracked scratch (`broken-busted/`, `claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `src/examples/{balloons,keyboard,maze}`,
  `worklog.md`). Nothing of the owner's to protect in a commit yet.
- Suite: **1048 / 0 / 0 / 10** — matches the prompt's baseline exactly. Interpreter is the
  container's **LuaJIT 2.1**, not the owner's PUC Lua.
- `lua-lsp` **is back**. Session63 ran with `broken pipe` all session; a `references` query on
  `checked_text` returned real AST hits (consoleController L791, L826). Caller enumeration this
  session is AST-backed.
- Re-entrance: no `track.md`/`report.md` existed → fresh start.

## Owner ruling — scope of the pass (2026-09-01)

The prompt proposed sessions **60, 61, 63**. Owner cut it: **61 and 63 max**.

> *"if 61 did revalidation then we won't recurse into revalidation spiral. lets see if 61 delivered
> something beyond revalidation (e.g. it could be asked for doing next step after revalidation
> pass) and start from there."*

So: session60 is **out** (61 already revalidated it — re-revalidating is the spiral). For session61
the subject is **what it delivered beyond its own verdicts** — its nine durable document edits, not
its findings. Session63 is in full.

Session61's delivery surface, from `git log 74a5e8fb..30308ed6`:

| commit | delivered |
|---|---|
| `13d9dd33` | `ui_messages.results` recorded as fixed in both records |
| `4ccd636f` | roadmap suite row 1030 → 1032 |
| `57ec0cca` | `agents/validation.md`: persistent corpus as a **rule**, not a list |
| `67a0ccfd` | Decision 8 gains the lower-case canonical-combo note |
| `ba09edcc` | `internals/user_input.md` cursor census 3 → 4 (`_apply_eval` added) |
| `2b59ca16` | debt: why the guide's *"every cursor position"* still holds |
| `4494a6f4` | `BUG-02` filed three ways + the row that rules on it |
| `34b9c40d` | two roadmap sizings re-counted |
| `4b6cd5d9` | `ACC-02` note — `BUG-01-09` reaches tixy, inert there |

## Pass results — 2026-09-01

**Session61's nine deliverables: all standing.** Verified in code/docs, not taken on report:
`ui_messages.results` reads *fixed* in both records; Decision 8 carries the lower-case note;
`agents/validation.md` states the corpus as a rule; `BUG-02`'s three-way filing closed consistently
in all three homes; `FIX-02-09`'s re-count of 13 still holds; `FIX-01-02`'s "re-derive" instruction
is doing its job (the count has drifted up again, as predicted). One deliverable was overtaken —
the census, F1 below.

**Session63's corrected claims: verified right.** `_set_text_line` has seven callers, all passing
`true`; `clear_input` is `_update_cursor`'s only reachable caller; `is_line_list` counts over
`pairs` and genuinely closes the hole `ipairs` left; the guide's *"refusal leaves the current
content untouched"* holds — `checked_text` raises before any state is touched, on both paths.
Marker gate clean; the one `DEBT:` marker is exemplary and its cited section resolves.
ACTIVE/BACKLOG slug convention survived six new entries (ACTIVE 3, all slugged; BACKLOG 46, none).

**Findings — registered in `technical_debt/input.md` at `da0def9d`, not fixed:**

- **F1 — the cursor census was left behind by session63's own discovery.** `internals/user_input.md`
  says four programmatic sites; `insert_text_line` is a fifth by the census's own definition, and
  the register says so 90 lines away in another file. Substantive: two docs, two answers.
- **F2 — four line citations stale on arrival.** `e3484987` shifted the lines by 3 with its own
  `DEBT:` comment and wrote the citations against the old numbering in the same commit. Session61
  had delivered the "cite the function name" lesson one day earlier.
- **F3 — `FIX-02-09` is sized by one file and the corpus is `#77`'s own.** Verified at the merge
  base: no `CHANGELOG.md`, no `smoke_checklists.md`, five entries under `doc/development/`.
  `smoke_checklists.md:215` has the banned idiom verbatim; session63 added a fresh one to
  `CHANGELOG.md:164`.
- **F4 — for the owner, not the ledger:** the boundary validates 2 keys of N. `check_keys` admits
  by name; `checked_cursor`/`checked_text` check values; four callables and `prompt` are unchecked
  and registered unslugged. Two sprints closed this class one key at a time. The guide documents
  the refusal for `cursor` and `text` and is silent on the rest, so a reader cannot tell which keys
  are checked.

**Proportionality (owner's second thread), measured `3dd14192..HEAD`:** ~100 lines of production
change → **620** lines of persistent documentation + **1445** lines of ephemeral session artifacts.
`technical_debt/input.md` alone took **+383** in one day, on a register that is now 2447 lines.

**No regression of the session63 shape found elsewhere.** The one worked example named in the
prompt (a fix shipped, then re-done inside the sprint) does not repeat in session61's output.

## Owner ruling — documentation volume (2026-09-01)

> *"as for volume size: we have planned compaction step before release. in the meantime, verbose
> docs support ongoing development and troubleshooting."*

Not a finding. Recorded on the ROADMAP beside Phase L's retirement, framed as the doc-corpus
statement of `commenting.md`'s existing *"do not compact as you go"*. **Raised with it, unanswered:**
the scheduled compaction covers **comments**; Phase L (ledger compaction) is retired and its three
items are specific excisions, none a volume pass. So no row currently compacts the prose corpus.

## F1/F2 executed on the owner's go — and F2 was wrong twice before it was right

- `61119177` — F1: `internals/user_input.md` now states **two populations** (callers of the cursor
  API vs writers of the field) rather than one longer list; parenthesis widened to *"a
  cursor-movement keypress"*. Entry RETIRED.
- `2e2cd1dc` — F2: four citations → function names. Entry RETIRED.
- `d6f9ed76` — **correction to my own F2.** Two errors of mine, both caught by re-deriving instead
  of trusting the first pass:
  1. **Wrong mechanism.** I said `e3484987` *inserted* the `DEBT:` comment and shifted the lines.
     That comment is at `:516`, *below* every cited line — it cannot have. The real cause is the
     same commit's F7, which **trimmed** `set_text`'s doc comment 6→3 lines at `:157`.
  2. **Wrong count, from a bad verification.** I checked `:475` by printing `472..478`, saw
     `set_text` in the output and called it correct. It is `end`. With `:487` that makes **six**,
     not four.
- Registered from the wreckage: **77 line citations in the persistent corpus; of the 62 resolvable
  to a unique `src/` basename, 14 (23%) land on a blank line or a bare `end`.** Filed in
  `general.md` as `T-DEC-NUMBERED`'s sibling, unslugged.

**Lesson worth carrying:** the failure this pass was hunting — a session's *documents* not
surviving attack while its *code* does — reproduced inside the pass itself, on the first try, in
the entry written to record that exact failure mode.

## Owner directive — restore the compaction sweep (2026-09-01)

> *"well than please add documents compaction sweep back to the roadmap."*

Added as **`DOC-01`**, a top-level stage: `{brace} → FIX-03 → **DOC-01** → ACC-02 → …`, five steps.

Design calls made while filing it, each stated in the row itself:

- **New KIND rather than `FIX-04`.** `DEC` and `CHG` set the precedent that a distinct release-prep
  docs operation gets its own kind (`roadmap.md` §4). It also keeps `FIX-03`'s number stable — no
  renumber, no crosswalk, no retired-id citations to wipe (§2, §5).
- **After `FIX-03`, not before.** First instinct was before, on "shrink the floor". Wrong way round:
  `FIX-03`'s deletions are *mechanical* (subject absent at base and today) and cheap, so running
  them first shrinks the floor that `DOC-01`'s **judgement** works over. Reversed before filing.
- **Before `ACC-02`**, so the cold reviewer reads the prose that ships.
- **Phase L is NOT un-retired.** Its retirement reasoning still holds; `DOC-01` is new work. Said
  explicitly in both places so a reader does not read this as a reversal.
- **`wip/77` out of scope** — `PR-01-05` may delete it whole.
- **`DOC-01-05` is a citation check over everything the row rewrites**, per `roadmap.md` §5: the
  pass that causes an orphan owes the fix, and `FIX-03-05` will already have run.

`validation/plan.md:125` still carries the old sequence in a dated blockquote. **Left alone
deliberately** — that document states it is never retro-edited and its NAVIGATION block already
sends a reader to the ROADMAP for what-next.
