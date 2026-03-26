# BoomBoomBoomKit Makefile

PROJECT := BoomBoomBoomKit

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

## benchmark: Run OA300 accuracy benchmark (requires OA300_CORPUS_PATH env var)
##   Usage: OA300_CORPUS_PATH=/path/to/corpus make benchmark
.PHONY: benchmark
benchmark:
ifndef OA300_CORPUS_PATH
	$(error OA300_CORPUS_PATH is not set. Usage: OA300_CORPUS_PATH=/path/to/corpus make benchmark)
endif
	OA300_CORPUS_PATH=$(OA300_CORPUS_PATH) swift test --filter OA300BenchmarkTests

## ablation: Run full ablation matrix against OA300 corpus
##   Usage: OA300_CORPUS_PATH=/path/to/corpus make ablation
.PHONY: ablation
ablation:
ifndef OA300_CORPUS_PATH
	$(error OA300_CORPUS_PATH is not set. Usage: OA300_CORPUS_PATH=/path/to/corpus make ablation)
endif
	OA300_CORPUS_PATH=$(OA300_CORPUS_PATH) swift test --filter AblationMatrixTests

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
