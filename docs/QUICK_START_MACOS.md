# 🚀 快速開始：使用 macOS SDK 測試訊息編輯功能

## ✅ 前置條件

你已經成功建置了 macOS 版本的 OpenIM SDK，包含訊息編輯功能：
- SDK 檔案：`output/macos/libopenim_sdk.dylib` (33.5MB)
- 版本：custom-fc140147-20251101-164706
- 功能：包含 EditMessage、ValidateEditPermission、GetMessageEditHistory、GetEditableMessages

## 📦 步驟 1：部署 SDK

### 選項 A：Flutter 專案測試
```bash
# 複製 SDK 到 Flutter 範例專案
cd /Users/macoluo/Projects/K2IM-github/flutter_openim_sdk_ffi
cp output/macos/libopenim_sdk.dylib example/macos/

# 或複製到你的 Flutter 專案
cp output/macos/libopenim_sdk.dylib /path/to/your/flutter/project/macos/
```

### 選項 B：直接在 Flutter SDK 中使用
```bash
# SDK 已經在正確位置
cd /Users/macoluo/Projects/K2IM-github/flutter_openim_sdk_ffi
ls -la output/macos/libopenim_sdk.dylib
```

## 🧪 步驟 2：測試訊息編輯功能

### 2.1 創建測試 Flutter 應用
```dart
// test/message_edit/test_edit_feature.dart
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

void main() async {
  // 初始化 SDK
  await OpenIMManager.init(
    apiAddr: 'http://your-server:10002',
    wsAddr: 'ws://your-server:10001',
    dataDir: './openIM',
  );

  // 登入
  await OpenIMManager.login(
    userID: 'testUser',
    token: 'your-token',
  );

  // 測試編輯訊息
  await testEditMessage();
}

Future<void> testEditMessage() async {
  // 1. 編輯訊息
  print('測試編輯訊息...');
  final result = await OpenIMManager.messageManager.editMessage(
    conversationID: 'si_userA_userB',
    seq: 123,
    newContent: '這是編輯後的內容',
    editReason: '修正錯字',
  );
  print('編輯結果: $result');

  // 2. 驗證編輯權限
  print('驗證編輯權限...');
  final canEdit = await OpenIMManager.messageManager.validateEditPermission(
    conversationID: 'si_userA_userB',
    seq: 123,
  );
  print('是否可編輯: $canEdit');

  // 3. 取得編輯歷史
  print('取得編輯歷史...');
  final history = await OpenIMManager.messageManager.getMessageEditHistory(
    conversationID: 'si_userA_userB',
    seq: 123,
  );
  print('編輯歷史: ${history.length} 筆');

  // 4. 取得可編輯訊息列表
  print('取得可編輯訊息...');
  final editableMessages = await OpenIMManager.messageManager.getEditableMessages(
    conversationID: 'si_userA_userB',
    pageNumber: 1,
    showNumber: 20,
  );
  print('可編輯訊息: ${editableMessages.length} 筆');
}
```

### 2.2 執行測試
```bash
# 在 Flutter 專案目錄
cd example
flutter run -d macos
```

## 🎯 步驟 3：Mock 模式開發（無需真實伺服器）

如果還沒有設置 OpenIM 伺服器，可以使用 Mock 模式：

```dart
// lib/src/mock/mock_message_manager.dart
class MockMessageManager implements MessageManager {
  @override
  Future<EditMessageResult> editMessage({
    required String conversationID,
    required int seq,
    required String newContent,
    String? editReason,
  }) async {
    // 模擬延遲
    await Future.delayed(Duration(milliseconds: 500));

    // 返回模擬結果
    return EditMessageResult(
      success: true,
      editTime: DateTime.now().millisecondsSinceEpoch,
      editorUserID: 'testUser',
      editedContent: newContent,
    );
  }

  @override
  Future<bool> validateEditPermission({
    required String conversationID,
    required int seq,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));
    return true; // 模擬有權限
  }

  // ... 實現其他方法
}
```

## 🔍 步驟 4：驗證 SDK 功能

### 檢查 SDK 是否包含編輯功能
```bash
# 列出所有編輯相關的導出函數
nm -g output/macos/libopenim_sdk.dylib | grep -i edit

# 預期輸出：
# _EditMessage
# _ValidateEditPermission
# _GetMessageEditHistory
# _GetEditableMessages
```

### 檢查 SDK 架構
```bash
# 確認支援 Apple Silicon 和 Intel
lipo -info output/macos/libopenim_sdk.dylib

# 預期輸出：
# Architectures in the fat file: libopenim_sdk.dylib are: x86_64 arm64
```

## 📱 步驟 5：在真實應用中使用

### 5.1 更新 pubspec.yaml
```yaml
dependencies:
  flutter_openim_sdk_ffi:
    path: /Users/macoluo/Projects/K2IM-github/flutter_openim_sdk_ffi
```

### 5.2 實現編輯 UI
```dart
// 編輯訊息的 UI 範例
class MessageEditDialog extends StatefulWidget {
  final Message message;

  @override
  _MessageEditDialogState createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  Future<void> _saveEdit() async {
    try {
      await OpenIMManager.messageManager.editMessage(
        conversationID: widget.message.conversationID,
        seq: widget.message.seq,
        newContent: _controller.text,
        editReason: '用戶編輯',
      );
      Navigator.pop(context, true);
    } catch (e) {
      // 處理錯誤
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('編輯失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('編輯訊息'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: '輸入新內容...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveEdit,
          child: Text('保存'),
        ),
      ],
    );
  }
}
```

## 🐛 疑難排解

### 問題 1：找不到 libopenim_sdk.dylib
```bash
# 確認檔案存在
ls -la output/macos/libopenim_sdk.dylib

# 如果不存在，重新建置
./scripts/build_with_local_sdk.sh --platform macos
```

### 問題 2：架構不相容
```bash
# 檢查你的 Mac 架構
uname -m

# 確認 SDK 支援該架構
file output/macos/libopenim_sdk.dylib
```

### 問題 3：權限問題
```bash
# 授予執行權限
chmod +x output/macos/libopenim_sdk.dylib

# 如果 macOS 阻擋未簽名的庫
xattr -d com.apple.quarantine output/macos/libopenim_sdk.dylib
```

## 📝 下一步

1. **測試其他平台**
   - 當 iOS/Android/Windows SDK 建置完成後，使用相同方法測試

2. **整合到生產環境**
   - 部署 OpenIM 伺服器到 AWS
   - 配置真實的 API 和 WebSocket 地址
   - 實現完整的錯誤處理

3. **擴展功能**
   - 實現編輯歷史查看 UI
   - 添加編輯權限檢查
   - 實現編輯通知處理

## 📚 相關文件

- [Flutter SDK 整合指南](./FLUTTER_PROGRAMMING_GUIDE.md)
- [訊息編輯功能文檔](./MESSAGE_EDITING_FEATURE.md)
- [建置進度報告](./BUILD_PROGRESS.md)

---

快速開始指南 v1.0 - 2025-11-02