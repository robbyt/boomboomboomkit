---
title: 'GH-167 row 8 — Release promotion mechanism + main hygiene (#110, #109)'
type: 'chore'
created: '2026-07-25'
status: 'done'
review_loop_iteration: 0
baseline_commit: '8a9b761'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The documented `develop` → `main` promotion is a **denylist**: step 3 removes "every path in the Stays-on-develop list", so anything not enumerated ships by default. That list names 6 paths; `develop` has 21 top-level entries. Six develop-only paths would ship today — `.gemini/`, `Demo/`, `docs/` (which holds three named LLM audit files), `TODO.md`, `hilbert-request.md`, and `.github/` (whose CI comments name `_bmad-output/ml-training/`). #110 caught two of the six, which is what a denylist failing open looks like. Separately, `main` is the public default branch and serves 164.6 MB — 155.4 MB of it committed `.build/` — to anyone who clones it (#109).

**Approach:** Replace the hand-maintained denylist with an **allowlist-driven script that fails closed**: anything not explicitly cleared for `main` is stripped, whether or not anyone remembered it. The allowlist lives in the script as executable truth, and a pytest asserts it matches CLAUDE.md's table so the two cannot drift. Separately, one ordinary commit on `main` removes the tracked build artifacts and adds the `.gitignore` whose absence caused them.

## Boundaries & Constraints

**Always:**
- The script is **dry-run by default**. Staging requires an explicit `--execute`.
- The allowlist is the single source of truth; CLAUDE.md's table documents it and is drift-tested against it.
- The script must be runnable **today**, on any day, to reveal drift before release day — not only during a release.
- `scripts/` is develop-only. Consumers never run this; it must not appear in the allowlist.
- Every test writes only into `tmp_path`, never the repo tree (the `scripts/tests/conftest.py` convention).

**Ask First:** Any push to `main` — it is the public default branch. Any change to what the allowlist admits. Adding a `main`-bound CI workflow.

**Never:** Rewriting `main`'s history (operator chose the non-rewrite path). Restoring `MODEL_CARD.md` / `.swiftlint.yml` / `tools/` to `main` in this change — v1 squash content, deliberately out of scope. Automating the release itself; this stages and verifies, a human commits.

**Decisions frozen at planning (operator, 2026-07-25):**
1. Allowlist + drift test + docs, not a two-entry patch to the denylist.
2. `main` commit restores **`.gitignore` only**; the other three missing ships-to-main paths are ledgered as v1 squash content.
3. `.github/` is **stripped**. Its `ci.yml` comments reference `_bmad-output/ml-training/` and "develop-only" tooling, and a dormant `main` receives no pushes to gate. Authoring a `main`-appropriate workflow is a v1 item.
4. Two landings: the tooling + docs via PR into `develop`; the artifact strip as a direct commit on `main`, gated on explicit operator go-ahead at execution time.

## Corrections to the row's own premises

Both were verified false and must be retracted, not implemented:

1. **#167 row 8 claims the squash "literally cannot run without `--allow-unrelated-histories`".** `git merge-base origin/main origin/develop` returns `468a7b3` — `main`'s init commit is a shared ancestor. The documented squash runs as written.
2. **#109 claims `git merge --squash develop` "will not remove already-tracked files, so the v1 release inherits them".** Develop's commit `aa0455b` deleted `.build/` relative to that shared base, and a `git merge-tree` simulation of `main`+`develop` yields a tree with **zero** `.build/`/`.swiftpm/` entries. The squash removes them automatically. The real and remaining problem is the clone-today cost, not release inheritance.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Default invocation | `make release-preview` | Prints kept/stripped sets + counts; stages nothing; exit 0 | n/a |
| Execute | `--execute` on a squash-staged tree | Strips non-allowlisted paths from the index; leaves the commit to a human | Refuses if the index is empty |
| New develop-only dir appears | e.g. `.newllm/` added | Stripped automatically, listed under STRIPPED | fails closed by construction |
| New ships-to-main path added to script only | allowlist gains an entry, CLAUDE.md not updated | **pytest fails** naming the divergent entry | loud |
| New path added to CLAUDE.md only | table gains a row, script not updated | **pytest fails** naming the divergent entry | loud |
| Allowlisted path absent from tree | e.g. `MODEL_CARD.md` missing | Reported as MISSING, non-fatal in dry-run | warn, do not fabricate |
| Run outside a git repo / wrong branch | not on `main`, or no staged merge | Refuses with a message naming the expected state | non-zero exit |
| `main` strip | `git rm -r --cached .build .swiftpm` | 2,276 files untracked; `.gitignore` added; working tree keeps the files | n/a |

</frozen-after-approval>

## Code Map

- `CLAUDE.md:31-46` — the "Stays on `develop` ONLY" denylist (6 entries). `:37-47` the ships-to-main table (10 rows). `:48-58` the squash protocol whose step 3 is the failing-open step.
- `_bmad-output/project-context.md:130` — the "four buckets" file-placement rule, which **does** place `Demo/` on develop. CLAUDE.md's list does not. Reconcile.
- `_bmad-output/project-context.md:127-132` — Development Workflow Rules "What goes to main" / "What stays on develop", a third copy of the same list.
- `scripts/docc-transclude.py` — the reference shape for a develop-only `uv run` CLI with `--check` mode.
- `scripts/tests/conftest.py` — `spec_from_file_location` loader for hyphenated script filenames + `tmp_path` workspace convention. Reuse both.
- `Makefile` — `docc-validate` shows the main-only-checkout self-skip idiom; `scripts-tests` is the pytest entry point that must pick up the new test.
- `.github/workflows/ci.yml:8-11` — the comments naming `_bmad-output/ml-training/`, the basis for decision 3.

## Tasks & Acceptance

**Execution:**
- [ ] `scripts/promote-to-main.py` — new. Owns `SHIPS_TO_MAIN` (the 10 allowlist entries). Walks the staged index, partitions into kept/stripped, prints both with counts, and `git rm --cached -r`s the stripped set only under `--execute`. Dry-run default. Refuses when not on `main` or when nothing is staged.
- [ ] `Makefile` — add `release-preview` (dry-run) and `release-stage` (`--execute`) targets, both develop-only with the established self-skip note.
- [ ] `scripts/tests/test_promote_to_main.py` — new. Parses CLAUDE.md's ships-to-main table and asserts set-equality with `SHIPS_TO_MAIN`; asserts the partition is total (every staged path lands in exactly one set); asserts a synthetic unlisted path is stripped. All under `tmp_path`.
- [ ] `CLAUDE.md` — rewrite the squash protocol around the script; mark the ships-to-main table as drift-tested; add `Demo/`, `docs/`, `.gemini/`, `TODO.md`, `hilbert-request.md`, `.github/` to the develop-only list for human readability; add the dated dormancy note; state that promotion is allowlist-driven and fails closed.
- [ ] `_bmad-output/project-context.md` — reconcile the two other copies of the list so all three agree.
- [ ] **`main` branch, separate commit** — `git rm -r --cached .build .swiftpm`; add `.gitignore` copied from develop; commit. **Do not push without explicit operator go-ahead.**
- [ ] `_bmad-output/implementation-artifacts/deferred-work.md` — ledger the three unrestored ships-to-main paths, the absent `main` CI workflow, and anything surfaced.

**Acceptance Criteria:**
- Given a develop-only directory that appears in neither list, when `make release-preview` runs, then it is reported under STRIPPED without anyone having enumerated it.
- Given the script's allowlist and CLAUDE.md's table disagree by one entry, when `make scripts-tests` runs, then it fails and names that entry.
- Given `make release-preview` on a clean checkout, when it completes, then the git index is unchanged and exit is 0.
- Given the `main` commit, when a consumer clones `main`, then the clone is ~9 MB rather than 164.6 MB and carries a `.gitignore`.
- Given `main` after the strip, when `git merge --squash develop` runs at v1, then it still succeeds without `--allow-unrelated-histories`.

## Spec Change Log

**2026-07-25 — operator escalated main hygiene from a strip-commit to a full-history purge.**
The frozen approach was "one ordinary commit on `main` removing the artifacts",
chosen to avoid rewriting a public branch. Two operator directives changed it:
first "rewrite main git history is fine", then "rewrite the history of develop as
well, we shouldn't be including compiled binaries in git". The decisive fact,
surfaced before execution: `468a7b3` is **develop's root commit too**, so the
blobs were reachable from every branch and rewriting `main` alone would have
reclaimed nothing on a normal clone. Executed with `git filter-repo` over a
mirror of the published state, verified, then force-pushed.
Result: pack 76.0 MB → 20.6 MB, 133 commits and 8 refs preserved, develop's tip
tree byte-identical (`efe6f43`), 0 purge-set objects remaining.
**KEEP on re-derivation:** verify on a mirror clone and prove develop's tip tree
hash is UNCHANGED before pushing — that single check is what distinguishes "we
removed build output" from "we altered the library".

**2026-07-25 — content audit built, then removed on operator direction.**
The `.gitignore` finding (45 of 132 lines naming Claude Code, BMAD, Codex,
party-mode) suggested cleared files could leak in their contents, so the script
gained an audit. It reported **113 of 265 shipping files**, including 48 in
`Sources/`. Operator: *"I'd prefer to leave context for our own use in the
comments… not super concerned."* The audit was removed rather than left
reporting 113 non-problems — a tool that cries wolf trains people to ignore it.
The position is now recorded in CLAUDE.md as measured and accepted.
**KEEP:** `PRESERVE_FROM_MAIN` survives on FUNCTIONAL grounds (develop's
patterns are dead config on `main`), not secrecy grounds.

**2026-07-25 — `--from-ref` added after the docs outran the implementation.**
CLAUDE.md was written to say the preview is "safe to run any day… run it
periodically, not only at release time", but `release-preview` refused off
`main`, so the promise was false. Rather than weaken the doc, the script gained
a read-only ref-partitioning mode and `make release-preview` now uses it.

## Design Notes

**Why an allowlist rather than more denylist entries.** The six unlisted paths are not an oversight to be corrected once; they are what a denylist produces over time. `.gemini/` is the proof — it is the same class as `.claude/`, arrived later, and nobody added it. A denylist must be updated by whoever adds a directory, at the moment they add it, or it silently ships. An allowlist inverts the default: a new directory ships only if someone deliberately clears it. The failure mode changes from "internal audit docs leak to a public branch" to "a legitimately public file is missing from the first release", which is visible and cheap.

**Why the drift test is not optional.** Moving the list into a script creates a second copy alongside CLAUDE.md's table. Two lists with no coupling is the same defect one layer up. The pytest makes CLAUDE.md's table a tested artifact rather than prose that happens to be accurate today.

**Why `main` still gets stripped even though the squash would fix it.** The squash-inheritance premise is false (see Corrections), so this is not about the release. It is that `main` is the public default branch: every clone today pulls 164.6 MB, 94% of it stale build output from March, and gets no `.gitignore`.

## Verification

**Commands:**
- `make release-preview` — expected: lists 10 allowlisted paths kept, 6+ develop-only paths stripped, index unchanged, exit 0.
- `make scripts-tests` — expected: new suite passes; drift test bites when either list is edited alone.
- `make test` — expected: 941 tests / 161 suites, 4 known issues, unchanged (no `Sources/`/`Tests/` edits).
- `make lint` — expected: 6 violations, 0 serious; `py-lint` clean on the new script (ruff + ty).
- `git merge-tree --write-tree origin/main <branch>` — expected: still resolves, confirming AC 5.

**Manual checks:**
- Bite proofs: add a synthetic top-level dir → appears under STRIPPED; remove one allowlist entry from the script → pytest names it; run `--execute` off `main` → refuses.
- `main` commit reviewed with `git show --stat` before any push is proposed.
