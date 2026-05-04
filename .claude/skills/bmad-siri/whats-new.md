# NW — What's New

Recent updates to a framework or technology, filtered by project context when available. Apply Pattern C: direct resolution (sidecar → apple-docs).

## Value over plain web search

Apple's release notes span thousands of changes per year — most irrelevant to any given project. NW adds: (a) sidecar-cached framework context from `wwdc-references.md` and `project-patterns.md` (so updates are framed against what this project already uses), (b) xcode MCP filtering to actively-used frameworks only, (c) WWDC session cross-referencing for context on each change, (d) write-back so framework changes that affect established patterns get flagged.

## Process

1. **Check `wwdc-references.md` and `project-patterns.md`** for framework context — what this project uses, what sessions have already been cited.

2. **Query `mcp__apple-docs__get_documentation_updates`** filtered by the technology / framework in question.

3. **If xcode MCP available**, filter updates to frameworks actively used in the project. Skip irrelevant ones.

4. **Highlight new APIs, deprecations, and behavioral changes**. Distinguish breaking changes from additive ones.

5. **Reference relevant WWDC sessions** for context on each major change. If a session explains the rationale, cite it.

6. **Write back new sessions** to `wwdc-references.md`.

7. **Write back to `project-patterns.md`** if changes affect established patterns (e.g. a deprecation invalidates a recorded convention).

8. **Append session note** to `memories.md` Recent Sessions log.

## Sidecar write criteria

Writes to `wwdc-references.md` for newly cited sessions. Writes to `project-patterns.md` only when an update directly affects an established pattern. Appends to `memories.md` always.

## Failure modes to defend against

- **Generic update dump** — if not filtered by project context, NW becomes Apple's release notes with extra steps. The filtering is the value.
- **Breaking-change blindness** — additive changes are nice-to-know; breaking changes need to lead. Lead with breaks, then deprecations, then additions.
