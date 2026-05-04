# SC — Bootstrap Repository Scan

Detect this repository's commit conventions, tag scheme, ID-namespace scheme, merge strategy, convention drift, and per-convention confidence scores. Populate the sidecar with this meta-knowledge so RC, SA, CT, and ME can do their work accurately. Run this first on any new repo.

## Value over plain git

`git log` and `git tag -l` show you commits and tags. SC produces *characterization* — what conventions this repo follows, how confidently, whether they've drifted, what merge strategy is used, whether epic IDs collide with PR numbers — none of which git alone exposes. The sidecar entries written here are the foundation every other command reads.

## Process

### 1. Sample commits across four windows

```bash
git log --oneline -20                       # recent
git log --oneline --skip=100 -20            # mid
git log --oneline --skip=500 -20            # deep-mid
git log --oneline --reverse -20             # early
```

Four windows (not three) catch convention drift across larger repos. For repos under ~120 commits the deep-mid window will overlap; that's fine.

### 2. Detect commit-message conventions

For each window, extract the prefix pattern (e.g. `feat:`, `fix(scope):`, `EPIC-12`, bare integer, free-form). Compute prefix-frequency distribution per window.

- **Strict convention** — single dominant prefix style (≥80%) consistent across all four windows → record `confidence_score: high`.
- **Loose convention** — dominant prefix style appears but with notable variance → `confidence_score: medium`.
- **Drift detected** — different dominant style in different windows → record both styles with `convention_drift: true` flag in `conventions.md`. `confidence_score: low`.
- **No convention** — high entropy across all windows, no dominant prefix → `confidence_score: low`, note as `free-form: true`.
- **Squash-merge false-uniform signal** — if every commit has identical structure (e.g. all read like "PR-title (#123)") with no developer-authored prefix variance, this is likely an artifact of squash-merge PR-title-generation, NOT a strict convention. Record as `confidence_score: low` with `merge_strategy_signal: squash-uniform` and note the reason.

### 3. Detect tag scheme

```bash
git tag -l --sort=-creatordate | head -50
```

- **Tagless** — no output → record `tagless: true` in `conventions.md`. Note that epic-boundary scoping in RC/SA must rely on commit grep only.
- **SemVer** — `v1.2.3` style → record scheme.
- **Epic-bugfix-build** — `v1.{epic}.{bugfix}-{build}` style → record scheme; this is the scheme RC's tag-boundary scoping was originally designed around.
- **Custom** — record exact pattern observed.

### 4. Detect merge strategy

```bash
git log --merges --pretty=format:"%s" -20
git log --no-merges --pretty=format:"%h %s" -10
```

Cross-reference:
- Many merge commits with `Merge pull request` or `Merge branch` in subject → `merge_strategy: merge-commits`.
- No merge commits, mostly linear history with PR refs in subject lines (`(#123)`) → `merge_strategy: squash`.
- No merge commits, no PR refs, linear history with arbitrary subjects → `merge_strategy: rebase`.
- Mixed → record `merge_strategy: mixed` with notes.

**This field is critical.** SA reads it and surfaces calibration warnings on squash repos.

### 5. Detect ID-namespace scheme

Survey commits and PRs/issues for ID format:
- **Hyphen** — `EPIC-12`, `12-4` → record `id_format: hyphen`, examples.
- **Dot** — `12.4` → record `id_format: dot`, examples.
- **Bare integer** — `#42`, `Issue 42` → record `id_format: bare-integer`. **Critical:** also check whether the same integer space is used by PRs and issues. If yes, record `id_namespace_collision: true` with the bounds (e.g. *"PR numbers run 1–800; epic IDs are also bare integers in the same range"*). RC must prompt for disambiguation on collision.
- **Multiple formats present** — record all formats with frequency.

### 6. Check for artifact paths

```bash
ls -d _bmad-output 2>/dev/null
ls -d _bmad-output/implementation-artifacts 2>/dev/null
ls -d docs/decisions 2>/dev/null
ls -d .changeset 2>/dev/null
```

Record any planning/artifact paths found in `conventions.md` under `artifact_paths`. RC and CT cross-reference these.

### 7. Populate the sidecar

Write back to `{project-root}/_bmad/_memory/gloria-sidecar/conventions.md`:

```markdown
## Detected (YYYY-MM-DD)

- **commit_format**: <observed pattern> (confidence: high|medium|low)
- **tag_scheme**: <pattern> | tagless: true
- **id_format**: <hyphen|dot|bare-integer|multiple>
- **id_namespace_collision**: true|false (with notes if true)
- **merge_strategy**: squash|merge-commits|rebase|mixed
- **convention_drift**: true|false (with notes if true)
- **artifact_paths**: [list]
- **discovered_at**: YYYY-MM-DD
- **last_validated**: YYYY-MM-DD
```

Write to `patterns.md` (only if structural insights surfaced — e.g. "feature work clusters in `src/api/`"). Most SC runs produce no `patterns.md` writes — the structural-insight bar is high.

Write to `navigation-hints.md` repo-specific git shortcuts that emerged from the scan (e.g. *"use `git log v1.17.0-0..v1.18.0-0` for epic 17 scope"* if tag scheme supports it).

### 8. Present the bootstrap report

Lead with the inflection point — what about this repo's setup is most likely to surprise the user or shape RC/SA later. Format:

```
📜 Bootstrap complete (high|medium|low confidence overall).

  Commit format: <pattern>
  Tag scheme: <pattern> | tagless
  ID format: <pattern> [⚠ namespace collision] (if applicable)
  Merge strategy: <strategy> [⚠ squash cliff caveat] (if squash)
  Drift: detected in <region> (if applicable)

  Artifact paths: <list> (if any)

  (sidecar updated: conventions.md, [patterns.md], [navigation-hints.md])

  Try RC on a recent epic to see what I've learned.
```

If `merge_strategy: squash` is detected, surface a one-line caveat under SA's section: *"struggle signals in this repo are likely suppressed by squash-merge — SA will surface that warning when invoked."* Don't be alarmist; this is a feature of disciplined teams, not a bug.

## Sidecar write criteria

SC always writes to `conventions.md` (that's its purpose). It writes to `patterns.md` only when a structural insight emerges (high bar). It writes to `navigation-hints.md` only when a repo-specific shortcut is genuinely useful (not just `git log --grep`).

Never write SHAs, commit messages, diffs, or log output to any sidecar file.
