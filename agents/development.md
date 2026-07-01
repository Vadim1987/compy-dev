KISS(Keep It Simple) is an authoritative rule
Do not fix/overoptimize things beyond current request and its blockers -- discovered non-blocking tech debt must be reported, not fixed on the spot
add inline comments explaining any unobvious non-trivial decisions (in the new code)
give meaningful names to functions, it reduces needs to comments
start with breaking tests, then fix by implementation
every test must exercise a real production code path and assert on its observable behaviour/output -- never write "empty" tests that stub/mock the unit under test and then only assert the mock was called (they pass without touching the real code); mock only genuine boundaries (I/O, love2d, external systems)
document significat changes (under doc/development), avoid leaking milestone ref-ids into docs (they are tactical)
git commit but do not push (author name - from recent commit, unless instructed explicitly)
