//
//  BatchedTaskGroupTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  AC #6 evidence for benchmark-infra-ablation-parallelism: proves the
//  batched-task-group helper honors its parallelism cap end-to-end. An
//  actor-protected counter records max in-flight body invocations across
//  the run; the assertion fails if more than `parallelism` bodies overlap.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("BatchedTaskGroup")
struct BatchedTaskGroupTests {

  /// Records the running max of an in-flight counter. Lives in an actor so
  /// concurrent increments/decrements from inside the body closures are
  /// serialized — without this, the "max" reading would race.
  private actor InFlightCounter {
    private var current: Int = 0
    private(set) var max: Int = 0

    func enter() {
      current += 1
      if current > max { max = current }
    }

    func leave() {
      current -= 1
    }
  }

  @Test("max in-flight ≤ parallelism (8 sentinels, parallelism=2)")
  func maxInFlightHonored() async throws {
    let counter = InFlightCounter()
    let items = Array(0..<8)

    let results = await AblationMatrixTests.batchedTaskGroup(
      items: items, parallelism: 2
    ) { item -> Int in
      await counter.enter()
      // Tiny async hop so the body actually overlaps if the cap is broken.
      try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms
      await counter.leave()
      return item * 10
    }

    let observedMax = await counter.max
    #expect(observedMax <= 2, "max in-flight \(observedMax) exceeded parallelism 2")
    #expect(observedMax >= 1, "max in-flight should be at least 1")
    #expect(results == items.map { $0 * 10 }, "results must preserve input order")
  }

  @Test("results preserve input order across chunk boundaries (parallelism=3, 10 items)")
  func resultsPreserveOrder() async throws {
    let items = Array(0..<10)
    let results = await AblationMatrixTests.batchedTaskGroup(
      items: items, parallelism: 3
    ) { item -> String in
      // Random delay to encourage out-of-order completion within a chunk.
      let jitter = UInt64.random(in: 0...2_000_000)  // up to 2ms
      try? await Task.sleep(nanoseconds: jitter)
      return "item-\(item)"
    }
    #expect(results == items.map { "item-\($0)" })
  }

  @Test("empty input returns empty output without launching tasks")
  func emptyInput() async throws {
    let results = await AblationMatrixTests.batchedTaskGroup(
      items: [Int](), parallelism: 4
    ) { _ -> Int in
      Issue.record("body should not run for empty input")
      return -1
    }
    #expect(results.isEmpty)
  }

  @Test("parallelism larger than input size still works (8 items, parallelism=32)")
  func parallelismExceedsInput() async throws {
    let items = Array(0..<8)
    let results = await AblationMatrixTests.batchedTaskGroup(
      items: items, parallelism: 32
    ) { item -> Int in
      return item + 1
    }
    #expect(results == items.map { $0 + 1 })
  }
}
