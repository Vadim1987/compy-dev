# DI2 — owner ruling + doc-A resolution index

_Session14 (Opus), 2026-07-19. Owner ruling captured live; index is the DI3 execution map._

## 1. Owner ruling (DI2)

**Ruling: option (b) — merge the survivors into the persistent corpus, tracking where each goes.**
Doc A (`notes/input-contracts.md`) stays a **frozen wip record, unedited in place**; `design/`
stays frozen. Rejected: (a) promoting doc A whole (would import inverted forward-tags + the four
false claims into the canonical corpus, and add a 6th overlapping input doc — against the "no extra
moving parts" frame). (c) collapses into (b) since the cited content is already homed.

Owner add-on: build a **resolution index** (this file) so the DI3 reference-retarget follows
already-discovered paths — DI1's Axis-2 corpus-home column joined with A1's citation inventory —
rather than re-discovering the corpus per reference.

Revalidation of DI1 was reported CLEAN (four false claims + both survivor facts re-verified in
code; circularity guard held; no section skipped) and **accepted by owner** before this ruling.

## 2. Survivor merges — the two `unique-no-home` facts (track where they go)

| Fact (doc-A origin) | Destination | Form |
|---|---|---|
| §9-3: a project overriding `on_key_pressed` with a truthy return **silently disables** `on_limit_reached` (tier-3 consume short-circuits `_dispatch` before the tier-4 sink where the limit fires). Real, unrecorded coupling. | `doc/development/technical_debt/input.md` | New tech-debt item (a few lines). |
| §9-2: `app_state == 'starting'` is **never observed by an input path** (`main.lua` sets `'starting'` then `'ready'` inside the same synchronous `love.load()`, before the event pump). | `doc/development/internals/user_input.md` → "Dispatch chain" (:130) | One clarifying line. |

Nothing else is promoted: §1 tag/provenance methodology, the §4 completeness-table device, the
§5.9 rule-of-five digest, and the §3 "free `show_widget()` is incoherent" framing are this-doc
editorial scaffolding, not system facts.

## 3. Retarget index — every doc-A citation → its corpus counterpart

Source: DI1 Axis-2 homes (`validation/outcomes/DI1-docA-fidelity.md`) × A1 inventory
(`validation/outcomes/A1-spec-ref-sweep.md` "Inventory → doc A"). All targets verified to exist
(heading grep, 2026-07-19). DI3 rewords each `{badspecref: doc A §N}` to cite the corpus target by
**behaviour + named section** (the same treatment A1 already applied to ~140 other refs); it does
**not** invent clause numbers in the corpus.

| doc-A § cited | Corpus target (doc → section) |
|---|---|
| §2 keypressed-vs-textinput channels | `internals/user_input.md` → "Data flow" (:15) |
| §3 routing vocabulary / exclusivity invariant | `decisions/input.md` → Decision 1 (:37); `internals/user_input.md` → "Dispatch chain" (:130) |
| §4 completeness table | no single home → reword to cite the routing invariant, `decisions/input.md` Decision 1 (behaviour, not the table device) |
| §5.1 keypressed EXCLUSIVE | `decisions/input.md` → Decision 1 (:37) + Decision 2 (:56); `internals/user_input.md` → "Dispatch chain" (:130) |
| §5.2 textinput EXCLUSIVE | as §5.1 + `internals/user_input.md` → "Data flow" (:15) |
| §5.3 keyreleased EXCLUSIVE | `internals/user_input.md` → "Key release" (:291) |
| §5.5 mouse EXCLUSIVE | `internals/user_input.md` → "Framework-level click handling" (:342) / "Direct mouse events" (:355) / "Input widget mouse" (:361) |
| §5.6 touch EXCLUSIVE | `internals/user_input.md` → "Touch" (:370) |
| §5.7 wheelmoved | `internals/user_input.md` → "Direct mouse events" (:355) |
| §5.9 the one rule (inter-route exclusivity) | `decisions/input.md` → Decision 1 (:37) |
| §6.7 framework click detection | `internals/user_input.md` → "Framework-level click handling" (:342) |
| §6.3-family (global shortcuts non-consuming; `spec.lua:278`) | `decisions/input.md` → Decision 1 (:37); `internals/user_input.md` → "Dispatch chain" (:130) |
| §8 out-of-radius (`spec.lua:663`) | reword to "out of #77 blast radius / future consideration" citing `internals/user_input.md` (the four named sections per DI1) — behaviour note, not an assertion |
| `design.md §4` sibling (`spec.lua:1657`) | same frozen-design-doc family — DI3 inspects context and cites the corpus section describing that behaviour (Sonnet: read the line, don't guess) |

**Cited-site inventory (from A1):** `input_fixture.lua:9-11` (the "doc A" *definition* — retarget
to name the corpus, or drop), `:137` (§5.5), `:168` (§6.7), `:221` (§5.5 prose);
`input_contracts_spec.lua:8-9,13,21,33` (header prose), `:82,85,97,106,113,124,146,154,162,167,191,203,216,230,242,278,519,582,663` (citations),
`:1657` (`design.md §4`). ~30 occurrences total.

**NOT in scope (stay Phase-C evidence, per prompt):** the ~25 non-doc-A inventory refs — milestone
marks (`M#`, `0.1.0-m#`), `M2-human-review.md` review-doc citations, ratified-model/scope-item
process artifacts. DI3 leaves these untouched.

## 4. Also in DI3 (from the prompt)

Refresh `tests.md` "Input Contract Suite" facts (drift confirmed this session): `tests.md:69`
"808 successes" → **815**; pending row line numbers 101/153/161/222 → **118/172/185/246** (same
four rows by content). Suite green (815/0/0/4) after every unit; commit unit-sized.
