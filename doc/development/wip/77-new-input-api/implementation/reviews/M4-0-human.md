name of test `characterization_spec` is weird -- it's not self-explanatory for someone just navigating the tests
I do not like mock textinput only propagating text, why not propagate any '...args'? (we're going to propagate args anyway soon)

# tests/mock.lua

function keystroke content is hard to follow --  this mods/keys setup -- was it before our changes or is a consequence of M1 implementation? why imitate M1 functionality instead of using it? if it was there before, should we consider exactly this "modifiers held" table as a more healthy alternative to current "all keys held" approach and use it as a library method?

# tests/input/characterization_spec.lua 

* All mentions of milestones should be prohibited in tests -- tests are self-contaiing part of the product/codebase; M0/M4 etc. are just current implementation terminology, its ephemeral
* Are we also testing that REPL and editor are working as they were before? I.e. can we ensure that keypressed/textinput reach their respective REPL/editor controllers as intended when project is *not* run? (i.e. when overlay/gateway is not set up and said respective controllers are expected to receive the input

See also: inline comments marked "REVIEW"


