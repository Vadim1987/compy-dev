# Feature #77 — Stakeholder Input

Verbatim. Source: original ticket and stakeholder clarification.

---

## Original ticket

A better REPL model, more consistent with the rest of the
controls, with callbacks. I.e. setting up an edit area with
an optional non-empty content, syntax highlighter and input
validator and receiving callbacks on the user entering
something on it.

## Owner clarification

1. It is certainly not an exhaustive feature list. Basically,
   what I would like to see is an API that allows for an easy
   implementation of interfaces that are similar to either the
   command console or the editor. Ideally, these should also be
   re-implemented using the same API. What I'd like to see in
   addition to features mentioned in the ticket are callbacks
   for keys pressed together with the Ctrl key or keys that do
   not insert or remove a symbol in the edit area.
   Unfortunately, function keys (the ones in the top row of the
   keyboard) only work with external keyboard, the internal ones
   are hijacked by the OS. Another thing, I'd like to see a
   callback for is cursor movements that "hit a wall", trying
   to move the cursor past the beginning or the end of the edit
   area and, of course, entering a line. Calls should be
   provided for setting up an edit area (with an optional
   initial text, cursor position, highlighter and verifier) and
   for removing the edit area, for querying and changing the
   cursor's position, and changing the text.

   (I might have forgotten something, but see the principles
   spelled out in the beginning)

2. Games and other examples already in development or even
   ready (like tixy), REPL dialogs, text-based adventure games,
   etc. The biggest problem with the current API is that it is
   inconsistent with the rest of love, handling keyboard events
   in parallel to editing is a PITA and it is not easy to hide
   or show the input area (see your struggles in sapper).
