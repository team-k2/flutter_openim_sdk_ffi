# 📱 Flutter OpenIM 消息編輯功能 - 編程指南

> **版本**: 1.0.0
> **最後更新**: 2024-11-01
> **適用於**: Flutter OpenIM SDK FFI v3.x

## 目錄

1. [快速開始](#快速開始)
2. [核心 API](#核心-api)
3. [數據模型](#數據模型)
4. [使用示例](#使用示例)
5. [UI 實現指南](#ui-實現指南)
6. [最佳實踐](#最佳實踐)
7. [錯誤處理](#錯誤處理)
8. [常見問題](#常見問題)

---

## 快速開始

### 安裝依賴

```yaml
# pubspec.yaml
dependencies:
  flutter_openim_sdk_ffi:
    path: ../flutter_openim_sdk_ffi  # 或使用 git/pub 倉庫
```

### 初始化 SDK

```dart
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

class IMManager {
  static Future<void> init() async {
    await OpenIM.iMManager.initSDK(
      config: IMConfig(
        apiAddr: 'https://your-api.com',    // API 地址
        wsAddr: 'wss://your-ws.com',        // WebSocket 地址
        dataDir: await getApplicationDocumentsDirectory(),
        logLevel: kDebugMode ? 5 : 3,
      ),
      listener: OnConnectListener(
        onConnecting: () => debugPrint('連接中...'),
        onConnectSuccess: () => debugPrint('連接成功'),
        onConnectFailed: (code, msg) => debugPrint('連接失敗: $msg'),
        onUserTokenExpired: () => _handleTokenExpired(),
      ),
    );
  }
}
```

---

## 核心 API

### 1. 編輯消息 - `editMessage`

編輯已發送的消息內容。

```dart
/// 編輯消息
///
/// @param conversationID - 會話ID
/// @param seq - 消息序號
/// @param newContent - 新的消息內容
/// @param editReason - 編輯原因（可選）
Future<void> editMessage({
  required String conversationID,
  required int seq,
  required String newContent,
  String? editReason,
}) async {
  try {
    await OpenIM.iMManager.messageManager.editMessage(
      conversationID: conversationID,
      seq: seq,
      newContent: newContent,
      editReason: editReason,
    );
    print('消息編輯成功');
  } catch (e) {
    print('編輯失敗: $e');
  }
}
```

**業務規則**：
- ⏰ 只能編輯 24 小時內的消息
- 👤 只能編輯自己發送的消息（群主/管理員可編輯所有）
- 🔢 每條消息最多編輯 3 次

---

### 2. 驗證編輯權限 - `validateEditPermission`

在顯示編輯按鈕前驗證用戶是否有權限編輯。

```dart
/// 驗證編輯權限
///
/// @return Map 包含 canEdit, reason, timeRemaining, editCountLeft
Future<Map<String, dynamic>> validateEditPermission({
  required String conversationID,
  required int seq,
}) async {
  final result = await OpenIM.iMManager.messageManager.validateEditPermission(
    conversationID: conversationID,
    seq: seq,
  );

  // 返回結構：
  // {
  //   'canEdit': true,           // 是否可編輯
  //   'reason': null,            // 不可編輯的原因
  //   'timeRemaining': 82800,    // 剩餘可編輯時間（秒）
  //   'editCountLeft': 2         // 剩餘編輯次數
  // }
  return result;
}
```

**使用場景**：
- 長按消息時判斷是否顯示"編輯"選項
- 實時更新編輯按鈕狀態

---

### 3. 獲取編輯歷史 - `getMessageEditHistory`

查看消息的所有編輯記錄。

```dart
/// 獲取消息編輯歷史
///
/// @return List<EditHistory> 編輯歷史列表
Future<List<Map<String, dynamic>>> getMessageEditHistory({
  required String conversationID,
  required int seq,
}) async {
  final history = await OpenIM.iMManager.messageManager.getMessageEditHistory(
    conversationID: conversationID,
    seq: seq,
  );

  // 返回結構：
  // [{
  //   'editorUserID': 'user123',
  //   'editorNickname': '張三',
  //   'editTime': 1698825600,
  //   'oldContent': '原始內容',
  //   'newContent': '編輯後內容',
  //   'editReason': '修正錯誤'
  // }]
  return history;
}
```

---

### 4. 獲取可編輯消息列表 - `getEditableMessages`

獲取當前用戶可編輯的消息列表。

```dart
/// 獲取可編輯消息列表
///
/// @param pageNumber - 頁碼（從1開始）
/// @param showNumber - 每頁數量
Future<Map<String, dynamic>> getEditableMessages({
  required String conversationID,
  int pageNumber = 1,
  int showNumber = 20,
}) async {
  final result = await OpenIM.iMManager.messageManager.getEditableMessages(
    conversationID: conversationID,
    pageNumber: pageNumber,
    showNumber: showNumber,
  );

  // 返回結構：
  // {
  //   'total': 45,
  //   'messages': [...],
  //   'pageNumber': 1,
  //   'showNumber': 20
  // }
  return result;
}
```

---

## 數據模型

### Message 擴展字段

```dart
class Message {
  // ... 現有字段 ...

  // 編輯相關新字段
  bool? isEdited;          // 是否已編輯
  int? editCount;          // 編輯次數
  int? lastEditTime;       // 最後編輯時間
  String? lastEditUserID;  // 最後編輯者ID
  String? originalContent; // 原始內容
}
```

### EditPermissionResult

```dart
class EditPermissionResult {
  final bool canEdit;        // 是否可編輯
  final String? reason;       // 不可編輯原因
  final int? timeRemaining;   // 剩餘時間（秒）
  final int? editCountLeft;   // 剩餘次數
}
```

### EditHistory

```dart
class EditHistory {
  final String editorUserID;    // 編輯者ID
  final String editorNickname;  // 編輯者暱稱
  final int editTime;           // 編輯時間
  final String oldContent;      // 舊內容
  final String newContent;      // 新內容
  final String? editReason;     // 編輯原因
}
```

---

## 使用示例

### 完整的消息編輯流程

```dart
class MessageEditHandler {
  /// 處理消息編輯
  static Future<void> handleMessageEdit(Message message) async {
    // 1. 驗證權限
    final permission = await OpenIM.iMManager.messageManager
        .validateEditPermission(
      conversationID: message.conversationID,
      seq: message.seq,
    );

    if (!permission['canEdit']) {
      showToast(permission['reason'] ?? '無法編輯此消息');
      return;
    }

    // 2. 顯示編輯對話框
    final newContent = await showEditDialog(
      currentContent: message.content,
      editCountLeft: permission['editCountLeft'],
      timeRemaining: permission['timeRemaining'],
    );

    if (newContent == null || newContent.isEmpty) return;

    // 3. 執行編輯
    try {
      await OpenIM.iMManager.messageManager.editMessage(
        conversationID: message.conversationID,
        seq: message.seq,
        newContent: newContent,
        editReason: '用戶編輯',
      );

      showToast('編輯成功');

      // 4. 更新 UI
      _updateMessageInUI(message, newContent);

    } catch (e) {
      showToast('編輯失敗: ${e.toString()}');
    }
  }

  /// 顯示編輯歷史
  static Future<void> showEditHistory(Message message) async {
    if (!message.isEdited) return;

    final history = await OpenIM.iMManager.messageManager
        .getMessageEditHistory(
      conversationID: message.conversationID,
      seq: message.seq,
    );

    showHistoryDialog(history);
  }
}
```

---

## UI 實現指南

### 1. 消息氣泡顯示編輯標記

```dart
class MessageBubble extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isSelf ? Colors.blue[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 消息內容
          Text(message.content),

          // 編輯標記
          if (message.isEdited == true)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '已編輯',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  if (message.editCount != null && message.editCount! > 1)
                    Text(
                      ' (${message.editCount}次)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

### 2. 長按菜單實現

```dart
class MessageContextMenu {
  static void show(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: _checkEditPermission(message),
        builder: (context, snapshot) {
          final canEdit = snapshot.data?['canEdit'] ?? false;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 編輯選項（根據權限顯示）
              if (canEdit)
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('編輯'),
                  subtitle: snapshot.data?['editCountLeft'] != null
                      ? Text('剩餘${snapshot.data!['editCountLeft']}次編輯')
                      : null,
                  onTap: () => _handleEdit(context, message),
                ),

              // 查看編輯歷史（如果已編輯）
              if (message.isEdited == true)
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('編輯歷史'),
                  onTap: () => _showEditHistory(context, message),
                ),

              // 其他選項
              ListTile(
                leading: Icon(Icons.copy),
                title: Text('複製'),
                onTap: () => _copyMessage(message),
              ),

              ListTile(
                leading: Icon(Icons.delete),
                title: Text('刪除'),
                onTap: () => _deleteMessage(message),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

### 3. 編輯對話框

```dart
class EditMessageDialog extends StatefulWidget {
  final String currentContent;
  final int? editCountLeft;
  final int? timeRemaining;

  @override
  _EditMessageDialogState createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentContent);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('編輯消息'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 提示信息
          if (widget.editCountLeft != null)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    '剩餘 ${widget.editCountLeft} 次編輯機會',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

          SizedBox(height: 12),

          // 編輯框
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '輸入新內容',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty &&
                _controller.text != widget.currentContent) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: Text('確認'),
        ),
      ],
    );
  }
}
```

---

## 最佳實踐

### 1. 權限預檢查

```dart
// ✅ 好的做法：預先檢查權限
class MessageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkEditPermission(),
      builder: (context, snapshot) {
        final canEdit = snapshot.data?.canEdit ?? false;
        return MessageBubble(
          showEditButton: canEdit,  // 根據權限顯示按鈕
        );
      },
    );
  }
}

// ❌ 不好的做法：點擊後才檢查
onTap: () async {
  // 用戶點擊後才發現不能編輯，體驗不好
  final permission = await validateEditPermission();
  if (!permission.canEdit) {
    showError('無法編輯');
  }
}
```

### 2. 實時更新狀態

```dart
class EditableMessageManager {
  // 監聽編輯時限
  Timer? _editTimer;

  void startEditTimeMonitor(Message message) {
    if (message.sendTime == null) return;

    final elapsed = DateTime.now().millisecondsSinceEpoch - message.sendTime!;
    final remaining = 86400000 - elapsed; // 24小時毫秒數

    if (remaining > 0) {
      _editTimer = Timer(Duration(milliseconds: remaining), () {
        // 時間到，禁用編輯按鈕
        setState(() {
          message.canEdit = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _editTimer?.cancel();
    super.dispose();
  }
}
```

### 3. 樂觀更新

```dart
Future<void> editMessageOptimistic(Message message, String newContent) async {
  // 1. 立即更新 UI（樂觀更新）
  setState(() {
    message.content = newContent;
    message.isEdited = true;
    message.editCount = (message.editCount ?? 0) + 1;
  });

  try {
    // 2. 發送請求到服務器
    await OpenIM.iMManager.messageManager.editMessage(
      conversationID: message.conversationID,
      seq: message.seq,
      newContent: newContent,
    );
  } catch (e) {
    // 3. 失敗則回滾
    setState(() {
      message.content = message.originalContent;
      message.editCount = (message.editCount ?? 1) - 1;
    });
    showError('編輯失敗');
  }
}
```

---

## 錯誤處理

### 錯誤碼對照表

| 錯誤碼 | 含義 | 處理建議 |
|--------|------|----------|
| 1001 | 參數錯誤 | 檢查必填參數 |
| 2001 | 無編輯權限 | 提示用戶無權限 |
| 2002 | 超過時間限制 | 提示"超過24小時" |
| 2003 | 超過次數限制 | 提示"編輯次數已用完" |
| 3001 | 消息不存在 | 刷新消息列表 |
| 5001 | 服務器錯誤 | 提示重試 |

### 統一錯誤處理

```dart
class MessageEditErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is OpenIMError) {
      switch (error.errCode) {
        case 2001:
          return '您沒有編輯此消息的權限';
        case 2002:
          return '消息發送已超過24小時，無法編輯';
        case 2003:
          return '此消息編輯次數已達上限';
        case 3001:
          return '消息不存在或已被刪除';
        default:
          return '編輯失敗，請重試';
      }
    }
    return '網絡錯誤，請檢查連接';
  }

  static void handleError(dynamic error, BuildContext context) {
    final message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '重試',
          onPressed: () => _retry(),
        ),
      ),
    );
  }
}
```

---

## 常見問題

### Q1: 如何自定義編輯時限？
```dart
// 服務器端配置，客戶端無法修改
// 但可以在 UI 上靈活處理
const int EDIT_TIME_LIMIT = 24 * 60 * 60; // 24小時（秒）
```

### Q2: 群主/管理員如何編輯他人消息？
```dart
// SDK 會自動處理權限判斷
// 群主和管理員調用相同的 API
await editMessage(
  conversationID: groupConversationID,
  seq: messageSeq,
  newContent: newContent,
  editReason: '管理員編輯',  // 建議標註原因
);
```

### Q3: 如何處理離線編輯衝突？
```dart
// 使用版本控制或時間戳
class ConflictResolver {
  static Future<void> resolveEditConflict(Message local, Message server) async {
    if (server.lastEditTime > local.lastEditTime) {
      // 服務器版本較新，使用服務器版本
      local.content = server.content;
      local.editCount = server.editCount;
    } else {
      // 重新提交本地編輯
      await resubmitEdit(local);
    }
  }
}
```

### Q4: 如何實現編輯預覽？
```dart
class EditPreview extends StatelessWidget {
  final String oldContent;
  final String newContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顯示差異
        Text('原始：', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(oldContent, style: TextStyle(decoration: TextDecoration.lineThrough)),
        SizedBox(height: 8),
        Text('修改為：', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(newContent, style: TextStyle(color: Colors.green)),
      ],
    );
  }
}
```

### Q5: 如何批量獲取可編輯消息？
```dart
// 分頁加載可編輯消息
class EditableMessagesLoader {
  int _currentPage = 1;
  final List<Message> _messages = [];

  Future<void> loadMore() async {
    final result = await OpenIM.iMManager.messageManager.getEditableMessages(
      conversationID: currentConversationID,
      pageNumber: _currentPage,
      showNumber: 20,
    );

    _messages.addAll(result['messages']);
    _currentPage++;

    if (_messages.length >= result['total']) {
      // 已加載全部
    }
  }
}
```

---

## 附錄

### 環境配置示例

```dart
// config/app_config.dart
class AppConfig {
  // 開發環境
  static const dev = {
    'apiUrl': 'http://192.168.1.100:10002',
    'wsUrl': 'ws://192.168.1.100:10001',
  };

  // 測試環境
  static const staging = {
    'apiUrl': 'https://staging-api.example.com',
    'wsUrl': 'wss://staging-ws.example.com',
  };

  // 生產環境
  static const production = {
    'apiUrl': 'https://api.example.com',
    'wsUrl': 'wss://ws.example.com',
  };

  // 根據編譯條件選擇
  static Map<String, String> get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'staging':
        return staging;
      case 'production':
        return production;
      default:
        return dev;
    }
  }
}
```

### 完整示例項目結構

```
message_edit_feature/
├── lib/
│   ├── config/
│   │   └── app_config.dart
│   ├── models/
│   │   ├── edit_models.dart
│   │   └── message.dart
│   ├── services/
│   │   ├── message_edit_service.dart
│   │   └── permission_service.dart
│   ├── ui/
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart
│   │   │   ├── edit_dialog.dart
│   │   │   └── edit_history_sheet.dart
│   │   └── screens/
│   │       └── chat_screen.dart
│   ├── utils/
│   │   ├── error_handler.dart
│   │   └── time_formatter.dart
│   └── main.dart
└── test/
    ├── unit/
    │   └── edit_service_test.dart
    └── integration/
        └── edit_flow_test.dart
```

---

## 支持和反饋

- 📧 技術支持：support@openim.io
- 🐛 問題反饋：https://github.com/OpenIMSDK/Open-IM-SDK-Flutter/issues
- 📚 更多文檔：https://doc.rentsoft.cn

**版本歷史**
- v1.0.0 (2024-11-01) - 初始版本，支持消息編輯基本功能