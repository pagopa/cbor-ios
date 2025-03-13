#!/bin/bash


param="false"
# Check if the parameter is passed
if [ -z "$1" ]; then
    echo "run without parameters.. default don't rebuild if exists"
else
    param=$(echo "$1" | tr '[:upper:]' '[:lower:]')
fi

# If the parameter is false, check if IOWalletCIE.xcframework exists
if [ "$param" == "false" ]; then

  if [ -d ".archives/IOWalletCBOR.xcframework" ]; then
    echo "IOWalletCBOR.xcframework exists."
    exit 0
  else
    echo "no exists"
  fi
fi

echo "building xcframework"

# Remove the old /archives folder
rm -rf .archives

cd IOWalletCBOR

# iOS Simulators
xcodebuild archive \
    -scheme IOWalletCBOR \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "../.archives/IOWalletCBOR-iOS-simulator.xcarchive" \
    -configuration Release \
    -sdk iphonesimulator

# iOS Devices
xcodebuild archive \
    -scheme IOWalletCBOR \
    -archivePath "../.archives/IOWalletCBOR-iOS.xcarchive" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -sdk iphoneos
    
# Build cbor.xcframework
xcodebuild -create-xcframework \
    -framework "../.archives/IOWalletCBOR-iOS.xcarchive/Products/Library/Frameworks/IOWalletCBOR.framework" \
    -framework "../.archives/IOWalletCBOR-iOS-simulator.xcarchive/Products/Library/Frameworks/IOWalletCBOR.framework" \
    -output "../.archives/IOWalletCBOR.xcframework"