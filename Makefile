# BoomBoomBoomKit Makefile

PROJECT := BoomBoomBoomKit
OA300_CORPUS_PATH ?= /Users/rterhaar/Dropbox/OA300_OnsetAudio300
GIANTSTEPS_CORPUS_PATH ?= /Users/rterhaar/Dropbox/research/giantsteps-tempo-dataset

.PHONY: all
all: help

## help: Display this help message
.PHONY: help
help: Makefile
	@echo
	@echo " Choose a make command to run"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'
	@echo

## build: Build the Swift package (Debug)
.PHONY: build
build:
	swift build

## build-release: Build the Swift package (Release)
.PHONY: build-release
build-release:
	swift build -c release

## test: Run unit tests only (excludes benchmark target; no corpus env required)
.PHONY: test
test:
	swift test --parallel --filter BoomBoomBoomKitTests

## test-verbose: Run unit tests with full streaming output
.PHONY: test-verbose
test-verbose:
	swift test --filter BoomBoomBoomKitTests

## test-filter: Run a specific test suite (usage: make test-filter SUITE=BPMAnalyzer120BPMTests)
.PHONY: test-filter
test-filter:
ifndef SUITE
	$(error SUITE is not set. Usage: make test-filter SUITE=BPMAnalyzer120BPMTests)
endif
	swift test --filter $(SUITE)

## benchmark: Run OA300 accuracy benchmark (fails loudly if OA300_CORPUS_PATH unset)
.PHONY: benchmark
benchmark:
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.OA300BenchmarkTests

## benchmark-giantsteps: Run GiantSteps Tempo Dataset accuracy benchmark
.PHONY: benchmark-giantsteps
benchmark-giantsteps:
	GIANTSTEPS_CORPUS_PATH="$(GIANTSTEPS_CORPUS_PATH)" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.GiantStepsBenchmarkTests

## perf-benchmark: Run wall-clock perf + accuracy snapshot with per-run baseline files
.PHONY: perf-benchmark
perf-benchmark:
	@mkdir -p "$(CURDIR)/_bmad-output/perf-baselines"
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	GIANTSTEPS_CORPUS_PATH="$(GIANTSTEPS_CORPUS_PATH)" \
	PERF_BASELINE_DIR="$(CURDIR)/_bmad-output/perf-baselines" \
	GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) \
	swift test --filter BoomBoomBoomKitBenchmarkTests.PerformanceBenchmarkTests

## ablation: Run full ablation matrix against OA300 corpus
.PHONY: ablation
ablation:
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.AblationMatrixTests

## oracle: Run three-way DAW oracle comparison (ours vs Rekordbox vs DAW-verified)
.PHONY: oracle
oracle:
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.DAWOracleBenchmarkTests

## oracle-generate: Regenerate daw-oracle.json from the dawproject file
.PHONY: oracle-generate
oracle-generate:
	uv run scripts/dawproject-bpm.py "$(OA300_CORPUS_PATH)/corpus/corpus.dawproject" \
		--match Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json \
		> "$(OA300_CORPUS_PATH)/daw-oracle.json"

## fmt: Format Swift source code
.PHONY: fmt
fmt:
	swift format --recursive --in-place Sources/ Tests/

## lint: Run SwiftLint code quality checks
.PHONY: lint
lint:
	swiftlint lint .

## lint-fix: Run SwiftLint with auto-fix
.PHONY: lint-fix
lint-fix:
	swiftlint --autocorrect lint .

## clean: Remove build artifacts and SPM caches
.PHONY: clean
clean:
	swift package clean
	rm -rf .build

## deps: Resolve SPM dependencies
.PHONY: deps
deps:
	swift package resolve

## deps-update: Update SPM dependencies
.PHONY: deps-update
deps-update:
	swift package update
