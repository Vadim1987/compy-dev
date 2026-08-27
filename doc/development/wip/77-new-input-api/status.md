# Status over view

A bookmark page, nothing more. **It is not updated dynamically**, it holds no state of its own, and
it does not survive the release: it exists so that "where are we?" starts with a few links instead of
a directory listing.

## Dev-facing documentation (describes NEW input, still being actively updated)

* [doc/input_api.md](../../../input_api.md) -- what projects can use (new API)
* [doc/internals/user_input.md](../../internals/user_input.md) -- what is under the cover

For design decisions and technical debt check list  below

## Where development stands — the four files to open

Three of the four are **ledgers** — persistent, and they outlive this working tree. The fourth is
the plan, which is ephemeral and moves fast. The contract binding them is
[`agents/rules/ledgers.md`](../../../../agents/rules/ledgers.md).

| | What it answers |
|---|---|
| [`CHANGELOG.md`](../../../../CHANGELOG.md) | **What shipped, and what is about to.** `CURRENT_SCOPE` is everything unreleased; it is emptied into a version section when one ships. |
| [`decisions/input.md`](../../decisions/input.md) | **What was ruled, and what still rules.** Split `ACTIVE` / `RETIRED`; a retired entry keeps its number so citations still resolve. |
| [`technical_debt/`](../../technical_debt/) | **What is owed.** Split `ACTIVE` / `BACKLOG` / `RETIRED` by release scope. `ACTIVE` entries carry a `T-` slug, which is what a plan cites. |
| [`ROADMAP.md`](ROADMAP.md) | **What is next.** Ordered tasks. Rows point at debt entries **many-to-one** — a debt entry is a goal, a row is a task towards it. |

**If you only want the position, read the first three.** The roadmap answers a different question and
is reorganised often; that churn is why the ledgers exist.
