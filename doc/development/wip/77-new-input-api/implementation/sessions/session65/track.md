# session65 — track

## 2026-09-01 — boot

- Fresh start: `session65/` held only `prompt.md`, no `track.md`/`report.md` (guardrail §2 → fresh).
- HEAD `90a2e87e` (session64 wrap). Working tree: only the known untracked scratch
  (`broken-busted/`, `claude.sh`, `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`,
  `worklog.md`, the three nested example repos). No unexpected diff.
- Baseline confirmed: **1048 / 0 / 0 / 10** — `busted tests`, **LuaJIT 2.1.1703358377** in the
  container (owner runs PUC Lua; no `lua` binary here).
- Read: `agents/validation.md`, `agents/sessions.md`, session65 prompt, session64 report,
  `ROADMAP.md` (sequence + the defect brace + `DEC-01`), `DEC-01-ledger-denoising-spec.md`.

### Sizing re-derived on boot, before proposing the row (prompt: "re-derive before working it")

The `DEC-01` row and its spec both drift. Measured today:

| quantity | roadmap / spec says | measured today |
|---|---|---|
| `Decision N` citations in `src/` + `tests/` | 165, 18 files | **222, 20 files** |
| persistent doc files citing a decision number | ~10 | **14** |
| decision headings in the ledger | 33 | **37** (31 ACTIVE + 6 RETIRED) |
| slugs to mint / entries to dispose | 29 + 4 | **31 + 6** |
| line-broken `Decision$` mentions in the ledger | 3 | **5** |

Arithmetic reconciles: the drafted inventory's 29 survivors lose Decisions 9 and 12 (both since
moved to `RETIRED`) and gain Decisions **35, 36, 37, 38** → 31. Removals are the four tombstones
(13, 16, 20, 29) plus those two, which is the roadmap's own "`RETIRED` holds six, not four" note.

- Awaiting the owner's pick of the row before any execution (prompt recommends `DEC-01`; `FIX-01`
  and `FIX-02` are the named alternatives).

## 2026-09-01 — owner picks `DEC-01`, and amends the method

**Ruling:** run `DEC-01`. **Two method changes on the spec, both the owner's:**

- **No sentinel wrapping.** We are not renumbering, so substitute directly — but in **descending
  numeric order**, so `Decision 3` cannot land inside `Decision 33`. The spec's step `DEC-01-02`
  (the sentinel gate) is therefore **not executed**; the completeness gate moves to `DEC-01-01`,
  which is where the owner put it: *inventorize the mentions first and ensure no leftover is there
  due to newline.*
- **The conversion map lives in `wip/` for forensics** — with the owner's own caveat that it may
  become a victim of later changes. Resolved as two artifacts: the forensic file in `validation/`,
  and the bare crosswalk appended to the ledger at `DEC-01-06`, which is the half that survives.

### `DEC-01-01` landed — `65281671`

The census found **three** variant forms, not the spec's two, and every count was low:

- **18 line-broken citations**, not 3 — and not ledger-only: `src/` 6, `tests/` 4, ledger 5,
  `technical_debt/input.md` 2, `internals/user_input.md` 1. Proof they were invisible: occurrences
  in scope went 510 → 528 the moment they were joined.
- **11 plural mentions**, expanded so each id carries its own `Decision`.
- **8 bare back-references — a class the spec never named.** `13 exposed it read-only, 20 made it
  readable outside an event, 29 made it…` — a decision cited by number with no `Decision` word
  anywhere near it. All 8 in the ledger, all 8 immediately after a plural mention: the plural
  introduces the list and the sentence unpacking it drops the noun. **The plural form breeds them**,
  which is why normalising plurals without looking at the next sentence would have left them.

Gates green: no plural, no lower-case, no line ends in `Decision(s)` before a number, no bare
back-reference; touched comment blocks within 64 chars; suite 1048.

### `DEC-01-03` landed — `94ce4960`

31 slugs (4 new: `D-CFG-BOUNDARY`, `D-AUTO-HIDE`, `D-PAYLOAD-SPLIT`, `D-CONTENT-NORM`), 6
dispositions. Three findings worth carrying:

- **The spec's "one decision the owner owes" is already ruled.** `agents/rules/ledgers.md` §3
  defines the `T-` slug as *"same shape as the decisions ledger's `D-SLUG` … declared first in the
  heading with the prose after"* — written naming this ledger as its model. No ruling owed.
- **Only Decision 12 is cited from code** (7 sites; the other five retired entries: zero). So the
  vacuum is nearly free, and the one entry that costs work is the one whose heading says it was
  never a decision.
- **Decision 16 has a stakeholder claim** — it is the Gate-2 closing ruling of 2026-07-06, verified
  in the frozen design. `ledgers.md` §2 keeps what came from outside. Recommended keep; owner's call.

**Open with the owner before `DEC-01-04`/`-05`:** the Decision 16 ruling, any slug that displeases,
and the `agents/` scope extension.

## 2026-09-01 — the owner rules on all three, and adds a directive

1. **Decision 16 → vacuum.** Ground: *"if it's not in stakeholders' verbatim attestations, it's my
   interim ruling and I reverted it with reason."* So all six go, not four. The owner also checked
   the scope — *"are we already vacuuming, not renaming?"* — and it is `DEC-01-04`, a filed step,
   ruled in place 2026-08-27.
2. **Slugs accepted** as proposed.
3. **`agents/` is in scope**, with the note that `agents/` will not be in the release.

**New standing directive: *justification should be lifted out of `wip/` if it is technical, not
procedural.*** Met immediately, because vacuuming Decision 16 would have deleted the only record in
the persistent corpus that a ratified position was reversed. Lifted into `D-ONE-LIFETIME`
(`e9a3501a`). **Then bounded rather than chased:** the *"Ratified deviations"* table is six rows and
**all six "Why" cells are technical**, so the directive's reach is a sprint of its own —
registered as `T-DEVIATION-WHY` / `FIX-02-26` (`42825710`) rather than absorbed into a rename.

### DEC-01 executed and closed — `65281671`..`06014230`

`-01` joins · `-03` inventory · `-04` in two commits (Decision 12's seven citations rehomed to
`internals/user_input.md` *"inspect mode"*, then the vacuum) · `-05` substitution · `-06` crosswalk
· plus the `ledgers.md` clause and the roadmap close. **`-02` deliberately not executed.**

**Method notes worth carrying:**

- **An unsupported regex is not an empty result.** The first sweep for surviving references to the
  vacuumed ids used `awk` with `\<`/`\>`; mawk does not support them. It returned nothing and looked
  exactly like a clean result. Four real references were sitting in the file. Second instance of
  this shape in two sessions — session64's was a range-print read as a resolution.
- **Reflow was proved, not eyeballed.** 68 comment lines crossed 64 chars. After rewrapping, every
  `.lua` file's comment text is word-for-word identical to the pre-substitution text with only the
  slug applied — no word added, dropped or reordered. That check is cheap and is the right one for
  any mechanical rewrap.
- **Markdown deliberately not reflowed**, and said so in the commit: `agents/rules.md` scopes the
  64-char limit to *coding*, and the prose corpus has no width convention (96 to 1158 chars in the
  touched files).

## 2026-09-01 — the owner reopens the category, and `T-DEVIATION-WHY` was a phantom

Sequence worth keeping, because the correction went through three stages and only the last one was
right.

1. I filed `T-DEVIATION-WHY`: the PR table's technical justifications die with the tree, and the
   decisions never say what they replaced.
2. Owner contested the **slug** — *"describes shape not subject"*. Correct, and I proposed
   `T-OVERTURNED`.
3. Owner then contested the **premise**: *"maybe not stating what was overturned is a good
   instinct. we do not make archaeology. 'X... why not Y' only makes sense if Y is likely option to
   be considered again."*

**Checking beat arguing.** The five decisions were read instead of assumed, and the second half of
my claim is simply false — `D-ROUTE-LIFETIME` marks itself SUPERSEDED IN PART and quotes the
superseded claim; `D-NO-LOG-NOISE` names the design's proposed debug log and declines it;
`D-HOOKS-SEEDED` argues the seed against a precedence rule by name. The PR table **summarises** the
ledger. The entry was a phantom problem in the strict sense of `agents/validation.md`'s checklist.

**And the answer was already in the file I was editing.** `decisions/input.md:462` carries the
owner's `REMARK`: *"clean up self-arguing with past decisions that were then reshaped before
release. What was not in released version is considered as never existing (except few bits
explicitly ratified by stakeholders)."* I filed a debt entry that runs directly against a standing
position sitting two lines above the decision I was editing. **Second time in two sessions** the
ledger already drew the line and I read the commit trail instead — session64's F4 was the first.

**The owner's own correction to their phrasing is the load-bearing part:** the defect is arguing
with an **interim, overwritten** past, *not* "arguing with itself" — that is too wide and catches
the legitimate cases. A decision weighing a live alternative is the ledger doing its job. The
operable test is theirs: *would a reader plausibly propose Y again?*

Landed: the rule (`16f5018e`), the archaeology paragraph removed from `D-ONE-LIFETIME` (`cd1264da`,
reversing `e9a3501a`), `T-DEVIATION-WHY` retired NOT DEBT, `T-ARGUES-INTERIM` opened, `FIX-02-26`
withdrawn, `DEC-02` filed (`1a162e5a`).

**One ruling with teeth beyond this row:** a `REMARK` is removed **when its defect is solved**, not
when a sweep reaches it. So the marker at `:462` is retained on purpose, names its slug, and
`DEC-02-04` is what deletes it. Any pass over `doc/` markers that takes it early is a defect.

**Where the sizing gap came from, since it will recur:** the spec sized by grepping `Decision N`.
Three forms do not match that pattern — line-broken, plural, and bare back-reference. The last is
the interesting one: it exists *because* of the plural, since the sentence unpacking a list drops
the noun. A sizing pass that greps the canonical form will always undercount by the variants that
form cannot see.
