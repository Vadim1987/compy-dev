Comments should be terse, useful, readable, meaningful, compact, dry

1. Comments should: 
  1.1 have minimal viable size (but not below readability). Comment of similar size or bigger than the code it comments is a symptom of either bad code/architecture (which for some reason cannot express itself) or bad readability
2. Comment should not: 
  2.1 tell what code is *not* doing unless the genuine confusion is possible which cannot be mitigated by other means
  2.2 contain literaturized proze that bloats the size of comment without adding new info
3. Comment is useful when: 
  5.1 it explains intent or constraint, which is not obvious from the code and not expressible by function/variables naming
  5.2 it references a concept or context which is expressed elsewhere (e.g. in a very different file or module)
  5.3 it marks deprecated/new functionality (e.g. "supported since <version>", "deprecated since <version>"
4. During active development (when code is moved, reorganized, prototyped, deleted), extensive interim comments are allowed to ensure logical integrity of the codebase (such as comments mentioning requirements and decisions ids, telling "code from here was removed because" etc). But such interim comments should be marked and removed completely before release (when code stabilizes).


META-RULE: comment should not exist if it does not bear any valuable information
