#!/bin/bash

# Build Android SDK using CGO instead of gomobile
set -e

echo "================================================"
echo "🔨 Building Android SDK with CGO (Alternative)"
echo "================================================"

SDK_PATH="../openim-sdk-core"

# Check if SDK exists
if [ ! -d "$SDK_PATH" ]; then
    echo "❌ SDK not found at $SDK_PATH"
    exit 1
fi

cd $SDK_PATH

# Create Android build script
cat > build_android_cgo.go << 'EOF'
//go:build android
// +build android

package main

import "C"
import (
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
)

// Export functions for JNI
//export Java_io_openim_sdk_OpenIMSDK_initSDK
func Java_io_openim_sdk_OpenIMSDK_initSDK() {
    // Implementation will be linked from the actual SDK
}

func main() {}
EOF

# Build for Android architectures
echo "Building for Android arm64..."
CGO_ENABLED=1 \
GOOS=android \
GOARCH=arm64 \
CC="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang" \
go build -buildmode=c-shared -o libopenim_arm64.so ./build_android_cgo.go

echo "Building for Android arm..."
CGO_ENABLED=1 \
GOOS=android \
GOARCH=arm \
CC="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/armv7a-linux-androideabi21-clang" \
go build -buildmode=c-shared -o libopenim_arm.so ./build_android_cgo.go

echo "✅ Android libraries built successfully!"
echo "Files:"
ls -lh libopenim_*.so