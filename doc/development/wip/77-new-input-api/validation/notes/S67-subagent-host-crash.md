---
description: Two Opus sub-agent spawns took the container's host down within ~20s; diagnosis, evidence, and the guardrails added to the commission
status: evidence note
audience: developer
authored: llm
session: 67
date: 2026-09-02
---

# The peer-review spawn that killed the host, twice

## What happened

Two spawns of the cold peer review (`S67-cold-peer-review-commission.md`) each took the **host**
running this container to 100% CPU, maximum disk read and active swapping, requiring a hard reboot.
Neither agent wrote a line. The owner reported both; the second cost this session its context.

## Evidence

From the session transcript, the three sub-agent spawns of session67 — same `general-purpose` type,
same tool set, same `run_in_background: false`, same repository:

| Spawn | Model | Outcome |
|---|---|---|
| 18:53:02 — mermaid diagram audit | `sonnet` | ran **9 minutes**, returned normally, wrote its report |
| 20:09:51 — cold peer review | `opus` | last local activity 20:10:08 — dead at **~16 s** |
| 22:24:56 — cold peer review | `opus` | last local activity 22:25:18 — dead at **~22 s** |

No `tool_result` was ever recorded for either failure and no sidechain entries survive, so the
agents' own actions are unrecoverable.

**The review's workload is not the cause.** Every operation the commission prescribes was measured
afterwards and is trivial: the full range diff is 3074 lines across 25 files, `git log -p` over the
range is 4269 lines, `git grep` at the PR base takes 0.36 s, `busted tests` takes 2.3 s.

**The environment has no ceiling.** `memory.max` = `max` and `cpu.max` = `max` — the container is
entitled to the whole host. It sees 2 CPUs and 3819 MB of RAM with **no swap inside**, while Node's
heap limit is **2006 MB**, over half of physical memory. The parent `claude` process already holds
~408 MB and `lua-language-server` ~294 MB. A process climbing toward a 2 GB ceiling it cannot reach
on a 3.8 GB box produces exactly the reported triad: back-to-back parallel full GCs (100% CPU on
both cores), RSS past physical memory (the host swaps), and each GC pass faulting swapped pages
back in (disk read at maximum). It thrashes rather than cleanly OOM-killing.

## Leading hypothesis — recursive agent fan-out

**Not proven.** No sidechain records survived and `dmesg` is blocked in the container. It is an
inference from the timing, the model split, and a real gap in the prompt:

- `general-purpose` declares `Tools: *`, which **includes the `Agent` tool**.
- The spawn message stated that a spawned agent inherits none of the repo's `CLAUDE.md` and then
  restated only the LSP, git and suite rules — **the sub-agent hygiene rules were not among them**,
  including `agents/validation.md`'s *"sequence sub-agents; do NOT parallelize"*. The one rule that
  would have prevented a fan-out was explicitly declared inapplicable.
- The commission's shape invites it: **seven independently-scoped questions**, plus an instruction
  to search `doc/`, `src/`, `tests/`, the planning tree and the nested example repos.
- Opus at `CLAUDE_EFFORT=high` delegates far more readily than Sonnet, which is the only variable
  separating the survivor from the two failures. ~20 s is about right for read-commission-then-fan-out.

A second contributor that cannot be excluded: each sub-agent's MCP connection triggering its own
`lua-language-server` cold index of the workspace.

## What was changed

In `S67-cold-peer-review-commission.md`:

1. **A leaf-agent rule** — the reviewer may not use the `Agent` tool at all, and works the seven
   questions sequentially. Stated with its reason, so a reader does not file it as fussiness.
2. **`lua-lsp` is to be queried serially** — one shared server process, not a per-query worker.
3. **Searches are scoped** — never recurse from `/repo` root (63 MB of `.git`, 28 MB of binary
   assets under `src/assets/`, a tarball and five nested repositories); prefer `git grep`.
4. **The commit range is pinned** to `4a0b4dd0..874411f5^` rather than `..HEAD`, which moves.

## What was NOT changed, and is the owner's call

The container has **no memory or CPU limit**, so any runaway — this one or a future one — takes the
host down rather than dying inside the box. The durable fix is a ceiling on the container in the
compose stack under `implementation/docker` (e.g. a memory limit near 2 GB, a CPU limit below the
host's core count, and a pid limit). Raised with the owner 2026-09-02; deferred as out of scope for
this session. **Until it lands, the prompt guardrails above are the only thing preventing a repeat**,
and they depend on a sub-agent choosing to obey them.

## The transferable lesson

Telling a sub-agent *"you inherit none of the repository's rules"* and then restating a subset is a
**licence to do anything unrestated**. When that sentence is used, the restated set must include the
constraints that bound the agent's *behaviour*, not only the ones that bound its *conclusions*.
