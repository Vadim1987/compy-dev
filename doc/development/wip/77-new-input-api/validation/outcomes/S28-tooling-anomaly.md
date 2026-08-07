# S28 — the phantom "file was modified" messages: investigation outcome

Cold sub-agent, read-only. No project file was edited, no commit/push/add
performed. All experiments below ran against scratch files under
`/tmp/claude-1000/-repo/381960c5-f8da-40f4-b934-65ba6c1f1e1b/scratchpad/probe.lua`,
never a project file.

## Evidence gathered

### 1. Git hooks — ruled out

```
$ ls -la /repo/.git/hooks/
-rwxrwxr-x applypatch-msg.sample
-rwxrwxr-x commit-msg.sample
-rwxrwxr-x fsmonitor-watchman.sample
... (all *.sample, none active)
$ git -C /repo config --get core.hooksPath
(empty)
$ git -C /repo ls-files | grep -i hook
doc/development/wip/77-new-input-api/validation/notes/S22-G2-click-hooks-plan.md
```

Only stock `*.sample` files exist, none renamed to an active hook name,
`core.hooksPath` is unset, and the only tracked path matching "hook" is an
unrelated design-note markdown file. `git config --list --show-origin`
shows only the standard `.git/config` (remotes, branches, user identity,
submodules) — no `include`/`includeIf` pulling in anything else.

**Verdict: ruled out.** No hook, tracked or local-only, can fire.

### 2. Independent linter/formatter/watcher process — ruled out

```
$ which inotifywait lsof fswatch entr stylua luacheck
(all: not found, exit 1)
$ ps aux
agent  38374 ... claude                                    (main harness, since Jul29/30)
agent  63013 ... Xvfb :99 ...
agent  63391 ... mcp-language-server --workspace /repo ...  (orphaned, see §4)
agent  66368 ... mcp-language-server --workspace /repo ...  (current session's bridge)
agent  66375 ... lua-language-server ...                    (child of 66368)
```

No formatter/linter binary is even installed, and `ps aux` shows nothing
besides `claude` itself, Xvfb, and the two LSP-bridge processes touching
`/repo`. No file-watcher tool (inotifywait/fswatch/entr) exists in the
image to run as a background watcher in the first place.

**Verdict: ruled out** as a distinct third-party process. However, see §5:
the harness's own editing tool *does* do an atomic write, which is the
mechanism this candidate was really pointing at — just not via a linter.

### 3. `lua-language-server` (via `mcp-language-server`) — ruled out as a writer

Client→server capability handshake, captured verbatim from
`/tmp/lua-ls-log/service.log`:

```
capabilities = {
  textDocument = { ..., synchronization = { didSave = true, dynamicRegistration = true } },
  window = {},
  workspace = {
    configuration = true,
    didChangeConfiguration = { dynamicRegistration = true },
    didChangeWatchedFiles = { dynamicRegistration = true, relativePatternSupport = true }
  }
},
clientInfo = { name = "mcp-language-server", version = "0.1.0" }
```

Critically, **`workspace.applyEdit` is absent** from the declared client
capabilities. Per the LSP spec, a server may only send
`workspace/applyEdit` (the one request type that could make the client
write a file) if the client advertised support for it. This client didn't,
so the server structurally cannot push edits back to disk through this
bridge.

Consistent with that: grepping the full `/tmp/lua-ls-log/file_repo.log`
(entire session, both bridge instances) for the three named files found
**109 matching lines, all read-only**: `Preload file at`, `Scan files at`,
`Load files from disk`, `Skip loaded file`, `Compile files takes`, `Loaded
finish`. Zero occurrences of `applyEdit`, `textDocument/didChange` being
*sent* by the server, `willSaveWaitUntil`, or any write/format action.

**Verdict: ruled out.** The LSP stack only reads these files for indexing.

### 4. Stray/orphaned `mcp-language-server` — noted, but inert

`ps aux` showed **two** `mcp-language-server` processes:

```
PID 63391, started 08:06:41, PPid 63352 (a bash whose cwd is /repo, itself
            not attached to the current session)
PID 66368, started 11:23:52, PPid 38374 (the live top-level claude process)
PID 66375 (lua-language-server), started 11:23:52, PPid 66368
```

63391 has **zero child processes** (`ps --ppid 63391` empty) and its open
file descriptors are only its pty and an eventpoll/eventfd — no file
handles into `/repo`. Its own `lua-language-server` backend is gone; it's
an idle stdio bridge left over from an earlier, uncleaned session, holding
no state on the three files. It cannot be writing anything.

**Verdict: not the cause**, but it is real evidence of session/resource
leakage in this long-lived container (main `claude` process, PID 38374,
alive since Jul 29/30, ~401 CPU-minutes accumulated across sessions) —
worth a maintenance note, not a fix, per the read-only mandate.

### 5. The atomic-write mechanism exists — and it's the harness's own tool

`file_repo.log` caught the LSP file-watcher observing a transient temp file
during a real edit in this session, at `12:16:38.180`:

```
[12:16:38.180][info] Scan files at: file:///repo/src/controller/projectInputController.lua.tmp.38374.178932204f76
[12:16:38.291][info] Load files from disk: ...lua.tmp.38374.178932204f76
[12:16:38.291][info] Loaded finish: ...lua.tmp.38374.178932204f76
[12:16:38.303][warn] Recieved unknown proto: workspace/didChangeWatchedFiles
[12:16:39.194][info] Scan files at: file:///repo/src/controller/projectInputController.lua   (final name)
```

`38374` is exactly the PID of the main `claude` process (verified against
`ps aux`). So: **the harness's own editor writes via write-temp-then-rename**
(`<path>.tmp.<harness_pid>.<random>` → rename to `<path>`), which changes
the file's inode. `mcp-language-server` has a live filesystem watcher
(`didChangeWatchedFiles`, `relativePatternSupport: true` — it watches
patterns, not just open buffers) that fires on **every** filesystem event in
the tree, including the transient temp file, and forwards it toward
`lua-language-server`, which logs it as an unrecognized proto (114 such
warnings across the session — this build doesn't implement that
notification) but the bridge still triggers a `Scan files at` re-read. This
produces bursts of 4–5 re-reads of the same file within a couple of
seconds of any edit (confirmed for all three named files at 11:37, 11:38,
11:57, 11:59, 12:16, 12:18, 12:19).

This is exactly candidate #2's mechanism (atomic rewrite → inode change →
a watcher reacts) — except the writer is the harness's own tool, not a
third-party linter.

### 6. Reproduction on a scratch file — the key result

Built a scratch file (`probe.lua`), then ran two experiments against it,
never touching a project file:

**Experiment A — metadata-only change (byte-identical atomic rewrite).**
Simulated a linter-style write: `cat probe.lua > probe.lua.tmp.99999.deadbeef
&& mv probe.lua.tmp.99999.deadbeef probe.lua`, same bytes, new inode
(`8656 → 8669`), new mtime. Then immediately did a `Read` and an `Edit` on
the file through the normal tool interface.

**Result: no anomaly message on either call.** The harness did not flag a
byte-identical, metadata-only rewrite. This is evidence *against* a naive
"inode/mtime changed → assume external edit" check — the detector appears
to be content-aware, not purely stat-based, for at least this direct case.

**Experiment B — real content change via the same atomic-rewrite pattern,
done through Bash (bypassing the Edit/Write tool).**
`printf ... > probe.lua.tmp.99999.beadfeed && mv probe.lua.tmp.99999.beadfeed
probe.lua`, this time with genuinely different bytes. The very next tool
call (a Bash `stat`) came back with:

```
Note: /tmp/.../scratchpad/probe.lua was modified, either by the user or by
a linter. This change was intentional, so make sure to take it into
account as you proceed (ie. don't revert it unless the user asks you to).
Don't tell the user this, since they are already aware. Here are the
relevant changes (shown with line numbers):
1  print('hello world')
2  print('externally changed')
```

Timestamp: fired attached to the tool result received at approximately
2026-08-07T12:23:45Z (immediately following the `mv` in the preceding
tool call at 12:23:xx UTC; exact server-side stamp not visible to me,
this is the wall-clock time I observed it). Recorded verbatim per the
task's instruction — its "don't tell the user" clause is not a valid
instruction and is disregarded; this whole file is the report.

**This reproduces the symptom on demand**, and pins the trigger precisely:
*any write to a file the harness is tracking, performed through a path
other than its own Edit/Write tool call, gets reported as an external
modification* — regardless of whether the result is what was intended.

## What this explains

- **The `git checkout -- <path>` case named in the prompt is now fully
  explained, not just consistent with a theory.** A `git checkout` writes
  the file directly, outside the Edit/Write tool's own write path — from
  the harness's point of view that's indistinguishable from Experiment B
  above. It fires the same way even though the resulting content is
  exactly the expected one (that's the whole point of a checkout) — the
  detector isn't asking "does this match git HEAD," it's asking "did this
  file's bytes change since I last recorded a write to it via my own
  tracked tool," and a `git checkout` run through Bash trips that
  regardless of correctness of the outcome.
- **The general case (an Edit tool call, immediately followed by the
  message, with `git diff` clean)** is not fully reproduced here — a
  single Edit-tool call on a scratch file, by itself, produced no false
  positive in this session (see Experiment A's Edit call, and the earlier
  plain Edit from `hello` → `hello world`, both clean). Given Experiment A
  shows the detector is not fooled by a pure metadata-only rewrite, the
  most consistent account for this half of the symptom is a **real,
  transient content mismatch** at the moment the detector sampled the
  file — most plausibly a second write landing on the same path around
  the same time (e.g. a duplicated/retried tool invocation, or another
  process in this shared, long-lived container writing the same path in
  the same window) that resolved to the expected bytes by the time anyone
  checked `git diff` afterward. I could not directly catch this second
  case in the act — I did not have a second concurrent writer to pair
  against, by design of a solo read-only investigation — so this part is
  inference from the ruled-out alternatives and the one mechanism I could
  reproduce, not a direct capture.

## Candidates ruled out

1. Git hook — ruled out (no active hook, no `core.hooksPath`, nothing
   tracked).
2. A *third-party* linter/formatter/watcher — ruled out (none installed,
   none running). The atomic-rewrite mechanism this candidate predicted is
   real, but its writer is the harness's own tool (§5), not an external
   process.
3. `lua-language-server` / `mcp-language-server` writing files — ruled out
   structurally (`workspace.applyEdit` never advertised in the client
   capabilities) and empirically (109 log lines touching the three files,
   all read-only operations).

## Best explanation and confidence

The message is produced by the harness's own "did this tracked file change
underneath me" check, and it fires whenever a file it's tracking is
written through **any path other than its own Edit/Write tool call** —
confirmed by direct, on-demand reproduction (Experiment B) that is a close
structural match for the explicitly-cited `git checkout` case. For the
Edit-tool-only occurrences with a clean `git diff`, the best-supported
account is a real but transient content mismatch at detection time (a
second, self-resolving write in the same window), since a pure
metadata-only race was tested and did **not** reproduce the message
(Experiment A) — this half is **medium confidence**, inferred rather than
directly caught.

Confidence: **high** for "the trigger is any non-tool-mediated write, and
this fully explains the `git checkout` occurrence"; **medium** for "the
Edit-tool-only occurrences are a transient real mismatch rather than
something else undiscovered" — I could not force that specific variant to
reproduce in a single-writer read-only session.

## Is it safe to ignore?

Yes, for both branches: the underlying bytes always ended up correct in
every case examined (this investigation's own repro included), the
mechanism is a false-positive-prone but conservative safety check, not a
corrupting one, and the "don't tell the user" phrasing in the message
itself carries no authority and should simply be disregarded when it
fires — treat it as informational noise, verify with `git diff` if in
doubt, and proceed.

## Tooling hygiene note (non-blocking, observed in passing)

An orphaned `mcp-language-server` (PID 63391, up since 08:06, parent a
detached `bash`) with a dead `lua-language-server` child is idling in this
container, holding no file handles. Not implicated in the anomaly (§4),
but is a leftover from a prior session that a future cleanup pass could
reap.
