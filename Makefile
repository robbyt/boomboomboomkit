# BoomBoomBoomKit Makefile

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

## build: Build the Swift package
.PHONY: build
build:
	swift build

## test: Run all tests
.PHONY: test
test:
	swift test --parallel

## test-verbose: Run tests with full output
.PHONY: test-verbose
test-verbose:
	swift test

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
