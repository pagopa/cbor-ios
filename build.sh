#!/bin/bash
# Remove the old /archives folder
rm -rf archives

cd cbor

# iOS Simulators
xcodebuild archive \
    -scheme cbor \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "../archives/cbor-iOS-simulator.xcarchive" \
    -configuration Release \
    -sdk iphonesimulator \
    ONLY_ACTIVE_ARCH=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# iOS Devices
xcodebuild archive \
    -scheme cbor \
    -archivePath "../archives/cbor-iOS.xcarchive" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -sdk iphoneos \
    ONLY_ACTIVE_ARCH=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
# Build cbor.xcframework
xcodebuild -create-xcframework \
    -framework "../archives/cbor-iOS.xcarchive/Products/Library/Frameworks/cbor.framework" \
    -framework "../archives/cbor-iOS-simulator.xcarchive/Products/Library/Frameworks/cbor.framework" \
    -output "../archives/cbor.xcframework"