# Roadmap — feat #77, from here to the PR

**The navigable view.** One page, current, ordered. The reasoning lives in
[`validation/plan.md`](validation/plan.md) and the review documents this points at; **this file is
the sequence**. Updated 2026-08-26.

## Where things stand

| | |
|---|---|
| branch | `feature/77-newapi-analysis-s20260615` |
| suite | **968 / 0 / 0 / 10** — the 10 pending are an owner ruling, an 11th is a finding |
| marker gate (`src`/`tests`) | clean — **but it never covered `doc/`**, which is FIX-02-01 |
| slices | regenerated, **100 / 100 complete and disjoint** |
| baselines | pinned as local tags, [`TAGS.md`](TAGS.md) — nothing fetched since |
| upstream | **86 commits behind the edge** (a floor: our view is 23 days old) |

**The spinoff sprint is closed and TF2 with it.** What remains is acceptance, four defect sprints,
reconciliation, and assembly.

---

## ✅ ACC-01 — device-free acceptance — **COMPLETE**

| id | step | result |
|---|---|---|
| ACC-01-01 | slice regeneration, the review cut | found **5 files outside every pathspec**, one production code |
| ACC-01-02 | cold PR review vs the original stakeholder ask | **merge with changes — 21 defects** (19 from the review, 2 the owner found reading it) |

Detail: [`validation/reviews/ACC-01-02-findings-triage.md`](validation/reviews/ACC-01-02-findings-triage.md) ·
report: [`validation/outcomes/ACC-01-02-cold-pr-review.md`](validation/outcomes/ACC-01-02-cold-pr-review.md)

---

## ⬜ The five defect sprints — **the current work**

Mostly unordered, with two constraints: **DEC-01 must finish before any slice is cut**, and
**FIX-03 runs last** — it is the sweep that catches what FIX-02 and DEC-01 miss, and running it
first means three brooms over one floor. Within BUG-01, `01`
and `02` are the majors.

### BUG-01 — runtime defects (6)

| id | defect | note |
|---|---|---|
| BUG-01-01 | `state.pending` survives a project stop | **major** · trace reachability first · carries a test gap · a debt entry rests on a false premise |
| BUG-01-02 | a highlighter cannot be turned off | **major** · needs a design call — *parked, see below* |
| BUG-01-03 | `show{force=true, prompt=…}` silently drops the prompt | |
| BUG-01-04 | `set_cursor` clamps bytes, boundary event measures characters | non-ASCII prompts |
| BUG-01-05 | `turtle` double-handles its own keys | **check the other migrated examples for siblings** · symptom of FIX-02-09 |
| BUG-01-06 | a `textinput` shortcut cannot bind an upper-case character | |

### FIX-02 — docs, vocabulary, process (15)

| id | defect | note |
|---|---|---|
| FIX-02-01 | 14 `> REMARK:` blocks ship in `3a` — **and the gate never covered `doc/`** | **major** · [full triage](validation/reviews/FIX-02-01-remark-triage.md) · none is stale |
| FIX-02-02 | provenance front matter | **3 files only**, by ruling |
| FIX-02-03 | `pong/README.md` — 316-line diff, 2-line change | |
| FIX-02-04 | CHANGELOG omits the breaking change | |
| FIX-02-05 | two docs disagree on route release | |
| FIX-02-06 | **tier / chain / "the walk"** — three names, one thing | strategic-frame clause |
| FIX-02-07 | **overlay / widget / area / field** — four names | known unclosed; `src` half swept in S45 |
| FIX-02-08 | "combinator" — concept earned, word not | |
| FIX-02-09 | the guide never says a shown widget **always consumes** (keyboard) | **fix with BUG-01-05** |
| FIX-02-10 | the guide never says callbacks cannot be un-set | |
| FIX-02-11 | `hide()` vs teardown — the singleton is never stated | |
| FIX-02-12 | the channel list exists twice | |
| FIX-02-13 | a `pending()` routing case deferred in the hardest-read area | |
| FIX-02-14 | **`release_keyboard_route` — name, comment and cited decision all describe retired behaviour** | **check with FIX-02-05**, likely its source |
| FIX-02-15 | **debt ledger is 34% resolved entries** (547/1610 lines), many about scaffolding this feature invented | test each against the PR base; rot goes, pre-existing fixes need a ruling |

### FIX-01 — pre-existing citation hygiene (3)

| id | defect |
|---|---|
| FIX-01-01 | 10 ephemeral step-id and `wip/` path citations in the persistent corpus |
| FIX-01-02 | session numbers in the persistent corpus (4 sites) |
| FIX-01-03 | P11's deferred editorial list — **named as a count, never enumerated; re-derive before sizing** |

### FIX-03 — the closed-arc sweep (4 steps) — **runs after FIX-02 and DEC-01**

Retire prose that narrates history which opened *and closed* inside this branch. Spec:
[`validation/reviews/FIX-03-closed-arc-sweep-spec.md`](validation/reviews/FIX-03-closed-arc-sweep-spec.md)

**Why a sweep and not more rows:** three instances were found this session by three unrelated
routes, none by looking — the signature of a class defect. **The test is mechanical:** subject
absent at base `3256aac` **and** absent today → the arc closed inside the branch.

| id | step |
|---|---|
| FIX-03-01 | enumerate subjects failing both greps |
| FIX-03-02 | classify: closed arc / lesson-bearing / pre-feature-deviation record |
| FIX-03-03 | for lesson-bearing, locate the materialized lesson — or promote it before deleting |
| FIX-03-04 | dispose: closed arcs vacuumed |

**Two exclusions.** Lessons already materialized in a decision or convention — *verify, then
delete*. And **prose that is the only record of a deviation from pre-feature behaviour**: Decision
11's rot paragraph sits directly above one such record, so a sweep matching on *tone* takes both.
**Match on subjects, never on tone.**

**Scope includes `src/` and `tests/` comments** — where FIX-02-14 hid, and where no doc sweep
reaches.

### DEC-01 — decisions ledger: names, not numbers (6 steps)

**Blocks slice cutting.** Spec + drafted inventory:
[`validation/reviews/DEC-01-ledger-denoising-spec.md`](validation/reviews/DEC-01-ledger-denoising-spec.md)

| id | step | gate |
|---|---|---|
| DEC-01-01 | join the 3 line-broken mentions; normalise plural/lower-case | `grep -cE 'Decision$'` = 0 |
| DEC-01-02 | wrap every id in sentinels | **the governing gate** — no bare `Decisions?` in scope |
| DEC-01-03 | inventory: 29 slugs + 4 removals | drafted; owner will grep-and-rename if a slug displeases |
| DEC-01-04 | remove the 4 tombstones (13, 16, 20, 29) | no `TOMB-` survives · decide where Decision 20's `keys_pressed` history goes |
| DEC-01-05 | substitute slugs, one pass per file | reflow long lines **in the same commit** |
| DEC-01-06 | strip sentinels; read the diff; append the crosswalk to the ledger | suite green |

**Scope:** the ledger, ~10 persistent docs, and **`src/` + `tests/` (165 citations)**. **`wip/` is
out of scope** — frozen history, and it carries its own dead `D-1…D-10` namespace.

---

## ⬜ ACC-02 — human acceptance — **blocked on the four sprints**

Runs only once the tree is fixed. Every row costs owner time; re-running them against a tree about
to change is what this ordering exists to prevent.

| id | step | note |
|---|---|---|
| ACC-02-01 | **a second cold PR review**, over the fixed tree | before any keyboard time |
| ACC-02-02 | `balloons` smoke | **first** — 5 ahead / 0 behind, the one result recon cannot invalidate |
| ACC-02-03 | `keyboard` smoke | the review could not check `4c`'s timing — run this one carefully |
| ACC-02-04 | `maze` + `draw` smoke | **against `newinput-edge`** — `da9d1c2` is on that branch only |
| ACC-02-05 | `sapper` smoke | **section C is expected to fail** — P19's accepted defect, described in the list |
| ACC-02-06 | slice regeneration, if the passes moved anything | |
| ACC-02-07 | owner's readability review of the slices | |

Lists: [`doc/development/smoke_checklists.md`](../../smoke_checklists.md). **Tag every green pass**
(`TAGS.md`, round 2) so "it passed" names a commit.

---

## ⬜ REC-01 — upstream reconnaissance — *discovery, not release*

**Renamed from "recon" and lifted out of the release path (owner, 2026-08-26)**, because it is not
release work: it measures **86+ commits** of drift we currently cannot see, and if upstream moved in
our surfaces its output is **new defect work**. It may spawn a sprint. Fetch-only, read-only;
nothing merges here.

| id | step |
|---|---|
| REC-01-01 | fetch every remote; measure the real drift against the pinned tags |
| REC-01-02 | assess whether it touched our surfaces — the reported edge-side editor overhaul above all |
| REC-01-03 | triage anything it surfaces into a sprint, or record that it surfaced nothing |

## ⬜ MERGE-01 — upstream reconciliation

*(was Phase U — renamed, unchanged in substance.)* Four repos, each with its own remote and its own
PR.

| id | step | note |
|---|---|---|
| MERGE-01-01 | `maze` | a **re-merge**, not a first one — reconciled already at a base dated 2026-07-24 |
| MERGE-01-02 | `keyboard` | merged at S37; ancestry preserved so re-merges stay cheap |
| MERGE-01-03 | `balloons` | zero divergence today |
| MERGE-01-04 | the platform repo | the big one — 86+ behind |

**Mechanic, standing:** pull each upstream into **its own branch**; never merge into the working
branch as the first move.

## ⬜ PR-01 — assembly

*(was Phase G — renamed and shrunk. Its opening item, the B→C→D collapse ruling, is already
settled; its checklists are written; its description was rewritten.)*

| id | step |
|---|---|
| PR-01-01 | the final slice cut — **the shipping one**, after MERGE-01 |
| PR-01-02 | the justification table in the PR description |
| PR-01-03 | reviewability gate: `doc/input_api.md` + the description, alone |
| PR-01-04 | open the coordinated PRs — platform + three example repos |
| PR-01-05 | the `wip/77` deletion ruling — **owner-gated, after the PRs are up** |

### Phase L — **retired** (owner-approved, 2026-08-26)

Ledger compaction had three items and **none needs a phase**:

1. excise the collapsed decisions → **DEC-01-04**, which is a *superset* (it also removes 16);
2. remove Decision 11's withdrawn-rationale trail → **already a row**: it is REMARK `:429`, inside
   FIX-02-01;
3. demote Decision 12 → **parked**, the owner disposes it during review.

Retiring L therefore drops nothing.

### Phases B, C, D — **dissolved** (owner ruling, 2026-08-26)

They are absent from this roadmap by **ruling**, not by omission. They were a prediction of the
shape of pre-release work; that shape emerged differently, so the placeholders go.

- **B, the intent check** → done by the **cold reviews** (`ACC-01-02`, repeated at `ACC-02-01`) —
  and by a reviewer with no stake, which a self-check could never be.
- **C2, the disposition table** → emerged as the **defect register**.
- **C1 and D** → dissolved outright: *principles are enforced at the row, without abstract
  encoding first.* The parked calls below are that method.

**This settled the gate early.** The collapse ruling was scheduled as step zero of Phase G; it is
done, and G no longer opens with it. **Phase F** goes with them — its "final revalidation" is what
`ACC-02-01` is.

---

## Parked, with the moment each gets answered

Not open questions to chase — each has a trigger:

| question | answered at |
|---|---|
| highlighter: sentinel, or a `clear_highlighter` member? | **when BUG-01-02 is fixed** |
| the 14 remarks: ruled individually, or swept? | **when FIX-02-01 starts** |
| Decision 12 — a ledger entry that says it is not a decision | **owner disposes during review** — needs context, stays in place |
| the slug table | **no review needed** — grep-and-rename if a slug displeases |
| provenance beyond the 3 files | **deferred** — a formal violation does not displace real work |
| where Decision 20's `keys_pressed` history lives after removal | **at DEC-01-04**, per entry |

---

## The one-line sequence

**ACC-01 ✅ → { BUG-01 · FIX-01 · FIX-02 · DEC-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01**
