-- Availability: the dispatch chain, the per-event
-- hooks and the project-handler install path are introduced by 
-- new input API (since 1.0.0-rc20260712); none exist prior to it.

-- dispatch chain: tier mechanics  Routing invariant
-- (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route,
-- fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"):
-- ROUTE = the controller an event is dispatched to; WIDGET =
-- the route-managed input surface and terminal of the chain.
-- Tests assert observable outcomes at public seams, never
-- method-name spies.  keypressed fires for every physical key,
-- textinput only for character-producing keys
-- (doc/development/internals/user_input.md, "Data flow").  This
-- file covers the dispatch-chain MECHANICS:
-- order/consume/fall-through, combo tables, signatures,
-- defaults, hook and handler install, the mutable/immutable
-- boundary (doc/development/decisions/input.md, Decision 2).
-- Widget OUTPUTS (the callbacks fired on submit and cancel)
-- live in input_widgets_callbacks_spec.lua.

local F = require('tests.helpers.input_fixture')

-- All rows drive the REAL project route: F.activate_project() installs the
-- ProjectInputController as the active route (app_state='running') via the
-- production Controller.set_user_handlers path, and returns the project-facing
-- compy.input surface. Assertions read the widget's text and the callbacks a
-- project registers — except the one widget-signature row, which patches the
-- shared widget and restores it.

describe('#input events dispatching', function()


  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)


  -- Press a modifier then a trigger so the combo serialises to 'ctrl+…' — a real chord
  -- (doc/development/decisions/input.md, Decision 8).
  local function chord(mod, k)
    F.session.press(mod)
    F.session.press(k)
  end

  describe('order, consume, fall-through', function()
    -- Walked on the keypressed channel only, deliberately. The walk
    -- is ONE channel-agnostic function in production —
    -- `dispatch(shortcuts, hooks, widget, event, trigger, ...)` in
    -- projectInputController.lua indexes `shortcuts[event]` and
    -- `hooks[event]` and is otherwise identical per channel — so
    -- re-running the order/consume rows for keyreleased and textinput
    -- would re-prove the same function three times. That the three
    -- channels each REACH the walk is proven separately, per channel,
    -- in the combo group below.

    -- doc/development/decisions/input.md, Decision 2: the dumb
    -- walk stops at the first consumer. A shortcut returning
    -- truthy consumes — the hook and widget below never run.
    it('a shortcut consumes before the hook and widget',
      function()
        local reached_hook = false
        local input = F.activate_project()
        input.shortcuts.keypressed['a'] =
            function() return true end
        input.hooks.keypressed =
            function() reached_hook = true; return true end
        F.show_widget({ text = 'b' })
        F.session.press('a')
        assert.is_false(reached_hook)
      end)

    -- doc/development/decisions/input.md, Decision 2: an
    -- unconsumed event walks shortcut → hook → widget in order;
    -- falsy consumers fall through, and the shown widget is the
    -- terminal consumer (backspace edits it — the observable trace).
    it('an unconsumed event walks shortcut, hook, then widget',
      function()
        local order = { }
        local input = F.activate_project()
        input.shortcuts.keypressed['backspace'] =
            function() order[#order + 1] = 'shortcut' end
        input.hooks.keypressed =
            function() order[#order + 1] = 'hook' end
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'shortcut', 'hook' }, order)
        assert.same({ 'a' }, F.widget:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 2: a truthy combo
    -- handler stops the descent —
    -- neither the hook nor the widget runs.
    it('a shortcut returning truthy stops the chain (hook not reached)', function()
      local reached_cb = false
      local input = F.activate_project()
      input.shortcuts.keypressed['backspace'] =
          function() return true end
      input.hooks.keypressed =
          function() reached_cb = true; return true end
      F.show_widget({ text = 'ab' })
      F.session.press('backspace')
      assert.is_false(reached_cb)
      assert.same({ 'ab' }, F.widget:get_text())
    end)

    -- doc/development/decisions/input.md, Decision 2: consuming never
    -- removes a configured callback — the same callback
    -- fires again on the next event (configuration is permanent).
    it('is a permanent configuration', function()
      local n = 0
      local input = F.activate_project()
      input.hooks.keypressed =
          function() n = n + 1; return true end
      F.session.press('a')
      F.session.press('a')
      assert.equal(2, n)
    end)

  end)

  -- doc/development/decisions/input.md, Decision 2: only the shortcut
  -- tier is KEYED — it participates for its own combo and for nothing
  -- else, while the hook and the widget are unkeyed and therefore see
  -- every event their channel carries. The groups above pin what a
  -- MATCHED shortcut does; these pin its silence on every other key,
  -- once per channel, since each channel keys its own combo table
  -- (doc/development/decisions/input.md, Decision 8). Every shortcut
  -- here is registered CONSUMING, so a spurious match would be
  -- observable twice over: `fired` flips AND the tiers below it stop
  -- receiving.
  describe('shortcut selectivity', function()

    it('a keypressed shortcut is silent for another key',
      function()
        local fired, seen = false, 0
        local input = F.activate_project()
        input.shortcuts.keypressed['a'] =
            function() fired = true; return true end
        input.hooks.keypressed = function() seen = seen + 1 end
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.is_false(fired)
        assert.equal(1, seen)
        assert.same({ 'a' }, F.widget:get_text())
      end)

    it('a textinput shortcut is silent for another character',
      function()
        local fired, got = false, { }
        local input = F.activate_project()
        input.shortcuts.textinput['s'] =
            function() fired = true; return true end
        input.hooks.textinput =
            function(t) got[#got + 1] = t end
        F.show_widget()
        F.session.type('q')
        assert.is_false(fired)
        assert.same({ 'q' }, got)
        assert.same({ 'q' }, F.widget:get_text())
      end)

    -- The widget is left out of this one on purpose: it is shown, so
    -- it consumes the release unconditionally and would witness
    -- nothing about the shortcut.
    it('a keyreleased shortcut is silent for another key',
      function()
        local fired, seen = false, 0
        local input = F.activate_project()
        input.shortcuts.keyreleased['a'] =
            function() fired = true; return true end
        input.hooks.keyreleased = function() seen = seen + 1 end
        F.session.press('b')
        F.session.release('b')
        assert.is_false(fired)
        assert.equal(1, seen)
      end)
  end)

  -- doc/development/decisions/input.md, Decision 2: the interception
  -- matrix. Two things at once — each participant intercepts for
  -- itself only (a consumer stops the walk exactly where it sits), and
  -- a MISSING participant is not a barrier: the walk skips it and the
  -- ones below still run. Rows configure (shortcut, hook) as
  -- pass-through or consuming, or leave them undefined; `seen` is the
  -- mnemonic trace and the widget's text is the observable terminal
  -- (backspace edits 'ab' -> 'a' exactly when the widget runs).
  describe('the interception matrix', function()

    local CONSUME, PASS = 'consume', 'pass'

    local rows = {
      { name = 'no participant defined: the widget still runs',
        widget_runs = true, expect = { } },
      { name = 'both pass through: shortcut, hook, then the widget',
        shortcut = PASS, hook = PASS,
        widget_runs = true, expect = { 'shortcut', 'hook' } },
      { name = 'a consuming shortcut stops the walk at itself',
        shortcut = CONSUME, hook = PASS,
        widget_runs = false, expect = { 'shortcut' } },
      { name = 'a consuming hook stops the walk before the widget',
        shortcut = PASS, hook = CONSUME,
        widget_runs = false, expect = { 'shortcut', 'hook' } },
      { name = 'a missing shortcut does not stop a consuming hook',
        hook = CONSUME,
        widget_runs = false, expect = { 'hook' } },
      { name = 'a missing shortcut does not stop the widget',
        hook = PASS,
        widget_runs = true, expect = { 'hook' } },
      { name = 'a missing hook does not stop the widget',
        shortcut = PASS,
        widget_runs = true, expect = { 'shortcut' } },
    }

    -- records itself in `seen`, then consumes iff mode is CONSUME
    local function participant(seen, who, mode)
      return function()
        seen[#seen + 1] = who
        return mode == CONSUME
      end
    end

    local function configure(input, row, seen)
      if row.shortcut then
        input.shortcuts.keypressed['backspace'] =
            participant(seen, 'shortcut', row.shortcut)
      end
      if row.hook then
        input.hooks.keypressed =
            participant(seen, 'hook', row.hook)
      end
    end

    for _, row in ipairs(rows) do
      it(row.name, function()
        local seen = { }
        configure(F.activate_project(), row, seen)
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same(row.expect, seen)
        assert.same({ row.widget_runs and 'a' or 'ab' },
          F.widget:get_text())
      end)
    end
  end)

  describe('shortcuts fire on the normalised combo', function()
    -- doc/development/decisions/input.md, Decision 8: each channel has its
    -- OWN combo sub-table
    -- and keys normalise on assignment ('Ctrl+S' -> 'ctrl+s').
    it('a keypressed combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.shortcuts.keypressed['Ctrl+S'] =
            function() fired = true; return true end
        chord('lctrl', 's')
        assert.is_true(fired)
      end)

    it('a textinput combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.shortcuts.textinput['Ctrl+S'] =
            function() fired = true; return true end
        F.session.press('lctrl')
        F.session.type('s')
        assert.is_true(fired)
      end)

    it('a keyreleased combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.shortcuts.keyreleased['Ctrl+S'] =
            function() fired = true; return true end
        chord('lctrl', 's')
        F.session.release('s')
        assert.is_true(fired)
      end)

    -- doc/development/decisions/input.md, Decision 8: the per-event
    -- tables are distinct — asserted by BEHAVIOUR (a registration on
    -- one channel does not fire on another) rather than by reading
    -- the table structure, which was the smell the previous form had.
    it('a keypressed combo does not fire on textinput',
      function()
        local leaked = false
        local input = F.activate_project()
        input.shortcuts.keypressed['s'] =
            function() leaked = true; return true end
        F.session.type('s')
        assert.is_false(leaked)
      end)

    -- The hook half of the same claim: hooks are per-event too, so a
    -- keypressed hook must not see a textinput event.
    it('a keypressed hook does not fire on textinput', function()
      local leaked = false
      local input = F.activate_project()
      input.hooks.keypressed =
          function() leaked = true; return true end
      F.session.type('s')
      assert.is_false(leaked)
    end)
  end)

  -- A combo is modifiers plus ONE trigger
  -- (doc/development/decisions/input.md, Decision 21). The rule is
  -- enforced at registration because the canonical form silently
  -- kept the LAST non-modifier token before: 'ctrl+a+b' became
  -- 'ctrl+b', and 'a+b+*' became a bare '*' — the widest possible
  -- binding written as the narrowest. Raising is the same
  -- treatment show/configure give an unrecognised key (Decision 15).
  describe('the combo registration contract', function()

    it('rejects a combo with two triggers', function()
      local input = F.activate_project()
      assert.has_error(function()
        input.shortcuts.keypressed['ctrl+a+b'] = function() end
      end)
    end)

    it('rejects a class combo with a trigger beside it', function()
      local input = F.activate_project()
      assert.has_error(function()
        input.shortcuts.keypressed['a+b+*'] = function() end
      end)
    end)

    -- The legal shapes stay legal: a bare trigger, modifiers plus a
    -- trigger, and modifiers plus the class marker.
    it('accepts a trigger, a combo, and a class', function()
      local input = F.activate_project()
      local sc = input.shortcuts.keypressed
      sc['a'] = function() end
      sc['Ctrl+Alt+S'] = function() end
      sc['ctrl+alt+*'] = function() end
      assert.is_function(sc['a'])
      assert.is_function(sc['ctrl+alt+s'])
      assert.is_function(sc['ctrl+alt+*'])
    end)

    -- A combo naming no trigger at all is not a binding.
    it('rejects a modifier-only combo', function()
      local input = F.activate_project()
      assert.has_error(function()
        input.shortcuts.keypressed['ctrl+alt'] = function() end
      end)
    end)
  end)

  -- A trailing '*' binds the whole modifier class
  -- (doc/development/decisions/input.md, Decision 21): 'alt+*' is
  -- every Alt chord. Exact bindings win; the class is consulted
  -- only on a miss, so the hit path is unchanged.
  describe('combo classes', function()

    local function bind_class(input, combo)
      local seen = { }
      input.shortcuts.keypressed[combo] = function(k)
        seen[#seen + 1] = k; return true
      end
      return seen
    end

    it('one class binding catches every key in it', function()
      local input = F.activate_project()
      local seen = bind_class(input, 'alt+*')
      F.session.press('lalt')
      F.session.press('q')
      F.session.press('z')
      assert.same({ 'q', 'z' }, seen)
    end)

    -- The handler needs to know WHICH key matched, and already
    -- does: the trigger is argument one, as on any other combo.
    it('the class handler receives the real trigger', function()
      local input = F.activate_project()
      local seen = bind_class(input, 'ctrl+alt+*')
      F.session.press('lctrl')
      F.session.press('lalt')
      F.session.press('h')
      assert.same({ 'h' }, seen)
    end)

    it('an exact binding wins over the class', function()
      local input = F.activate_project()
      local seen = bind_class(input, 'alt+*')
      local exact = false
      input.shortcuts.keypressed['alt+p'] =
          function() exact = true; return true end
      F.session.press('lalt')
      F.session.press('p')
      assert.is_true(exact)
      assert.same({ }, seen)
    end)

    -- A class is its modifier set exactly, so Ctrl+Alt+H is NOT an
    -- Alt chord. This is the exclusion a hand-rolled modifier test
    -- has to write out and get right.
    it('a wider modifier set is a different class', function()
      local input = F.activate_project()
      local seen = bind_class(input, 'alt+*')
      F.session.press('lalt')
      F.session.press('lctrl')
      F.session.press('h')
      assert.same({ }, seen)
    end)

    -- Holding Alt alone dispatches the combo 'alt+lalt' — the
    -- modifier prepended to itself as the trigger. A class must not
    -- match its own modifier, or every Alt press fires it.
    it('a class does not match its own modifier key', function()
      local input = F.activate_project()
      local seen = bind_class(input, 'alt+*')
      F.session.press('lalt')
      assert.same({ }, seen)
    end)

    it('classes work on the textinput channel too', function()
      local seen = { }
      local input = F.activate_project()
      input.shortcuts.textinput['ctrl+*'] = function(t)
        seen[#seen + 1] = t; return true
      end
      F.session.press('lctrl')
      F.session.type('x')
      assert.same({ 'x' }, seen)
    end)
  end)

  -- doc/development/decisions/input.md, Decision 22. Dispatch does
  -- not gate on isrepeat — a held combo fires every frame — so a
  -- command binding wraps itself. The consuming half is the part
  -- that is easy to get wrong by hand: a repeat that is NOT
  -- consumed falls through to the hook and the widget.
  describe('suppress_repeat', function()

    it('a fresh press runs the wrapped function', function()
      local ran = 0
      local input = F.activate_project()
      input.shortcuts.keypressed['ctrl+s'] =
          input.suppress_repeat(function() ran = ran + 1 end)
      chord('lctrl', 's')
      assert.equal(1, ran)
    end)

    it('a repeat does not run it', function()
      local ran = 0
      local input = F.activate_project()
      input.shortcuts.keypressed['s'] =
          input.suppress_repeat(function() ran = ran + 1 end)
      F.session.press('s')
      F.session.repeat_press('s')
      F.session.repeat_press('s')
      assert.equal(1, ran)
    end)

    -- The load-bearing half: consumed on a repeat as well, so the
    -- widget behind never sees the held key.
    it('consumes the repeat it swallows', function()
      local input = F.activate_project()
      input.shortcuts.keypressed['s'] =
          input.suppress_repeat(function() end)
      F.show_widget({ text = 'ab' })
      F.session.press('backspace')
      F.session.repeat_press('backspace')
      assert.same({ '' }, F.widget:get_text())
      input.shortcuts.keypressed['backspace'] =
          input.suppress_repeat(function() end)
      F.session.repeat_press('backspace')
      assert.same({ '' }, F.widget:get_text())
    end)

    it('passes the payload through to the wrapped function',
      function()
        local seen
        local input = F.activate_project()
        input.shortcuts.keypressed['alt+*'] =
            input.suppress_repeat(function(k, keys)
              seen = { k, keys['lalt'] }
            end)
        F.session.press('lalt')
        F.session.press('q')
        assert.same({ 'q', true }, seen)
      end)

    -- Same signature everywhere, so it wraps a hook as readily as a
    -- shortcut. Whether that is WISE is the project's call — a
    -- whole-channel hook swallows every repeat, the widget's
    -- included.
    it('wraps a hook the same way', function()
      local ran = 0
      local input = F.activate_project()
      input.hooks.keypressed =
          input.suppress_repeat(function() ran = ran + 1 end)
      F.session.press('s')
      F.session.repeat_press('s')
      assert.equal(1, ran)
    end)
  end)

  -- ---- signatures + read-only proxy of pressed-keys table
  -- (doc/development/decisions/input.md, Decision 9 and Decision 13) ---

  describe('signatures and the read-only proxy', function()
    -- The table's CONTENTS are asserted in this file's
    -- 'the pressed-keys table' group below (what it holds after a
    -- press, what it no longer holds after a release, and that a
    -- participant cannot write to it); this group covers the
    -- signature the participants are called with.
    -- doc/development/decisions/input.md, Decision 9: keypressed
    -- participants receive (k, proxy, isrepeat). Asserted over the
    -- WHOLE chain, not one participant: every step is configured
    -- pass-through (records its triple, returns false), so the event
    -- walks shortcut -> hook -> widget and each step is checked for
    -- what was actually DELIVERED — the key itself, a proxy that
    -- really reports the held key, and the true isrepeat flag — not
    -- merely for type compliance.
    it('every step of the chain receives the same delivered triple',
      function()
        local seen  = { }
        local input = F.activate_project()
        local step  = function(who)
          return function(k, keys, isr)
            seen[who] = { k, keys['a'], isr }
          end
        end
        input.shortcuts.keypressed['a'] = step('shortcut')
        input.hooks.keypressed         = step('hook')
        F.session.repeat_press('a')
        assert.same({ 'a', true, true }, seen.shortcut)
        assert.same({ 'a', true, true }, seen.hook)
      end)

    -- doc/development/decisions/input.md, Decision 9: isrepeat is false on
    -- a fresh press, true on repeat.
    it('isrepeat threads to the hook', function()
      local seen = { }
      local input = F.activate_project()
      input.hooks.keypressed = function(_, _, isr)
        seen[#seen + 1] = isr; return true
      end
      F.session.press('a')
      F.session.repeat_press('a')
      assert.same({ false, true }, seen)
    end)

    -- The held-key table as a participant sees it: what it contains,
    -- what it no longer contains, and that it cannot be written to
    -- (doc/development/decisions/input.md, Decision 13;
    -- doc/development/internals/user_input.md, "Key release").
    describe('the pressed-keys table', function()

      it('contains the pressed key', function()
        local proxy
        local input = F.activate_project()
        input.hooks.keypressed = function(_, keys)
          proxy = keys; return true
        end
        F.session.press('a')
        assert.is_table(proxy)
        assert.is_true(proxy['a'])
      end)

      -- the key is removed at the gateway BEFORE dispatch, so a
      -- keyreleased participant never sees it still held.
      it('no longer contains a released key', function()
        local present = true
        local input = F.activate_project()
        input.hooks.keyreleased = function(k, keys)
          present = keys[k]; return true
        end
        F.session.press('a')
        F.session.release('a')
        assert.is_nil(present)
      end)

      it('cannot be modified from a hook', function()
        local proxy
        local input = F.activate_project()
        input.hooks.keypressed = function(_, keys)
          proxy = keys; return true
        end
        F.session.press('a')
        assert.has_error(function() proxy['x'] = true end)
      end)
    end)

    -- The same held set, readable OUTSIDE an event
    -- (doc/development/decisions/input.md, Decision 20;
    -- doc/input_api.md, "Held keys"). The participant argument
    -- above cannot serve a project that RENDERS held state: a
    -- per-frame draw runs between events, with no argument in
    -- hand. examples/keyboard mirrored the whole set by hand for
    -- exactly this reason.
    describe('compy.input.keys_pressed', function()

      it('reports a held key from outside any handler',
        function()
          local input = F.activate_project()
          F.session.press('a')
          assert.is_true(input.keys_pressed['a'])
        end)

      it('drops a released key', function()
        local input = F.activate_project()
        F.session.press('a')
        F.session.release('a')
        assert.is_nil(input.keys_pressed['a'])
      end)

      -- Read-only, by the same rule as the participant argument:
      -- the project observes the held set, it does not own it.
      it('cannot be written to', function()
        local input = F.activate_project()
        assert.has_error(function()
          input.keys_pressed['x'] = true
        end)
      end)

      -- It is the SAME view, not a snapshot taken at namespace
      -- build time: what a handler is handed and what the project
      -- reads afterwards agree.
      it('agrees with the view a handler receives', function()
        local from_handler
        local input = F.activate_project()
        input.hooks.keypressed = function(_, keys)
          from_handler = keys['a']; return true
        end
        F.session.press('a')
        assert.equal(from_handler, input.keys_pressed['a'])
        assert.is_true(input.keys_pressed['a'])
      end)
    end)

    -- doc/development/decisions/input.md, Decision 9: the WIDGET is included
    -- in the uniform
    -- signature — it
    -- receives the same (k, proxy, isrepeat) triple. Patches the
    -- shared widget method, restored after the assertion.
    it('the widget receives the uniform keypressed triple',
      function()
        local seen
        F.activate_project()
        F.show_widget()
        -- This direct replacement observes the widget's documented key
        -- signature; restore the shared method after the event.
        F.widget.keypressed = function(_, k, keys, isr)
          seen = { k, keys, isr }
        end
        F.session.repeat_press('a')
        F.widget.keypressed = nil
        assert.equal('a', seen[1])
        assert.is_table(seen[2])
        assert.is_true(seen[3])
      end)

  end)

  -- defaults + hidden widget (doc/development/decisions/input.md,
  -- Decision 10 and Decision 2)

  describe('defaults and the hidden widget', function()
    -- The non-defined-participant permutations the symmetry calls
    -- for (none defined, shortcut missing, hook missing) are the
    -- missing-participant rows of the interception matrix above; this
    -- group covers what the DEFAULTS do once the event arrives.

    -- doc/development/decisions/input.md, Decision 10: the default hook neither
    -- edits nor
    -- consumes — the event falls through to the widget, which
    -- performs the edit.
    it('with no project hook set, the event passes through to the widget',
      function()
        F.activate_project()
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'a' }, F.widget:get_text())
      end)

    -- Availability: since 1.0.0-rc20260712 — pre-feature, a project
    -- with no keyboard handler left the console callback installed.
    -- An unhandled event therefore reached the hidden console. The
    -- project route now owns all running-project keyboard/text input.
    it('no participant + hidden widget mutates nothing',
      function()
        F.activate_project()
        F.show_widget({ text = 'keep' })
        F.widget:hide()
        F.console:add_text('ab')
        F.session.press('backspace')
        assert.same({ 'keep' }, F.widget:get_text())
        assert.same({ 'ab' }, F.console:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 2: whether
    -- the route reports the event as consumed follows from ONE
    -- fact -- is the widget shown. The rows above observe that
    -- through mutations; this one reads the route's own answer,
    -- because a shown widget consumes even keys it does nothing
    -- with (so a 'did it change anything' test cannot witness
    -- it).
    it('the route consumes exactly while the widget is shown',
      function()
        F.activate_project()
        local route = Controller.project_input
        assert.is_falsy(route:keypressed('x'))
        F.show_widget({ text = 'a' })
        assert.is_true(route:keypressed('x'))
      end)
  end)

  -- ---- the per-event hook
  -- (doc/development/decisions/input.md, Decision 5 and Decision 10) ---

  describe('the per-event hook', function()

    -- The keypressed counterpart is not missing, it is upstream: the
    -- interception matrix and the delivered-triple row both drive
    -- hooks.keypressed. What is specific to textinput, and is why
    -- this row exists, is the PER-CHARACTER cadence.
    -- doc/development/decisions/input.md, Decision 5: the textinput hook
    -- fires PER-CHARACTER (distinct from the submit output on_text_entered)
    it('the textinput hook fires per character as text arrives',
      function()
        local got = { }
        local input = F.activate_project()
        input.hooks.textinput = function(t)
          got[#got + 1] = t; return true
        end
        F.session.type('a')
        F.session.type('b')
        assert.same({ 'a', 'b' }, got)
      end)

    -- doc/development/decisions/input.md, Decision 10 (hooks install path):
    -- a truthy callback intercepts
    -- the widget; a present-but-falsey callback falls through.
    it('a truthy textinput hook intercepts; falsey reaches the widget',
      function()
        local input = F.activate_project()
        F.show_widget()
        input.hooks.textinput = function() return true end
        F.session.type('X')
        assert.is_true(F.widget:is_empty())
        input.hooks.textinput = function() return false end
        F.session.type('Y')
        assert.same({ 'Y' }, F.widget:get_text())
      end)
  end)

  -- ---- the project-handler install path
  -- (doc/development/decisions/input.md, Decision 10) -----

  describe('the project-handler install path', function()
    -- doc/development/decisions/input.md, Decision 10: a project
    -- handler is a plain hook
    -- participant that fires REGARDLESS of widget-shown state
    -- (the reversed suppress-while-shown mutation is gone).
    -- Fires in all THREE widget states — never shown, shown, and
    -- shown-then-hidden (widget absence has two distinct forms) — on
    -- both the keypressed and keyreleased channels: a downstream
    -- chain member never blocks upstream consumption. A handler is
    -- seeded into hooks[event], so this is the hook contract, not a
    -- handler-only one (seed_hooks, projectInputController.lua).
    it('a project handler fires whether or not the widget is shown',
      function()
        local seen = { pressed = 0, released = 0 }
        F.activate_project({
          keypressed  = function()
            seen.pressed = seen.pressed + 1
          end,
          keyreleased = function()
            seen.released = seen.released + 1
          end,
        })
        F.session.press('a')
        F.session.release('a')
        F.show_widget()
        F.session.press('a')
        F.session.release('a')
        F.widget:hide()
        F.session.press('a')
        F.session.release('a')
        assert.same({ pressed = 3, released = 3 }, seen)
      end)

    -- doc/development/decisions/input.md, Decision 10, project-handler
    -- path: a truthy handler intercepts the widget.
    it('a handler returning truthy intercepts the widget',
      function()
        F.activate_project({
          keypressed = function() return true end,
        })
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'ab' }, F.widget:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 10, project-handler
    -- path: a falsey handler falls through to
    -- the widget (asserted on the textinput channel too, so all
    -- three channels are covered across the handler
    -- rows).
    it('a falsey handler textinput falls through to the widget',
      function()
        F.activate_project({
          textinput = function() return false end,
        })
        F.show_widget()
        F.session.type('Z')
        assert.same({ 'Z' }, F.widget:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 10 precedence:
    -- an explicit hook takes
    -- precedence over the captured handler — the
    -- handler never
    -- seeds the hook when an explicit hook is set (no
    -- "replace" relation).
    it('an explicit hook takes precedence over the handler',
      function()
        local handler_hits, cb_hits = 0, 0
        local function bump() handler_hits = handler_hits + 1 end
    -- Audited: BOTH paths are exercised in this file, not one.
    -- F.activate_project({ keypressed = f }) is the legacy path — f
    -- is the project's sandboxed love.keypressed, seeded into
    -- hooks[event] once at activation (seed_hooks,
    -- projectInputController.lua) — while every row that assigns
    -- input.hooks.<event> directly (the interception matrix, the
    -- delivered-triple row, the textinput rows) drives the explicit
    -- path. This row is the one that pins how they INTERACT.
        local input = F.activate_project({ keypressed = bump })
        input.hooks.keypressed =
            function() cb_hits = cb_hits + 1; return true end
        F.session.press('a')
        assert.equal(1, cb_hits)
        assert.equal(0, handler_hits)
      end)

    -- doc/development/decisions/input.md, Decision 10:
    -- the seeding happens ONCE, at activation. Clearing the
    -- hook afterwards leaves it cleared -- the captured handler
    -- is not re-resolved behind it. (The retired model re-read
    -- `explicit or handler` per event, so a nil silently fell
    -- back to the handler; a project could then not turn its
    -- own love.keypressed off.)
    it('clearing a seeded hook does not resurrect the handler',
      function()
        local seen = 0
        local input = F.activate_project({
          keypressed = function() seen = seen + 1 end,
        })
        F.session.press('x')
        assert.equal(1, seen)
        input.hooks.keypressed = nil
        F.session.press('x')
        assert.equal(1, seen)
      end)
  end)

  -- ---- the mutable/immutable boundary
  -- (doc/development/decisions/input.md, Decision 7)
  -- -------------

  describe('the mutable/immutable boundary', function()
    -- doc/development/decisions/input.md, Decision 7:
    -- `compy.input` and the IDENTITY of its three sub-tables
    -- (shortcuts, hooks, callbacks) are frozen, while every
    -- leaf inside them is freely writable. A project therefore
    -- fills the surface in but can neither replace nor shadow
    -- it, and a misspelled field raises instead of being
    -- swallowed.
    it('replacing the surface or a sub-table raises', function()
      local input = F.compy_input()
      assert.has_error(function() input.nonsense = 1 end)
      assert.has_error(function()
        input.show = function() end
      end)
      assert.has_error(function() input.shortcuts = { } end)
      assert.has_error(function() input.hooks = { } end)
      assert.has_error(function() input.callbacks = { } end)
      assert.has_error(
        function() input.shortcuts.keypressed = { } end)
    end)

    it('leaf writes inside the sub-tables are accepted',
      function()
        local input = F.compy_input()
        assert.has_no.errors(function()
          input.hooks.keypressed  = function() end
          input.hooks.textinput   = function() end
          input.hooks.keyreleased = function() end
          input.callbacks.validator = function() return true end
          input.shortcuts.keypressed['ctrl+s'] = function() end
        end)
      end)
  end)
end)
