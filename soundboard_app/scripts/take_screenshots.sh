#!/bin/bash

# Ensure we're in the project root
cd "$(dirname "$0")/.." || exit

echo "Running screenshot tests..."

# Get available devices
DEVICES=$(flutter devices)
echo "Available devices:"
echo "$DEVICES"

# Try to find an Android device first
ANDROID_DEVICE=$(echo "$DEVICES" | grep -i android | head -n 1 | awk -F'•' '{print $2}' | xargs)

if [ -n "$ANDROID_DEVICE" ]; then
  echo "Using Android device: $ANDROID_DEVICE"
  DEVICE_ID="$ANDROID_DEVICE"
else
  # If no Android device, try to find any mobile device
  MOBILE_DEVICE=$(echo "$DEVICES" | grep -i mobile | head -n 1 | awk -F'•' '{print $2}' | xargs)
  
  if [ -n "$MOBILE_DEVICE" ]; then
    echo "Using mobile device: $MOBILE_DEVICE"
    DEVICE_ID="$MOBILE_DEVICE"
  else
    # If no mobile device, just use the first available device
    FIRST_DEVICE=$(echo "$DEVICES" | grep '•' | head -n 1 | awk -F'•' '{print $2}' | xargs)
    
    if [ -n "$FIRST_DEVICE" ]; then
      echo "Using first available device: $FIRST_DEVICE"
      DEVICE_ID="$FIRST_DEVICE"
    else
      echo "No devices found. Please connect a device or start an emulator."
      exit 1
    fi
  fi
fi

# Run the integration test and pipe the output to the extract_screenshots.dart script
echo "Running tests on device: $DEVICE_ID"
flutter test integration_test/screenshot_test.dart -d "$DEVICE_ID" | dart scripts/extract_screenshots.dart

echo "Screenshots have been saved to the 'screenshots' directory" 