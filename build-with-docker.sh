#!/bin/bash

# Docker-based build script for OpenIM SDK
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================================"
echo "🐳 Building OpenIM SDK using Docker"
echo "================================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker from: https://www.docker.com/get-started"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose is not installed${NC}"
    echo "Installing docker-compose is required"
    exit 1
fi

# Parse arguments
USE_LOCAL_SDK=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            USE_LOCAL_SDK=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--local]"
            echo "  --local: Use local openim-sdk-core instead of cloning from GitHub"
            exit 1
            ;;
    esac
done

# Create output directory
mkdir -p output

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker-compose build sdk-builder

# Run the build
echo -e "${YELLOW}Building SDKs...${NC}"

if [ "$USE_LOCAL_SDK" = true ]; then
    echo "Using local openim-sdk-core..."
    # Make sure the SDK is in the parent directory
    if [ ! -d "../openim-sdk-core" ]; then
        echo -e "${RED}❌ Local openim-sdk-core not found at ../openim-sdk-core${NC}"
        exit 1
    fi
    docker-compose run --rm sdk-builder
else
    echo "Using remote SDK from GitHub..."
    docker-compose run --rm \
        -e SDK_REPO=team-k2/openim-sdk-core \
        -e SDK_BRANCH=completeEditMessage \
        sdk-builder
fi

# Check results
echo ""
echo "================================================"
if [ -f "output/OpenIMSDK.aar" ]; then
    echo -e "${GREEN}✅ Android SDK built successfully!${NC}"
    echo "File: output/OpenIMSDK.aar"
    echo "Size: $(ls -lh output/OpenIMSDK.aar | awk '{print $5}')"
else
    echo -e "${YELLOW}⚠️ Android SDK not built${NC}"
fi

if [ -f "output/OpenIMCore.xcframework" ]; then
    echo -e "${GREEN}✅ iOS SDK built successfully!${NC}"
    echo "File: output/OpenIMCore.xcframework"
else
    echo -e "${YELLOW}⚠️ iOS SDK not built (can only be built on macOS)${NC}"
fi

echo "================================================"
echo ""
echo "📁 Output directory contents:"
ls -la output/
echo ""
echo -e "${GREEN}✅ Build process completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Copy the SDK files to your Flutter project:"
echo "   - Android: cp output/OpenIMSDK.aar android/libs/"
echo "   - iOS: cp -r output/OpenIMCore.xcframework ios/"
echo ""