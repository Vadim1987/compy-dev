-- live reconfigure and the continuous-session idiom — split from
-- input_contracts_spec.lua (TF1). Routing invariant (doc/development/decisions/input.md,
-- Decision 1): inter-route dispatch is EXCLUSIVE — each event reaches
-- exactly ONE route, fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"): ROUTE = consumer an event
-- is dispatched to; WIDGET = a route-managed input surface; SINK = last
-- consumer. Tests assert observable outcomes at public seams, never
-- method-name spies. keypressed fires for every physical key, textinput
-- only for character-producing keys (doc/development/internals/user_input.md, "Data
-- flow").
-- configure()/clear() live-reconfigure semantics and the re-show-from-
-- after_submit continuous-session recipe (doc/development/internals/user_input.md,
-- "configure(config)", "clear()"; doc/input_api.md, "The continuous-session
-- idiom").

local F = require('tests.helpers.input_fixture')

describe('input contracts: live reconfigure #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ====================================================
  -- Live reconfigure + clear (configure/clear, closing
  -- the {badspecref: M7-01} re-target boundary (design/
  -- spec/M7-01-retarget.md: can an active session's
  -- result sink / evaluator be re-targeted?) — the
  -- {badspecref: M7-02-recut} spec's (design/spec/
  -- M7-02-recut.md, extended widget-surface API)
  -- Contract). The former 'later forward contracts' anchor
  -- ('configure/set_text/cursor, force-vs-configure') is
  -- now fully authored: set_text/cursor above, configure/
  -- clear here; force-vs-configure is documented in
  -- doc/development/internals/user_input.md.
  -- ====================================================

  describe('live reconfigure and clear #m7', function()

    -- doc/development/internals/user_input.md, "configure(config)": prompt
    -- updates live on an active session;
    -- content/cursor/callbacks stay untouched.
    it('configure updates the prompt on an active session',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.show({ text = 'hi', on_text_entered = cb })
        input.configure({ prompt = 'new' })
        assert.equal('new', F.singleton.model:get_label())
        assert.same({ 'hi' }, F.singleton:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(3, c)
        assert.equal(cb, input.on_text_entered)
      end)

    -- doc/development/internals/user_input.md, "configure(config)":
    -- validator — the NEXT submit uses the new fn,
    -- not the one set at show() (exercised, not just read).
    it('configure swaps the live validator', function()
      local input = F.activate_project()
      input.show({
        text      = 'ab',
        validator = function() return false, 'old' end,
      })
      local seen
      input.configure({
        validator = function(t)
          seen = t
          return true
        end,
      })
      F.session.press('return')
      assert.equal('ab', seen)
      assert.is_nil(love.state.user_input)
    end)

    -- doc/development/internals/user_input.md, "configure(config)":
    -- highlighter — the NEXT keystroke's highlight
    -- uses the new fn.
    it('configure swaps the live highlighter', function()
      local input = F.activate_project()
      local marker = { { 'x' } }
      input.show({
        highlighter = function() return { { 'old' } } end,
      })
      input.configure({
        highlighter = function() return marker end,
      })
      F.session.type('a')
      local got = F.singleton.model:get_highlight()
      assert.equal(marker, got.hl)
    end)

    -- doc/development/internals/user_input.md, "configure(config)":
    -- on_text_entered — the swapped fn fires on the
    -- next submit; the old one set at show() does not.
    it('configure swaps the live on_text_entered', function()
      local old_called, new_text = false, nil
      local input = F.activate_project()
      input.show({
        text            = 'ab',
        on_text_entered = function() old_called = true end,
      })
      input.configure({
        on_text_entered = function(t) new_text = t end,
      })
      F.session.press('return')
      assert.is_false(old_called)
      assert.equal('ab', new_text)
    end)

    -- doc/development/internals/user_input.md, "configure(config)":
    -- on_limit_reached — the swapped fn fires on the
    -- next boundary; the old one set at show() does not.
    it('configure swaps the live on_limit_reached', function()
      local old_called, new_dir = false, nil
      local input = F.activate_project()
      input.show({
        text             = 'ab',
        on_limit_reached = function() old_called = true end,
      })
      input.configure({
        on_limit_reached = function(dir) new_dir = dir end,
      })
      F.singleton:jump_home()
      F.session.press('left')
      assert.is_false(old_called)
      assert.equal('left', new_dir)
    end)

    -- doc/development/internals/user_input.md, "configure(config)":
    -- text/cursor are inert on an active session
    -- — even mixed with a live field, the live one applies
    -- and the inert ones are untouched (no partial/silent
    -- application: each field's own rule holds exactly).
    it('configure leaves text/cursor untouched on an ' ..
      'active session, even mixed with a live field',
      function()
        local input = F.compy_input()
        input.show({ text = 'hi' })
        input.set_cursor(1, 2)
        input.configure({
          prompt = 'live',
          text   = 'ignored',
          cursor = { 1, 99 },
        })
        assert.same({ 'hi' }, F.singleton:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(2, c)
        assert.equal('live', F.singleton.model:get_label())
      end)

    -- doc/development/internals/user_input.md, "configure(config)":
    -- configure while hidden is safe
    -- (no warn —
    -- it is not a refusal) and text/cursor apply on the
    -- very next show().
    it('hidden configure applies text and cursor on the ' ..
      'next show', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.configure({ text = 'draft', cursor = { 1, 2 } })
      Log.warn = ow
      assert.equal(0, warned)
      input.show({})
      assert.same({ 'draft' }, F.singleton:get_text())
      local l, c = input.get_cursor()
      assert.same(1, l)
      assert.same(2, c)
    end)

    -- doc/development/internals/user_input.md, "configure(config)": a
    -- hidden configure of a live field
    -- (prompt,
    -- validator) applies cleanly on the next show() too.
    it('hidden configure applies prompt and validator on ' ..
      'the next show', function()
      local input = F.compy_input()
      input.configure({
        prompt    = 'draft-label',
        validator = function() return true end,
      })
      input.show({})
      assert.equal(
        'draft-label', F.singleton.model:get_label())
      assert.is_function(input.validator)
    end)

    -- Pending fields are one-shot: a LATER bare show() must
    -- not keep re-injecting a stale hidden-configured draft
    -- (distinguishes this from the output-callback {jargon:
    -- slots},
    -- which stay sticky forever by design).
    it('hidden-configured text does not leak into a later ' ..
      'show', function()
      local input = F.compy_input()
      input.configure({ text = 'draft' })
      input.show({})
      input.hide()
      input.show({})
      assert.is_true(F.singleton:is_empty())
    end)

    -- doc/development/internals/user_input.md, "clear()": on an active
    -- session empties content,
    -- cursor to start, no callback fires.
    it('clear empties an active session with no callback',
      function()
        local input = F.compy_input()
        local called = false
        input.show({
          text            = 'hi',
          on_text_entered = function() called = true end,
        })
        input.clear()
        assert.is_true(F.singleton:is_empty())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(1, c)
        assert.is_false(called)
      end)

    -- doc/development/internals/user_input.md, "clear()": while hidden is
    -- a no-op + warn —
    -- unlike configure(), this call IS refused.
    it('clear while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.clear()
      Log.warn = ow
      assert.equal(1, warned)
    end)

    -- doc/development/decisions/input.md, Decision 7: the mutable boundary
    -- is unchanged for the two
    -- new callables.
    it('assigning configure/clear raises', function()
      local input = F.compy_input()
      assert.has_error(function()
        input.configure = function() end
      end)
      assert.has_error(function()
        input.clear = function() end
      end)
    end)
  end)

  -- ====================================================
  -- doc/input_api.md, "The continuous-session idiom"
  -- (migration recipe):
  -- on_text_entered consumes; after_submit re-shows.
  -- Pins the pattern every example
  -- migration relies
  -- on, before any example is touched.
  --
  -- SURFACED ({jargon: surprise-first}, see {badspecref: M8-01}
  -- ledger, implementation/outcomes/M8-01.md, surprise #1):
  -- before_submit/after_submit/before_cancel/after_cancel
  -- are NOT among show()'s merged cfg keys (only
  -- on_text_entered/on_limit_reached/validator/highlighter
  -- are, per OUTPUT_KEYS in consoleController.lua) — passing
  -- after_submit inside show{...} is silently dropped (no
  -- error, no warn). The wired path is a direct field
  -- write (`input.after_submit = fn`), exactly the pattern
  -- the existing doc/development/decisions/input.md, Decision 6
  -- submit-chain test above
  -- already
  -- uses. The commission's illustrative show{after_submit=…}
  -- sugar does not literally work; this test uses the
  -- field-write form that does.
  -- ====================================================

  describe('continuous-session idiom #m8', function()

    -- The recipe: consume in on_text_entered, re-show
    -- (bare, no config) in after_submit. Asserts (a) the
    -- assembled text reaches on_text_entered and (b) the
    -- widget is active again once after_submit returns.
    it('re-shows from after_submit with the same callbacks',
      function()
        local input = F.activate_project()
        local seen = { }
        input.after_submit = function() input.show({}) end
        input.show({
          prompt = 'first',
          on_text_entered = function(t)
            seen[#seen + 1] = t
          end,
        })
        F.session.type('a')
        F.session.press('return')
        assert.same({ 'a' }, seen)
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.singleton:is_shown())
      end)

    -- The re-show re-arms with the STICKY callback — a
    -- second submit is observed without re-passing
    -- on_text_entered, proving the loop can repeat (the
    -- shape every migrated example's re-prompt depends on).
    it('the re-armed session observes a second submit',
      function()
        local input = F.activate_project()
        local seen = { }
        input.after_submit = function() input.show({}) end
        input.show({
          on_text_entered = function(t)
            seen[#seen + 1] = t
          end,
        })
        F.session.type('a')
        F.session.press('return')
        F.session.type('b')
        F.session.press('return')
        assert.same({ 'a', 'b' }, seen)
      end)

    -- Balloons shape (doc/input_api.md, "Live reconfigure",
    -- "A continuous session with a changing prompt"): a
    -- hint set via configure()
    -- INSIDE on_text_entered (session still active,
    -- doc/development/internals/user_input.md, "Submit and cancel — the
    -- framework tier-1 chains")
    -- must survive the after_submit bare re-show, not the
    -- show()-time prompt. Model-sticky per {badspecref: M8-01}
    -- surprise #2 (implementation/outcomes/M8-01.md)
    -- + doc/input_api.md, "The continuous-session idiom"'s
    -- apply_config: custom_label is
    -- only overwritten
    -- when cfg.prompt is given, so a bare show({}) never
    -- resets what configure() just set.
    it('a prompt configured inside on_text_entered ' ..
      'survives the after_submit re-show', function()
      local input = F.activate_project()
      input.after_submit = function() input.show({}) end
      input.show({
        prompt = 'first',
        on_text_entered = function()
          input.configure({ prompt = 'live' })
        end,
      })
      F.session.type('a')
      F.session.press('return')
      assert.equal('live', F.singleton.model:get_label())
      assert.is_not_nil(love.state.user_input)
    end)
  end)
end)
