# Lines the PR description owes from session43

Drafted here rather than written into `implementation/pr-description.md`, which
is **stale since session27** and regenerated as the last step before the PR
(`pr-assembly-guide.md`). These are the paragraphs that step must pick up. Both
belong under **"Ratified deviations from the original design"** — they are owner
rulings taken after the design was ratified, not design content.

---

## 1. Framework shortcuts now match their modifier set exactly

> The framework reserves a handful of key combinations for itself — Ctrl+Escape
> to leave a running project, Ctrl+T to switch between run and editor, and a few
> more. Each of those tested only the modifiers it named and ignored the rest, so
> Ctrl+**Shift**+Escape was taken as Ctrl+Escape, and a project that bound the
> richer chord had its binding fire and then be undone by the platform. This PR
> makes every such reservation exact: the modifiers it names are held, and no
> other. Plain Ctrl+Escape and Ctrl+T are unchanged, so the way out of a running
> project is exactly what it was.
>
> Why it is in a PR about the project-facing input API: the feature made every
> other layer match its modifier set exactly, and left the one layer with the
> most power — a reservation a project cannot override — matching loosely. The
> reasoning is recorded as Decision 33 in
> `doc/development/decisions/input.md`. It also closes a real defect:
> Ctrl+Alt+Shift+R satisfied both the reset gate (ctrl+shift) and the restart
> gate (ctrl+alt) and fired **both** in one event.
>
> **User-visible:** Ctrl+Shift+Escape and Ctrl+Shift+T no longer act as escape
> hatches out of a run. They belong to the project now. Anyone with that muscle
> memory should use the plain chords.

Supporting material, if a reviewer asks: `validation/reviews/S43-P-21-00-blast-radius.md`
(all nine reservations, before and after), and fifteen live cases in
`tests/input/input_global_shortcuts_spec.lua` asserting for the first time what a
reservation does **not** claim.

---

## 2. The harmony scripting harness keeps its manual release discipline

> `src/harmony` is the project's scripted UI-automation harness. Mid-feature it
> was changed to emit modifier press/release events and drop its manual
> `release_keys()` step; that change is reverted here. The harness pushes events
> onto LÖVE's queue, which drains a frame later, so clearing the simulated
> modifier inside the same call left it released before the app ever saw the key
> — every scripted chord arrived as a bare key. The harness is outside the test
> suite and outside CI, so nothing signalled it.
>
> The subsystem is now byte-identical to the PR base apart from one seven-line
> comment stating why simulated modifiers never enter the event stream.

Supporting material: `validation/notes/S43-harmony-p13-timing-finding.md` and the
A/B probes beside it.

---

## Also owed, but not from this session

The **reserved-combo section the guide has never had** is P10's, and it now has
to state what a reservation *claims* — not only which combos are reserved but
that a reservation does not extend to chords it does not name. Flagged on the P10
row so it is not improvised at write-time.
