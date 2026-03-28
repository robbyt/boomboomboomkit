# BoomBoomBoomKit Makefile

PROJECT := BoomBoomBoomKit
OA300_CORPUS_PATH ?= /Users/rterhaar/Dropbox/OA300_OnsetAudio300

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

## test: Run all tests (concise output)
.PHONY: test
test:
	swift test --parallel

## test-verbose: Run tests with full streaming output
.PHONY: test-verbose
test-verbose:
	swift test

## test-filter: Run a specific test suite (usage: make test-filter SUITE=BPMAnalyzer120BPMTests)
.PHONY: test-filter
test-filter:
ifndef SUITE
	$(error SUITE is not set. Usage: make test-filter SUITE=BPMAnalyzer120BPMTests)
endif
	swift test --filter $(SUITE)

## benchmark: Run OA300 accuracy benchmark
.PHONY: benchmark
benchmark:
	OA300_CORPUS_PATH=$(OA300_CORPUS_PATH) swift test --filter OA300BenchmarkTests

## ablation: Run full ablation matrix against OA300 corpus
.PHONY: ablation
ablation:
	OA300_CORPUS_PATH=$(OA300_CORPUS_PATH) swift test --filter AblationMatrixTests

## oracle: Run three-way DAW oracle comparison (ours vs Rekordbox vs DAW-verified)
.PHONY: oracle
oracle:
	OA300_CORPUS_PATH=$(OA300_CORPUS_PATH) swift test --filter DAWOracleBenchmarkTests

## oracle-generate: Regenerate daw-oracle.json from the dawproject file
.PHONY: oracle-generate
oracle-generate:
	uv run scripts/dawproject-bpm.py $(OA300_CORPUS_PATH)/corpus/corpus.dawproject \
		--match Tests/BoomBoomBoomKitTests/Fixtures/oa300-ground-truth.json \
		> $(OA300_CORPUS_PATH)/daw-oracle.json

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
