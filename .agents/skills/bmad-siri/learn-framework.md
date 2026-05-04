# LN — Learn Framework

Getting-started guide and learning path for a new Apple framework. Apply Pattern C: direct resolution (sidecar → apple-docs). Shift to **patient, contextual communication register** for this command — this is teaching mode, not verdict mode.

## Value over plain web search

Apple's frameworks have official tutorials, sample projects, and introductory WWDC sessions — but discovering them in the right order is the actual challenge. LN adds: (a) sequenced learning path (concepts → WWDC → samples → docs) rather than a flat link dump, (b) axiom-cached learning resources when available, (c) curated WWDC introductory sessions filtered by recency, (d) write-back so the recommended sessions enter the project's reference catalog.

## Process

1. **Query axiom skills** for framework tutorials, guides, and learning resources (graceful skip if unavailable).

2. **Query `mcp__apple-docs__get_technology_overviews`** for guides and tutorials on the framework.

3. **Query `mcp__apple-docs__list_wwdc_videos`** to find introductory sessions. Prefer "Meet X" / "Introducing X" / "Get started with X" formats.

4. **Query `mcp__apple-docs__get_sample_code`** for starter projects.

5. **Suggest a learning path** in this order: **concepts → WWDC → samples → docs**. Frame it as a sequence, not a list.

6. **Write back recommended sessions** to `wwdc-references.md` so they enter the project's catalog for future cross-reference.

7. **Append session note** to `memories.md` Recent Sessions log.

## Communication register

LN shifts to patient teaching mode. Concepts before code. Define jargon when it first appears. Offer to drill into any one of the four learning-path stages on request.

## Sidecar write criteria

Writes recommended introductory sessions to `wwdc-references.md`. Appends to `memories.md` always.

## Failure modes to defend against

- **Verdict-mode delivery** — LN is teaching mode, not validation mode. Don't bark "use SwiftUI not UIKit" at someone learning iOS development; explain when each fits.
- **Flat link dump** — listing 20 resources with no order is worse than 5 resources in the right sequence. Order matters.
