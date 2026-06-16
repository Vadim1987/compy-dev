## What is not in scope

- touch is in scope as far as it's part of mouse handlers.
  neither the user nor we have to anything to have this working,
  just making a note because it's misleading to phrase it this
  way

## Decisions (BEFORE)

1. Backwards compat: as discussed, we are pre-1.0, no such
   guarantees are offered, nor are they desirable.
2. I suggest we block this (i.e. the new one won't do anything),
   and offer a flag for "I know what I'm doing, override the
   existing one".
3. The base approach is passing through what LOVE does. Further
   helpers should be added, but not as part of this effort.
4. At first glance, definitely. This will probably be refined in
   the course of implementation. I'm not sure what's meant here
   by "the framework's own teardown"
5. There's prior art for this as part of editor navigation, it
   is also fairly intuitive (at least to me, do tell if it's
   just me as the implementor).
   - when moving up/down, being in the first/last line
   - when moving left/right, being on the first/last character
     for the whole input or the line
6. I though this was part of 3. Same approach.
7. This is just for user code, running in projects (soon there
   won't be another way for running user code).

* it should not be named `ProjectController`, that sounds like
  something that handles project creation/deletion, loosely what
  `ProjectService` does currently. If it's an input controller,
  call it `ProjectInputController`.
* proposed lifecycle - very sensible

# Spec

## `keys_pressed` table

"iterate with `for k in pairs(proxy) do`; direct indexing not
supported" - why? it's straightforward to create a proxy table
that allows read indexing but not write indexing.

## `compy.input.show(config)`

"Calling `show()` while already active reconfigures in-place" -
again, I'd gate this with a "force" flag


# Decisions (AFTER)

3. Ok, it makes sense with this implementation to improve upon
   it.
