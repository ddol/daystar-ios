# Daystar — local iOS development build.
#
#   make run             build the dev app and launch it in the iOS Simulator
#   make help            every target, with a description
#   make doctor          check this machine has what the build needs
#
# Override any variable on the command line, e.g.
#   make run DEVICE="iPhone 16 Pro"
#   make ipa TEAM_ID=ABCDE12345

PROJECT        := Daystar.xcodeproj
SCHEME         := Daystar
CONFIG         ?= Debug
BUNDLE_ID      ?= dev.daystar.app

DERIVED_DATA   := build/DerivedData
BUILD_DIR      := build
ARCHIVE_PATH   := $(BUILD_DIR)/$(SCHEME).xcarchive
EXPORT_DIR     := $(BUILD_DIR)/export
APP_PATH        = $(DERIVED_DATA)/Build/Products/$(CONFIG)-iphonesimulator/$(SCHEME).app

# Simulator target. DEVICE is matched by name against the available device list.
DEVICE         ?= iPhone 17 Pro

# Asset pipeline.
ASSET_CATALOG  := App/Daystar/Assets.xcassets
APP_ICON_PNG   := $(ASSET_CATALOG)/AppIcon.appiconset/icon-1024.png
ASSETS_OUT     := $(BUILD_DIR)/assets
DEPLOY_TARGET  := 17.0

# Signing. Simulator builds are ad-hoc signed ("-"), which needs no Apple account.
# Device builds and IPA export need a real team: make ipa TEAM_ID=ABCDE12345
SIGN_IDENTITY  ?= -
TEAM_ID        ?=

XCODEBUILD     := xcodebuild
XCPRETTIFY     := 2>&1 | grep -E "error:|warning:|\*\* [A-Z]+ [A-Z]+" || true

.DEFAULT_GOAL := help
.PHONY: help doctor test check build run sim boot install launch logs assets icon clean clean-all \
        device archive ipa sign verify identities open bootstrap-sim

## help: show this list
help:
	@echo "Daystar — make targets"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /' | awk -F': ' '{printf "  \033[1m%-16s\033[0m %s\n", $$1, $$2}' | sed 's/^  //'
	@echo ""
	@echo "  Variables: CONFIG=$(CONFIG) DEVICE=\"$(DEVICE)\" BUNDLE_ID=$(BUNDLE_ID) TEAM_ID=$(TEAM_ID)"

## doctor: check toolchain, simulator runtimes and signing identities
doctor:
	@echo "== Toolchain =="
	@xcodebuild -version | sed 's/^/  /'
	@echo "  $$(swift --version 2>&1 | head -1)"
	@echo "  xcode-select: $$(xcode-select -p)"
	@echo ""
	@echo "== iOS Simulator runtimes =="
	@if [ -z "$$(xcrun simctl list runtimes -j | grep -c '"identifier"' | grep -v '^0$$')" ]; then \
	  echo "  none installed  ->  run 'make bootstrap-sim' (multi-GB download)"; \
	else \
	  xcrun simctl list runtimes | grep -E "^iOS" | sed 's/^/  /'; \
	fi
	@echo ""
	@echo "== Matching simulator =="
	@udid=$$($(MAKE) -s _device_udid 2>/dev/null); \
	  if [ -n "$$udid" ]; then echo "  $(DEVICE)  $$udid"; else echo "  no booted-or-creatable '$(DEVICE)' (needs a runtime)"; fi
	@echo ""
	@echo "== Signing identities =="
	@security find-identity -v -p codesigning | sed 's/^/  /' || echo "  none"

## test: run the offline solar/UV engine tests (SwiftPM — see note below)
# The suite lives in the daystar-ios package, so SwiftPM is its runner. `xcodebuild test
# -scheme Daystar` has no bundle to run and errors out; it does not report a false pass.
test:
	swift test

## check: everything CI should run — engine tests plus a simulator build
check: test build

## assets: generate the app icon and compile the asset catalog
assets: icon
	@mkdir -p $(ASSETS_OUT)
	xcrun actool $(ASSET_CATALOG) \
	  --compile $(ASSETS_OUT) \
	  --platform iphonesimulator \
	  --minimum-deployment-target $(DEPLOY_TARGET) \
	  --target-device iphone --target-device ipad \
	  --app-icon AppIcon \
	  --accent-color AccentColor \
	  --output-partial-info-plist $(ASSETS_OUT)/assets-partial.plist \
	  --output-format human-readable-text
	@echo "assets -> $(ASSETS_OUT)/Assets.car"

## icon: redraw the 1024px app icon from Scripts/make-appicon.swift
icon:
	swift Scripts/make-appicon.swift $(APP_ICON_PNG)

## build: build the dev app for the iOS Simulator (ad-hoc signed)
build:
	$(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) \
	  -destination 'generic/platform=iOS Simulator' \
	  -derivedDataPath $(DERIVED_DATA) \
	  CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES \
	  PRODUCT_BUNDLE_IDENTIFIER=$(BUNDLE_ID) \
	  build $(XCPRETTIFY)
	@test -d "$(APP_PATH)" && echo "app -> $(APP_PATH)"

sim: build

## run: build, boot the simulator, install and launch
run: build boot install launch
	@echo "Launched $(BUNDLE_ID) on $(DEVICE)."

## boot: boot the target simulator (creates it if the runtime allows)
boot:
	@udid=$$($(MAKE) -s _device_udid); \
	if [ -z "$$udid" ]; then \
	  echo "No simulator named '$(DEVICE)' is available."; \
	  echo "Installed iOS runtimes:"; xcrun simctl list runtimes | grep -E "^iOS" || echo "  (none)"; \
	  echo "Run 'make bootstrap-sim' to download an iOS simulator runtime, or pass DEVICE=\"<name>\"."; \
	  exit 1; \
	fi; \
	state=$$(xcrun simctl list devices -j | python3 -c "import json,sys;d=json.load(sys.stdin)['devices'];print(next((x['state'] for v in d.values() for x in v if x['udid']=='$$udid'),''))"); \
	if [ "$$state" != "Booted" ]; then xcrun simctl boot "$$udid"; fi; \
	open -a Simulator --args -CurrentDeviceUDID "$$udid"; \
	xcrun simctl bootstatus "$$udid" -b >/dev/null

## install: install the built .app onto the booted simulator
install:
	@test -d "$(APP_PATH)" || { echo "No app at $(APP_PATH). Run 'make build' first."; exit 1; }
	@udid=$$($(MAKE) -s _device_udid); xcrun simctl install "$$udid" "$(APP_PATH)"
	@echo "installed $(APP_PATH)"

## launch: launch the installed app on the booted simulator
launch:
	@udid=$$($(MAKE) -s _device_udid); xcrun simctl launch "$$udid" $(BUNDLE_ID)

## logs: stream this app's simulator log output
logs:
	@udid=$$($(MAKE) -s _device_udid); \
	xcrun simctl spawn "$$udid" log stream --level debug --style compact \
	  --predicate 'subsystem CONTAINS "$(BUNDLE_ID)" OR processImagePath CONTAINS "$(SCHEME)"'

## sign: (re-)sign the built simulator app with SIGN_IDENTITY (default ad-hoc "-")
sign:
	@test -d "$(APP_PATH)" || { echo "No app at $(APP_PATH). Run 'make build' first."; exit 1; }
	codesign --force --sign "$(SIGN_IDENTITY)" --timestamp=none "$(APP_PATH)"
	@echo "signed $(APP_PATH) with identity: $(SIGN_IDENTITY)"

## verify: check the code signature on the built app
verify:
	@test -d "$(APP_PATH)" || { echo "No app at $(APP_PATH). Run 'make build' first."; exit 1; }
	codesign --verify --strict --verbose=2 "$(APP_PATH)"
	codesign --display --verbose=4 "$(APP_PATH)" 2>&1 | grep -E "Identifier|Authority|Signature|TeamIdentifier|flags"

## identities: list code-signing identities available in the keychain
identities:
	@security find-identity -v -p codesigning

## device: build for a physical iPhone (needs TEAM_ID)
device:
	@test -n "$(TEAM_ID)" || { echo "Set a team: make device TEAM_ID=ABCDE12345  (see 'make identities')"; exit 1; }
	$(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) \
	  -destination 'generic/platform=iOS' \
	  -derivedDataPath $(DERIVED_DATA) \
	  -allowProvisioningUpdates \
	  DEVELOPMENT_TEAM=$(TEAM_ID) CODE_SIGN_STYLE=Automatic \
	  PRODUCT_BUNDLE_IDENTIFIER=$(BUNDLE_ID) \
	  build $(XCPRETTIFY)

## archive: build a signed release archive (needs TEAM_ID)
archive:
	@test -n "$(TEAM_ID)" || { echo "Set a team: make archive TEAM_ID=ABCDE12345"; exit 1; }
	$(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
	  -destination 'generic/platform=iOS' \
	  -archivePath $(ARCHIVE_PATH) \
	  -allowProvisioningUpdates \
	  DEVELOPMENT_TEAM=$(TEAM_ID) CODE_SIGN_STYLE=Automatic \
	  PRODUCT_BUNDLE_IDENTIFIER=$(BUNDLE_ID) \
	  archive $(XCPRETTIFY)
	@echo "archive -> $(ARCHIVE_PATH)"

## ipa: export a signed development .ipa from the archive (needs TEAM_ID)
ipa: archive
	@mkdir -p $(EXPORT_DIR)
	@printf '%s\n' \
	  '<?xml version="1.0" encoding="UTF-8"?>' \
	  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
	  '<plist version="1.0"><dict>' \
	  '  <key>method</key><string>development</string>' \
	  '  <key>teamID</key><string>$(TEAM_ID)</string>' \
	  '  <key>signingStyle</key><string>automatic</string>' \
	  '  <key>stripSwiftSymbols</key><true/>' \
	  '  <key>compileBitcode</key><false/>' \
	  '</dict></plist>' > $(BUILD_DIR)/ExportOptions.plist
	$(XCODEBUILD) -exportArchive \
	  -archivePath $(ARCHIVE_PATH) \
	  -exportPath $(EXPORT_DIR) \
	  -exportOptionsPlist $(BUILD_DIR)/ExportOptions.plist \
	  -allowProvisioningUpdates $(XCPRETTIFY)
	@echo "ipa -> $(EXPORT_DIR)/$(SCHEME).ipa"

## bootstrap-sim: download an iOS Simulator runtime (several GB)
bootstrap-sim:
	$(XCODEBUILD) -downloadPlatform iOS

## open: open the project in Xcode
open:
	open $(PROJECT)

## clean: remove build products
clean:
	rm -rf $(BUILD_DIR)
	$(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) clean $(XCPRETTIFY)

## clean-all: remove build products and the SwiftPM cache
clean-all: clean
	rm -rf .build

# Resolve the UDID for DEVICE: prefer an existing device, otherwise create one on the
# newest installed iOS runtime. Prints nothing when no runtime is installed.
.PHONY: _device_udid
_device_udid:
	@xcrun simctl list devices available -j | python3 -c "$$FIND_DEVICE" "$(DEVICE)" || true

define FIND_DEVICE_PY
import json, re, subprocess, sys
name = sys.argv[1]
data = json.load(sys.stdin)["devices"]

def runtime_key(identifier):
    nums = re.findall(r"\d+", identifier.rsplit(".", 1)[-1])
    return [int(n) for n in nums] or [0]

ios = {rt: devs for rt, devs in data.items() if "iOS" in rt and devs}

# An already-booted match wins, then any existing match on the newest runtime.
for rt in sorted(ios, key=runtime_key, reverse=True):
    for dev in ios[rt]:
        if dev["name"] == name and dev.get("state") == "Booted":
            print(dev["udid"]); sys.exit()
for rt in sorted(ios, key=runtime_key, reverse=True):
    for dev in ios[rt]:
        if dev["name"] == name:
            print(dev["udid"]); sys.exit()

# Otherwise create it on the newest installed runtime.
runtimes = json.loads(subprocess.run(
    ["xcrun", "simctl", "list", "runtimes", "-j"], capture_output=True, text=True).stdout)["runtimes"]
usable = [r for r in runtimes if r.get("isAvailable") and "iOS" in r["identifier"]]
if not usable:
    sys.exit()
newest = sorted(usable, key=lambda r: runtime_key(r["identifier"]))[-1]
types = json.loads(subprocess.run(
    ["xcrun", "simctl", "list", "devicetypes", "-j"], capture_output=True, text=True).stdout)["devicetypes"]
match = next((t for t in types if t["name"] == name), None)
if not match:
    sys.exit()
created = subprocess.run(
    ["xcrun", "simctl", "create", name, match["identifier"], newest["identifier"]],
    capture_output=True, text=True)
if created.returncode == 0:
    print(created.stdout.strip())
endef
export FIND_DEVICE = $(value FIND_DEVICE_PY)
