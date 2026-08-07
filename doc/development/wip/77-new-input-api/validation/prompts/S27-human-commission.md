# Technical adjustments
1. Adjust rules for PR assembly guide:  patches of group 3 should have prefixes reflexing the ordering (i.e. if docs come first than they star with 3a, tests with 3b etc.) -- purely mechanical reorganization
2. Adjust rules for PR assembly guide:  patches for externalized projects (maze, balloons, keyboards) should also be included as group 4 (4a-balloons, 4b-maze, 4c-keyboard)
3. Read my new rule under agents/rules/commenting.md -- update and modify it so it would be better understood by LLMs, and plug it into validation workflow


# FEEDBACK

Analyze my commits done since session prompt was created -- there are lots of inline remarks. Analyze both main repo and three adjacent examples repos (balloons, maze, keyboard) 

a) Inventorize remarks and triage. 
b) create a plan for addressing them all 
c) follow the plan
d) reassemble the PR slices
e) inventorize all *comments* in the codebase within the PR slices scope. Run subagent which would heavily process them and compress/distill/edit/dissolve according to commenting rules. Current prose is *too* verbose
f) reassemble the PR slices
8) run revalidator about PR slices (group 3 and 4 only) -- store its review. address(autofix) any serious concerns if they arise
9) reassemble the PR slices, rerun cold revalidator (as in p8) -- this time do not autofix, but present findings to human
