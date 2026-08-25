# S45 worker prompt of record — reflow our over-long comment lines to 64 chars

Model: **Sonnet**, explicit. Spawned 2026-08-25 by session45 (parent: Opus).
Mechanical reflow. **No git, ever. No wording changes, ever.**

---

You are working in the LÖVE2D project at `/repo` (cwd), on feature #77's pre-PR
comment pass (row P11).

## What this is

`agents/rules.md` sets a **hard limit of 64 characters per line**. This
feature's work introduced **419 comment lines that exceed it**. The owner ruled
(2026-08-25): **reflow ours, leave pre-existing ones alone** — the limit binds
new code.

Your job is to **re-wrap those comment lines so no line exceeds 64 characters**,
changing **not one word**.

## Absolute constraints

- **No git.** No `commit`, `add`, `stash`, `checkout`, `restore`, `reset`,
  `branch`, `clean`, `rm`. `git show` reads are allowed only where this prompt
  tells you to use one. The parent commits; you never do.
- **Reflow only.** You may move words between lines of the same comment block
  and add or remove line breaks. You may **not** reword, shorten, summarise,
  merge two comments, split one comment into two blocks, fix a typo, change
  punctuation, or "improve" anything. If a comment says something wrong or
  clumsy, it stays wrong and clumsy — a different pass owns that, and the
  parent verifies your work by comparing the word stream mechanically.
- **Never touch a code line.** Only lines whose first non-whitespace characters
  are `--`.
- **Never touch a comment that was already over-length before this feature.**
  A line counts as pre-existing if that exact text appears in the file's version
  at the PR base: `git show 3256aac:<path>`. Those are out of scope by owner
  ruling. Everything else in the list below is ours.
- **`busted tests` must report `968 successes / 0 failures / 0 errors /
  10 pending`** when you finish. Run it first to see the baseline is real.

## How to reflow

- Keep the comment's own prefix and indentation exactly: a `---` doc-comment
  line stays `---`, a `--` stays `--`, and the leading whitespace of the block
  is preserved on every line you create.
- Wrap at a word boundary, as close under 64 as the words allow. Do not
  hyphenate, and do not break inside a backtick-quoted identifier or a path.
- **A path or identifier that is itself longer than the limit stays on its own
  line, over-length.** That is unavoidable and correct; leave it and note it in
  your report. Do not shorten a path to make it fit — a truncated citation is
  worse than a long line.
- Preserve deliberate structure: a list, a two-column table drawn in a comment,
  an ASCII diagram, or a `@param`/`@return` annotation keeps its shape. If
  wrapping one would destroy the structure, leave that line and report it.
- Blank comment lines (`--` alone) are separators; keep them.

## The files, with the count of our over-long comment lines in each

Work them in this order. Do **`src/` first, then `tests/`**, and run
`busted tests` after each file so a mistake is caught next to its cause.

```
src/controller/consoleController.lua      30
src/controller/controller.lua             29
src/controller/projectInputController.lua 25
src/controller/userInputController.lua    23
src/util/key.lua                          10
src/main.lua                               6
src/view/input/userInputView.lua           4
src/model/input/userInputModel.lua         3

tests/input/input_events_spec.lua         76
tests/input/input_widget_callbacks_spec.lua 32
tests/input/input_widget_control_spec.lua 31
tests/input/input_routing_spec.lua        29
tests/input/highlight_regression_spec.lua 25
tests/helpers/input_fixture.lua           24
tests/input/input_route_lifecycle_spec.lua 21
tests/input/input_shortcuts_click_spec.lua 9
tests/input/input_combo_serialisation_spec.lua 7
tests/input/input_nfr_mechanism_spec.lua   7
tests/editor/editor_spec.lua               6
tests/input/input_cursor_text_spec.lua     6
tests/input/project_open_liveness_spec.lua 5
tests/helpers/input_session.lua            4
tests/mock.lua                             4
tests/util/key_spec.lua                    3
```

To find the lines in a file:

```
python3 - <<'EOF'
import subprocess
p = 'src/controller/controller.lua'   # the file you are on
base = subprocess.run(['git','show',f'3256aac:{p}'],
                      capture_output=True,text=True)
old = set(base.stdout.split('\n')) if base.returncode==0 else set()
for n,l in enumerate(open(p,encoding='utf-8').read().split('\n'),1):
    if len(l)>64 and l.lstrip().startswith('--') and l not in old:
        print(n, len(l), l)
EOF
```

## Deliverable

`doc/development/wip/77-new-input-api/validation/outcomes/S45-comment-reflow.md`

1. **Per file:** lines over the limit before, lines over the limit after,
   lines you deliberately left over-length.
2. **The left-over-length list** — every one, with the reason (an unbreakable
   path, an ASCII diagram, a table).
3. **Anything you noticed and did not touch** — a comment whose claim looks
   false, a citation to a heading that may not exist, a duplicated comment.
   Report; do not act. The parent owns those.
4. The final `busted tests` line.

Report back: total before, total after, how many you left long, and the suite
line.
