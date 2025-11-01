# Flutter OpenIM SDK - 消息編輯功能

## 功能概述

本模組提供完整的消息編輯功能，允許用戶編輯已發送的消息。

## 快速開始

### 1. 初始化 SDK

```dart
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

await OpenIM.iMManager.initSDK(
  config: IMConfig(
    apiAddr: 'https://your-api.com',
    wsAddr: 'wss://your-ws.com',
    dataDir: await getApplicationDocumentsDirectory(),
  ),
);
```

### 2. 編輯消息

```dart
// 編輯消息
await OpenIM.iMManager.messageManager.editMessage(
  conversationID: 'conversation_id',
  seq: 123,
  newContent: '編輯後的內容',
  editReason: '修正錯誤',
);
```

### 3. 驗證權限

```dart
// 檢查是否可以編輯
final permission = await OpenIM.iMManager.messageManager.validateEditPermission(
  conversationID: 'conversation_id',
  seq: 123,
);

if (permission['canEdit']) {
  // 顯示編輯按鈕
}
```

## 文件結構

```
flutter_openim_sdk_ffi/
├── docs/message_edit/
│   ├── README.md              # 本文檔
│   └── PROGRAMMING_GUIDE.md   # 詳細編程指南
├── example/
│   └── message_edit_demo.dart # 完整示例應用
├── lib/src/
│   ├── config/
│   │   └── environment_config.dart # 環境配置
│   ├── manager/
│   │   └── im_message_manager.dart # 消息管理器（已添加編輯方法）
│   ├── models/
│   │   ├── edit_models.dart        # 編輯相關數據模型
│   │   └── message.dart            # 消息模型（已擴展）
│   └── enum/
│       └── _port_method.dart       # 方法常量（已添加）
└── test/message_edit/
    ├── edit_message_unit_test.dart       # 單元測試
    ├── edit_message_integration_test.dart # 集成測試
    └── test_config.dart                   # 測試配置
```

## API 文檔

詳細 API 使用說明請參考 [`PROGRAMMING_GUIDE.md`](./PROGRAMMING_GUIDE.md)

### 核心 API

| 方法 | 功能 | 返回值 |
|------|------|--------|
| `editMessage` | 編輯消息 | `Future<void>` |
| `validateEditPermission` | 驗證編輯權限 | `Future<Map>` |
| `getMessageEditHistory` | 獲取編輯歷史 | `Future<List>` |
| `getEditableMessages` | 獲取可編輯消息列表 | `Future<Map>` |

## 測試

### 運行單元測試
```bash
flutter test test/message_edit/edit_message_unit_test.dart
```

### 運行集成測試
```bash
# 需要 OpenIM 服務器運行
flutter test test/message_edit/edit_message_integration_test.dart
```

### 運行示例應用
```bash
flutter run example/message_edit_demo.dart
```

## 環境配置

使用 `lib/src/config/environment_config.dart` 進行環境切換：

```dart
// 本地開發
await OpenIMConfig.initSDK(useAWS: false);

// AWS 生產環境
await OpenIMConfig.initSDK(useAWS: true);
```

## 注意事項

1. **編輯限制**
   - 只能編輯 24 小時內的消息
   - 每條消息最多編輯 3 次
   - 只能編輯自己發送的消息

2. **權限控制**
   - 群主和管理員可編輯所有群消息
   - 普通用戶只能編輯自己的消息

3. **UI 提示**
   - 編輯過的消息應顯示"已編輯"標記
   - 顯示剩餘編輯次數和時間

## 故障排查

| 問題 | 解決方案 |
|------|----------|
| FFI 載入失敗 | 重新編譯 gomobile 動態庫 |
| Token 過期 | 重新獲取認證 Token |
| 編輯失敗 | 檢查時間限制和權限 |

## 相關文檔

- [編程指南](./PROGRAMMING_GUIDE.md) - 詳細的 API 使用說明
- [SDK Core API](../../openim-sdk-core/docs/message_edit/API_REFERENCE.md) - 底層 API 文檔
- [部署指南](../../open-im-server/docs/message_edit/DEPLOYMENT_GUIDE.md) - 服務器部署

---

**版本**: 1.0.0
**最後更新**: 2024-11-01