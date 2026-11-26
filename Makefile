# Convenience commands. Uses the full Xcode even if xcode-select points to the CommandLineTools.
export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

DERIVED_DATA := build/DerivedData
APP := $(DERIVED_DATA)/Build/Products/Debug/Keydex.app

.PHONY: project build run test clean

project: ## Generate Keydex.xcodeproj from project.yml
	xcodegen generate

build: project ## Build the Debug app
	xcodebuild -project Keydex.xcodeproj -scheme Keydex -configuration Debug \
		-destination "platform=macOS,arch=arm64" -derivedDataPath $(DERIVED_DATA) -quiet build

run: build ## Build, then (re)launch the app
	-@pkill -x Keydex || true
	open $(APP)

test: ## Run the unit tests of the core package
	cd Packages/KeydexCore && swift test

clean:
	rm -rf build Keydex.xcodeproj Packages/KeydexCore/.build
