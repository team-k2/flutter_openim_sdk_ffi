# 📚 自定義 SDK Core 編譯指南

## 🎯 概述

本指南說明如何配置 `flutter_openim_sdk_ffi` 使用自定義的 `openim-sdk-core` 進行編譯，而不是使用官方版本。

## 🔧 三種編譯方式

### 方式一：本地編譯（開發階段）

最快速的方式，適合開發測試。

```bash
# 1. 確保兩個專案在同一目錄下
cd /Users/macoluo/Projects/K2IM-github/
ls -la
# openim-sdk-core/       # 你的自定義 SDK
# flutter_openim_sdk_ffi/ # Flutter FFI 專案

# 2. 進入 Flutter SDK 目錄
cd flutter_openim_sdk_ffi

# 3. 執行本地編譯腳本
chmod +x scripts/build_with_local_sdk.sh
./scripts/build_with_local_sdk.sh --platform all

# 4. 指定自定義 SDK 路徑（如果不在預設位置）
./scripts/build_with_local_sdk.sh \
  --sdk-core-path /path/to/your/openim-sdk-core \
  --platform ios
```

### 方式二：GitHub Actions 自動編譯

適合 CI/CD 和團隊協作。

#### 設置步驟：

1. **Fork 或創建自己的倉庫**
   ```bash
   # Fork openim-sdk-core 到你的 GitHub
   # Fork flutter_openim_sdk_ffi 到你的 GitHub
   ```

2. **修改 workflow 配置**

   編輯 `.github/workflows/build-with-custom-sdk.yml`：
   ```yaml
   env:
     SDK_CORE_REPO: 'your-org/openim-sdk-core'  # 改為你的倉庫
     SDK_CORE_BRANCH: 'feature/message-edit'     # 你的分支
   ```

3. **設置 GitHub Secrets（如果使用私有倉庫）**
   - 進入 Settings → Secrets → Actions
   - 添加 `PERSONAL_ACCESS_TOKEN`

4. **觸發編譯**
   ```bash
   # 推送代碼觸發
   git push origin main

   # 或手動觸發（GitHub Actions 頁面）
   # Actions → Build FFI with Custom SDK → Run workflow
   ```

5. **下載編譯結果**
   - 進入 Actions → 選擇最新的 workflow run
   - 下載 Artifacts 中的編譯產物

### 方式三：Docker 容器編譯

最一致的編譯環境，避免環境差異。

```dockerfile
# Dockerfile.build
FROM golang:1.21

# 安裝必要工具
RUN apt-get update && apt-get install -y \
    build-essential \
    mingw-w64 \
    git

# 安裝 gomobile
RUN go install golang.org/x/mobile/cmd/gomobile@latest
RUN go install golang.org/x/mobile/cmd/gobind@latest

# 設置工作目錄
WORKDIR /workspace

# 複製源碼
COPY openim-sdk-core /workspace/openim-sdk-core
COPY flutter_openim_sdk_ffi /workspace/flutter_openim_sdk_ffi

# 編譯腳本
COPY build.sh /workspace/
RUN chmod +x /workspace/build.sh

CMD ["/workspace/build.sh"]
```

## 📝 配置文件說明

### `build_config.yaml`

控制編譯行為的主配置文件：

```yaml
custom_sdk_core:
  # 本地開發時設為 true
  use_local: true
  local_path: "../openim-sdk-core"

  # CI/CD 時設為 true
  use_remote: false
  repository: "your-org/openim-sdk-core"
  branch: "main"
```

## 🔄 工作流程

### 1. 修改 SDK Core

```bash
cd openim-sdk-core

# 創建功能分支
git checkout -b feature/message-edit

# 添加你的修改
vim internal/conversation_msg/edit.go

# 測試修改
go test ./...

# 提交修改
git add .
git commit -m "feat: Add message edit functionality"
git push origin feature/message-edit
```

### 2. 編譯 FFI 庫

```bash
cd flutter_openim_sdk_ffi

# 使用本地 SDK 編譯
./scripts/build_with_local_sdk.sh --platform all

# 或使用 GitHub Actions（推送後自動）
git push
```

### 3. 集成到 Flutter

```dart
// 在 Flutter 專案中使用
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

// 初始化 SDK
await OpenIM.iMManager.initSDK(
  apiAddr: 'http://your-server:10002',
  wsAddr: 'ws://your-server:10001',
  dataDir: 'path/to/data',
);

// 使用新功能
await OpenIM.iMManager.messageManager.editMessage(
  conversationID: 'conv_123',
  seq: 1,
  newContent: '編輯後的內容',
);
```

## 🚀 快速開始命令

### macOS/Linux 用戶

```bash
# 一鍵編譯所有平台
cd /Users/macoluo/Projects/K2IM-github/flutter_openim_sdk_ffi
./scripts/build_with_local_sdk.sh --platform all

# 只編譯特定平台
./scripts/build_with_local_sdk.sh --platform ios
./scripts/build_with_local_sdk.sh --platform android
```

### Windows 用戶

```powershell
# 使用 PowerShell
cd C:\Projects\flutter_openim_sdk_ffi
.\scripts\build_with_local_sdk.ps1 -Platform windows
```

## 📦 預期輸出

成功編譯後，會在以下位置生成動態庫：

```
flutter_openim_sdk_ffi/
├── ios/
│   └── OpenIMCore.xcframework      # iOS Framework
├── android/
│   └── libs/
│       └── openim-sdk.aar          # Android AAR
├── macos/
│   └── libs/
│       └── libopenim_sdk.dylib     # macOS 動態庫
├── windows/
│   └── libs/
│       └── openim_sdk.dll          # Windows DLL
└── linux/
    └── libs/
        └── libopenim_sdk.so         # Linux 共享庫
```

## 🐛 常見問題

### Q1: 編譯失敗 "cannot find package"

**原因**: SDK Core 的依賴未下載
**解決**:
```bash
cd openim-sdk-core
go mod tidy
```

### Q2: iOS 編譯失敗 "requires Xcode"

**原因**: 未安裝 Xcode
**解決**:
```bash
# 安裝 Xcode（從 App Store）
# 然後安裝命令行工具
xcode-select --install
```

### Q3: Android 編譯失敗 "ANDROID_HOME not set"

**原因**: Android SDK 未配置
**解決**:
```bash
# macOS
export ANDROID_HOME=$HOME/Library/Android/sdk

# Linux
export ANDROID_HOME=$HOME/Android/Sdk

# 或安裝 Android Studio
```

### Q4: GitHub Actions 無法訪問私有倉庫

**原因**: 缺少訪問權限
**解決**:

1. 創建 Personal Access Token：
   - GitHub → Settings → Developer settings → Personal access tokens
   - 生成新 token，勾選 `repo` 權限

2. 添加到 Secrets：
   - Repository → Settings → Secrets → Actions
   - 添加 `PERSONAL_ACCESS_TOKEN`

3. 在 workflow 中使用：
   ```yaml
   - uses: actions/checkout@v3
     with:
       repository: your-org/private-repo
       token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
   ```

### Q5: Windows 交叉編譯失敗

**原因**: 缺少 MinGW
**解決**:
```bash
# macOS
brew install mingw-w64

# Linux
sudo apt-get install mingw-w64

# Windows（原生編譯）
# 使用 Visual Studio 或 MinGW-w64
```

## 🔍 驗證編譯結果

### 1. 檢查動態庫

```bash
# iOS
file ios/OpenIMCore.xcframework/ios-arm64/OpenIMCore.framework/OpenIMCore

# Android
unzip -l android/libs/openim-sdk.aar | grep .so

# macOS
otool -L macos/libs/libopenim_sdk.dylib

# Linux
ldd linux/libs/libopenim_sdk.so

# Windows
# 使用 Dependency Walker 或
dumpbin /EXPORTS windows/libs/openim_sdk.dll
```

### 2. 檢查導出函數

```bash
# 檢查是否包含編輯功能
nm -g macos/libs/libopenim_sdk.dylib | grep -i edit

# 應該看到：
# EditMessage
# ValidateEditPermission
# GetMessageEditHistory
# GetEditableMessages
```

### 3. 運行測試

```bash
cd flutter_openim_sdk_ffi

# 單元測試
flutter test test/message_edit/edit_message_unit_test.dart

# 集成測試
flutter test test/message_edit/edit_message_integration_test.dart

# 示例應用
flutter run example/message_edit_demo.dart
```

## 📊 版本管理

每次編譯都會生成 `VERSION.json`：

```json
{
    "version": "custom-abc1234-20240101-120000",
    "sdk_core_path": "/path/to/openim-sdk-core",
    "build_time": "2024-01-01 12:00:00 UTC",
    "platform": "all",
    "git_commit": "abc1234",
    "git_branch": "feature/message-edit"
}
```

用於追踪：
- 使用的 SDK Core 版本
- 編譯時間
- Git 信息

## 🎯 最佳實踐

1. **版本對齊**：確保 SDK Core 和 Flutter SDK 的 proto 定義一致
2. **測試優先**：修改後先在本地測試，再推送到 CI/CD
3. **文檔更新**：修改 API 後同步更新文檔
4. **版本標記**：為重要版本創建 Git Tag

## 📚 相關文檔

- [BUILD_GUIDE.md](./BUILD_GUIDE.md) - 標準編譯指南
- [PROGRAMMING_GUIDE.md](./message_edit/PROGRAMMING_GUIDE.md) - Flutter 編程指南
- [API_REFERENCE.md](../../openim-sdk-core/docs/message_edit/API_REFERENCE.md) - API 參考

---

**最後更新**: 2024-11-01
**維護者**: OpenIM SDK Team