# Story 7.6 — FR-18 re-run governance log

Committed (NOT .gitignore'd). One row per `evaluate_fr18.py` invocation.
N=3 tripwire: run 4+ for the same v2 checkpointFamilyId requires a `SIGNOFF: <familyId>` line (a `EXCEPTION:bugfix-not-tuning <issue>` line cites a bugfix). The v1 smoke is a separate family, excluded from the count.

| timestamp | gitSha | checkpointFamilyId | checkpointShas | whatChanged | gate_a | gate_b | gate_c | gate_d | gate_e | decision |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-06-05T00:33:48Z | 9f69e1c-dirty | giantsteps_v1 | 42:v1smoke | dev smoke (negative control) | fail | fail | fail | fail | fail | byow |
