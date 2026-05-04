# AL — Find Alternatives

Find modern replacements for a deprecated Apple API with migration guidance. Apply Pattern B: targeted resolution (sidecar → axiom → apple-docs).

## Value over plain web search

Migration guides on the open web go stale fast — Apple's deprecation notes, related-API maps, and inheritance/protocol options are authoritative. AL adds: (a) sidecar-cached prior verdicts (if the deprecated API was already analyzed, the verdict is on file), (b) axiom-cached migration patterns when available, (c) related-API discovery via `find_similar_apis` and `get_related_apis`, (d) supersedes-tracking write-back so the institutional memory captures the deprecation chain.

## Process

1. **Check `api-decisions.md`** for an existing verdict on the deprecated API. If present, surface the prior verdict and any recorded alternatives.

2. **Query axiom skills** for known migration patterns (graceful skip if unavailable).

3. **Query `mcp__apple-docs__find_similar_apis`** to discover alternatives for the deprecated API.

4. **Query `mcp__apple-docs__get_related_apis`** for inheritance and protocol options that may serve the same use case.

5. **Explain why the old API was deprecated** and the benefits of the modern replacement (performance, safety, framework alignment, deprecation timeline).

6. **Provide migration guidance** with code examples if available — call out signature changes, semantic differences, and any new error-handling requirements.

7. **Write back to `api-decisions.md`**:
   - Mark the deprecated API as `REJECTED` (with `Reason: deprecated as of <version>`, `Source URL`)
   - Mark the replacement as `APPROVED` with the `Supersedes` field pointing to the deprecated entry

8. **Append session note** to `memories.md` Recent Sessions log.

## Sidecar write criteria

Writes both REJECTED (deprecated) and APPROVED (replacement) entries to `api-decisions.md` with the supersedes link. This is the canonical deprecation-chain record. Appends to `memories.md` always.

## Failure modes to defend against

- **Synthesized migration code** — if apple-docs has migration sample, use it. Don't fabricate a migration that hasn't been validated.
- **Missing supersedes link** — without `Supersedes`, future ME recall can't trace the deprecation chain. Always link.
- **Recommending a still-deprecated alternative** — verify the proposed replacement isn't itself deprecated (cross-check via `get_platform_compatibility`).
