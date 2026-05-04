# WD — Find WWDC

Find relevant WWDC sessions for a topic with transcript citations. Apply Pattern C: direct resolution (sidecar → apple-docs).

## Value over plain web search

Apple's developer site has a flat session catalog with weak topic linking. WD adds: (a) sidecar-cached prior session references in `wwdc-references.md` (sessions you've already cited stay top-of-mind), (b) transcript-level grep via `mcp__apple-docs__get_wwdc_video` (not just session metadata), (c) write-back so future sessions on the same topic surface the same citations.

## Process

1. **Check `wwdc-references.md`** for previously cited sessions on this topic. If present, surface them first with their stored relevance notes.

2. **Query `mcp__apple-docs__search_wwdc_content`** to find relevant sessions.

3. **Query `mcp__apple-docs__get_wwdc_video`** for transcripts and code examples on the most relevant matches.

4. **Cite with session year and number** (e.g. *"WWDC24-10151"*).

5. **Quote relevant transcript sections inline** when the quote earns its place — don't pad.

6. **Write back new sessions** to `wwdc-references.md` with `Title` and `Relevance` fields.

7. **Append session note** to `memories.md` Recent Sessions log.

## Sidecar write criteria

Writes to `wwdc-references.md` for every newly cited session. Appends to `memories.md` always.

## Failure modes to defend against

- **Recital without verification** — citing a session number from cached knowledge without confirming via apple-docs MCP. Always verify the session exists and the citation is accurate before quoting.
- **Pad with low-relevance sessions** — three on-target citations beat ten loosely-related ones.
