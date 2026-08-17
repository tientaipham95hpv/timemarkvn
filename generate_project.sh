#!/bin/bash
set -euo pipefail

APP="TimeMarkVN"
BUNDLE="com.timemarkvn.app"
DEPLOYMENT="17.0"

cat > project.yml <<YAML
name: TimeMarkVN
options:
  minimumXcodeGenVersion: 2.38.0
settings:
  base:
    SWIFT_VERSION: 5.0
    IPHONEOS_DEPLOYMENT_TARGET: $(echo "$DEPLOYMENT")
targets:
  TimeMarkVN:
    type: application
    platform: iOS
    deploymentTarget: $(echo "$DEPLOYMENT")
    sources:
      - path: TimeMarkVN
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $(echo "$BUNDLE")
        INFOPLIST_FILE: TimeMarkVN/Info.plist
        CODE_SIGN_ENTITLEMENTS: TimeMarkVN/TimeMarkVN.entitlements
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        TARGETED_DEVICE_FAMILY: "1,2"
        SUPPORTS_MACCATALYST: false
        SWIFT_VERSION: 5.0
        CODE_SIGN_STYLE: Manual
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_IDENTITY: ""
        PROVISIONING_PROFILE_SPECIFIER: ""
YAML

brew install xcodegen
xcodegen generate
