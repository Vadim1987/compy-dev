# Code Conventions

<!-- authored By LLM; human-approved NOT YET -->

> These conventions are not fully fixed — they evolve with experience. Some are unique to this project by design.
> Further discussion: https://github.com/compy-toys/compy/issues/54

---

## Formatting

Formatting is handled automatically by the metalua pretty-printer. No manual formatting rules are enforced — the built-in Compy editor auto-reformats on save. **Published examples must be idempotent under the editor** (run the editor over the code before publishing; it should produce no changes).

### Style examples

```lua
-- if/for/function: `end` on the same line as the last statement in the block
if condition then
  ...end

for iteration do
  ...end

function outer(args)
  local inner = function(args)
    ...  end
end

-- empty table: spaces inside braces
empty = { }

-- array/table: each element on its own line
array = {
  1,
  2,
  3
}

-- all comments on their own line (not inline)

-- at most one blank line between non-blank lines
```

---

## Structural Limits

| Rule | Limit |
|---|---|
| Line length | 64 characters (fits the Compy screen) |
| Function length | 14 lines |
| Parameters per function | 4 |
| Nesting depth | 4 levels |

---

## Code Style

**Extract compound conditions to named locals:**
```lua
-- avoid
if a and b or c then end

-- prefer
local cond = a and b or c
if cond then end
```

**Do not use local variables outside their block.** A local should be scoped as tightly as possible.

**File = console equivalence.** Code in a `.lua` file and the same code typed into the Compy console must have identical effect. This guides how modules and scripts are structured.

---

## Standard Abbreviations

```lua
local gfx = love.graphics
local sfx = compy.audio
```

## Comment References

Comments cite **canonical docs** (`doc/…`), never a feature's ephemeral working tree
(`doc/development/wip/…`). A wip path rots when the feature's scratch is deleted; cite the
persistent doc — and a **named section**, not "paragraph N" — so the reference stays
discoverable and greppable.

A named section is only useful while it exists. When you rename or remove a heading, grep
`src/` and `tests/` for comments citing the old name — a citation that no longer resolves is
worse than none, because it reads as authoritative. Renaming the input guide's headings once
left 31 citations pointing at sections that were gone, two of them naming a design model the
feature had already retired.
