# 📱 Android SDK 安裝指南 (macOS)

## ⚠️ 重要提醒
Homebrew 的 `android-sdk` cask 已於 2024-12-16 停用。以下提供官方替代方案。

## 🎯 快速安裝方案

### 方案 A: Command Line Tools Only（推薦，最小安裝）

1. **下載 Command Line Tools**
   ```bash
   # 訪問官網下載
   open https://developer.android.com/studio#command-tools
   # 選擇 "Command line tools only" for macOS
   ```

2. **設置目錄結構**
   ```bash
   # 創建 Android SDK 目錄
   mkdir -p ~/Library/Android/sdk/cmdline-tools

   # 解壓下載的文件（假設下載到 Downloads）
   cd ~/Library/Android/sdk/cmdline-tools
   unzip ~/Downloads/commandlinetools-mac-*.zip

   # 重要：必須重命名為 'latest'
   mv cmdline-tools latest
   ```

3. **設置環境變量**
   ```bash
   # 添加到 ~/.zshrc 或 ~/.bash_profile
   echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
   echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.zshrc
   echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.zshrc
   echo 'export PATH=$PATH:$ANDROID_HOME/build-tools/30.0.3' >> ~/.zshrc

   # 立即生效
   source ~/.zshrc
   ```

4. **安裝必要組件**
   ```bash
   # 接受所有許可
   yes | sdkmanager --licenses

   # 安裝基礎組件
   sdkmanager "platform-tools"
   sdkmanager "platforms;android-30"
   sdkmanager "platforms;android-31"
   sdkmanager "platforms;android-33"
   sdkmanager "build-tools;30.0.3"

   # 安裝 NDK（gomobile 需要）
   sdkmanager "ndk;21.4.7075529"
   ```

5. **驗證安裝**
   ```bash
   # 檢查安裝
   sdkmanager --list_installed

   # 檢查 adb
   adb version

   # 檢查環境變量
   echo $ANDROID_HOME
   ```

### 方案 B: Android Studio（完整 IDE）

1. **下載 Android Studio**
   ```bash
   open https://developer.android.com/studio
   ```

2. **安裝並初始化**
   - 拖動 Android Studio.app 到 Applications
   - 首次啟動會自動下載 SDK
   - SDK 位置：`~/Library/Android/sdk`

3. **通過 Android Studio 管理 SDK**
   - Preferences → Appearance & Behavior → System Settings → Android SDK
   - 安裝需要的 SDK 版本和工具

## 🔧 建置 Android SDK

### 前置檢查
```bash
# 1. 確認 Android SDK 已安裝
echo $ANDROID_HOME
# 應該輸出: /Users/your-username/Library/Android/sdk

# 2. 確認 gomobile 已安裝
~/go/bin/gomobile version

# 3. 如果 gomobile 未安裝
go install golang.org/x/mobile/cmd/gomobile@latest
go install golang.org/x/mobile/cmd/gobind@latest

# 4. 初始化 gomobile（會下載 Android 工具鏈）
~/go/bin/gomobile init
```

### 建置 OpenIM Android SDK
```bash
# 進入專案目錄
cd /Users/macoluo/Projects/K2IM-github/flutter_openim_sdk_ffi

# 建置 Android AAR
./scripts/build_with_local_sdk.sh --platform android

# 或直接使用 gomobile
cd ../openim-sdk-core
~/go/bin/gomobile bind -v \
    -target=android \
    -androidapi 21 \
    -o ../flutter_openim_sdk_ffi/output/android/openim-sdk.aar \
    -ldflags="-s -w" \
    ./open_im_sdk ./open_im_sdk_callback
```

### 預期輸出
```
output/android/
└── openim-sdk.aar  # Android Archive，包含所有架構
```

## 🐛 常見問題

### 問題 1: sdkmanager: command not found
```bash
# 確認路徑設置正確
ls -la ~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager

# 確保環境變量已設置
source ~/.zshrc
```

### 問題 2: Failed to find target with hash string 'android-30'
```bash
# 安裝缺失的 Android 版本
sdkmanager "platforms;android-30"
```

### 問題 3: gomobile: no Android NDK found
```bash
# 安裝 NDK
sdkmanager "ndk;21.4.7075529"

# 或指定特定版本
sdkmanager "ndk;25.2.9519653"

# 重新初始化 gomobile
~/go/bin/gomobile init
```

### 問題 4: JAVA_HOME is not set
```bash
# macOS 通常有內建 Java，設置 JAVA_HOME
echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >> ~/.zshrc
source ~/.zshrc

# 如果沒有 Java，安裝 OpenJDK
brew install openjdk@11
```

## 🎯 快速驗證腳本

創建 `test_android_setup.sh`：
```bash
#!/bin/bash

echo "檢查 Android SDK 環境..."
echo "========================="

# 檢查環境變量
if [ -z "$ANDROID_HOME" ]; then
    echo "❌ ANDROID_HOME 未設置"
else
    echo "✅ ANDROID_HOME: $ANDROID_HOME"
fi

# 檢查 SDK 目錄
if [ -d "$ANDROID_HOME" ]; then
    echo "✅ SDK 目錄存在"
else
    echo "❌ SDK 目錄不存在"
fi

# 檢查工具
command -v sdkmanager >/dev/null 2>&1 && echo "✅ sdkmanager 已安裝" || echo "❌ sdkmanager 未找到"
command -v adb >/dev/null 2>&1 && echo "✅ adb 已安裝" || echo "❌ adb 未找到"
command -v ~/go/bin/gomobile >/dev/null 2>&1 && echo "✅ gomobile 已安裝" || echo "❌ gomobile 未找到"

# 列出已安裝的 SDK 組件
if command -v sdkmanager >/dev/null 2>&1; then
    echo ""
    echo "已安裝的 SDK 組件："
    sdkmanager --list_installed | head -20
fi
```

## 📋 完整安裝檢查清單

- [ ] Android SDK Command Line Tools 已下載
- [ ] ANDROID_HOME 環境變量已設置
- [ ] PATH 包含 Android 工具路徑
- [ ] sdkmanager 可以執行
- [ ] 必要的 SDK 平台已安裝 (android-30+)
- [ ] Build Tools 已安裝
- [ ] NDK 已安裝
- [ ] gomobile 已安裝並初始化
- [ ] 可以成功建置 AAR 文件

## 🔗 相關資源

- [Android SDK 官方下載](https://developer.android.com/studio#command-tools)
- [sdkmanager 文檔](https://developer.android.com/studio/command-line/sdkmanager)
- [gomobile 文檔](https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile)
- [Flutter Android 設置](https://docs.flutter.dev/get-started/install/macos#android-setup)

---

更新時間：2025-11-02 01:10 UTC+8