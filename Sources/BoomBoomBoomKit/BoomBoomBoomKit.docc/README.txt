BoomBoomBoomKit DocC catalog — authoring notes
==============================================

The Cases/ subdirectory is a GENERATED build artifact. Do not hand-edit it.

Each Cases/<Type>-<case>.md page is mirrored, one-way, from the canonical
per-case documentation at

    Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md

by `make docc-transclude` (scripts/docc-transclude.py). The generator strips the
YAML front-matter, prepends a symbol-extension h1, and reproduces the body
verbatim. Cases/ is gitignored — regenerate it, never commit it.

To change a case's prose, edit the canonical file under Resources/Documentation/
(the single source of truth, also surfaced inline through DocumentedCase.docs)
and re-run `make docc-transclude`. Editing anything under Cases/ directly is lost
on the next regeneration. To add a case, scaffold the canonical file with
`make new-case TYPE=<TypeName> CASE=<caseName>` (see Resources/README.md, "Adding
a case"), fill it in, then regenerate.

This note is a .txt file on purpose: DocC treats a stray .md in the catalog root
as an uncurated article (a build warning under --warnings-as-errors), whereas
.txt is an inert resource.

The hand-authored Articles/ pages (survey guides that may use tables, code, and
DocC symbol links) ARE source-of-truth and git-tracked — those you edit directly.
