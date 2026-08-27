---
description: Outcome of actualising CHANGELOG.md and giving it the CURRENT_SCOPE protocol
status: complete
audience: developer
authored: llm
reviewed: none
---

# LEDGER-02 — changelog actualisation, outcome

`/repo/CHANGELOG.md` rewritten. `REMARK:` line at top untouched, as
instructed. No other file touched.

## Structure

- `## Unreleased` → `## CURRENT_SCOPE`, content carried forward.
- A short protocol note added directly under the `# Changelog` H1,
  above the section, stating what happens to `CURRENT_SCOPE` on a
  release and that released versions go below it, newest first.
- No version number invented, nothing dated.

## Entries added, with sourcing

### `### Removed`

- **Legacy globals gone, no shim** (`input_text`, `input_code`,
  `validated_input`, `user_input`, `write_to_input`,
  `compy.singleclick`, `compy.doubleclick`). Sourced from
  `doc/input_api.md` "Migration from the legacy globals" table and
  `doc/development/decisions/input.md` Decision 4 ("removed outright
  — no shim, no compatibility flag") and Decision 25 (singleclick/
  doubleclick retired as a bespoke surface). **Checked against code**:
  `grep -rln "input_text\|input_code\|validated_input" src/
  --include="*.lua"` returns nothing; the only hits for
  `compy.input.shortcuts`/`hooks` are the controllers and the
  migrated examples (`maze`, `turtle`, `paint`, `sapper`,
  `keyboard`). This is the entry the prompt calls out as `FIX-02-17`
  — it is now first under `CURRENT_SCOPE`, ahead of every `Added`/
  `Changed` bullet, as instructed.

### `### Added`

- The `compy.input.show/hide/configure/clear` + `on_text_entered`
  surface, replacing the polling idiom. Sourced from
  `doc/input_api.md` §"The input widget" and the PR description's
  "Intent" section.
- Shortcuts (`compy.input.shortcuts[event][combo]`, modifier classes
  like `'alt+*'`) and hooks (`compy.input.hooks[event]`, auto-seeded
  from a project's existing `love.*` handler). Sourced from
  `doc/input_api.md` §"Event hooks and shortcuts" and Decision 10.
  **Checked against code**: `projectInputController.lua` implements
  exactly the `shortcuts[event][combo] → hooks[event] → widget`
  three-step dispatch the docs describe (comment block at the top of
  the file, and the `dispatch` function around line 138).
- `compy.input.fn.ignore_repeat/stop_here/side_run`. Sourced from
  `doc/input_api.md` §"A held key repeats..." table and Decisions 22
  and 24.
- `compy.before_exit`. Sourced from `doc/input_api.md` §"Stop hook".
- The new guide itself, `doc/input_api.md`. Sourced from its own
  front matter and from pr-commit-messages.md commit 4's description
  of what the docs commit contains. Kept to the one file a project
  author would actually read (`doc/input_api.md`); the internals/
  decisions/debt docs are marked `audience: developer`, not project
  author, so I did not list them as things a project author gets.

### `### Changed`

- **The unblocked-keyboard bullet, made prominent and specific**
  (love.keypressed/textinput/keyreleased now fire while a prompt is
  shown). Sourced from the PR description's "Intent" §2 ("Keyboard
  lockout") and Decision 1 in the decisions doc.
- **Show/hide no longer rebuilds; `configure()` while hidden stages
  the next `show()`.** This is the one claim I had to correct after
  checking code. My first draft said "content and cursor persist
  across `hide()` and a later `show()`" — that is **false**: I read
  `src/controller/userInputController.lua` and found `show()` on a
  hidden widget goes through `open_widget`, which calls
  `self.model:clear_input()` whenever `cfg.text == nil` (line
  304-306, comment: "Clear-on-no-text is activation policy — a fresh
  show with no text starts empty"). So a bare `show()` after `hide()`
  clears the field; nothing persists automatically. What *is* true
  and documented is `configure()` called while hidden retaining
  `prompt`/`text`/`cursor` for the next `show()` — `doc/input_api.md`
  line 90-91 states this directly, and I rewrote the bullet to say
  exactly that instead.
- The three existing bullets (separate `highlighter`/`validator`/
  `on_text_entered`, raise-on-bad-key, no console accumulation) are
  the file's originals — left as they were, since they were already
  accurate and matched the model.

## Claims I could not source, and did not write

- Anything about the four nested example repos (`balloons`, `maze`,
  `keyboard`) shipping their own PRs — pr-commit-messages.md "Set 4"
  says they exist and are out of scope for this PR, but this
  changelog is presumably the compy repo's own, and I could not
  confirm from the given artifacts whether those repos' changes are
  meant to appear here at all. Left out rather than guessed.
- A precise list of which bundled examples migrated (guess, repl,
  tixy, turtle, valid, paint, sapper) — commit 10's message names
  them, but I judged this as refactor detail (which files moved to
  the new API) rather than something a project author needs to be
  told, since the examples are demonstrations, not part of the
  contract. Omitted on purpose, not for lack of a source.
- Anything about the "three usability defects predating this work"
  or the open questions in the PR description — explicitly recorded
  there as non-blocking / for a later stakeholder call, not shipped
  behaviour, so they do not belong in a changelog of what changed.

## Defects / contradictions noticed, not fixed

- The PR description's own preamble records that an *earlier draft*
  of that same document "described a member that does not exist and
  denied a capability the code ships" — already caught and fixed by
  the PR description's own author before I read it, so nothing to
  flag there, but worth noting I did not blindly trust the first
  paragraph either.
- `doc/development/decisions/input.md` is mid-edit by another agent:
  it carries several inline `> REMARK:` owner notes (e.g. under
  Decision 2, 4, 5, 8, 10) disputing or requesting rewrites of the
  surrounding prose. I read the file as instructed and did not write
  to it. None of the disputed passages fed a changelog claim — the
  REMARKs concern internal rationale/vocabulary (e.g., whether the
  widget deserves special treatment in the chain, terminology for
  "callbacks" vs "widget outputs"), not the user-facing facts I
  sourced from it (Decision 1's lockout fix, Decision 4's clean
  break, Decision 22/24's wrapper behaviour). If those REMARKs land
  as rewrites, none of the underlying facts I cited look likely to
  change, only their internal framing.
- One real inaccuracy I found and fixed myself (see "Changed"
  above): my first-draft claim about content persisting across
  hide/show was wrong per the actual `userInputController.lua`
  behaviour. Caught before publishing, not left in.

## Verdict: does it now answer "what changed for me?"

Yes, for a project author who reads only this file. The breaking
change (retired globals, no shim) is now the first bullet under the
first heading of `CURRENT_SCOPE`, stated in plain terms with the
guide's migration table pointed to for specifics. The four
surface-level changes the owner's note named are all present: the
lockout fix, the new shortcuts/hooks topology, the rewired dispatch
(described by its effect, not its mechanism), and a pointer to the
new documentation. What it does not do, deliberately: give a
version number, a date, or a list of which bundled examples moved —
those are either not yet decided (release) or not the contract
(examples).
