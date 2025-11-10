# 📱 Flutter App 消息編輯功能集成指南（混合方案）

## 🎯 方案概述

由於無法重新編譯 SDK，我們採用**混合方案**：
- **現有 SDK**：負責 WebSocket 連接、基礎消息功能
- **直接 API 調用**：實現新的消息編輯功能

## 📋 架構說明

```
Flutter App
    ├── OpenIM SDK (現有版本)
    │   ├── WebSocket 連接管理 ✓
    │   ├── 用戶認證 ✓
    │   ├── 基礎消息收發 ✓
    │   └── 本地數據庫 ✓
    │
    └── MessageEditService (新增)
        ├── editMessage() → 直接調用 API
        ├── getEditHistory() → 直接調用 API
        ├── getEditableMessages() → 直接調用 API
        └── validateEditPermission() → 直接調用 API
```

## 🔧 集成步驟

### 1. 添加依賴

```yaml
# pubspec.yaml
dependencies:
  flutter_openim_sdk_ffi: ^3.5.1  # 使用現有版本
  http: ^1.1.0                     # 用於 API 調用
  shared_preferences: ^2.2.0       # 本地緩存
  event_bus: ^2.0.0               # 事件通知
```

### 2. 初始化服務

```dart
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';
import 'message_edit_service.dart';

class ChatManager {
  late OpenIM _sdk;
  late MessageEditService _editService;

  Future<void> init() async {
    // 初始化現有 SDK
    _sdk = OpenIM.getInstance();
    await _sdk.init(
      platformID: Platform.isIOS ? 1 : 2,
      apiAddr: 'https://your-server.com',
      wsAddr: 'wss://your-server.com',
      // ... 其他配置
    );

    // 初始化消息編輯服務
    _editService = MessageEditService(
      baseUrl: 'https://your-server.com',
      sdk: _sdk,
    );

    // 開始監聽編輯通知
    _editService.listenForEditNotifications();
  }

  MessageEditService get editService => _editService;
}
```

### 3. 在聊天界面使用

```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatManager _chatManager = ChatManager();
  final List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
    _listenToEditEvents();
  }

  void _listenToEditEvents() {
    // 監聽消息編輯事件
    eventBus.on<MessageEditedEvent>().listen((event) {
      setState(() {
        // 更新對應的消息
        final index = _messages.indexWhere(
          (m) => m.clientMsgID == event.clientMsgID,
        );
        if (index != -1) {
          _messages[index].content = event.newContent;
          _messages[index].isEdited = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('聊天')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return MessageEditWidget(
            message: _messages[index],
            editService: _chatManager.editService,
          );
        },
      ),
    );
  }
}
```

## 🎨 UI 交互設計

### 編輯消息流程
1. **長按消息** → 檢查權限
2. **顯示編輯框** → 用戶修改內容
3. **保存編輯** → 調用 API
4. **更新 UI** → 顯示"已編輯"標記

### 查看編輯歷史
1. **點擊"已編輯"** → 獲取歷史記錄
2. **底部彈窗** → 顯示所有版本
3. **顯示詳情** → 編輯者、時間、原因

## 📡 API 端點說明

### 1. 編輯消息
```http
POST /msg/edit_msg
Headers:
  token: {user_token}
  Content-Type: application/json
Body:
{
  "conversationID": "xxx",
  "clientMsgID": "xxx",
  "newContent": "修改後的內容",
  "editReason": "修正錯誤"
}
```

### 2. 獲取編輯歷史
```http
POST /msg/get_message_edit_history
Headers:
  token: {user_token}
Body:
{
  "conversationID": "xxx",
  "clientMsgID": "xxx"
}
```

### 3. 獲取可編輯消息
```http
POST /msg/get_editable_messages
Headers:
  token: {user_token}
Body:
{
  "conversationID": "xxx",
  "count": 100
}
```

### 4. 驗證編輯權限
```http
POST /msg/validate_edit_permission
Headers:
  token: {user_token}
Body:
{
  "conversationID": "xxx",
  "clientMsgID": "xxx"
}
```

## 🔄 WebSocket 通知處理

當其他用戶編輯消息時，通過 WebSocket 接收通知：

```dart
// WebSocket 消息格式
{
  "type": "message_edited",
  "data": {
    "conversationID": "xxx",
    "clientMsgID": "xxx",
    "newContent": "新內容",
    "editorUserID": "xxx",
    "editTime": 1234567890
  }
}
```

處理邏輯：
```dart
void handleWebSocketMessage(String message) {
  final data = jsonDecode(message);
  if (data['type'] == 'message_edited') {
    // 更新本地緩存
    updateLocalMessage(data['data']);
    // 通知 UI 更新
    eventBus.fire(MessageEditedEvent(...));
  }
}
```

## 💾 本地緩存策略

為了優化性能，編輯後的消息會緩存到本地：

```dart
class LocalCache {
  static Future<void> saveEditedMessage(
    String conversationID,
    String clientMsgID,
    String newContent,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'edited_${conversationID}_$clientMsgID';
    await prefs.setString(key, jsonEncode({
      'content': newContent,
      'editTime': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  static Future<String?> getEditedContent(
    String conversationID,
    String clientMsgID,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'edited_${conversationID}_$clientMsgID';
    final data = prefs.getString(key);
    if (data != null) {
      final json = jsonDecode(data);
      return json['content'];
    }
    return null;
  }
}
```

## ⚠️ 注意事項

1. **權限檢查**：編輯前必須驗證權限
2. **時間限制**：通常只能編輯 2 分鐘內的消息
3. **版本衝突**：多人同時編輯時，以最後保存為準
4. **離線處理**：離線時編輯操作排隊，上線後執行
5. **性能優化**：批量獲取可編輯消息，避免頻繁請求

## 🧪 測試建議

### 單元測試
```dart
test('編輯消息權限驗證', () async {
  final service = MessageEditService(...);
  final canEdit = await service.validateEditPermission(
    conversationID: 'test_conv',
    clientMsgID: 'test_msg',
  );
  expect(canEdit, isTrue);
});
```

### 集成測試
1. 測試編輯自己的消息
2. 測試編輯超時的消息（應失敗）
3. 測試查看編輯歷史
4. 測試 WebSocket 通知接收

## 📝 完整示例

完整的示例代碼已提供在以下文件：
- `/lib/src/message_edit_service.dart` - 核心服務
- `/lib/src/widgets/message_edit_widget.dart` - UI 組件
- `/example/chat_with_edit.dart` - 完整示例

## 🚀 部署檢查清單

- [ ] 服務器 API 已部署並測試
- [ ] WebSocket 消息編輯通知已配置
- [ ] Flutter App 已集成 MessageEditService
- [ ] UI 組件已添加編輯功能
- [ ] 本地緩存機制已實現
- [ ] 錯誤處理和重試機制已添加
- [ ] 性能測試已通過

## 🆘 常見問題

### Q: 編輯後其他用戶看不到更新？
A: 檢查 WebSocket 連接和通知機制是否正常工作

### Q: 編輯權限總是返回 false？
A: 確認服務器端的權限配置和時間限制設置

### Q: 編輯歷史獲取失敗？
A: 檢查 API token 是否有效，以及服務器是否正確保存歷史記錄

---

## 📞 技術支持

如有問題，請聯繫：
- GitHub Issues: [your-repo/issues]
- Email: support@your-domain.com