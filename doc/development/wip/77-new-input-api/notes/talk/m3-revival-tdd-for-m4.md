# Reviving M3 as TDD regression net for M4

_Materialised from a chat discussion (2026-06-18, session 09). Human raised; agent analysed. Decision: **open — not yet decided, successor entrypoint created.**_

## The problem

M4 (overlay gate removal) is the **highest-risk** milestone. Its acceptance currently rests on:

- "All four app modes verified manually"
- "Full test suite passes"

But there is **no automated test driving the real input path for any example project**. The M2-01
overlay test runs against a *stub*, not the real wiring (already flagged as anticipated debt:
"overlay test vs. stub"). Manual verification is the only regression net for M4's central claim
that "overlay input works as before."

With **build-time continuity in force**, tixy/balloons/turtle must not fault at any milestone
boundary. Without integration tests, we discover breakage only at manual-verification time — after
the implementation work is done.

## Human's proposal

Revive M3 (previously removed when D-1 backwards-compat was withdrawn) as **"input-path integration
tests for the key examples"** — writing tests before M4 so the gate removal has an automated
acceptance net. Possibly split M4 itself into two sessions (failing tests first, then
implementation).

## Agent analysis

### M3 revival — yes, but reframe the lifecycle

The old M3 was "facade wrappers" — dead. The new M3 is "input-path integration tests."

**Build-time continuity constrains the test lifecycle:**

- M3 writes the tests. All pass now.
- **Through M4–M7, these tests must continue to pass.** M4's contract says overlay input still works.
  If M4 breaks these tests, it's a regression in M4, not an expected outcome. The tests are the
  *enforcement mechanism* for build-time continuity.
- **At M8, the tests break and are rewritten.** M8 removes legacy globals and migrates examples to
  `compy.input.*`. The tests update to match the new API.

So the framing is not "tests expected to break at M4, restored at M8" but rather "tests that
**protect** M4–M7 build-time continuity, then **evolve** at M8."

### M4 split — achieved by M3 + M4, not by splitting M4 internally

Writing "failing tests for the new controller" before the controller exists doesn't work — there's
no interface to test against. But M3 + M4 achieves TDD at the milestone level:

1. **M3:** Write behaviour-level tests (does tixy's `input_code` flow work? does turtle's `input_text`
   flow work?). All pass against the current implementation.
2. **M4:** Change the routing. M3's tests serve as the automated acceptance net.

This is the "red-green" cycle, just at a coarser granularity. The tests don't test
`ProjectInputController` directly — they test the *observable behaviour* that the controller must
preserve.

### Impact on M4 escalation

Adding M3 as a test-writing prerequisite **reduces escalation pressure on M4**. With a proper
regression net, the black-box model (Sonnet implements, Opus reviews) becomes safer — regressions
are caught by the suite, not just by manual verification.

## What M3 tests would cover (sketch)

- **tixy:** `input_code` → overlay appears → type code → submit → overlay hides → result
  available via `user_input()`. Exercises the full show/type/submit/hide cycle.
- **balloons:** `input_text` → overlay appears → type text → submit → result available.
- **turtle:** `input_text` → overlay appears → type → submit; also Esc semantics (ties into the
  turtle-Esc-clears-in-place / G-B debt items).
- **editor:** REPL input flow (already somewhat covered, but verify the overlay routing).
- **D-9 coexistence:** A native-handler-only project (e.g. `pong`) — `love.keypressed` still
  reaches the project handler after M4.

The tests exercise the *input path*, not the controller implementation — so they survive the M4
routing change (which preserves behaviour) and only break at M8 (which changes the API surface).

## Open question — test feasibility

The main risk is **test infrastructure**: driving the real input path for an example project from
a busted test requires standing up the project environment (or enough of it). The existing test
harness has `mock.keystroke` and `EditorSession` — can it be extended to drive a project-level
input flow? This needs investigation as part of commissioning M3.

## Decision status

**Open.** The human instructed to create an entrypoint (E9) to decide on M3/M4 based on this
analysis. The successor session should resolve:

1. Is M3 (input-path integration tests) commissioned?
2. What does its spec look like? (Test targets, infrastructure requirements, acceptance criteria.)
3. Does M4 stay as black-box, or is it escalated?
4. Does M7 run in parallel with M4? (Its prerequisites are already met.)
