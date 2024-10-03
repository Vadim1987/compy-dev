#!/bin/bash

APK="%%APK%%"
PACKAGE_NAME="%%BUNDLE_ID%%"

if ! command -v adb &> /dev/null; then
    echo "Error: adb is not installed."
    exit 1
fi

# Check if a device is connected
if ! adb get-state &> /dev/null
then
    echo "Error: No device connected."
    exit 2
fi

adb uninstall "$PACKAGE_NAME" || true

echo "Installing APK..."
if adb install -r "$APK"
then
    echo "Installation complete."
else
    echo "Error: Installation failed."
    exit 1
fi
