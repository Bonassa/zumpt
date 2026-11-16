SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

PROJECT := Zumpt.xcodeproj
SCHEME := Zumpt
DERIVED_DATA := .build/DerivedData
APP := $(DERIVED_DATA)/Build/Products/Debug/Zumpt.app
XCODEBUILD := xcodebuild -quiet -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS,arch=$(shell uname -m)' -derivedDataPath $(DERIVED_DATA)
SWIFT_SOURCES := App UITests Packages/ZumptKit/Package.swift Packages/ZumptKit/Sources Packages/ZumptKit/Tests

# CI has no Apple Development certificate, so it signs ad hoc.
ifdef CI
XCODEBUILD += CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=
endif

# make test-ui ONLY=DragTasksTests or ONLY=DragTasksTests/testUndoesAndRedoesAMove,BacklogTests
comma := ,
ONLY_TESTING := $(foreach test,$(subst $(comma), ,$(ONLY)),-only-testing:ZumptUITests/$(test))

.PHONY: generate build run test test-all test-unit test-ui lint format clean

generate:
	xcodegen generate --quiet

build: generate
	$(XCODEBUILD) build

run: build
	pkill -x Zumpt || true
	open $(APP)

test: test-unit

test-all: test-unit test-ui

test-unit:
	swift test --package-path Packages/ZumptKit

test-ui: generate
	$(XCODEBUILD) test $(ONLY_TESTING)

lint:
	swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)

format:
	swift format --in-place --recursive --parallel $(SWIFT_SOURCES)

clean:
	rm -rf .build Packages/ZumptKit/.build $(PROJECT)
