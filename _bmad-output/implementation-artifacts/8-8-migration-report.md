# Story 8-8 migration report

One-time flat-JSON -> JAMS 0.4 migration (Stories 8.8b/8.8c). Develop-only.

| artifact | input shape | output namespace | entries | curator | sandbox-routed fields |
|---|---|---|---|---|---|
| oa300-ground-truth.json | already-JAMS (valid) | tempo | 82 | Robert Terhaar | genre, subdir |
| daw-oracle.json | flat array | tempo | 23 | Robert Terhaar | rekordbox_bpm, rekordbox_disagrees, disagreement_type, subdir |
