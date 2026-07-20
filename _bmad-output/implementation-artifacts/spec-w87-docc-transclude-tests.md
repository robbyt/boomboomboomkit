---
title: 'W87 — pytest coverage for scripts/docc-transclude.py'
type: 'chore'
created: '2026-07-19'
status: 'done'
baseline_commit: '8678498868803baa3fbbcc45b8bfda1b38c8cd06'
review_loop_iteration: 2
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `scripts/docc-transclude.py` carries real branching logic — front-matter stripping, an associated-value signature map, atomic temp-build-then-swap with rollback, a path-overlap guard, `--check` byte comparison — and has zero automated tests. A regression already slipped through once (the `--check`-vs-clean-checkout defect, PR #101). `scripts/` has no pytest harness and CI runs no `uv`, so there is nowhere for a suite to live.

**Approach:** Add `scripts/tests/` holding a stdlib-only pytest suite that drives the generator's `main(argv)` against synthetic temp-dir corpora (plus one integration pass over the real corpus), loaded through an `importlib` shim in `conftest.py` because the module filename is hyphenated. Run it in the existing `_bmad-output/ml-training` uv env behind a new `make scripts-tests` target.

## Boundaries & Constraints

**Always:** Develop-only — `scripts/` never ships to `main`; nothing under `Sources/`, `Tests/`, or `Package.swift` changes. Tests are stdlib + pytest only (no new dependency in `pyproject.toml`; `pytest` is already in the ml-training dev group). Every write goes to a pytest `tmp_path`; no test may write into the repo tree or into `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/`. The real-corpus test asserts a roster-derived assertion built from disk (both the count and the page-name set), never a hardcoded 49. Changes to `scripts/docc-transclude.py` are limited to three operator-authorized fixes: the non-directory `--output-dir` guard applied to BOTH `run_generate` and `run_check` (2026-07-19), `run_check`'s misleading "dir missing" message for a path that exists, and the failed-rollback fix that stops `atomic_swap` deleting a moved-aside original it could not restore (2026-07-20). Every other generator behavior stays byte-identical.

**Ask First:** Any change to `scripts/docc-transclude.py` beyond the authorized `--output-dir` guard — HALT with the failing case and the proposed fix before editing. Adding a new Python dependency. Wiring the new target into `make lint`, `make test`, or CI (`make pre-commit` wiring is authorized).

**Never:** No second uv project (no `scripts/pyproject.toml`). No CI wiring — `.github/workflows/ci.yml` deliberately excludes develop-only `uv` tooling, same policy as `py-lint`. No coverage-percentage gate. No refactor of the generator for testability; it already exposes `main(argv)`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Generate happy path | Synthetic corpus, fresh `--output-dir` | One page per eligible source; body byte-identical after the front-matter block; h1 is `` # ``<Type>/<stem>`` `` | N/A |
| Assoc-value symbol | `EnsemblePolicy/weightedVoting.md` | h1 is `` ``EnsemblePolicy/weightedVoting(_:)`` `` | N/A |
| Underscore exclusion | `_Fixture/` dir and `_probe.md` stem present | Both skipped; no page emitted for either | N/A |
| Stale-page sweep | Output dir pre-populated with an orphan page | Orphan gone after generate; only current pages remain | N/A |
| Fresh parent | `--output-dir` under a nonexistent parent dir | Parent created, pages written | N/A |
| Malformed source | Missing opening `---`, missing closing `---`, CR byte in body, or invalid UTF-8 | Exit 1; pre-existing output dir left byte-identical | `MalformedInput` → `fail()` |
| Output-name collision | Two sources mapping to the same `<Type>-<stem>.md` | Exit 1; nothing written | `MalformedInput` → `fail()` |
| Path overlap | `--output-dir` equal to, inside, or containing `--docs-root` | Exit 1 before any write | `fail()` |
| Missing docs-root | `--docs-root` absent, a regular file, or a broken symlink | Exit 1 | `fail()` |
| Non-directory output-dir | `--output-dir` exists as a regular file, a symlink to a directory, or a broken symlink | Exit 1 before any rename; the existing path is left byte-identical and no `.cases-bak-*` is minted | `fail()` |
| Non-directory output-dir under `--check` | The same three shapes, with `--check` | Exit 1 with the SAME guard message as generate (the two modes must not disagree); a path that exists as a file is never reported as "missing" | `fail()` |
| Failed rollback preserves the original | Restore rename fails after the original was moved aside | Exit 1 naming the `.cases-bak-*` path where the original was preserved; the backup is NOT deleted | `fail()` |
| No temp residue | After any success and any failure above | No `.cases-tmp-*` / `.cases-bak-*` left in the output parent | N/A |
| Rollback on mid-swap failure | Write into the temp dir raises `OSError` after the original was moved aside | Exit 1; the original output dir is restored byte-identical; no residue | `fail()` via `main`'s `OSError` handler |
| Empty body | Source whose closing `---` is the final line | Page is the h1 plus a blank line, nothing more | N/A |
| Whole-file CRLF | Every line ends `\r\n`, including the delimiters | Exit 1 (reported as a missing opening delimiter — characterization, not endorsement) | `MalformedInput` → `fail()` |
| Degenerate source bytes | Zero-byte file, or a UTF-8 BOM before the opening `---` | Exit 1 | `MalformedInput` → `fail()` |
| Unreadable source | A directory named `<something>.md` inside a type dir | Exit 1 | `MalformedInput` → `fail()` |
| Silent input drops | A `.md` loose at `docs-root` top level, and one nested a level below a type dir | Both ignored; characterization test pinning the depth-1 walk | N/A |
| Symlinked overlap | `--docs-root` a symlink resolving inside `--output-dir` | Exit 1 (the reason `reject_path_overlap` resolves both paths) | `fail()` |
| Check round-trip | `--check` against a dir just generated from the same corpus | Exit 0 (the PR #101 regression) | N/A |
| Check drift | `--check` with a page missing, an extra page, or one byte altered | Exit 1, one distinct message per case | `fail()` |
| Check ignores non-`.md` | A stray non-`.md` file under the output dir | `--check` passes while a generate would sweep it — second documented asymmetry, encoded as-is | N/A |
| Check empty/absent | `--check` on an empty corpus, or output dir absent | Exit 1, and `--check` creates nothing (assert the dir still does not exist afterwards) | `fail()` |
| Idempotency | Two consecutive generates over an unchanged corpus | Run-2 bytes equal run-1 bytes for every page | N/A |

</frozen-after-approval>

## Code Map

- `scripts/docc-transclude.py` — system under test; `main(argv)` is the entry point, `fail()` raises `SystemExit(1)`, `MalformedInput` is caught in `main`. Carries the three authorized fixes (`reject_non_directory_output` at :177, its `run_check` call at :264, the failed-rollback branch in `atomic_swap` at :203).
- `_bmad-output/ml-training/pyproject.toml` — owns the `pytest`/`ruff`/`ty` dev group and `[tool.ruff] line-length = 100`, `target-version = "py311"`. No edit expected.
- `_bmad-output/ml-training/ablation/tests/conftest.py` — precedent for one-place path setup shared across a suite.
- `Makefile` — `ML_TRAINING_DIR` var; `ablation-tests` (line ~"## ablation-tests") is the shape to copy; `py-lint` enumerates the `ty` file list and globs `../../scripts/` for ruff.
- `Sources/BoomBoomBoomKit/Resources/Documentation/` — the real corpus: 10 type dirs + `_Fixture/` with three `_`-prefixed sentinels.

## Tasks & Acceptance

**Execution:**
- [x] Cut branch `rterhaar/w87-docc-transclude-tests` off `develop` — per-unit PR convention.
- [x] `scripts/tests/conftest.py` — load `docc-transclude.py` via `importlib.util.spec_from_file_location` and expose it as a session fixture (the hyphenated filename is not importable); add a helper fixture that writes a synthetic corpus into `tmp_path`.
- [x] `scripts/tests/test_docc_transclude.py` — one test per I/O Matrix row, driving `main([...])` and asserting exit status, on-disk bytes, and absence of temp residue.
- [x] `scripts/tests/test_docc_transclude.py` — add the real-corpus integration test: generate into `tmp_path`, assert the page count equals the eligible-source count computed from disk, then `--check` the same dir and expect exit 0.
- [x] `Makefile` — add `## scripts-tests:` running `cd $(ML_TRAINING_DIR) && uv run pytest ../../scripts/tests/`, placed beside `ablation-tests`.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` — mark W87 resolved with a cross-reference to this spec and the landing commit.

**Iteration 2 (post-review, operator-authorized):**
- [x] `scripts/docc-transclude.py` — reject an existing non-directory `--output-dir` (regular file, symlink, broken symlink) before any rename.
- [x] `.gitignore` — drop the trailing slash from the `.cases-tmp-*/` / `.cases-bak-*/` patterns so non-directory residue is also ignored.
- [x] `scripts/tests/test_docc_transclude.py` — add one test per new matrix row, including the monkeypatched mid-swap `OSError` that finally exercises `atomic_swap`'s rollback branch.
- [x] `scripts/tests/test_docc_transclude.py` — apply the review patches: non-vacuous absent-output-dir assertion, recursive `snapshot()`, a valid sibling that sorts BEFORE the malformed file, real-corpus name-set assertion, loud failure instead of `pytest.skip` when the corpus is absent, relative-path `docs_before` comparison, overlap-test residue checked in the right parent.
- [x] `Makefile` — `$(CURDIR)`-based path instead of the hardcoded `../../` escape, a develop-only guard, and `scripts-tests` added to the `pre-commit` prerequisite list; explain the `scripts/tests/` ty exclusion in the `py-lint` comment block where every other exclusion is documented.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` — rewrite the W87 resolution note: drop the inaccurate "stdlib-only" phrasing (pytest is not stdlib), cite the spec, and record the generator fix.

**Iteration 3 (review round 2, operator-authorized):**
- [x] `scripts/docc-transclude.py` — call `reject_non_directory_output` from `run_check` too, so `--check` and generate emit the same message for the same shape; stop reporting an existing non-directory path as "missing".
- [x] `scripts/docc-transclude.py` — failed-rollback fix: capture the restore `OSError`, skip the `shutil.rmtree(backup)` in that case, and fail naming the `.cases-bak-*` path where the original survives.
- [x] `scripts/docc-transclude.py` + `deferred-work.md` — correct the broken-symlink over-claim: silent displacement was real for a regular file and a symlink-to-directory ONLY; a broken symlink already failed loudly pre-guard.
- [x] `scripts/tests/test_docc_transclude.py` — localize the `os.rename` monkeypatch to `tmp_path` paths, preserve the real signature, assert the missing message fragment on the unreadable-source test, add `--check` overlap and guard-before-`collect_outputs` precedence tests.
- [x] `scripts/tests/conftest.py` — `snapshot()` records symlinks instead of skipping them, and the non-existent-output-dir case is explicit rather than a silently empty dict.
- [x] `Makefile` — `scripts-tests` self-skips with a printed note on a main-only checkout (the `docc-validate` precedent) so `make pre-commit` stays runnable end to end.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` — file W92 (case-insensitive collision check) and W93 (non-directory / symlinked output-dir PARENT), each with a reproduction and a re-open trigger.

**Acceptance Criteria:**
- Given a clean checkout, when `make scripts-tests` runs, then every test passes and no file under the repo tree is created or modified.
- Given the suite, when a test asserts generator behavior, then it fails for the right reason — each malformed-input test asserts both the nonzero exit AND that the pre-existing output dir is unchanged, not merely that an exception was raised.
- Given `make py-lint`, when it runs after this change, then ruff reports clean over `scripts/tests/` (it is reached by the existing `../../scripts/` glob) and the target list still passes `ty`.
- Given `make docc-transclude` and `make docc-validate`, when run after this change, then both stay green and the normal generate/check path is byte-identical; the only observable generator differences are the three authorized fixes, each on a path that previously failed or silently displaced data.
- Given a non-directory `--output-dir`, when either generate or `--check` runs, then both exit 1 with the same message and the existing path is left untouched.

## Spec Change Log

### 2026-07-20 — iteration 2: guard symmetry, a corrected over-claim, and the failed-rollback fix

**Triggering findings (review round 2).** Three items, all verified by hand against the code before acting:

1. The iteration-1 guard was called from `run_generate` only, so `--check` and generate disagreed: a symlink-to-directory at `--output-dir` passed `--check` with exit 0 while a generate hard-failed. Reproduced.
2. `run_check` reports `generated Cases/ dir missing at <path>; run make docc-transclude` for a path that exists as a regular file. It is not missing, and the suggested command now refuses it, so the operator is sent in a loop. Reproduced.
3. **The iteration-1 defect narrative over-claimed the broken-symlink case.** Running the pre-guard generator (`git show 8678498:scripts/docc-transclude.py`) against a broken symlink at the output path already exited 1 with `NotADirectoryError`, symlink intact, no residue — because `atomic_swap`'s `output_dir.exists()` follows the link and is False, so no backup is ever minted. Silent displacement was real for a regular file and for a symlink-to-directory ONLY. The iteration-1 Change Log entry, the guard docstring, and the `deferred-work.md` resolution note all stated it more broadly; `deferred-work.md` is a permanent record, so the correction lands there regardless of any other decision.

**Amendments.** Operator authorized both generator changes (2026-07-20): extend the guard to `run_check` with the same message, and fix `atomic_swap`'s failed-rollback path so a restore that raises no longer falls through to an unconditional `shutil.rmtree(backup)` that deletes the operator's only copy. Matrix gained two rows; the `Always` boundary now enumerates exactly three authorized generator changes.

**Known-bad state avoided.** Shipping a guard that makes the two modes disagree about what a valid output dir is, while a permanent deferred-work entry overstates what the guard fixed.

**KEEP — must survive re-derivation.** Everything listed under iteration 1's KEEP, plus: the `reject_non_directory_output` guard's `os.path.lexists` + `is_symlink` shape (a symlink must be caught on its own terms, never followed), its placement before `collect_outputs`, and the mid-swap rollback test that induces the failure at the second `os.rename` rather than at a write.

### 2026-07-19 — iteration 1: restored the dropped `--output-dir` row (intent gap), authorized the generator fix

**Triggering finding.** Both review layers independently found that the frozen I/O matrix rewrote W87's recommended row "absent / file-typed / broken-symlink `--output-dir`" into "Missing docs-root: absent, a regular file, or a broken symlink". The suite faithfully implemented the substitute, so a non-directory `--output-dir` was never exercised.

**What that hid — an operator-confirmed defect.** With a regular file at the output path, `atomic_swap` renames the user's file onto a `.cases-bak-*` name, creates a fresh directory in its place, and `shutil.rmtree(backup, ignore_errors=True)` silently no-ops because the backup is not a directory. The run prints `wrote N pages` and exits 0; the file is gone from its path and survives only as orphan residue. With a symlink at the output path the symlink is displaced and left behind permanently, falsifying `atomic_swap`'s own "never leaves an orphan `.cases-tmp-*` / `.cases-bak-*`" docstring. `.gitignore:10` uses a trailing slash (`.cases-bak-*/`), so non-directory residue would not even be ignored. Reproduced twice under `/private/tmp` before amending.

**Amendments.** Operator authorized (2026-07-19), so the frozen matrix gained the `Non-directory output-dir` row plus nine rows the reviews showed uncovered (rollback-on-mid-swap-failure, empty body, whole-file CRLF, degenerate source bytes, unreadable source, silent input drops, symlinked overlap, check-ignores-non-`.md`, idempotency); the `Check empty/absent` row now requires asserting the output dir is still absent afterwards; the `Always`/`Ask First` boundaries were narrowed to authorize exactly the `--output-dir` guard and the `make pre-commit` wiring, both operator-approved.

**Known-bad state avoided.** Shipping a W87 resolution whose own matrix had quietly dropped one of W87's named cases — closing the ticket while leaving a silent-data-displacement path live, and recording it in `deferred-work.md` as fully covered.

**KEEP — must survive re-derivation.** The `expect_abort` helper capturing `before` internally so a caller cannot forget it. Both `--docs-root` and `--output-dir` always pinned into `tmp_path` by `Workspace.argv()`, so the repo-rooted defaults are unreachable. The five-way parametrized associated-value test plus its value-only control. The nested-`---`-in-body test proving first-delimiter stripping. The real-corpus count derived from disk. The empty-corpus asymmetry as characterization, not a fix.

## Design Notes

The generator is already structured for testing: `main(argv)` takes an explicit argv, `fail()` raises `SystemExit(1)`, and both `--docs-root` and `--output-dir` are overridable — so no production refactor is needed. The one friction point is the hyphenated module name:

```python
# conftest.py
import importlib.util, pathlib
_SRC = pathlib.Path(__file__).resolve().parent.parent / "docc-transclude.py"
_spec = importlib.util.spec_from_file_location("docc_transclude", _SRC)
docc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(docc)
```

Rollback assertions are the highest-value tests here, since `atomic_swap`'s `finally` block is the least-exercised path: seed the output dir with a known page, run a generate over a corpus containing one malformed file, then assert exit 1, the seeded page still byte-identical, and no `.cases-tmp-*` / `.cases-bak-*` sibling remaining.

Note the empty-corpus asymmetry to encode as-is, not to "fix": `run_generate` on an empty corpus succeeds and writes an empty dir, while `run_check` explicitly fails with "no eligible source docs". If that asymmetry looks wrong, it is an Ask First, not a silent change.

**Implementation outcomes (iteration 1, 2026-07-19).** 31 tests, all passing; the pass reported no generator defect and did not modify `scripts/docc-transclude.py`. That report was wrong on the first count: the matrix row it was derived from had dropped the non-directory `--output-dir` case (see the Change Log entry above).

**Implementation outcomes (iteration 2, 2026-07-19).** 44 tests, all passing. The generator now carries `reject_non_directory_output`, called from `run_generate` after `reject_path_overlap` and before `collect_outputs`; it uses `os.path.lexists` plus `Path.is_symlink` so a symlink is rejected on its own terms rather than followed, and `atomic_swap`'s docstring now states the resulting precondition instead of over-claiming. Two mutation checks confirm the new tests are non-vacuous: deleting the guard call fails exactly the three `test_non_directory_output_dir_is_rejected` variants, and gutting `atomic_swap`'s rollback `os.rename` fails exactly `test_rollback_restores_the_original_when_the_swap_fails_mid_way`. That rollback test induces the failure by patching the SECOND `os.rename` (temp dir into place), which is the only way to land after the original was moved aside; iteration 1's claim that this branch was unreachable from a test was a limitation of the approach, not of the generator.

**Implementation outcomes (iteration 3, 2026-07-20).** 50 tests, all passing. The guard is now called from `run_check` too (same placement, before `collect_outputs`, same message), and `run_check`'s "dir missing" branch re-runs the guard so an existing non-directory is never reported as absent. `atomic_swap`'s `finally` captures a failed restore instead of swallowing it, skips the `shutil.rmtree(backup)` in that case, and exits 1 with a message naming the surviving `.cases-bak-*` path. Six new tests: three parametrized `--check` guard-symmetry cases (each also asserting the generate-side stderr is byte-identical), the `--check` path-overlap case, the guard-before-`collect_outputs` precedence case, and the failed-rollback case (the rollback test's `patch_rename` helper now fails calls 2 AND 3). The mid-swap monkeypatch was rewritten: it rebinds the module attribute `docc.os` to a forwarding proxy instead of mutating the global `os` module, advances its counter only when both rename operands sit under the test's `tmp_path`, and forwards the real `src_dir_fd` / `dst_dir_fd` signature. `Workspace.snapshot()` now records symlinks by link target and gives the absent / non-directory / symlink output-dir states distinguishable values instead of an empty dict, so no byte-identity assertion is vacuous. Mutation check: all five generator-dependent new tests fail against the pre-guard baseline (`8678498`).

One honest limit carries forward unchanged: `ty` still cannot check `scripts/tests/` — its search path is `_bmad-output/ml-training`, so the sibling `conftest` import is unresolvable even behind `TYPE_CHECKING`. The files stay out of the `py-lint` `ty` enumeration and that exclusion is now documented in the `py-lint` help comment alongside every other exclusion; ruff coverage (the AC requirement) is clean.

## Verification

**Commands:**
- `make scripts-tests` — expected: all tests pass, exit 0.
- `make py-lint` — expected: ruff check + ruff format --check clean, `ty` clean.
- `make docc-transclude && make docc-validate` — expected: unchanged behavior, both green.
- `git status --porcelain` after a full run — expected: only the intended new/modified files; no stray `Cases/`, `.cases-tmp-*`, or `__pycache__` additions beyond what `.gitignore` already covers.

## Suggested Review Order

**The generator fixes (start here — this is the only shipping-behavior change)**

- The guard that closes the silent-displacement defect; note `lexists` + `is_symlink` so a link is caught, not followed.
  [`docc-transclude.py:177`](../../scripts/docc-transclude.py#L177)

- Called before `collect_outputs` on the generate path, so nothing is read before the path is judged.
  [`docc-transclude.py:256`](../../scripts/docc-transclude.py#L256)

- The same guard on `--check`, and why "missing" is no longer reported for a path that exists.
  [`docc-transclude.py:264`](../../scripts/docc-transclude.py#L264)

- Failed-rollback fix: the backup is kept and named when a restore fails, instead of being swept.
  [`docc-transclude.py:203`](../../scripts/docc-transclude.py#L203)

**Test harness (how every assertion is made non-vacuous)**

- `expect_abort` captures the before-snapshot internally so no caller can forget the byte-identity check.
  [`test_docc_transclude.py:35`](../../scripts/tests/test_docc_transclude.py#L35)

- `patch_rename` fails only on renames under `tmp_path`, keeping the global `os.rename` patch from leaking.
  [`test_docc_transclude.py:67`](../../scripts/tests/test_docc_transclude.py#L67)

- `snapshot()` records symlinks and recurses, so residue cannot hide from a byte-identity assertion.
  [`conftest.py:105`](../../scripts/tests/conftest.py#L105)

**Highest-value tests**

- The rollback branch, reached by failing the second rename rather than a write.
  [`test_docc_transclude.py:573`](../../scripts/tests/test_docc_transclude.py#L573)

- Failed restore: asserts the surviving backup holds the original bytes and the message names it.
  [`test_docc_transclude.py:600`](../../scripts/tests/test_docc_transclude.py#L600)

- Guard-before-corpus-collection, pinning the call order in `run_generate`.
  [`test_docc_transclude.py:541`](../../scripts/tests/test_docc_transclude.py#L541)

**Wiring and records**

- `scripts-tests` self-skips on a main-only tree because it is now a `pre-commit` prerequisite.
  [`Makefile:708`](../../Makefile#L708)

- The gate chain that now runs the suite on every pre-PR pass.
  [`Makefile:113`](../../Makefile#L113)
