Documentation:
1. I separated docs patch myself into 'rubber-stamping' part (which only altered existing docs with "LLM generated" line) and meaningful changes. Would be nice to do it always
2. in fact the commit which enrolled rubber-stamping was `6c766`. I would just reproduce it in PR slice as 1a and would build any other doc changes from it

Other patch composition notes:
it would be great to carve protection of highlight regression (alongside with its test) into a separate commit

Potential bugs:

Examples: (WARNINNG: detached repos (maze, ballloons) were not synchronized properly so their regressions are unconfirmed, kept there only for future recheck; regressions of in-repo examples are real)

1. I run "guess". It does not tell me what to do, it does not show what I entered (only responses like 'the number is higher') and it freezes after 5 inputs (maybe after occasionally entering symbol?). Not sure how to restart or exit. However, with muscle memory I was able to exit into console with Ctrl+Q (UX remark: nothing signalled me I am out of console now)
2. Project REPL -- I can run it but am not sure what to run there besides. by trial-and-error I was able to type "x=2+3" and then "print(x)"2. Still obvious UX problems -- I am not told what is expected (that's where prompt would help) and not told what I typed. If its previous behaviour, we can keep it. If its regression we should fix it. If UX can be improved with light touch of new API -- we can plan it (also as a demo case).
3. tixy is BROKEN -- if I open it AFTER exiting from another project (Ctrl+Q -> 'project("tixy") -> run()) I do not see the overlay, so cannot type anything; switching examples by click works though (still no input widgets, but examples are rotating). If I exit framework, boot it and start from scratch and run tixy as a first project - I see the input widget and can modify it. But whenever I hit enter, the text on the upper right side of the screen disappears (the one which explains what example is for)
4. sapper works -- it does not rely on input at all. however, it would be nice to see if we can now suppress the *unused* input widget in pen-and-paper mode (likely we cannot?)
5. balloons are BROKEN, they do not start. first start says "L432: compy.input -- 'after_submit' is not assignable". It also does not show me standard 'snapshot with stacktrace' window which I would expect -- instead it shows me console without any signal that I am not in native console mode but still inside the project (which means I can run 'project' again and it will even be 'opened' or 'created' until I hit Ctrl+Q)
6. maze -- kind of works (first levels) but I think it was showing input before -- now it does not. console has lots of warnings about 'show' being ignored -- likely generated on every tick? after few levels game simply stops working.  (in first levels reaction to my keypresses is immedate. than it stops. I think it may correspond to game logic (hypothesis!) which probably starts with 'real-time' driving and then increases complexity to 'delayed' driving, expecting full line of governing symbols to be entered (which does not happen because widget is hidden). Moreover eeven 'movement symbols' alongside F,L,R in the legend are displayed as 'squares' (font problem?)
6.1 when run fresh (first project after boot) maze passes first 1-2 levels as expected (real-time reaction on keypressed). when 'sequenced level' starts the input SHOWS (console immediately starts firing warnings about repeated ignored 'show()' -- likely triggered on tick. and the level works as intended, except input is NOT cleared. beyond that everything works perfect. Font problem also does not appear
7. Keyboard -- all works, but I expect its exactly because it relies on keypressed only (and is there a chance it still bypasses our routes and compy input, simply working with love handlers directly?). I was not able to make fourth game though -- maybe because I do not understand the rules of what 'making alt characters' is.
8. Turtle -- if launched after other project (exited by Ctrl+Q), the input widget does not show on 'i'. If launched on fresh boot, input widget shows, but input is not cleared on enter (I have to backspace and type something else),  and occasionally entering 'i' (i.e. "forwardi") triggers warning in the console about 'show' already being active.
9. Validator -- runs inconsistently (first project opened after boot). I do not see what I am typing. Valid lines are printed. Entering invalid line ('1') completely stops processing any input. No visible error reporting.  I am not sure how it worked before. The input field has black bar, not the blue one seen in some other projects (likely meaning its native console input?)


Tests:

ALL tests must actualize their prose for the cold-reader (no "this feature", "feature-new", "#77", "pre-baseline" -- we have clean boundaries -- supposed version name (1.0.0-rc-something), and generic feature name ('compy input API')

editor_spec_fwd.lua was an intermittent copy, never intended to be commited. must be removed from everywhere, its a leftover from totally different past work

everywhere: 'this feature' -> 'input API introduced in <version>'

cursor_spec.lua, history_spec.lua: 
  a) just remove 'this feature' comment, test stays intact

highlight_regression_spec.lua:
  a) '1a2a9a3' -- avoid mentioning specific commits they do not survive rebasing or squashing
  b) 'highlight is memoized' is wrong assertion message (it does not check memoization just non-nillness, can go without message at all

input_cursor_spec.lua:
  a) 'feature-new' is not persistent comment, rewrite so it reads normally 10 features later
  b) name what "Decision 7" is (annotate in 2-3 words)
  c) looks like opening comment is a bit duplicated
  d) doing some fixes myself


input_events_spec.lua: overall *very* good -- I've made minor tweaks and mentioned one possibly missing negative test (analyse: maybe it really should be 2 or 3 extra tests or assertions with the same logic)

input_lifecycle_unfork -- did not review, awaiting for reframing
input_nfr_spec -- reframe proce for cold reader (no 'planned' or 'forward' or 'non-final' or 'pre-baseline' or 'feature #77' -- just a part of engine past-pr (boundary at specific rc version, generic name "compy input API")). pending test is no more pending. at the end here are leftover comments which have no test attached -- clean them up

input_reconfigure_spec -- remove '#m7','#m8'

shortcuts_click_spec -- reframe the last test -- 'legacy solicitation is REMOVED'

input_widget_lifecycle_spec -- console receiving input while widget is hidden was one of the biggest controversies. its worth being marked as 'distputable' at least -- and if we have concern described anywhere in persistent docs corpus, worth referencing from the test case

input_widget_callbacks_spec -- 'revised', 'no-longer' smell development-time jargon (let alone covering decision flipped in-development) -- rerframe for cold-reader and persistent documentation . Comment why love.state.user_input is checked directly (precursor of showing/not showing widget on framework render) -- consider factoring this check into fixture's "is_widget_visible" -- honest behavioural check not relying on self-report and aligned with prod behavior closely enough. 'a custom validator' case is preceded by prose that references submit/cancel -- some clarification needed. "Decision 6 revised" -- smells devtime-context leak -- on long term we do not care it was revised (actually clarified) mid-development. Prose about "Shift+Return never intercepted" is misleading: a) they could be intercepted and its fine b) the test does not test incerception c) inside widget (*if* event reaches it) they do what is tested -- so the test *framing* should be updated, not test itself (but paired test of interceptability may be worth adding). "Decision 6 revised (AC1-,AC-3)" -- smeeeeeeelll, reframe and cleanupa










### On the patch itself

I still do not like ambiguity of forward_keypressed, or chain_native/wrap_native -- would appreciate simply better naming, more obvious for cold reader!
