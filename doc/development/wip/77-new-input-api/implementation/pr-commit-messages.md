# Commit messages for the reassembled branch

One section per commit, in apply order. Copy the body of a section into
`git commit -F -` after applying its slice.

Order is **docs → tests → code → examples** (owner, 2026-08-03). Two
consequences worth stating up front, because a reviewer will notice both:

- **The test commit is red.** It lands before the implementation, matching the
  project's tests-first discipline, and goes green when the code commits land.
  That red→green arc is the point, not an accident to hide.
- **One exception to the ordering**, commit 6: the highlight regression carries
  its fix *and* its test together, because they are one self-contained change
  and splitting them would leave a commit that proves nothing. It also must
  precede commit 9, which shares a file with it.

Slices live in `pr-slices/`; §1 of `pr-assembly-guide.md` regenerates them.
Verified 2026-08-03: applying all ten in this order reproduces the branch tip
byte-identically outside `doc/development/wip/`.

---

## 1 — `1a-generic-docs-rubberstamping`

```
docs: mark LLM-authored dev docs as pending human approval

One line inserted after each H1, 21 files, nothing else. Split out
so the docs commit that follows can be read for its arguments
rather than its line count.
```

## 2 — `1b-generic-docs`

```
docs: refresh the development doc corpus

The meaningful half of the docs pass: conventions, the overview,
and the per-example and internals docs.

Provenance moves from the inline marker of the previous commit to
a YAML front-matter block (conventions/docs.md), so two files show
a marker removed and a described block added. The convention
itself is new.
```

## 3 — `2-agentic`

```
chore(agents): add agent charters and process docs

Working agreements for LLM-assisted development: role charters,
coding rules, the session workflow, and the review/inspection
planes. No product code.
```

## 4 — `3f-input-docs`

```
docs(input): the input API guide, internals, decisions and debt

The persistent documentation for the new input surface, landing
before the code so a reviewer can read the contract first.

- doc/input_api.md — the project author's guide: show/hide, the
  submit lifecycle, validation and highlighting, event hooks and
  shortcuts, pointer and click hooks, held keys, the stop hook,
  and a migration table from the retired polling globals.
- internals/user_input.md — how it works underneath: routing, the
  dispatch chain, and the mechanism behind each guarantee.
- decisions/input.md — the ratified decisions and, for each, what
  it was chosen over.
- technical_debt/input.md — what is known and not done, with a
  revisit condition each.
- tests.md, CHANGELOG.md — suite inventory and the release note.
```

## 5 — `3d-tests`

```
test(input): the #input contract suite and its fixtures

Lands before the implementation, per tests-first. RED at this
commit and green once the code commits land: every row here
describes behaviour the next four commits introduce.

The suite drives the real production path throughout — the real
love.handlers gateway, a real ConsoleController, and the real
project-activation call — rather than a simulation of them. Two
shared helpers carry the standup: input_fixture (the world) and
input_session (a keypress-level driver that fires real events
through the gateway).

Rows that are not behaviour contracts are collected in
input_nfr_mechanism_spec under headings that say so, precisely so
nobody reads them as promises.
```

## 6 — `3g-highlight-regression`

```
fix(input): keep the highlight table indexable

A nil-index crash in UserInputModel:highlight, carried with its
own test so the pair reads as one self-contained change. This is
the one commit that does not depend on the red→green arc of the
suite: it is green on its own.
```

## 7 — `3a-routing-core`

```
feat(input): route-centric dispatch and the project route

The structural change the rest hangs off. The application mode
selects exactly one active route — console, editor, or project —
and a widget never selects the route. Widget visibility becomes
state on the widget rather than a routing condition, which is
what removes the keyboard lockout: a project's own handlers now
run while a prompt is on screen.

Inside the route, one chain of three: shortcuts, then the hook,
then the widget. A truthy return consumes; a falsey one falls
through. The widget is terminal and consumes by being shown. The
same shape runs on every channel — key presses, releases, text,
pointer, and the framework's derived click events.

One lifetime: the route holds every channel from project start to
project stop, and nothing a project installed survives it. One
error boundary, at route entry, so project input code runs with
its canvas bound and its errors routed to the project error
handler.
```

## 8 — `3b-widget-surface`

```
feat(input): the compy.input surface and widget sink

The project-facing API and the widget it drives.

show/hide/configure/clear replace four polling globals with one
call plus a callback. is_shown answers the one state question a
project cannot answer itself, its `love` being a sandboxed clone.
set_text/get_cursor/set_cursor edit an ACTIVE prompt, which the
old API could only do by rebuilding it.

The surface is frozen at the sub-table level: leaf writes land,
replacing a sub-table raises. compy.before_exit gives a project
one chance to put back global device state it changed.

Type annotations for the whole surface land here too.
```

## 9 — `3c-model-view-util`

```
feat(input): held keys, combo parsing, text model and view

The pieces the chain and the widget are built from.

Combo strings normalise on registration — 'Ctrl+Alt+S' and
'ctrl+alt+s' are one binding — with modifiers in fixed order and
left/right folded. A combo names modifiers plus exactly one
trigger; two or none raises, and so does a bare '*', which would
otherwise be a second spelling for "every key" that reads like a
narrow binding.

The trigger may be '*' with modifiers, binding a whole modifier
class: 'alt+*' is every Alt chord. Exact bindings win; the class
is consulted only on a miss.

compy.input.keys_pressed exposes the held set as a read-only view,
readable outside an event — the callback argument cannot serve a
per-frame renderer.
```

## 10 — `3e-examples-tracked`

```
refactor(examples): migrate the bundled examples to the input API

The retired globals have no compatibility shim, so every example
that solicited text moves to compy.input.show plus a callback:
guess, repl, tixy, turtle, valid.

paint and sapper move off compy.singleclick/doubleclick onto
compy.input.hooks.singleclick/.doubleclick — the derived click
events are ordinary chain participants now, not a bespoke
surface.

These migrations are the platform's work product, not homework
for the example authors.
```

---

## Set 4 — the nested example repos

Not part of this PR. `balloons`, `maze` and `keyboard` are separate repos with
their own remotes; each opens its own PR alongside this one, sliced the same
way. `pr-assembly-guide.md` §5 covers them.
