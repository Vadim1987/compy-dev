# session58 — report

**Date:** 2026-08-30 · **Suite:** **1021 → 1023 / 0 / 0 / 10**, green at every commit
**Mode:** scoped revalidation → execution → owner ruling mid-sprint → execution → owner remarks →
commissioned cold review → corrections.

---

## 1. What this session was

**`FEAT-02`, complete — all five rows**, plus the owner's five follow-up remarks, an example
conversion, a new manual smoke checklist, and a commissioned cold peer review whose findings were
verified and acted on.

The session was **cold on `FEAT-01` by owner preference**, because `FEAT-02` overturns part of it.
That framing earned its keep twice, and both times against text the previous session had written.

## 2. Outcomes

**The public surface changed once more, and it is the last of the surface changes.** `oneshot`
became **`auto_hide`**, and stopped being a `show`-only key: it is project-owned, settable at `show`
**and** `configure`, set-if-given, `false` to unset, and **persistent until replaced** — a mode
rather than a one-off. Five lines of production code, seated in `configure_core` so both entry
points share one statement.

**The ledger gate ran first and amended rather than reinterpreted.** Decision 36 keeps its ruled
edge 1 verbatim, marked superseded, with an *Amendment* section stating what replaces it; its first
**ground** is corrected as a matter of fact (there is no migrating author for whom the name is
familiar); Decision 35 gains `auto_hide` in the project-owned row and a note on why the remaining
three show-only keys belong there. `T-ONESHOT-SCOPE` is retired.

**The opening revalidation found two ledger defects, both stale citations of rows withdrawn the day
before.** `FEAT-02-04` still said renaming was off the table; `FEAT-02-05` wired a test inversion to
the **withdrawn** going-down rule, which executed literally would have re-filed the clearing rule in
a test — the most durable place to put it. Both repaired in the pass that owned them.

**One collision needed the owner, and the ruling reframed the question.** The persistence retires
the *implicit* disarm a bare `show{force}` used to perform, so `a forced follow-up show survives the
close` could not pass unchanged. I framed the delta as *a working idiom stops working*; the owner:
**"there is no working idiom"** — `FEAT-01`'s shape was a quick implementation of a disposable flag,
ruled and overruled within a day and never released, so a contradiction with it is the thing being
removed, not a cost to be weighed. The instruction was to implement the pivot across code, tests,
examples and docs.

**`turtle` is now the only in-tree consumer of the key** and demonstrates both capabilities:
`auto_hide = true` on its single `show`, leaving `after_submit` with its one real job — re-arming
the `i` echo guard. It gained its own smoke checklist (`ACC-02-08`), since its prompt lifecycle now
belongs to the framework.

## 3. Non-obvious points worth carrying

- **A test can pin two things and be filed as pinning one.** `a forced follow-up show survives the
  close` was described in two documents as pinning the flag's read *placement*. It also pinned the
  implicit disarm — the very category being retired — and nobody noticed until the code moved. When
  a case survives a design change "by definition", check what else it asserts.
- **The strongest argument for the change was stronger than filed.** The debt entry offered a
  consolation — *"or an exact hand re-supply of `text` and `cursor`"*. There is no text getter on
  `compy.input` and a project's `love` is a sandboxed clone, so the draft a forced disarm destroys
  **cannot be read back**. Verified before relying on it; the entry was corrected.
- **A rename's blast radius is not a token search.** `oneshot` legitimately survives in-tree for the
  profiler, in vendored metalua, and in two comments that say *"oneshot is gone"* about the base's
  **model** argument — renaming those would have made them false. It also surfaced drift nobody was
  looking for: three mermaid diagrams still show `oneshot` as a *model* field (`T-MERMAID-MODEL`,
  `FIX-02-24`).
- **The documents that quote a call site are the ones that rot.** Session57 learned this on a
  payload change; it repeated here on a *category* change, and the cold review found the instance
  the sprint missed — the guide's echo-guard worked example, which turtle **cites by name**, still
  showed the idiom the sprint had just deleted, with a rule `auto_hide` falsifies.

## 4. What this session got wrong

- **I wrote a false sentence into the ledger while amending it.** Decision 36's Amendment called
  *"leave the follow-up plain"* an escape from the close — retired by the persistence the same
  paragraph rules. Caught by the commissioned review, corrected and dated.
- **The first smoke checklist I wrote did not survive being read as a script.** Its A6 told the
  tester to press `i` while the previous row had deliberately left the prompt open with the guard
  spent — they would have typed a stray `i` and reported the symptom B2 teaches them to file as a
  defect.
- **The four new tests asserted behaviour but were named after mechanism.** Corrected on the owner's
  remark; the project is strongly BDD and the names are part of the contract.

## 5. Artifacts

- Track: `session58/track.md`
- `validation/reviews/FEAT-02-case-and-executability.md` — the opening scoped revalidation
- `validation/notes/auto-hide-persistence-vs-the-forced-follow-up.md` — the collision, its three
  runs, and the owner's ruling verbatim
- `validation/outcomes/FEAT-02-peer-review.md` + prompt of record
  `validation/prompts/FEAT-02-peer-review.md`
- Persistent corpus: Decisions 35 and 36 amended; `T-ONESHOT-SCOPE` retired and `T-ONESHOT` marked
  as history; **`T-MERMAID-MODEL`** opened; `doc/input_api.md`, `internals/user_input.md`,
  `smoke_checklists.md` (new `turtle` list), `CHANGELOG.md`, `src/types.lua`
- Roadmap: `FEAT-02` ✅ with its outcome and the collision; **`FIX-02-24`** and **`ACC-02-08`**
  filed; `FIX-02-09` and `FIX-02-22` citations corrected
