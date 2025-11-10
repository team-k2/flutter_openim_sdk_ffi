#!/bin/bash

# Build with Go 1.20 which is known to work with gomobile
set -e

echo "================================================"
echo "🔧 Installing Go 1.20 for gomobile compatibility"
echo "================================================"

# Download and install Go 1.20
cd /tmp
curl -O https://go.dev/dl/go1.20.14.darwin-arm64.tar.gz
sudo rm -rf /usr/local/go-1.20
sudo tar -C /usr/local -xzf go1.20.14.darwin-arm64.tar.gz
sudo mv /usr/local/go /usr/local/go-1.20

# Use Go 1.20 for this session
export PATH=/usr/local/go-1.20/bin:$PATH
export GOROOT=/usr/local/go-1.20

echo "Go version:"
go version

# Clean previous gomobile installations
rm -rf ~/go/bin/gomobile
rm -rf ~/go/pkg/mod/golang.org/x/mobile*
rm -rf ~/go/src/golang.org/x/mobile

# Install gomobile with Go 1.20
echo "Installing gomobile..."
go install golang.org/x/mobile/cmd/gomobile@latest
go install golang.org/x/mobile/cmd/gobind@latest

# Initialize gomobile
~/go/bin/gomobile init

echo "✅ Go 1.20 and gomobile installed successfully!"

# Now build the SDKs
cd /Users/macoluo/Projects/K2IM-github/openim-sdk-core

echo "Building iOS SDK..."
~/go/bin/gomobile bind -v \
    -target=ios \
    -o ../flutter_openim_sdk_ffi/ios/OpenIMCore.xcframework \
    -ldflags="-s -w" \
    ./open_im_sdk ./open_im_sdk_callback

echo "Building Android SDK..."
~/go/bin/gomobile bind -v \
    -target=android \
    -androidapi 21 \
    -o ../flutter_openim_sdk_ffi/android/libs/openim-sdk.aar \
    -ldflags="-s -w" \
    ./open_im_sdk ./open_im_sdk_callback

echo "✅ SDKs built successfully with Go 1.20!"