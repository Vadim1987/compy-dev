# ARC-01-07 — behaviour probes: what `show`/`configure` actually do, per field

Session49, 2026-08-27. Evidence for
[`../reviews/ARC-01-07-reconfiguration-policies.md`](../reviews/ARC-01-07-reconfiguration-policies.md).
Run at HEAD `c70a7032`, suite green (979) before and after; the probe specs were scratch and are
**not** committed — the source below reproduces them under `tests/` with `busted tests/probe_spec.lua`.

Everything here is driven through `F.compy_input()` — the project-facing `compy.input` surface,
not the controller — so each line is what a project author can observe.

## Results (verbatim probe output)

| # | Sequence | Observed |
|---|---|---|
| 1 | `show{prompt='first:', text='hello'}` → `hide()` → `show{}` | label `first:` **kept**, text **cleared** |
| 2 | active; `show{prompt='second:', text='b', highlighter=hl2, force=true}` | text → `b`; label still `first:`; highlighter still `hl1` |
| 3 | active with text `a`; `show{force=true}` (no `text`) | content **kept** (`is_empty` false) |
| 4 | `show{prompt='p1', text='a'}` → `configure{prompt='p2', text='zzz'}` | label → `p2`, text still `a` |
| 5 | `show{prompt='p1'}` → `hide()` → `configure{prompt='pending:'}` → `show{}` | label → `pending:` |
| 6 | active; `show{highlighter=hl2, force=true}`, then `hide()` → `show{}` | hl2 **not** applied during the force call; **applied at the next show** |
| 7 | `show{prompt='p1'}` → `configure{prompt=''}` | label → `` (empty string clears it) |
| 8 | `show{}` on a fresh widget, no prompt ever given | label → `text input` (evaluator default) |
| 9 | `show{highlighter=hl}` → `configure{highlighter=nil}` | highlighter **kept** (cannot be unset) |
| 10 | `show{validator=v}` → `configure{validator=nil}` → `hide()` → `show{}` | validator **kept** through both |

Probe 6 is the non-obvious one: the force path does not apply the highlighter *now*, but it lands on
the **next** activation. The call is neither honoured nor refused — it is deferred, silently.

**Scope of that, corrected 2026-08-27 (cold review, re-probed):** it is the **highlighter alone**.
`merge_callback_keys` writes into the widget's own `callbacks` table — the same table `apply_config`
writes — so `validator`, `on_text_entered` and `on_limit_reached` passed to a forced `show` are
**applied immediately**. The `highlighter` differs because it is stored on `model.evaluator`, which
that merge never touches. An earlier reading of these probes generalised from the one field tested
to all four.

Probe 3 vs. probe 1: `text` absent means **clear** on a fresh `show` and **keep** on a forced
re-`show`. Two policies for one field, both reachable from the same function.

## Pre-feature baseline (PR base `3256aac`)

- `custom_label` existed, as **constructor argument 4** of `UserInputModel`
  (`src/model/input/userInputModel.lua:47`), i.e. fixed for the widget's lifetime.
- A widget's lifetime *was* one input session: `consoleController.lua:569` built a fresh
  `UserInputModel(cfg, eval, true, prompt)` per `input_text(prompt, init)` / `input_code(prompt, init)`
  call and `set_text(init)` right after.
- Consequence: **`prompt` and `text` were the two arguments of one call and behaved identically** —
  per invocation, absent meaning "none". `get_label()` fell back to the evaluator label
  (`userInputModel.lua:69-74`), which is where today's `text input` default still comes from.
- There was **no `configure`** at base — the symbol does not exist anywhere in `3256aac:src/`.

So neither the split nor the stickiness is inherited. Both are this feature's.

## Probe source

```lua
local F = require('tests.helpers.input_fixture')

describe('ARC-01-07 probe', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  it('prompt survives a hide/show cycle, text does not', function()
    local input = F.compy_input()
    input.show({ prompt = 'first:', text = 'hello' })
    input.hide()
    input.show()
    print('label:', tostring(F.widget.model:get_label()))
    print('empty:', tostring(F.widget:is_empty()))
  end)

  it('force re-show: which fields land', function()
    local input = F.compy_input()
    local hl1 = function(l) return l end
    local hl2 = function(l) return l end
    input.show({ prompt = 'first:', text = 'a', highlighter = hl1 })
    input.show({ prompt = 'second:', text = 'b', highlighter = hl2, force = true })
    print('label:', tostring(F.widget.model:get_label()))
    print('text: ', tostring(F.widget:get_text()[1]))
    print('hl2? ', tostring(F.widget.model.evaluator.highlighter == hl2))
    input.hide(); input.show()
    print('hl2 after re-show?', tostring(F.widget.model.evaluator.highlighter == hl2))
  end)

  it('force re-show with no text keeps content', function()
    local input = F.compy_input()
    input.show({ text = 'a' })
    input.show({ force = true })
    print('empty:', tostring(F.widget:is_empty()))
  end)

  it('configure while shown: text inert, prompt live', function()
    local input = F.compy_input()
    input.show({ prompt = 'p1', text = 'a' })
    input.configure({ prompt = 'p2', text = 'zzz' })
    print('label:', tostring(F.widget.model:get_label()))
    print('text: ', tostring(F.widget:get_text()[1]))
  end)

  it('hidden configure stashes prompt for the next show', function()
    local input = F.compy_input()
    input.show({ prompt = 'p1' })
    input.hide()
    input.configure({ prompt = 'pending:' })
    input.show()
    print('label:', tostring(F.widget.model:get_label()))
  end)

  it('empty string clears the label, nil does not', function()
    local input = F.compy_input()
    input.show({ prompt = 'p1' })
    input.configure({ prompt = '' })
    print('label: [' .. tostring(F.widget.model:get_label()) .. ']')
  end)

  it('no prompt ever given: evaluator default', function()
    local input = F.compy_input()
    input.show({})
    print('label: [' .. tostring(F.widget.model:get_label()) .. ']')
  end)

  it('highlighter and validator cannot be unset', function()
    local input = F.compy_input()
    local hl = function(l) return l end
    local v = function() return true end
    input.show({ highlighter = hl, validator = v })
    input.configure({ highlighter = nil, validator = nil })
    print('hl kept: ', tostring(F.widget.model.evaluator.highlighter == hl))
    print('val kept:', tostring(F.widget.callbacks.validator == v))
  end)
end)
```
