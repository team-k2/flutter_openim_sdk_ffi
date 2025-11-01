#!/bin/bash
# Flutter 消息編輯功能測試腳本

echo "運行 Flutter 測試..."
cd /Users/macoluo/Projects/K2IM-github/flutter_openim_sdk_ffi

# 1. 獲取依賴
flutter pub get

# 2. 運行單元測試
echo -e "\n運行單元測試..."
flutter test test/message_edit/edit_message_unit_test.dart

# 3. 運行集成測試（需要服務器運行）
echo -e "\n運行集成測試..."
flutter test test/message_edit/edit_message_integration_test.dart

echo -e "\n測試完成！"
