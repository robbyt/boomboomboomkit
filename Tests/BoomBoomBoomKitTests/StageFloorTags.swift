//
//  StageFloorTags.swift
//  BoomBoomBoomKitTests
//
//  Swift Testing tag extension for the Story 6.1 Stage 1 regression-floor
//  scaffold. The `.stage1Floor` tag scopes "Stage 1 metadataPolicy = .disabled
//  regression floor" — applied to the four existing disabled-policy tests in
//  MetadataCorroborationTests.swift per Story 6.1 DD #8. SwiftPM's
//  `swift test --filter` is a regex over test-case identifiers, NOT a tag
//  selector — running the four tagged tests today goes via the test-name
//  regex: `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`.
//  Source-level grep for `.tags(.stage1Floor)` is the canonical verification
//  surface until SwiftPM grows first-class tag-filter support (or Story
//  authors migrate to an xctestplan).
//

import Testing

extension Tag {
  @Tag static var stage1Floor: Self
}
