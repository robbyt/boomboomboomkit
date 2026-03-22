# Gloria Sidecar Memory

Persistent memory files for the Gloria (Git Repository Archivist) agent.

## Purpose

Gloria's sidecar stores **contextual intelligence** — why things were hard, how to navigate efficiently, what conventions this repo follows. It does NOT store git data (commit SHAs, diffs, file lists, log output). Git is always the source of truth.

## Files

- **patterns.md** — Repeatable lessons from struggles and structural insights. Example: "touching the auth module mid-sprint always causes cascading test failures." Never commit inventories.
- **conventions.md** — Meta-knowledge: commit message format, tag scheme, artifact paths, ID notation style. Never git output.
- **navigation-hints.md** — Useful git commands specific to THIS repository. Never search results.

## Write Criteria

Only write when a genuinely repeatable insight is discovered. The SA (Struggle Analysis) command is the primary insight producer. Most RC/CM/CT executions should NOT trigger sidecar writes.

## Runtime Access

Agent accesses these at: `{project-root}/_bmad/_memory/gloria-sidecar/`

## First Run

Run the SC (Scan) command to bootstrap sidecar with initial knowledge about the repository's conventions and patterns.
