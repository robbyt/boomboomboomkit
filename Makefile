# BoomBoomBoomKit Makefile

PROJECT := BoomBoomBoomKit
OA300_CORPUS_PATH ?= /Users/rterhaar/Dropbox/OA300_OnsetAudio300
GIANTSTEPS_CORPUS_PATH ?= /Users/rterhaar/Dropbox/research/giantsteps-tempo-dataset
ML_MODEL_INPUT ?= _bmad-output/ml-models/tempo_classifier.mlmodel
ML_MODEL_OUT_DIR ?= Sources/BoomBoomBoomKitML/Resources

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

## ablation: Run full 128-combination ablation matrix against OA300 corpus (ABLATION_PARALLELISM override range [1, 128]; default auto-detected)
.PHONY: ablation
ablation:
	@mkdir -p "$(CURDIR)/_bmad-output/implementation-artifacts"
ifdef ABLATION_PARALLELISM
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	ABLATION_RESULTS_DIR="$(CURDIR)/_bmad-output/implementation-artifacts" \
	ABLATION_PARALLELISM="$(ABLATION_PARALLELISM)" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.AblationMatrixTests/fullAblationMatrix
else
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	ABLATION_RESULTS_DIR="$(CURDIR)/_bmad-output/implementation-artifacts" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.AblationMatrixTests/fullAblationMatrix
endif

## ablation-smoke: Run 16 curated combos for fast cadence (honors ABLATION_PARALLELISM override; default auto-detected)
.PHONY: ablation-smoke
ablation-smoke:
ifdef ABLATION_PARALLELISM
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	ABLATION_SMOKE=1 \
	ABLATION_PARALLELISM="$(ABLATION_PARALLELISM)" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.AblationMatrixTests/smokeAblation
else
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	ABLATION_SMOKE=1 \
	swift test --filter BoomBoomBoomKitBenchmarkTests.AblationMatrixTests/smokeAblation
endif

## click-impact-report: Generate per-track click-impact JSON to _bmad-output/implementation-artifacts/3-3-click-impact-report.json
.PHONY: click-impact-report
click-impact-report:
	@mkdir -p "$(CURDIR)/_bmad-output/implementation-artifacts"
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	CLICK_IMPACT=1 \
	CLICK_IMPACT_OUT_DIR="$(CURDIR)/_bmad-output/implementation-artifacts" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.AblationMatrixTests/clickImpactReport

## duration-impact-report: Generate per-track duration-impact JSON to _bmad-output/implementation-artifacts/3-4-duration-impact-report.json
.PHONY: duration-impact-report
duration-impact-report:
	@mkdir -p "$(CURDIR)/_bmad-output/implementation-artifacts"
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	DURATION_IMPACT=1 \
	DURATION_IMPACT_OUT_DIR="$(CURDIR)/_bmad-output/implementation-artifacts" \
	swift test --filter BoomBoomBoomKitBenchmarkTests.AblationMatrixTests/durationImpactReport

## compile-model: Compile $(ML_MODEL_INPUT) (.mlmodel) into $(ML_MODEL_OUT_DIR)/<name>.mlmodelc via xcrun coremlc; override path with ML_MODEL_INPUT=...
.PHONY: compile-model
compile-model:
	@if [ ! -f "$(ML_MODEL_INPUT)" ]; then \
		echo "Error: ML_MODEL_INPUT not found at $(ML_MODEL_INPUT)."; \
		echo "Override with: make compile-model ML_MODEL_INPUT=path/to/model.mlmodel"; \
		exit 1; \
	fi
	@mkdir -p "$(ML_MODEL_OUT_DIR)"
	xcrun coremlc compile "$(ML_MODEL_INPUT)" "$(ML_MODEL_OUT_DIR)"

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
