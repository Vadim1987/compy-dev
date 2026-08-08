# S29 — the held-state design agenda, handed to a fresh session

Five questions raised by the owner on 2026-08-08, after Decision 29 landed and
while P9d/P9e were being scheduled. They are recorded verbatim in substance
because they are the owner's framing, and they are **not** answered here: the
owner judged them a design session's worth of work and called for a cold start
rather than continuing in a long, heterogeneous context.

They are coherent as one agenda — every one of them is about the same object,
the held-key set, and answering any of them in isolation risks a mechanism that
the next answer contradicts. **Answer them together.**

---

## Q1 — the stale set needs a recovery path, not just a fix

*"We need recovery path when set goes stale — it's not written and without
recovery set is not reliable."*

P9d (clear the set on focus loss) closes the **known** way it goes stale. It is not a
recovery path: it names one cause. Anything else that loses a `keyreleased` —
a route change mid-press, a raise that abandons dispatch, an OS quirk, a mode
switch — leaves the set wrong with nothing to notice or correct it.

Framing worth keeping: a set maintained by paired events is only as reliable as
the pairing, so either the pairing is guaranteed structurally, or something
reconciles the set against reality periodically. Decision 29 asserts the set is
the framework's truth for event-time questions; that assertion is only as strong
as its recovery story, and today there is none.

## Q2 — [ANSWERED IN SESSION] contradictions between Decisions 26 and 29

There were none to resolve, and the answer is short enough to close here.

**26 governs the payload; 29 governs where the framework looks.** Decision 26
says no argument is added, removed or reordered on the way through the chain, and
already states that the held set is *not* among the arguments — a consumer reads
`compy.input.keys_pressed` instead. Decision 29 says the framework itself answers
event-time questions from that same set rather than from a device poll. Those are
different questions: what a handler is *handed*, versus what the framework must
*track*. 29 makes the second explicit; it does not touch the first.

The one place they *would* collide is **Q3 below** — passing the set as a
trailing argument is exactly the "no argument is added" that 26 forbids. So Q3 is
not only a design question, it is an amend-or-supersede question against a
ratified decision.

Also cleared while writing 29, and worth not re-finding: `doc/input_api.md` still
claimed the table "arrives as the second argument of every shortcut, hook and
widget call". That was a contradiction — but with **26**, not 29, and it predated
this session. Fixed.

## Q3 — should the held set come back as a trailing argument?

*"Should we return passing keys pressed as an extra argument to all consumers
(strictly after LÖVE's args to keep signatures compatible), or it makes no
sense?"*

The trailing position is the interesting part of the proposal: it is what makes
it compatible with Decision 26's "LÖVE's own list, unchanged and in LÖVE's
order", since nothing LÖVE sends moves. Whether "unchanged in order" also means
"nothing appended" is the question 26 has to be re-read for — and the owner is
the one to rule on what 26 meant.

Weigh against: W1 removed this argument for stated reasons, and re-adding it in a
different position is either those reasons overturned or a different argument
with the same name.

## Q4 — expose a serialised form instead of a table?

*"`pairs` issue makes the table unindexable — then maybe we should just expose
serialized form instead (all-keys-pressed-as-a-string) which would be only
writable from within gateway but not from consumers and rebuildable on
keypressed/keyreleased?"*

Note the premise needs one correction: the table is **indexable** —
`keys_pressed['lctrl']` works. It is **un-iterable** on the shipping runtime,
because the read-only proxy carries `__pairs` and LuaJIT/Lua 5.1 ignores it. So
the gap is "read the whole set", not "read a key".

A serialised form is attractive for a different reason than the one that prompted
it: it is the same shape as a combo string, so the vocabulary would be one. It
also raises: rebuilt when, compared how, and does a project parse it or match it?

## Q5 — how are repeated press/release of the same key tracked?

*"How do we track multiple keypressed/keyreleased over the same key? Should we
count both directions or just rely on events derived in real order? What if they
come with isrepeat flag?"*

Today the set is a **boolean** per key: `keys_pressed[k] = true` on press, `nil`
on release, no counting, and `isrepeat` is not consulted at that point. A repeat
therefore re-asserts a key already held, and a release clears it regardless of
how many presses preceded it.

This is the question underneath Q1: whether a counter (or an ordered log) would
make the set self-correcting, or merely make a stuck entry harder to clear.

---

## Why these belong together

Q1 asks how the set recovers. Q5 asks what the set records. Q4 asks what shape it
is exposed in. Q3 asks how it reaches a consumer. A recovery path chosen before
deciding whether entries are booleans or counts, or a serialisation chosen before
knowing whether it is rebuilt or reconciled, is a mechanism that the next answer
invalidates. Decision 29 is the frame they sit in and may itself need amending on
its "the framework's truth" claim, which Q1 shows is currently unsupported.
