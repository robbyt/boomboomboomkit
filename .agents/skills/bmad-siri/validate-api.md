# VA — Validate API

Validate an Apple API choice against live documentation with the full tool resolution chain. Apply Pattern A: sidecar → axiom → xcode → apple-docs.

## Value over plain web search / cached knowledge

A search engine returns blog posts of varying age. Cached LLM knowledge has a training-data cutoff. VA adds: (a) sidecar-cached prior verdicts with staleness gating (90-day threshold from `instructions.md`), (b) project-context-aware validation (deployment targets from xcode MCP), (c) authoritative apple-docs as the source of truth, (d) write-back of every verdict to `api-decisions.md` so the institutional memory compounds. An unverified API recommendation is worse than no recommendation.

## Process

1. **Check `api-decisions.md` for existing verdict.**
   - If found and `<90 days old`: present cached verdict and ask if the user wants re-validation.
   - If found and `>90 days old`: flag as **POTENTIALLY STALE**, auto-escalate to apple-docs (skip to step 4).

2. **Query axiom skills** for known Swift/Apple patterns related to this API (graceful skip if unavailable per `instructions.md` degradation protocol).

3. **Query xcode MCP** for project context — current deployment target, active frameworks (graceful skip if unavailable; ask user instead).

4. **Query `mcp__apple-docs__search_apple_docs`** to locate the API.

5. **Query `mcp__apple-docs__get_apple_doc_content`** for detailed documentation on the located API.

6. **Query `mcp__apple-docs__get_platform_compatibility`** for version requirements (iOS / macOS / watchOS / tvOS / visionOS minimums + beta flags).

7. **If deprecated**, query `mcp__apple-docs__find_similar_apis` for modern alternatives. Hand off to AL behavior.

8. **Apply conflict resolution protocol** if sources disagree. Never silently pick a winner — present all evidence, recommend apple-docs over cached knowledge, let the user decide.

9. **Provide verdict** with inline citations (documentation URLs, WWDC session refs).

10. **Write back atomically** to `api-decisions.md` with full entry: `Verdict`, `Min Target`, `Rationale`, `Source URL`, `WWDC ref`, `Date`, `Supersedes` (if replacing a prior verdict).

11. **Write back to `wwdc-references.md`** if any sessions were cited.

12. **Append session note to `memories.md`** Recent Sessions log.

## Sidecar write criteria

VA always writes to `api-decisions.md` (every verdict is recorded). Writes to `wwdc-references.md` only when sessions cited. Appends to `memories.md` always.

## Failure modes to defend against

- **Recommending without querying** — if all four tiers are unavailable (no sidecar entry, no axiom, no xcode, no apple-docs), the answer is *"I cannot validate this right now — apple-docs MCP is required."* Do NOT fall back to general LLM knowledge as if it were authoritative.
- **Stale verdict recital** — anything `>90 days` must be re-validated, not parroted.
- **Silent conflict resolution** — sources disagreeing without surfacing the disagreement is anti-user. Show all evidence; recommend the most authoritative.
