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

## 3. The framework's own shortcuts are now a table, not a cascade

> The handful of key combinations the framework reserves for itself were written
> as a chain of modifier tests inside the keyboard gateway. They are now a table
> keyed by the same combo strings a project uses for its own bindings —
> `['ctrl+t']`, `['ctrl+s']`, `['ctrl+escape']` — one entry per reservation.
>
> Nothing about which combos are reserved, what they do, or when they apply
> changed; the tests that pin them were not touched, which is the evidence. What
> changes is that the reserved set can now be listed and documented rather than
> read out of a cascade, and that exactness is enforced by the representation:
> a string key cannot match a chord carrying a modifier it does not name.
>
> The table is deliberately **not** the same table a project registers into, and
> the difference runs both ways: a project cannot override a reservation, and —
> the opposite of a project's rule — **a reservation never consumes the key**,
> which still reaches the project afterwards. That contract is stated in the code
> beside the table. Recorded as Decision 34 in
> `doc/development/decisions/input.md`.

Supporting material: `validation/reviews/S43-P-24-00-only-mods-api.md` and
`S43-P-24-00b-table-and-sharing.md` for the alternatives weighed, including the
two that were rejected — sharing one assembled combo between the gateway and the
route (a cache of device state with no path back to the truth) and reusing a
module-level buffer to avoid an allocation (shared mutable state in a function
that must then never be re-entered).

---

## Also owed, but not from this session

The **reserved-combo section the guide has never had** is P10's, and it now has
to state what a reservation *claims* — not only which combos are reserved but
that a reservation does not extend to chords it does not name. Flagged on the P10
row so it is not improvised at write-time.
