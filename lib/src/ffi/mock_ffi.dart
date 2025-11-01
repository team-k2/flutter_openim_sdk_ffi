/// Mock FFI 實現 - 用於開發測試
///
/// 當動態庫尚未編譯時，可以使用此 Mock 實現進行開發測試

import 'dart:convert';
import 'package:flutter/foundation.dart';

class MockOpenIMSDK {
  static bool _initialized = false;
  static final Map<String, dynamic> _mockData = {};

  /// Mock 初始化
  static Future<void> initSDK({
    required String apiAddr,
    required String wsAddr,
    required String dataDir,
  }) async {
    await Future.delayed(Duration(milliseconds: 500)); // 模擬初始化延遲
    _initialized = true;
    debugPrint('[Mock] SDK 初始化成功');
    debugPrint('[Mock] API: $apiAddr, WS: $wsAddr');
  }

  /// Mock 編輯消息
  static Future<String> editMessage({
    required String conversationID,
    required int seq,
    required String newContent,
    String? editReason,
  }) async {
    if (!_initialized) throw Exception('SDK 未初始化');

    await Future.delayed(Duration(milliseconds: 300)); // 模擬網絡延遲

    final result = {
      'success': true,
      'conversationID': conversationID,
      'seq': seq,
      'newContent': newContent,
      'editReason': editReason,
      'editTime': DateTime.now().millisecondsSinceEpoch,
    };

    _mockData['lastEdit_$conversationID$seq'] = result;

    debugPrint('[Mock] 編輯消息成功: $result');
    return jsonEncode(result);
  }

  /// Mock 驗證編輯權限
  static Future<String> validateEditPermission({
    required String conversationID,
    required int seq,
  }) async {
    if (!_initialized) throw Exception('SDK 未初始化');

    await Future.delayed(Duration(milliseconds: 200));

    // 模擬權限邏輯
    final now = DateTime.now();
    final messageTime = now.subtract(Duration(hours: 12)); // 假設消息12小時前發送
    final timeRemaining = 86400 - (now.difference(messageTime).inSeconds);

    final result = {
      'canEdit': true,
      'reason': null,
      'timeRemaining': timeRemaining,
      'editCountLeft': 2,
    };

    debugPrint('[Mock] 編輯權限: $result');
    return jsonEncode(result);
  }

  /// Mock 獲取編輯歷史
  static Future<String> getMessageEditHistory({
    required String conversationID,
    required int seq,
  }) async {
    if (!_initialized) throw Exception('SDK 未初始化');

    await Future.delayed(Duration(milliseconds: 250));

    final history = [
      {
        'editorUserID': 'user123',
        'editorNickname': '測試用戶',
        'editTime': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600,
        'oldContent': '原始消息內容',
        'newContent': '第一次編輯的內容',
        'editReason': '修正錯誤',
      },
      {
        'editorUserID': 'user123',
        'editorNickname': '測試用戶',
        'editTime': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1800,
        'oldContent': '第一次編輯的內容',
        'newContent': '第二次編輯的內容',
        'editReason': '優化表達',
      },
    ];

    debugPrint('[Mock] 編輯歷史: ${history.length} 條');
    return jsonEncode(history);
  }

  /// Mock 獲取可編輯消息
  static Future<String> getEditableMessages({
    required String conversationID,
    int pageNumber = 1,
    int showNumber = 20,
  }) async {
    if (!_initialized) throw Exception('SDK 未初始化');

    await Future.delayed(Duration(milliseconds: 300));

    final messages = List.generate(5, (i) => {
      'seq': i + 1,
      'content': '測試消息內容 ${i + 1}',
      'sendTime': DateTime.now().millisecondsSinceEpoch ~/ 1000 - (i * 3600),
      'isEdited': i % 2 == 0,
      'editCount': i % 2 == 0 ? 1 : 0,
      'lastEditTime': i % 2 == 0
          ? DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1800
          : null,
    });

    final result = {
      'messages': messages,
      'total': 5,
      'pageNumber': pageNumber,
      'showNumber': showNumber,
    };

    debugPrint('[Mock] 可編輯消息: ${messages.length} 條');
    return jsonEncode(result);
  }
}

/// Mock FFI 橋接層
class MockFFIBridge {
  static bool useMock = true; // 設置為 false 使用真實 FFI

  static Future<dynamic> call(String method, Map<String, dynamic> params) async {
    if (!useMock) {
      // 調用真實 FFI
      throw UnimplementedError('真實 FFI 尚未實現，請先編譯動態庫');
    }

    // 使用 Mock 實現
    switch (method) {
      case 'initSDK':
        return MockOpenIMSDK.initSDK(
          apiAddr: params['apiAddr'],
          wsAddr: params['wsAddr'],
          dataDir: params['dataDir'],
        );

      case 'EditMessage':
        return MockOpenIMSDK.editMessage(
          conversationID: params['conversationID'],
          seq: params['seq'],
          newContent: params['newContent'],
          editReason: params['editReason'],
        );

      case 'ValidateEditPermission':
        return MockOpenIMSDK.validateEditPermission(
          conversationID: params['conversationID'],
          seq: params['seq'],
        );

      case 'GetMessageEditHistory':
        return MockOpenIMSDK.getMessageEditHistory(
          conversationID: params['conversationID'],
          seq: params['seq'],
        );

      case 'GetEditableMessages':
        return MockOpenIMSDK.getEditableMessages(
          conversationID: params['conversationID'],
          pageNumber: params['pageNumber'] ?? 1,
          showNumber: params['showNumber'] ?? 20,
        );

      default:
        throw UnimplementedError('方法 $method 尚未實現');
    }
  }
}

/// 使用示例
class MockUsageExample {
  static Future<void> testEditFlow() async {
    // 1. 初始化
    await MockFFIBridge.call('initSDK', {
      'apiAddr': 'http://localhost:10002',
      'wsAddr': 'ws://localhost:10001',
      'dataDir': './test_data',
    });

    // 2. 驗證權限
    final permissionJson = await MockFFIBridge.call('ValidateEditPermission', {
      'conversationID': 'test_conv_123',
      'seq': 1,
    });
    final permission = jsonDecode(permissionJson);
    print('可以編輯: ${permission['canEdit']}');

    if (permission['canEdit']) {
      // 3. 執行編輯
      final editResult = await MockFFIBridge.call('EditMessage', {
        'conversationID': 'test_conv_123',
        'seq': 1,
        'newContent': '編輯後的內容',
        'editReason': '測試編輯',
      });
      print('編輯結果: $editResult');

      // 4. 獲取歷史
      final historyJson = await MockFFIBridge.call('GetMessageEditHistory', {
        'conversationID': 'test_conv_123',
        'seq': 1,
      });
      final history = jsonDecode(historyJson);
      print('編輯歷史: ${(history as List).length} 條');
    }

    // 5. 獲取可編輯消息
    final messagesJson = await MockFFIBridge.call('GetEditableMessages', {
      'conversationID': 'test_conv_123',
    });
    final messages = jsonDecode(messagesJson);
    print('可編輯消息: ${messages['total']} 條');
  }
}

/// 環境配置
class FFIConfig {
  static bool get isProduction => const bool.fromEnvironment('PRODUCTION');

  static bool get useMockFFI {
    // 開發環境使用 Mock，生產環境使用真實 FFI
    if (kDebugMode && !isProduction) {
      return true;
    }

    // 檢查動態庫是否存在
    // 如果動態庫不存在，自動降級到 Mock
    try {
      // 嘗試載入動態庫
      // loadLibrary();
      return false;
    } catch (e) {
      debugPrint('動態庫載入失敗，使用 Mock 模式: $e');
      return true;
    }
  }
}