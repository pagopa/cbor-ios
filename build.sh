#!/bin/bash
# Remove the old /archives folder
rm -rf archives

cd IOWalletCBOR

# iOS Simulators
xcodebuild archive \
    -scheme IOWalletCBOR \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "../archives/IOWalletCBOR-iOS-simulator.xcarchive" \
    -configuration Release \
    -sdk iphonesimulator

# iOS Devices
xcodebuild archive \
    -scheme IOWalletCBOR \
    -archivePath "../archives/IOWalletCBOR-iOS.xcarchive" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -sdk iphoneos
    
# Build cbor.xcframework
xcodebuild -create-xcframework \
    -framework "../archives/IOWalletCBOR-iOS.xcarchive/Products/Library/Frameworks/IOWalletCBOR.framework" \
    -framework "../archives/IOWalletCBOR-iOS-simulator.xcarchive/Products/Library/Frameworks/IOWalletCBOR.framework" \
    -output "../archives/IOWalletCBOR.xcframework"