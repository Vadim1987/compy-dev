---> REMARK: rename the file to say something about submit-cancel (better than ambigous 'lifecycle')
---> REMARK: dry up the prose and consider making test cases more readable and self-evident
---> REMARK: I'd avoid word 'overlay' fully -- can be 'project input widget'

-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — one uniform lifecycle across all
-- surfaces.

-- Enter and Escape mean the same thing in every input surface.
-- A single lifecycle — `submit_flow` / `cancel_flow` in
-- UserInputController — serves the console line, the editor's
-- input and the project overlay alike; no widget instance reads
-- the global screen mode to decide what a key does. Where a
-- surface needs different behaviour it says so locally: the
-- editor consumes Enter/Escape upstream before the widget sees
-- them, and Ctrl+D line-duplication is a per-instance
-- `allow_duplicate_line` flag set at construction.
--
-- This file is the guard against that uniformity being quietly
-- re-conditioned on global state. Each group drives one surface
-- through the same two keys and states what it must produce;
-- the ones that look repetitive ARE the claim — same keys, same
-- lifecycle, three surfaces.
--
-- Rationale: doc/development/decisions/input.md, Decision 6.
-- Mechanism: doc/development/internals/user_input.md.
--
-- Assertions are on observable seams (widget text, fired
-- callbacks), plus two narrow method patches where the seam IS
-- the call itself (the console's evaluate_input call count, and
-- model:cancel not running under the editor's Escape) — the
-- same technique input_widgets_callbacks_spec.lua uses for its
-- one widget-signature row.

local F    = require('tests.helpers.input_fixture')
local mock = require('tests.mock')
local TU   = require('tests.testutil')

describe('#input #lifecycle one input lifecycle, every surface',
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

    -- ---- 1. the lifecycle ignores the screen mode ----------

    describe('a widget does not read the screen mode',
      function()
      -- The clearest statement of the rule: a plain widget,
      -- owned by nobody, behaves identically no matter what
      -- love.state.app_state happens to say. Screen mode picks
      -- which ROUTE receives an event; it never changes what
      -- the widget does with one.
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

    -- ---- 2. the editor's own meaning for Escape ------------

    -- In the editor, Escape means "load the selected line into
    -- the input for editing" — the opposite of the widget's
    -- clear-the-draft cancel. The editor therefore consumes the
    -- key upstream (EditorController:_normal_mode_keys) and the
    -- widget's cancel_flow never runs; the spy on model.cancel
    -- is how that absence is observed.
    describe('editor Escape loads instead of cancelling',
      function()
      it('loads the selection and does not clear it', function()
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

    -- ---- 3. the editor's own meaning for Enter -------------

    -- Same shape as Escape above: Enter (plain or with Ctrl)
    -- applies the edit to the buffer, and the editor consumes
    -- it, so the submission is delivered once — to the editor —
    -- and never a second time through the widget's
    -- on_text_entered.
    describe('editor Enter submits to the editor alone',
      function()
        it('plain Enter applies the edit, no on_text_entered',
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

        it('Ctrl+Enter applies the edit, no on_text_entered',
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

    -- ---- 4. an Enter variant the editor does not claim -----

    -- Alt+Enter is not one of the editor's submit variants, so
    -- the editor lets it through and the widget's ordinary
    -- submit runs. Nothing happens, and nothing is supposed to:
    -- the editor assigns no on_text_entered or after_submit, so
    -- a submit with no callbacks delivers to nobody and leaves
    -- the loaded text alone — the same harmless no-op the
    -- console relies on. The row exists so an unclaimed variant
    -- can never grow into a real, unintended editor submit.
    describe('editor Alt+Enter, an unclaimed variant',
      function()
      it('submits to nobody and leaves the text alone',
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

    -- ---- 5. Shift+Enter is a newline everywhere ------------

    -- Shift+Enter is carved out of submit in every surface: it
    -- inserts a line-feed and never submits, including inside
    -- the editor's input, where the surrounding Enter variants
    -- are claimed by the editor.
    describe('editor Shift+Enter on non-empty input', function()
      it('inserts a line-feed instead of submitting', function()
        local doc = { '', 'body', '' }
        local ed  = open_doc(doc)

        ed.input:add_text('abc')
        mock.keystroke('S-return', driver(ed))

        assert.same({ 'abc', '' }, ed.input:get_text():items())
      end)
    end)

    -- ---- 6. the same two keys in the other two surfaces ----

    -- The uniformity claim in its plainest form: after the
    -- editor rows above, the console and the project overlay
    -- are driven through the same Enter and Escape. Their
    -- subject-matter contracts (the full submit call-order
    -- chain, the cancel chain, validators) belong to
    -- input_widgets_callbacks_spec.lua; what is asserted here
    -- is only that each surface runs the one lifecycle at all.
    describe('console: the same Enter and Escape', function()
      it('Enter evaluates the line exactly once, text intact',
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

    describe('project overlay: the same Enter and Escape',
      function()
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

    -- Line-duplication is the one behaviour that genuinely
    -- differs between surfaces, and it is carried by a
    -- constructor flag on the instance that wants it —
    -- `allow_duplicate_line`, alongside `disable_selection` — not by
    -- the screen mode. Each case still sets app_state, to the
    -- value the real caller would have, precisely to show the
    -- flag and not the mode is what decides
    -- (doc/development/decisions/input.md, Decision 6).
    describe('the modify flag alone gates Ctrl+D', function()
      it('with the flag: Ctrl+D duplicates the line', function()
        local c = bare_uic()
        c.allow_duplicate_line = true
        love.state.app_state = 'editor'
        c:show({ text = 'abc' })

        mock.keystroke('C-d', driver(c))

        assert.same({ 'abc', 'abc' }, c:get_text():items())
      end)

      it('without it: Ctrl+D does nothing', function()
        local c = bare_uic()
        c.allow_duplicate_line = false
        love.state.app_state = 'ready'
        c:show({ text = 'abc' })

        mock.keystroke('C-d', driver(c))

        assert.same({ 'abc' }, c:get_text():items())
      end)
    end)

    -- ---- 8. how wide "Enter" is -----------------------------

    -- Submit triggers on any Enter that is not Shift+Enter, so
    -- Ctrl+Enter and Alt+Enter submit as well; only the newline
    -- is carved out (doc/development/decisions/input.md,
    -- Decision 6 and Decision 14; mechanism in
    -- doc/development/internals/user_input.md). It is
    -- longstanding behaviour the input API kept, pinned here so
    -- the breadth is not narrowed to bare Enter by accident —
    -- narrowing it is a deliberate spec change, not a tidy-up.
    describe('every non-Shift Enter submits', function()
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
