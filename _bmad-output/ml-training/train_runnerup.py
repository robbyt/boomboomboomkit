"""train_runnerup.py — Story 7.5 Task 5 / AC2.

Preserves the KDD-B2 RUNNER-UP recipe (``supervisedAugmented``) for follow-up
retrain stories. The headline v2 run (``train.py``) hard-codes the WINNER
(``maskedMelPretrain``); this entry point keeps the loser reachable without
re-deriving it.

The runner-up recipe is REUSED verbatim from
``ablation/train_supervised_augmented.py`` (Story 7.3, smoke-verified) — this
module is a thin, single-source delegation so the named path Story 7.5 AC2
requires exists, while the actual training body stays in ONE place (no
copy-paste drift). The substrate-bound v2 swap (feature_substrate_v2 features +
the Tony split) + the AC10 precondition gate are owned by ``train.py``; a future
runner-up retrain story wires them here the same way.

Run (operator, post-KDD-B4-signoff):
    uv run python train_runnerup.py --weighting-profile uniform --seed 42
"""

from __future__ import annotations

import runpy
import sys
from pathlib import Path

ABLATION_SUPERVISED = Path(__file__).resolve().parent / "ablation" / "train_supervised_augmented.py"


def main(argv: list[str] | None = None) -> int:
    if not ABLATION_SUPERVISED.exists():
        print(
            f"runner-up recipe missing: {ABLATION_SUPERVISED} "
            "(Story 7.3 ablation/train_supervised_augmented.py)",
            file=sys.stderr,
        )
        return 2
    # Delegate to the single-source runner-up arm. argv is forwarded verbatim
    # so the runner-up shares the ablation arm's flag surface.
    forwarded = argv if argv is not None else sys.argv[1:]
    sys.argv = [str(ABLATION_SUPERVISED), *forwarded]
    runpy.run_path(str(ABLATION_SUPERVISED), run_name="__main__")
    return 0


if __name__ == "__main__":
    sys.exit(main())
