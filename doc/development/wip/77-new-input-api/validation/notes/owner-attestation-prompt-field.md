# Owner attestation — the `prompt` field: origin, and the behaviour that is wanted

**Owner, 2026-08-27, in session49**, responding to
[`../reviews/ARC-01-07-reconfiguration-policies.md`](../reviews/ARC-01-07-reconfiguration-policies.md).
Recorded because the review reasoned from provenance ("the stakeholder never asked for `prompt`")
and this corrects the premise. Owner's words, lightly punctuated:

> *"The need to change the label mid-run is real though not anticipated by the stakeholder — I ruled
> adding it to requirements as it was needed for balloons and lack of such ability was a real
> defect."*
>
> *"Behaviorally I would say it's convenient to have label surviving bare `.show()`. It's decoration
> surface."*
>
> *"Text really is special field — it's expected to be changed by user so we legitimately think that
> new `show()` must clear it."*
>
> *"Even if balloons could be now designed without widget at all (based solely on combos) I can
> imagine the situation where updating prompt mid-run would be useful. Building a separate machinery
> for hypothetical case could be an overkill though."*

## What this settles

1. **`prompt` in FR-1 is an owner ruling, not a normalization slip.** It was added to
   `design/requirements.md` deliberately, against a real defect. The review's "no stakeholder
   origin" framing is therefore only half true: no *stakeholder* origin, but a legitimate *owner*
   one, which outranks the inference drawn from its absence in the ticket.
2. **Mid-run label change is a requirement**, so `configure()`'s live-update path is serving a real
   need. The design's citation of "updating a label mid-run" as `configure()`'s motivating example
   was correct, not self-invented.
3. **Label surviving a bare `show()` is wanted behaviour**, on the stated principle: the label is
   **decoration surface** — the project owns it. Option 2 of the review (make `prompt` per-show) is
   therefore **declined**.
4. **`text` clearing on a fresh `show()` is affirmed**, on the stated principle: content is
   **user-owned** — the user is expected to change it, so a new `show()` must not inherit a draft.
5. **An unset mechanism for a hypothetical case is overkill.** Bears on `BUG-01-02`: whatever is
   ruled there should be justified by a real need, not by uniformity for its own sake.

## Corroboration in balloons (checked in-tree, `src/examples/balloons`)

Stronger than the attestation claims. `terminal.lua`:

```lua
function terminal_write(msg, flushed)
  compy.input.configure({ prompt = msg })
end
```

The label is balloons' **entire text-output channel**, and `terminal_init` activates the widget
**once** and leaves it open (continuous-session idiom).

*(Corrected 2026-08-27, same session: an earlier draft of this note said `ui_draw_hint` runs "on
every draw". It does not — it is reached only from `ui_set_hint` (`ui.lua:48-51`), so the label is
re-pushed on state transitions, not per frame. `ui_renderers` does not call it. The shadow-copy
pattern that re-push belongs to is filed as `BUG-01-07`.)*

A nuance worth keeping separate from the ruling: balloons demonstrates the **live-update**
requirement (`configure` on an active session) and never exercises **stickiness across a bare
`show()`**, because it never re-shows. The two behaviours are distinct, and the attestation covers
them by different arguments — item 2 by defect, item 3 by convenience.
