//
//  StageFloorTags.swift
//  BoomBoomBoomKitTests
//
//  Swift Testing tag extensions for the Epic 6 KDD-A6 staged regression-floor
//  scaffold. Each `.stageNFloor` tag scopes "Stage N metadataPolicy = .disabled
//  regression floor" — applied to the same four existing disabled-policy tests
//  in MetadataCorroborationTests.swift as the unified pool migrates through the
//  KDD-A6 stages. Per the staging contract (architecture.md KDD-A6) "stage N
//  floor = stage N-1 measurement; no week-long red intervals":
//  - `.stage1Floor` (Story 6.1): pool built pre-merge as a post-hoc trace
//    artifact in `analyzeBPM`.
//  - `.stage2Floor` (Story 6.3): pool built inside `runPreCorroborationPipeline`
//    and consumed via `PreCorroborationOutput.pool`; `MetadataCorroborator` owns
//    metadata-participation production. Stage 2 floor = Stage 1 measurement.
//  Both tags coexist on the four tests.
//
//  SwiftPM caveat: `swift test --filter` is a regex over test-case identifiers,
//  NOT a Swift Testing tag selector — `swift test --filter "stage2Floor"`
//  matches zero tests. Running the tagged tests goes via the test-name regex:
//  `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`.
//  Source-level grep for `.tags(.stage1Floor, .stage2Floor)` is the canonical
//  verification surface until SwiftPM grows first-class tag-filter support (or
//  Story authors migrate to an xctestplan).
//

import Testing

extension Tag {
  @Tag static var stage1Floor: Self
  @Tag static var stage2Floor: Self
}
