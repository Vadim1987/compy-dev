1. Update 'replace' -- store only leading clear code, load the rest into unsaveable buffer
2. Modify 'add' -- do the same, except add the stuff.
3. Look if ithas to be done as part of 'submit'a


Still, no issues with visibility -- we still tolerate monster blocks in reading, but only for specific conditions

which becomes: if we CAN saef stuff partially, should we proceed.Otherwise, oldbehaeiour.
