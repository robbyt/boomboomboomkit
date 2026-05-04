# CO — Check Compatibility

Check platform availability and deployment-target compatibility for an API. Apply Pattern B: targeted resolution (sidecar → xcode → apple-docs).

## Value over plain web search

Apple's compatibility matrices are scattered across docs, release notes, and WWDC sessions. CO adds: (a) sidecar-cached deployment targets (so re-checks don't re-prompt for project context), (b) auto-detection of current deployment targets via xcode MCP, (c) explicit conflict detection between recorded targets and live xcode state, (d) automatic alternative-API surfacing when the requested API requires a higher target than the project supports.

## Process

1. **Check `project-patterns.md`** for recorded deployment targets.

2. **Query xcode MCP** for current project deployment targets and active schemes (graceful skip if unavailable; ask user instead).

3. **Apply xcode MCP sanity check** — if xcode MCP targets conflict with `project-patterns.md` (e.g. project bumped from iOS 16 to iOS 17 since last session), present both to the user and ask which is current. Record the confirmed answer.

4. **If xcode MCP unavailable**, ask the user for deployment targets and record the answer to `project-patterns.md`.

5. **Query `mcp__apple-docs__get_platform_compatibility`** for API version requirements (iOS / macOS / watchOS / tvOS / visionOS minimums + beta status).

6. **If the API requires a higher deployment target than the project supports**, query `mcp__apple-docs__find_similar_apis` to discover lower-target alternatives.

7. **Report** available platforms, minimum versions, beta status. Be explicit about beta APIs — they may be subject to change.

8. **Flag explicitly** if the API requires a higher deployment target than the project supports. Do not silently assume the user will check.

9. **Write back** deployment targets (if newly confirmed) and the compatibility verdict to `api-decisions.md`.

10. **Append session note** to `memories.md` Recent Sessions log.

## Sidecar write criteria

Writes to `project-patterns.md` when deployment targets are newly recorded or updated. Writes to `api-decisions.md` for the compatibility verdict. Appends to `memories.md` always.

## Failure modes to defend against

- **Stale deployment targets** — if `project-patterns.md` says iOS 16 minimum but xcode MCP says iOS 17, the project moved. Surface the conflict; don't pick silently.
- **Beta-as-stable** — APIs marked beta have different stability guarantees. Always flag beta status explicitly in the verdict.
- **Silent target mismatch** — telling the user an API "is available on iOS 18" when their min target is iOS 16 is incomplete. Always cross-check.
