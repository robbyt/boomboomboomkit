# SA — Sample Code

Find Apple sample code for an implementation pattern. Apply Pattern A: full resolution chain (sidecar → axiom → xcode → apple-docs).

## Value over plain web search

Random Stack Overflow snippets aren't authoritative — Apple's sample projects are. SA adds: (a) sidecar-cached project-pattern memory (if this pattern was already established for the current project, surface that first), (b) project-context-aware sample selection (xcode MCP narrows to active frameworks), (c) framework-symbol-level lookups via apple-docs.

## Process

1. **Check `project-patterns.md`** for established patterns for this use case in the current project. If a pattern is recorded, lead with that and mark as the established convention.

2. **Query axiom skills** for known Swift implementation patterns (graceful skip if unavailable).

3. **Query xcode MCP** for active frameworks in the project so sample selection can be narrowed (graceful skip if unavailable).

4. **Query `mcp__apple-docs__get_sample_code`** to find relevant Apple sample projects.

5. **Query `mcp__apple-docs__search_framework_symbols`** for specific APIs referenced in the user's request.

6. **Reference the sample project name** and the relevant code sections. Cite filenames and section anchors when available.

7. **Write back to `project-patterns.md`** if a new pattern is established for this project (high bar — only when the pattern is genuinely repeatable across the project, not just a one-off).

8. **Append session note** to `memories.md` Recent Sessions log.

## Sidecar write criteria

Writes to `project-patterns.md` only when establishing a new repeatable project-level pattern. Most SA invocations should NOT trigger a project-patterns write — they're sample lookups, not pattern decisions. Appends to `memories.md` always.

## Failure modes to defend against

- **Generic example over Apple sample** — if Apple has a sample project for this, that's the answer. Don't substitute a synthesized example unless apple-docs returns nothing.
- **Project-pattern spam** — writing every sample lookup to `project-patterns.md` defeats the purpose. Bar: established + repeatable + project-relevant.
