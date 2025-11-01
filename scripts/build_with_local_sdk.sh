#!/bin/bash
# 使用本地自定義 openim-sdk-core 編譯 FFI 動態庫

set -e

echo "================================================"
echo "Flutter OpenIM SDK FFI - 本地自定義 SDK 編譯"
echo "================================================"

# 默認路徑設置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_SDK_ROOT="$(dirname "$SCRIPT_DIR")"
SDK_CORE_PATH="${SDK_CORE_PATH:-$FLUTTER_SDK_ROOT/../openim-sdk-core}"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函數：打印彩色信息
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 檢查參數
while [[ $# -gt 0 ]]; do
    case $1 in
        --sdk-core-path)
            SDK_CORE_PATH="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            echo "使用方法: $0 [選項]"
            echo ""
            echo "選項:"
            echo "  --sdk-core-path <路徑>  指定 openim-sdk-core 路徑 (默認: ../openim-sdk-core)"
            echo "  --platform <平台>        編譯指定平台 (ios|android|macos|windows|linux|all)"
            echo "  --output-dir <目錄>      輸出目錄 (默認: ./output)"
            echo "  --help                   顯示此幫助信息"
            exit 0
            ;;
        *)
            echo "未知參數: $1"
            exit 1
            ;;
    esac
done

# 設置默認值
PLATFORM="${PLATFORM:-all}"
OUTPUT_DIR="${OUTPUT_DIR:-$FLUTTER_SDK_ROOT/output}"

# 驗證 SDK Core 路徑
if [ ! -d "$SDK_CORE_PATH" ]; then
    log_error "找不到 openim-sdk-core: $SDK_CORE_PATH"
    log_info "請使用 --sdk-core-path 參數指定正確的路徑"
    exit 1
fi

# 檢查 SDK Core 是否有我們的修改
if [ ! -f "$SDK_CORE_PATH/internal/conversation_msg/edit.go" ]; then
    log_warn "SDK Core 中找不到 edit.go，可能未應用消息編輯修改"
    read -p "是否繼續？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

log_info "使用 SDK Core: $SDK_CORE_PATH"
log_info "編譯平台: $PLATFORM"
log_info "輸出目錄: $OUTPUT_DIR"

# 創建輸出目錄
mkdir -p "$OUTPUT_DIR"

# 進入 SDK Core 目錄
cd "$SDK_CORE_PATH"

# 確保 go.mod 正確
log_info "檢查 go.mod..."
if [ ! -f go.mod ]; then
    log_info "初始化 go.mod..."
    go mod init github.com/openimsdk/openim-sdk-core/v3
fi

# 下載依賴
log_info "更新依賴..."
go mod tidy

# 設置環境變量
export PATH=$PATH:$(go env GOPATH)/bin
export CGO_ENABLED=1

# 獲取版本信息
VERSION_INFO=$(git describe --always --dirty 2>/dev/null || echo "unknown")
BUILD_TIME=$(date -u +"%Y%m%d-%H%M%S")
VERSION_TAG="custom-${VERSION_INFO}-${BUILD_TIME}"

log_info "版本標記: $VERSION_TAG"

# 編譯函數
build_ios() {
    log_info "編譯 iOS Framework..."

    # 檢查環境
    if ! command -v gomobile &> /dev/null; then
        log_warn "gomobile 未安裝，正在安裝..."
        go install golang.org/x/mobile/cmd/gomobile@latest
        go install golang.org/x/mobile/cmd/gobind@latest
        gomobile init
    fi

    # 檢查 Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "需要安裝 Xcode 才能編譯 iOS"
        return 1
    fi

    # 編譯
    gomobile bind -v \
        -target=ios \
        -o "$OUTPUT_DIR/ios/OpenIMCore.xcframework" \
        -ldflags="-s -w -X main.Version=$VERSION_TAG" \
        ./open_im_sdk ./open_im_sdk_callback

    if [ -d "$OUTPUT_DIR/ios/OpenIMCore.xcframework" ]; then
        log_info "✅ iOS Framework 編譯成功: $OUTPUT_DIR/ios/OpenIMCore.xcframework"

        # 複製到 Flutter SDK
        cp -r "$OUTPUT_DIR/ios/OpenIMCore.xcframework" "$FLUTTER_SDK_ROOT/ios/" 2>/dev/null || true
    else
        log_error "❌ iOS Framework 編譯失敗"
        return 1
    fi
}

build_android() {
    log_info "編譯 Android AAR..."

    # 檢查環境
    if ! command -v gomobile &> /dev/null; then
        log_warn "gomobile 未安裝，正在安裝..."
        go install golang.org/x/mobile/cmd/gomobile@latest
        go install golang.org/x/mobile/cmd/gobind@latest
        gomobile init
    fi

    # 檢查 Android SDK
    if [ -z "$ANDROID_HOME" ]; then
        log_warn "ANDROID_HOME 未設置"
        log_info "嘗試常見位置..."

        if [ -d "$HOME/Library/Android/sdk" ]; then
            export ANDROID_HOME="$HOME/Library/Android/sdk"
        elif [ -d "$HOME/Android/Sdk" ]; then
            export ANDROID_HOME="$HOME/Android/Sdk"
        else
            log_error "找不到 Android SDK"
            return 1
        fi
    fi

    # 編譯
    gomobile bind -v \
        -target=android \
        -androidapi 21 \
        -o "$OUTPUT_DIR/android/openim-sdk.aar" \
        -ldflags="-s -w -X main.Version=$VERSION_TAG" \
        ./open_im_sdk ./open_im_sdk_callback

    if [ -f "$OUTPUT_DIR/android/openim-sdk.aar" ]; then
        log_info "✅ Android AAR 編譯成功: $OUTPUT_DIR/android/openim-sdk.aar"

        # 複製到 Flutter SDK
        mkdir -p "$FLUTTER_SDK_ROOT/android/libs"
        cp "$OUTPUT_DIR/android/openim-sdk.aar" "$FLUTTER_SDK_ROOT/android/libs/" 2>/dev/null || true
    else
        log_error "❌ Android AAR 編譯失敗"
        return 1
    fi
}

build_macos() {
    log_info "編譯 macOS 動態庫..."

    # 創建 clib wrapper
    mkdir -p cmd/clib
    cat > cmd/clib/main.go << 'EOF'
package main

import "C"
import (
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
)

//export InitSDK
func InitSDK() {}

//export GetVersion
func GetVersion() *C.char {
    return C.CString("VERSION_PLACEHOLDER")
}

func main() {}
EOF

    # 替換版本占位符
    sed -i '' "s/VERSION_PLACEHOLDER/$VERSION_TAG/g" cmd/clib/main.go

    # 編譯 x86_64
    log_info "編譯 macOS x86_64..."
    GOARCH=amd64 go build -buildmode=c-shared \
        -ldflags="-s -w" \
        -o "$OUTPUT_DIR/macos/libopenim_sdk_x86_64.dylib" \
        ./cmd/clib

    # 編譯 arm64
    log_info "編譯 macOS arm64..."
    GOARCH=arm64 go build -buildmode=c-shared \
        -ldflags="-s -w" \
        -o "$OUTPUT_DIR/macos/libopenim_sdk_arm64.dylib" \
        ./cmd/clib

    # 創建通用二進制
    if [ -f "$OUTPUT_DIR/macos/libopenim_sdk_x86_64.dylib" ] && \
       [ -f "$OUTPUT_DIR/macos/libopenim_sdk_arm64.dylib" ]; then
        log_info "創建通用二進制..."
        lipo -create \
            "$OUTPUT_DIR/macos/libopenim_sdk_x86_64.dylib" \
            "$OUTPUT_DIR/macos/libopenim_sdk_arm64.dylib" \
            -output "$OUTPUT_DIR/macos/libopenim_sdk.dylib"

        log_info "✅ macOS 通用動態庫編譯成功: $OUTPUT_DIR/macos/libopenim_sdk.dylib"

        # 複製到 Flutter SDK
        mkdir -p "$FLUTTER_SDK_ROOT/macos/libs"
        cp "$OUTPUT_DIR/macos/libopenim_sdk.dylib" "$FLUTTER_SDK_ROOT/macos/libs/" 2>/dev/null || true
        cp "$OUTPUT_DIR/macos/libopenim_sdk.h" "$FLUTTER_SDK_ROOT/macos/libs/" 2>/dev/null || true
    else
        log_error "❌ macOS 動態庫編譯失敗"
        return 1
    fi
}

build_windows() {
    log_info "編譯 Windows DLL..."

    # 檢查 MinGW
    if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
        log_warn "MinGW 未安裝"
        log_info "安裝方法: brew install mingw-w64"
        return 1
    fi

    # 創建 clib wrapper（如果不存在）
    if [ ! -f cmd/clib/main.go ]; then
        mkdir -p cmd/clib
        cat > cmd/clib/main.go << 'EOF'
package main

import "C"
import (
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
)

//export InitSDK
func InitSDK() {}

func main() {}
EOF
    fi

    # 編譯
    CC=x86_64-w64-mingw32-gcc \
    GOOS=windows GOARCH=amd64 CGO_ENABLED=1 \
    go build -buildmode=c-shared \
        -ldflags="-s -w" \
        -o "$OUTPUT_DIR/windows/openim_sdk.dll" \
        ./cmd/clib

    if [ -f "$OUTPUT_DIR/windows/openim_sdk.dll" ]; then
        log_info "✅ Windows DLL 編譯成功: $OUTPUT_DIR/windows/openim_sdk.dll"

        # 複製到 Flutter SDK
        mkdir -p "$FLUTTER_SDK_ROOT/windows/libs"
        cp "$OUTPUT_DIR/windows/openim_sdk.dll" "$FLUTTER_SDK_ROOT/windows/libs/" 2>/dev/null || true
        cp "$OUTPUT_DIR/windows/openim_sdk.h" "$FLUTTER_SDK_ROOT/windows/libs/" 2>/dev/null || true
    else
        log_error "❌ Windows DLL 編譯失敗"
        return 1
    fi
}

build_linux() {
    log_info "編譯 Linux 共享庫..."

    # 創建 clib wrapper（如果不存在）
    if [ ! -f cmd/clib/main.go ]; then
        mkdir -p cmd/clib
        cat > cmd/clib/main.go << 'EOF'
package main

import "C"
import (
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
)

//export InitSDK
func InitSDK() {}

func main() {}
EOF
    fi

    # 編譯
    GOOS=linux GOARCH=amd64 CGO_ENABLED=1 \
    go build -buildmode=c-shared \
        -ldflags="-s -w" \
        -o "$OUTPUT_DIR/linux/libopenim_sdk.so" \
        ./cmd/clib

    if [ -f "$OUTPUT_DIR/linux/libopenim_sdk.so" ]; then
        log_info "✅ Linux 共享庫編譯成功: $OUTPUT_DIR/linux/libopenim_sdk.so"

        # 複製到 Flutter SDK
        mkdir -p "$FLUTTER_SDK_ROOT/linux/libs"
        cp "$OUTPUT_DIR/linux/libopenim_sdk.so" "$FLUTTER_SDK_ROOT/linux/libs/" 2>/dev/null || true
        cp "$OUTPUT_DIR/linux/libopenim_sdk.h" "$FLUTTER_SDK_ROOT/linux/libs/" 2>/dev/null || true
    else
        log_error "❌ Linux 共享庫編譯失敗"
        return 1
    fi
}

# 主編譯流程
log_info "開始編譯..."

case $PLATFORM in
    ios)
        build_ios
        ;;
    android)
        build_android
        ;;
    macos)
        build_macos
        ;;
    windows)
        build_windows
        ;;
    linux)
        build_linux
        ;;
    all)
        # 檢測當前操作系統
        OS="$(uname -s)"

        case "$OS" in
            Darwin)
                log_info "檢測到 macOS 系統"
                build_ios || true
                build_android || true
                build_macos || true
                build_windows || true
                ;;
            Linux)
                log_info "檢測到 Linux 系統"
                build_android || true
                build_linux || true
                build_windows || true
                ;;
            MINGW*|MSYS*|CYGWIN*)
                log_info "檢測到 Windows 系統"
                build_windows || true
                ;;
            *)
                log_warn "未知系統: $OS"
                ;;
        esac
        ;;
    *)
        log_error "未知平台: $PLATFORM"
        exit 1
        ;;
esac

# 生成版本信息文件
cat > "$OUTPUT_DIR/VERSION.json" << EOF
{
    "version": "$VERSION_TAG",
    "sdk_core_path": "$SDK_CORE_PATH",
    "build_time": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
    "platform": "$PLATFORM",
    "git_commit": "$(cd $SDK_CORE_PATH && git rev-parse --short HEAD 2>/dev/null || echo "unknown")",
    "git_branch": "$(cd $SDK_CORE_PATH && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
}
EOF

# 總結
echo ""
echo "================================================"
echo "編譯完成！"
echo "================================================"
echo "SDK Core 路徑: $SDK_CORE_PATH"
echo "版本標記: $VERSION_TAG"
echo "輸出目錄: $OUTPUT_DIR"
echo ""
echo "已生成的文件:"
ls -la "$OUTPUT_DIR"/*/ 2>/dev/null || true
echo ""
echo "動態庫已自動複製到 Flutter SDK 對應目錄"
echo ""
echo "下一步:"
echo "1. 在 Flutter 項目中運行: flutter clean && flutter pub get"
echo "2. 運行測試: flutter test test/message_edit/"
echo "3. 運行示例: flutter run example/message_edit_demo.dart"