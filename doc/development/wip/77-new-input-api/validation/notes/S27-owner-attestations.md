# S27 — owner attestations

Attestations the owner gave in chat during session27. Project-facing: each is a
ruling or a stated intent a future session must honour, and none of it exists
anywhere else. Behavioural and process observations from the same session are
**not** here — they live in the session workspace
(`../../implementation/sessions/session27/observations.md`), because they serve
self-assessment rather than the project.

Each is already acted on; this is the record of the reasoning, not a to-do list.

**On the broken assertions (opening).** The three-line
`local l, c = get_cursor(); assert.same(1, l); assert.same(3, c)` was collapsed
deliberately, for readability — the syntax was the slip, not the idea. Fixed as
part of remark triage rather than as a separate regression.

**On the 16-line function-body tolerance.** Ratified: 14 stands, 16 is tolerated
where the alternative is extracting a helper whose only job is to satisfy the
counter. Owner's own diagnosis of the case that produced it — comment
boilerplate was padding the count — proved correct: with the boilerplate gone
the merged body was **eight** lines and needed no tolerance at all.

**On `singleclick`/`doubleclick`.** They keep `(x, y)` and name no button.
"They anyway do not resemble stock love functions" — so there is no stock shape
to converge on, and widening them for symmetry's sake buys nothing.

**On `before_exit` (the largest ruling of the session).** Stopping is a
lifecycle step the framework performs, **not one the project participates in**.
Exposing a hook at all is a convenience gesture — somewhere to do cleanup. It
follows that the project's hook must never be invoked through any standard
dispatch mechanism, because that is how a return value acquires the meaning
"stop the propagation". The framework therefore owns its own teardown function
and calls the project's from inside it, in a pcall, reading nothing. Single
invocation point by construction, and a natural seam for the forced restore of
altered hardware settings discussed in earlier sessions. Refined immediately
after: uninstall the hook **inside** that function, right after the call and
never before, since before would leave a window for the hook to reinstall
itself; and no wrapper function for the uninstall, because "safely execute and
uninstall" reads as one transaction without a name in the middle.

**On the maze smoke finding.** Hypothesis, to check before treating it as a
route bug: maze switches fonts, and the switch probably only takes on a first
start rather than after another project. The Ctrl-dims-screen half is likely
maze's own UX bug — not critical, but pin it rather than leave it unexplained.

**On session economy.** Escalate only what sub-agent advisors cannot settle.
Cold sub-agents review triage and plan quality *before* implementation.

---
