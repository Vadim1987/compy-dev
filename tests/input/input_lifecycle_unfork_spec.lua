-- Availability: feature-new — the un-forked widget lifecycle is
-- introduced by this feature (since 1.0.0-rc20260712).

-- Pins the behaviour of the UserInputController:keypressed
-- `app_state`-fork removal: deleting the `love.state.app_state ==
-- 'editor'` branch so `keypressed` runs one uniform path. See
-- doc/development/decisions/input.md Decision 6 for the rationale
-- and doc/development/internals/user_input.md for the mechanism.
-- Mirrors input_redesign_ac_spec.lua's style — assertions on
-- observable seams (widget text, fired callbacks), plus a couple
-- of narrow method-patch spies where the seam IS the call itself
-- (evaluate_input call count, model:cancel not running) — the same
-- technique input_widgets_callbacks_spec.lua uses for its one
-- widget-signature row.

local F    = require('tests.helpers.input_fixture')
local mock = require('tests.mock')
local TU   = require('tests.testutil')

describe('#input #lifecycle_unfork input lifecycle un-forking',
  function()
    setup(function() F.setup() end)
    teardown(function() F.teardown() end)
    before_each(function() F.reset() end)

    -- A standalone widget, NOT the persistent/overlay — direct
    -- construction, like user_input_view_spec.lua.
    local function bare_uic()
      local m = UserInputModel(F.cfg, InputEvalText)
      local c = UserInputController(m, true)
      c:init_view({
        render = function() end,
        draw   = function() end,
      })
      return c
    end

    -- keypressed-only driver: mock.keystroke calls
    -- press(k, scancode, isrepeat); controllers here only
    -- care about k.
    local function driver(ctrl)
      return function(k) ctrl:keypressed(k) end
    end

    -- Open a plaintext doc in the REAL wired editor (F.editor),
    -- mirroring ConsoleController:edit's own app_state flip.
    local function open_doc(lines)
      love.state.app_state = 'editor'
      local save = TU.get_save_function(lines)
      F.editor:open('doc.txt', lines, save)
      return F.editor
    end

    -- ---- 1. uniform lifecycle, no app_state gate ----------

    describe('uniform lifecycle (no app_state gate)', function()
      -- RED today: the 'editor' branch never runs
      -- submit_flow/cancel_flow at all, regardless of
      -- who the caller is — a bare widget under app_state
      -- 'editor' should still submit/cancel like any other.
      it('plain Enter submits, plain Escape cancels', function()
        local c = bare_uic()
        love.state.app_state = 'editor'
        local submitted = 0
        c:show({
          text = 'hello',
          on_text_entered = function() submitted = submitted + 1 end,
        })

        mock.keystroke('return', driver(c))
        assert.equal(1, submitted)

        mock.keystroke('escape', driver(c))
        assert.is_true(c:is_empty())
      end)
    end)

    -- ---- 2. editor Escape preserves the load ---------------

    describe('editor Escape preserves the load', function()
      it('loads the selection, does not wipe it', function()
        local doc = { 'first line', 'second line', '' }
        local ed  = open_doc(doc)
        local model = ed.input.model
        local canceled = false
        local orig_cancel = model.cancel
        model.cancel = function(...)
          canceled = true
          return orig_cancel(...)
        end

        mock.keystroke('up', driver(ed))
        mock.keystroke('escape', driver(ed))

        assert.same({ 'second line' }, ed.input:get_text():items())
        assert.is_false(canceled)
        model.cancel = orig_cancel
      end)
    end)

    -- ---- 3. editor Enter / Ctrl+Enter submit locally -------

    describe('editor submit does not double-fire through UIC',
      function()
        it('plain Enter: _handle_submit, no on_text_entered',
          function()
            local doc = { '', 'body', '' }
            local ed  = open_doc(doc)
            local fired = false
            ed.input.callbacks.on_text_entered =
              function() fired = true end

            mock.keystroke('up', driver(ed))
            ed.input:add_text('replaced')
            mock.keystroke('return', driver(ed))

            assert.is_false(fired)
            assert.is_true(ed.input:is_empty())
          end)

        it('Ctrl+Enter: _handle_submit, no on_text_entered',
          function()
            local doc = { '', 'body', '' }
            local ed  = open_doc(doc)
            local fired = false
            ed.input.callbacks.on_text_entered =
              function() fired = true end

            ed.input:add_text('inserted')
            mock.keystroke('C-return', driver(ed))

            assert.is_false(fired)
          end)
      end)

    -- ---- 4. editor Alt+Enter does nothing ------------------

    -- Alt+Enter is NOT one of the editor's own submit variants
    -- (submit() handles only plain/Ctrl Enter), so it is not
    -- blocked — it falls through to the widget's uniform
    -- submit_flow. That is acceptable precisely because the editor
    -- sets no on_text_entered/after_submit callbacks, so submit_flow
    -- delivers to nothing and leaves the loaded input untouched
    -- (the same harmless no-op console relies on). This guards that
    -- an unhandled Enter variant causes no real editor submit.
    describe('editor Alt+Enter (unhandled variant)', function()
      it('reaches a callback-less submit_flow — input untouched',
        function()
          local doc = { 'first line', 'second line', '' }
          local ed  = open_doc(doc)
          mock.keystroke('up', driver(ed))
          mock.keystroke('escape', driver(ed))   -- load selection

          mock.keystroke('M-return', driver(ed))

          assert.same({ 'second line' },
            ed.input:get_text():items())
        end)
    end)

    -- ---- 5. Shift+Enter on non-empty editor input ----------

    describe('editor Shift+Enter on non-empty input', function()
      it('is NOT blocked — inserts a line-feed', function()
        local doc = { '', 'body', '' }
        local ed  = open_doc(doc)

        ed.input:add_text('abc')
        mock.keystroke('S-return', driver(ed))

        assert.same({ 'abc', '' }, ed.input:get_text():items())
      end)
    end)

    -- ---- 6. console + a light overlay re-assert ------------

    describe('console lifecycle', function()
      it('plain Enter: evaluate_input runs once, text intact',
        function()
          local calls, seen = 0, nil
          local orig = F.cc.evaluate_input
          F.cc.evaluate_input = function(self, ...)
            calls = calls + 1
            seen = self.input:get_text():items()
            return orig(self, ...)
          end

          F.console:add_text('1')
          mock.keystroke('return', F.session.press)

          assert.equal(1, calls)
          assert.same({ '1' }, seen)
          F.cc.evaluate_input = orig
        end)

      it('Escape clears the console line', function()
        F.console:add_text('abc')
        mock.keystroke('escape', F.session.press)
        assert.is_true(F.console:is_empty())
      end)
    end)

    describe('overlay submit/cancel — light re-assert', function()
      it('Enter submits, Escape cancels', function()
        local input = F.activate_project()
        local got
        input.show({
          text = 'hi',
          on_text_entered = function(t) got = t end,
        })
        F.session.press('return')
        assert.same({ 'hi' }, got)

        input.show({ text = 'bye', force = true })
        F.session.press('escape')
        assert.is_true(F.widget:is_empty())
      end)
    end)

    -- ---- 7. `modify` per-instance flag ---------------------

    -- self.allow_modify alone decides whether Ctrl+D duplicates
    -- the line; app_state no longer gates it (the app_state fork
    -- was removed — decisions/input.md Decision 6). The ON case
    -- still pairs the flag with app_state 'editor' and the OFF
    -- case with a non-editor app_state to mirror the editor's
    -- real usage, though UIC itself no longer reads app_state.
    describe('modify flag gates Ctrl+D duplicate-line', function()
      it('ON: Ctrl+D duplicates the current line', function()
        local c = bare_uic()
        c.allow_modify = true
        love.state.app_state = 'editor'
        c:show({ text = 'abc' })

        mock.keystroke('C-d', driver(c))

        assert.same({ 'abc', 'abc' }, c:get_text():items())
      end)

      it('OFF: Ctrl+D does nothing', function()
        local c = bare_uic()
        c.allow_modify = false
        love.state.app_state = 'ready'
        c:show({ text = 'abc' })

        mock.keystroke('C-d', driver(c))

        assert.same({ 'abc' }, c:get_text():items())
      end)
    end)

    -- ---- 8. non-shift Enter breadth (Ctrl/Alt) submits -----

    -- The lifecycle guard is `is_enter and not shift`, NOT "bare
    -- Enter": Ctrl+Enter and Alt+Enter submit too (only Shift+Enter
    -- is carved out, as the newline). Rationale for pinning:
    -- discovered as existing behaviour, with no mandate to alter
    -- it — treated as a de-facto standard per the implementation
    -- (decisions/input.md Decision 6 / Decision 14; mechanism in
    -- internals/user_input.md) and frozen so the console/overlay
    -- expectation isn't silently narrowed later. (Narrowing to
    -- bare-Enter-only would be a separate, owner-gated spec change.)
    describe('non-shift Enter (Ctrl/Alt) submits by design',
      function()
        it('overlay: Ctrl+Enter submits', function()
          local input = F.activate_project()
          local got
          input.show({
            text = 'hi',
            on_text_entered = function(t) got = t end,
          })
          mock.keystroke('C-return', F.session.press)
          assert.same({ 'hi' }, got)
        end)

        it('overlay: Alt+Enter submits', function()
          local input = F.activate_project()
          local got
          input.show({
            text = 'hi',
            on_text_entered = function(t) got = t end,
          })
          mock.keystroke('M-return', F.session.press)
          assert.same({ 'hi' }, got)
        end)

        it('console: Ctrl+Enter evaluates', function()
          local calls = 0
          local orig = F.cc.evaluate_input
          F.cc.evaluate_input = function(self, ...)
            calls = calls + 1
            return orig(self, ...)
          end

          F.console:add_text('x')
          mock.keystroke('C-return', F.session.press)

          assert.equal(1, calls)
          F.cc.evaluate_input = orig
        end)
      end)
  end)
