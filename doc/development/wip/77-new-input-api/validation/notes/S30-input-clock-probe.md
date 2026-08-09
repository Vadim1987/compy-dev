# S30 — the input clock probe: how to run it, and how to read it

The probe is `src/probe/input_probe.lua`. It exists to turn the
polling-vs-tracking question from an argument into a number, on the **target
device**, which is the one thing no amount of reading this tree can supply.

It is a **diagnostic and temporary**. Delete the file when the question is ruled
on; nothing in the app requires it.

## Running it

No source edit and no launch argument — install it from the app's own console:

```lua
require('probe.input_probe').install()
```

Then **type normally for a while.** The editor is the best place, because that is
where the most keystrokes happen and where all 35 of `editorController`'s device
polls live. Deliberately include:

- **fast chords** — `ctrl+s`, `ctrl+shift+q`, `shift+arrow` selections, held
  arrows;
- **fast taps** — a key struck and released as quickly as you can;
- **modifier release races** — hold `ctrl`, hit a key, let go of `ctrl`
  immediately.

Then ask for the totals:

```lua
probe_report()
```

Findings also print as they happen, capped at 40 lines so a bad case cannot
flood the terminal. Counting continues after the cap.

## What it measures, and why these three

| number | meaning |
|---|---|
| `frames with >1 key event` | the **precondition**. LÖVE pumps the whole OS batch and then dispatches it one event at a time, so skew is only possible when two key events share a frame |
| `self-skew` | during dispatch of `keypressed(k)`, the device already reports `k` **up** — press and release shared one batch. Direct proof the poll answers on the later clock |
| `modifier-skew` | during dispatch, the device poll and the event-tracked set **disagreed about a modifier** — i.e. a polling consumer and an event-tracked one would have been looking at different worlds for that event |

`modifier-skew` is the one that matters: it is the mechanism behind the
unrecorded *"weird reaction to keyboard sometimes"* complaints, and its rate
decides whether the 70 device-poll call sites are a live defect or a theoretical
one.

## Suggested reading of the numbers — **proposed, not ratified**

The owner rules; this is only what the assistant would conclude, written down
**before** the data exists so it cannot be fitted afterwards.

- **`frames with >1 key event` ≈ 0** — the mechanism is dormant on this device.
  The polling reform is theoretical; keep the current split, keep the debt entry,
  and stop spending on it.
- **`self-skew` > 0, at all** — proof the batch really does collapse a press and
  its release. The mechanism is live, whatever its rate.
- **`modifier-skew` more than rarely, during ordinary editing** — polling
  consumers are misjudging in normal use, and the 70 call sites become a real
  defect rather than a tidiness question.

## Honest limits of the instrument

- It measures at the **gateway**, so it sees every key event the app receives —
  but it does **not** instrument `textinput`, so a `textinput`-vs-`keypressed`
  ordering question is out of its reach.
- `modifier-skew` counts events where the two sources **disagreed**. It does not
  prove a wrong decision was made: a consumer only misjudges if it actually
  consults the modifier that disagreed. Treat the count as an **upper bound** on
  misjudgements, not a defect count.
- It cannot verify SDL's own state-array timing. It measures the *consequence*
  (the two sources disagree), which is the thing under dispute, not the cause.
- Under `harmony` the reading would be meaningless — locked harmony never
  consults the real device. Run it in the ordinary app.

## What was verified before it shipped

Behaviour proven, not assumed, on a fake gateway under LuaJIT (the shipping
runtime): return values pass through unchanged; the frame boundary is counted at
`love.update`; a fast tap raises `self-skew`; a set/device disagreement raises
`modifier-skew`; three events in one frame register as one multi-event frame;
and the `love.update` wrapper **re-applies itself** when a route change
reassigns `love.update` underneath it. Suite unaffected: **955 / 0 / 0 / 3**.
