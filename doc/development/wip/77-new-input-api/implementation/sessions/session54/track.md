# session54 — track

## 2026-08-28 boot

- HEAD `ad534984`, branch `feature/77-newapi-analysis-s20260615`.
- Tree: clean against HEAD; untracked = known scratch (`claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `worklog.md`,
  the three nested example repos).
- Baseline `busted tests` → **990 / 0 / 0 / 10**. Matches prompt.
- Fresh start (no prior `track.md`/`report.md` in session54).
- Prompt is a wait-for-human placeholder (session53 was a revalidation).

## Detour — owner-raised defect, ahead of any commissioned task

Owner: same branch, same command, **107 failures in their own dev setup**;
**0 failures on the upstream branch there**; green here. Asked for a way to
capture busted results machine-readably and hand the file over.

Mode: **research + analysis** (named per validation.md). No feature work.

- Built `tests/diag_output.lua` (busted output handler → report *file*, so
  the app's stdout logging cannot corrupt it) and `tests/diag_env.sh`
  (toolchain/git/submodule fingerprint). Both throwaway, both outside PR
  scope, deleted once the cause is known.
- Stock `json` handler is unusable on this suite: *"type 'function' is not
  supported by JSON"*, even on a fully green run. `TAP`/`junit` work but
  interleave with the app's stdout logging.
- Self-tested the handler against injected failure / error / file-load-error
  cases; temp specs removed, suite re-confirmed 990/0/0/10.
- Two hypotheses reproduced and **eliminated** in the container:
  metalua submodule rolled back to master's `0c4c30de` → 3 failures + 18
  tests not run (not 107); stringutils rolled back to `3662789` → no change.
  Pointers restored, suite green.
- Finding worth keeping regardless: this branch **does** bump
  `src/lib/metalua` (`0c4c30de` → `d0dbd0d9`) while `master` does not — a
  checkout that skips `git submodule update` diverges here and not upstream.
- Written up: `validation/notes/S54-suite-env-divergence.md`. OPEN, waiting
  on the owner's `busted-report.txt` + `busted-env.txt`.
