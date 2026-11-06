SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

PROJECT := Zumpt.xcodeproj
SCHEME := Zumpt
DERIVED_DATA := .build/DerivedData
APP := $(DERIVED_DATA)/Build/Products/Debug/Zumpt.app
XCODEBUILD := xcodebuild -quiet -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS,arch=$(shell uname -m)' -derivedDataPath $(DERIVED_DATA)
SWIFT_SOURCES := App UITests Packages/ZumptKit/Package.swift Packages/ZumptKit/Sources Packages/ZumptKit/Tests

.PHONY: generate build run test test-unit test-ui lint format clean

generate:
	xcodegen generate --quiet

build: generate
	$(XCODEBUILD) build

run: build
	pkill -x Zumpt || true
	open $(APP)

test: test-unit test-ui

test-unit:
	swift test --package-path Packages/ZumptKit

test-ui: generate
	$(XCODEBUILD) test

lint:
	swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)

format:
	swift format --in-place --recursive --parallel $(SWIFT_SOURCES)

clean:
	rm -rf .build Packages/ZumptKit/.build $(PROJECT)
