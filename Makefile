# BoomBoomBoomKit Makefile

PROJECT := BoomBoomBoomKit
OA300_CORPUS_PATH ?= /Users/rterhaar/Dropbox/OA300_OnsetAudio300
GIANTSTEPS_CORPUS_PATH ?= /Users/rterhaar/Dropbox/research/giantsteps-tempo-dataset
ML_MODEL_INPUT ?= _bmad-output/ml-models/giantsteps_v1.mlmodel
ML_MODEL_OUT_DIR ?= _bmad-output/ml-models
BNNS_IMPACT_OUT_DIR ?= $(CURDIR)/_bmad-output/perf-baselines/bnns-impact

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

## demo-build: Build the BoomBoomBoomKitDemo macOS app (Debug, no code signing — Story 5-1 DD #6)
.PHONY: demo-build
demo-build:
	xcodebuild \
		-project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj \
		-scheme BoomBoomBoomKitDemo \
		-destination 'platform=macOS' \
		-configuration Debug \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_IDENTITY="" \
		build

## demo-test: Run BoomBoomBoomKitDemo tests via the app scheme + xctestplan (Story 5-7 2026-05-24 fourth-pass review D1 — committing only the app scheme makes Xcode stop auto-generating the Tests scheme, so the Makefile uses `-scheme BoomBoomBoomKitDemo -testPlan BoomBoomBoomKitDemo` instead). Modern Xcode 26 convention: xctestplan is the canonical test-config entry point.
.PHONY: demo-test
demo-test:
	xcodebuild \
		-project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj \
		-scheme BoomBoomBoomKitDemo \
		-testPlan BoomBoomBoomKitDemo \
		-destination 'platform=macOS' \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_IDENTITY="" \
		test

## demo-build-sandboxed: Build the BoomBoomBoomKitDemo macOS app with signing enabled so the app-sandbox entitlements actually attach at launch (Story 5-1 code review D4). Requires a configured signing identity (Xcode > Settings > Accounts, OR invoke with DEVELOPMENT_TEAM=<your-team-id> make demo-build-sandboxed — the env var is threaded into xcodebuild per PR #3 Copilot review 2026-05-19 / W14 closure); does NOT pass CODE_SIGNING_ALLOWED=NO. Use to reproduce sandbox bugs that demo-build cannot exercise; not for fresh-clone CI.
.PHONY: demo-build-sandboxed
demo-build-sandboxed:
	xcodebuild \
		-project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj \
		-scheme BoomBoomBoomKitDemo \
		-destination 'platform=macOS' \
		-configuration Debug \
		DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) \
		build

## demo-archive: Produce a signed App Store archive at build/BoomBoomBoomKitDemo.xcarchive. Requires DEVELOPMENT_TEAM=<team-id> in the environment (Story 5-7 AC #3, mirrors the demo-build-sandboxed W14 pattern; whitespace-only values are rejected via $(strip ...) per Story 5-7 review patch). Does NOT auto-upload; xcodebuild -exportArchive or Xcode Organizer handle the final submission step (user owns App Store Connect distribution per Story 5-7 OUT-OF-SCOPE). Failing fast on unset DEVELOPMENT_TEAM prevents an unsigned archive from being silently produced. Stale-archive preflight (rm -rf) added per Story 5-7 review patch to match sibling compile-model idempotency.
.PHONY: demo-archive
override DEVELOPMENT_TEAM := $(strip $(DEVELOPMENT_TEAM))
demo-archive:
ifndef DEVELOPMENT_TEAM
	$(error DEVELOPMENT_TEAM is not set. Invoke as: DEVELOPMENT_TEAM=ABC1234DEF make demo-archive)
endif
	@rm -rf build/BoomBoomBoomKitDemo.xcarchive
	xcodebuild \
		-project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj \
		-scheme BoomBoomBoomKitDemo \
		-destination 'generic/platform=macOS' \
		-configuration Release \
		-archivePath build/BoomBoomBoomKitDemo.xcarchive \
		-allowProvisioningUpdates \
		DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) \
		archive

## demo-bump-build: Increment CURRENT_PROJECT_VERSION (CFBundleVersion) in pbxproj before the next archive. Closes the ITMS-90062 round-trip risk surfaced by Story 5-7 review. Implemented as `scripts/demo-bump-build.py` (stdlib-only Python) per operator directive 2026-05-24 — the original shell-pipeline form went through three rounds of churn in 48 hours and was extracted to Python to stop the fragility cycle (recurring review flags around BSD-vs-GNU sed, regex anchoring, shell quoting, arithmetic edge cases). The Python form enforces the same invariants more robustly: every CURRENT_PROJECT_VERSION assignment must parse as an integer (hard error on mixed integer/non-integer pbxproj state, no partial bump possible); all assignments converge to MAX+1 in one rewrite; post-rewrite count verification refuses to write if the substitution touched only a subset. Run as: `make demo-bump-build` (then `DEVELOPMENT_TEAM=<id> make demo-archive`).
.PHONY: demo-bump-build
demo-bump-build:
	uv run scripts/demo-bump-build.py

## demo-fmt: Format Swift source code under Demo/ (sibling of `fmt`, which covers Sources/Tests only)
.PHONY: demo-fmt
demo-fmt:
	swift format --recursive --in-place Demo/

## demo-lint: Guard against DEVELOPMENT_TEAM leak across all Demo/.pbxproj files (Story 5-2 W16 close-out — regex covers both quoted and unquoted Xcode-emitted team-ID forms)
.PHONY: demo-lint
demo-lint:
	@if grep -rnE 'DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*"?[A-Z0-9]{10}"?[[:space:]]*;' Demo/ --include='project.pbxproj'; then \
		echo "ERROR: DEVELOPMENT_TEAM leak detected in Demo/ .pbxproj — must be empty for public release."; \
		exit 1; \
	fi

## pre-commit: Run all pre-PR gates (library + demo fmt + lint). NOT a git hook — runs on demand
.PHONY: pre-commit
pre-commit: fmt demo-fmt lint demo-lint

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

## ml-policy-sweep: Generate per-policy ml-policy-sweep JSON to _bmad-output/implementation-artifacts/4-4-ml-policy-sweep.json
.PHONY: ml-policy-sweep
ml-policy-sweep:
	@mkdir -p "$(CURDIR)/_bmad-output/implementation-artifacts"
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	ML_POLICY_SWEEP=1 \
	ML_POLICY_SWEEP_OUT_DIR="$(CURDIR)/_bmad-output/implementation-artifacts" \
	GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) \
	swift test --filter BoomBoomBoomKitBenchmarkTests.MLPolicySweepTests/policySweepReport

## super-flux-impact-report: Generate per-track SuperFlux impact JSON to _bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json
.PHONY: super-flux-impact-report
super-flux-impact-report:
	@mkdir -p "$(CURDIR)/_bmad-output/implementation-artifacts"
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	SPECTRAL_FLUX_IMPACT=1 \
	SUPER_FLUX_IMPACT_OUT_DIR="$(CURDIR)/_bmad-output/implementation-artifacts" \
	GIT_SHA=$$( \
	  SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown); \
	  DIRTY=$$( [ -n "$$(git status --porcelain 2>/dev/null)" ] && echo "-dirty" || echo "" ); \
	  echo "$$SHA$$DIRTY" \
	) \
	XCODE_VERSION=$$( \
	  V=""; \
	  if command -v xcodebuild >/dev/null 2>&1; then \
	    V=$$(xcodebuild -version 2>/dev/null | awk '/^Xcode/ {print $$2; exit}'); \
	  fi; \
	  if [ -z "$$V" ]; then echo unknown; else echo "$$V"; fi \
	) \
	SWIFT_VERSION=$$( \
	  V=$$(swift --version 2>/dev/null | sed -nE 's/.*Swift version ([^ ]+).*/\1/p' | head -n1); \
	  if [ -z "$$V" ]; then echo unknown; else echo "$$V"; fi \
	) \
	swift test --filter BoomBoomBoomKitBenchmarkTests.SuperFluxImpactTests/superFluxImpactReport

## bnns-impact-report: Generate per-track BNNS impact JSON to $(BNNS_IMPACT_OUT_DIR)
.PHONY: bnns-impact-report
bnns-impact-report:
	@mkdir -p "$(BNNS_IMPACT_OUT_DIR)"
	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
	BNNS_IMPACT=1 \
	BNNS_IMPACT_OUT_DIR="$(BNNS_IMPACT_OUT_DIR)" \
	GIT_SHA=$$( \
	  SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown); \
	  DIRTY=$$( [ -n "$$(git status --porcelain 2>/dev/null)" ] && echo "-dirty" || echo "" ); \
	  echo "$$SHA$$DIRTY" \
	) \
	swift test --filter BoomBoomBoomKitBenchmarkTests.BNNSImpactTests/bnnsImpactReport

## compile-model: Compile $(ML_MODEL_INPUT) (.mlmodel or .mlpackage directory bundle) into $(ML_MODEL_OUT_DIR)/<name>.mlmodelc via xcrun coremlc. Develop-only — Story 4-6 retargeted the default output to _bmad-output/ml-models/ (was Sources/BoomBoomBoomKitML/Resources/ pre-Branch-C). Override path with ML_MODEL_INPUT=... or ML_MODEL_OUT_DIR=...; consumers don't run this target.
.PHONY: compile-model
compile-model:
	@if [ ! -e "$(ML_MODEL_INPUT)" ]; then \
		echo "Error: ML_MODEL_INPUT not found at $(ML_MODEL_INPUT)."; \
		echo "Override with: make compile-model ML_MODEL_INPUT=path/to/model.mlmodel"; \
		exit 1; \
	fi
	@mkdir -p "$(ML_MODEL_OUT_DIR)"
	@MODEL_NAME=$$(basename "$(ML_MODEL_INPUT)"); \
	MODEL_BASE=$${MODEL_NAME%.*}; \
	rm -rf "$(ML_MODEL_OUT_DIR)/$$MODEL_BASE.mlmodelc"
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

# ---------------------------------------------------------------------------
# ML training pipeline + tools/coreml-convert/ shortcuts.
#
# The ml-train / ml-eval / ml-export / ml-pipeline targets require the
# develop-only _bmad-output/ml-training/ directory and fail loudly on a
# main-only checkout — consumers shouldn't run them. The ml-convert /
# ml-convert-tests targets drive the consumer-facing tools/coreml-convert/
# CLI, which DOES ship to main.
# ---------------------------------------------------------------------------

ML_TRAINING_DIR := _bmad-output/ml-training
TOOLS_CONVERT_DIR := tools/coreml-convert
TRAIN_SEED ?= 42
TRAIN_EPOCHS ?= 60
TRAIN_BATCH ?= 32
TRAIN_WORKERS ?= 4

## ml-train-deps: Sync Python deps for the training pipeline (idempotent)
.PHONY: ml-train-deps
ml-train-deps:
	cd $(ML_TRAINING_DIR) && uv sync --locked

## ml-dump-fixture: Build feature_pipeline_v1.npz from Swift CLI + Python wrapper
.PHONY: ml-dump-fixture
ml-dump-fixture:
	cd $(ML_TRAINING_DIR)/swift_feature_extractor && swift run dump-fixture
	cd $(ML_TRAINING_DIR) && uv run python build_fixture.py

## ml-parity: Run 4-stage Swift/Python feature-pipeline parity harness
.PHONY: ml-parity
ml-parity:
	cd $(ML_TRAINING_DIR) && uv run python test_feature_parity.py

## ml-splits: Build corpus_splits.json with leak and DnB-triplet checks
.PHONY: ml-splits
ml-splits:
	cd $(ML_TRAINING_DIR) && uv run python dataset.py

## ml-summary: Regenerate model_summary.txt and model_metadata.json
.PHONY: ml-summary
ml-summary:
	cd $(ML_TRAINING_DIR) && uv run python model.py

## ml-train-smoke: Smoke train (1 epoch, 32 tracks; should complete in <2 min — slower means MPS likely fell back to CPU)
.PHONY: ml-train-smoke
ml-train-smoke:
	cd $(ML_TRAINING_DIR) && uv run python train.py \
		--seed $(TRAIN_SEED) --epochs 1 --subset 32 --num-workers $(TRAIN_WORKERS)

## ml-train: Full training run (60 epochs default). Override TRAIN_EPOCHS / TRAIN_SEED / TRAIN_BATCH / TRAIN_WORKERS as needed.
.PHONY: ml-train
ml-train:
	cd $(ML_TRAINING_DIR) && uv run python train.py \
		--seed $(TRAIN_SEED) --epochs $(TRAIN_EPOCHS) \
		--batch-size $(TRAIN_BATCH) --num-workers $(TRAIN_WORKERS)

## ml-train-resume: Resume training from a checkpoint (CHECKPOINT=path/to/epoch_N.pt; project-root-relative paths are resolved automatically)
.PHONY: ml-train-resume
ml-train-resume:
ifndef CHECKPOINT
	$(error CHECKPOINT is not set. Usage: make ml-train-resume CHECKPOINT=$(ML_TRAINING_DIR)/checkpoints/epoch_044.pt)
endif
	@RESUME_PATH=$$(cd $(CURDIR) && python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" $(CHECKPOINT)) && \
	cd $(ML_TRAINING_DIR) && uv run python train.py \
		--seed $(TRAIN_SEED) --epochs $(TRAIN_EPOCHS) \
		--batch-size $(TRAIN_BATCH) --num-workers $(TRAIN_WORKERS) \
		--resume "$$RESUME_PATH"

## ml-eval: Evaluate trained model on OA300 held-out test set
.PHONY: ml-eval
ml-eval:
	cd $(ML_TRAINING_DIR) && uv run python eval.py \
		--checkpoint model.pt --test-corpus oa300

## ml-export: Export trained checkpoint to CoreML .mlmodel
.PHONY: ml-export
ml-export:
	@mkdir -p "$(CURDIR)/_bmad-output/ml-models"
	cd $(ML_TRAINING_DIR) && uv run python export.py \
		--checkpoint model.pt --output ../ml-models/giantsteps_v1.mlmodel

## ml-convert: Run the consumer-facing convert tool on the dev-only reference checkpoint as a smoke test
.PHONY: ml-convert
ml-convert:
	cd $(TOOLS_CONVERT_DIR) && uv sync --locked
	@TMPOUT=$$(mktemp -d)/coreml-convert-test.mlmodelc && \
	cd $(TOOLS_CONVERT_DIR) && uv run python convert.py \
		--checkpoint $(CURDIR)/$(ML_TRAINING_DIR)/model.pt \
		--arch reference \
		--output "$$TMPOUT" \
		--validate

## ml-convert-tests: Run pytest suite for tools/coreml-convert/
.PHONY: ml-convert-tests
ml-convert-tests:
	cd $(TOOLS_CONVERT_DIR) && uv run pytest tests/

## ml-pipeline: Post-training gate run — fixture → parity → eval → export → compile (assumes ml-train has already produced model.pt)
.PHONY: ml-pipeline
ml-pipeline: ml-dump-fixture ml-parity ml-eval ml-export compile-model

# ---------------------------------------------------------------------------
# Tony's private corpus (Rekordbox XML export + on-disk audio under
# /Users/rterhaar/Dropbox/tony-tunes/). Develop-only.
# ---------------------------------------------------------------------------

TONY_XML ?= /Users/rterhaar/Dropbox/tony-tunes/05092026.xml
TONY_AUDIO_ROOT ?= /Users/rterhaar/Dropbox/tony-tunes
TONY_CORPUS_DIR := _bmad-output/ml-training/tony-corpus
TONY_MISSING_TXT ?= $(TONY_AUDIO_ROOT)/missing-tracks.txt

## tony-survey: Parse Rekordbox XML, resolve on-disk paths, dump survey JSON + missing-tracks.txt
.PHONY: tony-survey
tony-survey:
	@mkdir -p "$(CURDIR)/$(TONY_CORPUS_DIR)"
	uv run scripts/tony-tunes-survey.py "$(TONY_XML)" \
		--audio-root "$(TONY_AUDIO_ROOT)" \
		--write-missing "$(TONY_MISSING_TXT)" \
		> "$(CURDIR)/$(TONY_CORPUS_DIR)/tony-survey.json"

## tony-dsp-prepass: Run BoomBoomBoomKit DSP against each resolved track and dump per-track bpm/confidence
.PHONY: tony-dsp-prepass
tony-dsp-prepass:
	@mkdir -p "$(CURDIR)/$(TONY_CORPUS_DIR)"
	cd $(ML_TRAINING_DIR)/swift_feature_extractor && \
		swift run -c release tony-dsp-prepass \
			--survey-json "$(CURDIR)/$(TONY_CORPUS_DIR)/tony-survey.json" \
			--output "$(CURDIR)/$(TONY_CORPUS_DIR)/tony-dsp-prepass.json"

## tony-labels: Derive bpm_truth labels from the 5 noisy signals (Codex strategy 4+6)
.PHONY: tony-labels
tony-labels:
	uv run scripts/tony-tunes-labels.py \
		--survey-json "$(CURDIR)/$(TONY_CORPUS_DIR)/tony-survey.json" \
		--dsp-json    "$(CURDIR)/$(TONY_CORPUS_DIR)/tony-dsp-prepass.json" \
		--output      "$(CURDIR)/$(TONY_CORPUS_DIR)/tony-truth-labels.json"

## tony-corpus: Full pipeline — survey → DSP prepass → labeler
.PHONY: tony-corpus
tony-corpus: tony-survey tony-dsp-prepass tony-labels
