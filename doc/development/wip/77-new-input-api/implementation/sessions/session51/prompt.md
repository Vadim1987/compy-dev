# session51 — revalidate `ARC-02`

Read `agents/sessions.md` and `agents/validation.md` first. Then the commissioning prompt
[`../session50/prompt.md`](../session50/prompt.md) and the report
[`../session50/report.md`](../session50/report.md) — the handover. Session50's track is long and
you do not need it, though its two "mistake worth keeping" sections are short and worth the minute.

Baseline: **990 / 0 / 0 / 10**. A different count is a finding, not a go-signal. (979 at session50's
boot, + 11 across the sprint; the report carries the arithmetic per step.)

## Your task

**Revalidate `ARC-02`**, per [`agents/rules/revalidation.md`](../../../../../../agents/rules/revalidation.md)
— work its six checks and report. This is **research + analysis**, not execution
(`agents/validation.md`, operational modes): you produce findings and proposed corrections, not a
new sprint. Do not start the next roadmap row.

`ARC-02` qualifies for revalidation on all three of the rule's triggers: it applied a multi-step
transformation to existing material, it produced substantive new content through judgment, and it
wrote documents — `doc/input_api.md`, `internals/user_input.md`, the three ledgers — that
downstream work will trust **without re-reading the source**. That last one is the reason this
session exists.

**Ten commits to revalidate:** `b325826d` `ef20466a` `af1e8ec6` `7b927249` `191e28c3` `cad0bb25`
`3bade47a` `e4748e60` `ddfe8be0` `ee59ccdc`. `git diff 9a27e044..HEAD` is the whole sprint.

## Where to point the checks — the highest-value targets first

The checklist is generic; these are where this particular sprint is most likely to be wrong.

1. **Three judgment calls that were made rather than ruled.** All three are flagged in the report
   and all three are cheap to reverse. Check them against intent, not just against consistency:
   - malformed cursor shapes **raise** rather than defaulting (`ARC-02-07`);
   - `cursor = false` is **unset**, extending Decision 35 statement 3 to a *user-owned* field;
   - Decision 35's ratified "What this amends" text was **edited** to match the owner's
     addition ruling.
2. **Check 2(c) and 2(d) are the load-bearing ones here.** Three ledgers, two persistent docs and
   the roadmap were all touched. Do the cross-references still resolve, and do the ledgers agree
   with each other and with the code? Session49's own cross-check came back green **for the wrong
   reason**; session50's citation checker came back red for the wrong reason. Do not trust a
   checker whose result you have not sanity-tested against a case you already know the answer to.
3. **Integrity (check 4) on the deletions.** `re_show`, `state.pending`, `consume_pending`,
   `stash_hidden_configure`, `PER_SHOW_KEYS` and the `live` table all went. Did anything they
   were doing go silently with them? The named risk is `merge_callback_keys` on the hidden
   `configure` path — a hidden `configure{validator}` must still persist.
4. **Gap check (5), under-done side.** `BUG-01-09` was deliberately left although the roadmap said
   it "belongs with `ARC-02-03`". Is that the right call, or did the sprint's own contract ("`show`
   is a full re-setup; absent `text` ⇒ empty") make it louder?

## Standing cautions

- **Verify in code, not from this prompt or the report.** Session49 had four claims overturned;
  session50 had one design assumption overturned by its own red test's output, and one test
  expectation that was simply wrong while the code was right. Both reports may carry more of the
  same.
- **A green suite proves less than it looks like here.** `with_canvas_and_errors` xpcalls the
  project dispatch walk, so a raise there is swallowed; and three of the effects `clear_input`
  performs (selection, custom status, history index) have **no test that would notice them
  going missing**.
- **Check the PR base `3256aac`** when provenance matters. It has overturned a verdict repeatedly.
- `| head` on a counting grep lies, and so does a loose one.
- **Sub-agents:** always pass `model` explicitly; Fable is retired. The `lua-lsp` MCP is up.
- If you find corrections: **make or explicitly propose them, do not leave the state ambiguous**,
  and **ask the owner before proceeding** to anything else. Errors here propagate downstream.
- Commit at the natural seam, one concern each; suite green and its count stated. **Never push.**

## Where the project stands

[`../../../status.md`](../../../status.md) — the bookmark page for the three ledgers and the
roadmap. With `ARC-01` and `ARC-02` both complete, what remains after this revalidation is
acceptance, the residue of the defect sprints, reconciliation and assembly —
`ROADMAP.md`'s closing sequence line.
