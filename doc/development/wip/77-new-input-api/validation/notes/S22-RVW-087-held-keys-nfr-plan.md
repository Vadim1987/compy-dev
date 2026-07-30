# S22 RVW-087 -- held-key allocation guard

## Ruling

Owner-ratified 2026-07-30: the pressed-keys view has no public identity
contract. Its observable contract is read-through current contents and
write rejection. The current cached view is retained as a non-functional
allocation and garbage-collection guard.

## Deferred execution

Add one explicitly labelled mechanism/NFR test showing that repeated
held-key view retrieval with the same backing table returns the cached view.
The test protects no-per-event-proxy allocation; it must not claim that a
project callback may rely on identity. Remove the stale owed/planned-change
comment in the NFR test, retaining the already-landed delivery/content tests.
