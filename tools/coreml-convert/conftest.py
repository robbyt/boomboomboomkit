"""pytest bootstrap.

Prepends `tools/coreml-convert/` (this directory) onto sys.path at pytest
collection time so test modules can import sibling modules (`convert`,
`reference_arch`, `validate`) without per-test sys.path manipulation.
"""

import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
