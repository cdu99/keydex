# Convenience commands. Uses the full Xcode even if xcode-select points to the CommandLineTools.
export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

# ".noindex": Spotlight ignores the folder, so the built apps do not show up next to the
# installed one (/Applications/Keydex.app).
DERIVED_DATA := build/DerivedData.noindex
APP := $(DERIVED_DATA)/Build/Products/Debug/Keydex.app
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/Keydex.app
INSTALL_DIR := /Applications

.PHONY: project build run test release install clean

project: ## Generate Keydex.xcodeproj from project.yml
	xcodegen generate

build: project ## Build the Debug app
	xcodebuild -project Keydex.xcodeproj -scheme Keydex -configuration Debug \
		-destination "platform=macOS,arch=arm64" -derivedDataPath $(DERIVED_DATA) -quiet build

run: build ## Build, then (re)launch the app
	-@pkill -x Keydex || true
	open $(APP)

release: project ## Build the optimized Release app
	xcodebuild -project Keydex.xcodeproj -scheme Keydex -configuration Release \
		-destination "platform=macOS,arch=arm64" -derivedDataPath $(DERIVED_DATA) -quiet build

install: release ## Install the Release app in /Applications (needed for launch at login), then launch it
	-@pkill -x Keydex || true
	rm -rf "$(INSTALL_DIR)/Keydex.app"
	cp -R "$(RELEASE_APP)" "$(INSTALL_DIR)/"
	open "$(INSTALL_DIR)/Keydex.app"

test: ## Run the unit tests of the core package
	cd Packages/KeydexCore && swift test

clean:
	rm -rf build Keydex.xcodeproj Packages/KeydexCore/.build
