# Owner inquiry — the console `_G` / running-program environment relationship

> **SIDE-DRAFT — NOT PART OF `#77`'s DELIVERY.** This document belongs to an architecture discussion
> that ran alongside the feature's pre-PR phase (session62, 2026-08-31), opened at the project
> owner's initiative. It is exploratory: **nothing in it is ratified**, no production code was
> changed for it, none of it ships with `#77`, and nothing in the persistent documentation corpus
> was modified. Its subject — the console/project environment lifecycle, and the dispatch
> unification that followed from it — is expected to become **its own ticket, after** the feature is
> released.

**Received:** 2026-08-31, session62, cited verbatim by the owner (relayed from the project owner).
**Status:** pre-ticket. The project owner asks whether there are further requirements/expectations
before a formal ticket is filed.
**Analyses:** [`../reviews/env-lifecycle-inquiry-assessment.md`](../reviews/env-lifecycle-inquiry-assessment.md)
(essence + collision with `#77`), evidence map in
[`../outcomes/session62-env-lifecycle-code-map.md`](../outcomes/session62-env-lifecycle-code-map.md).

---

## The inquiry, verbatim

> Hi,
>
> The current relationship between the environment (_G) of the console and the running program is
> an unintuitive, difficult to maintain and not even properly specified mess. I think, it should
> work as follows (not a full specification, just a few very important expectations):
>
> * Running a lua file from the project using dofile("filename.lua") should be executed in the same
>   environment in which it was launched and only restore the interaction callbacks (so that the
>   console works) upon return. Any other symbols assigned inside the executed lua file should stay
>   assigned and accessible from the console. The expectation is that it should work as if the same
>   commands found in the file were typed in from the console, except for outermost local symbols.
>
> * Running a project either via run() or run("project name") should reset the environment to some
>   well-defined default. No symbol assignment made previously should affect how the project runs.
>
> * However, if main.lua runs it course without changing the interaction callbacks or they are
>   explicitly reset by calling quit() (or whatever it is called today), all symbols assigned during
>   execution, with the exception of interaction callbacks (see above) should stay accessible from
>   the console. This should allow for projects that are merely extending the console in a
>   predictable way.
>
> Do you have any other requirements/expectations before a formal ticket is filed? I think, this is
> super-important and pretty urgent, removing a lot of mystery and frustration from programming
> Compy.

---

## Reading of the three expectations (labels used by the analyses)

- **R1 — `dofile` is transparent.** A project file run via `dofile("x.lua")` executes *in the
  caller's environment*; on return only the interaction callbacks are restored. Every other global
  it assigned stays visible to the console. Mental model: *as if typed at the console*, modulo
  outermost `local`s.
- **R2 — `run()` starts from a well-defined default.** No prior assignment may influence how a
  project runs.
- **R3 — a project that does not take over the interaction callbacks (or gives them back via
  `quit()`) leaves its globals behind**, accessible from the console. Purpose: *projects that merely
  extend the console, predictably*.

The unifying intent, stated in the owner's own terms: **the environment relationship must be
specifiable in one paragraph a user can hold in their head** — the complaint is as much about
"not even properly specified" as about behaviour.
