import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

/// 消息編輯服務 - 繞過 SDK 直接調用 API
class MessageEditService {
  final String baseUrl;
  final OpenIM _sdk;

  MessageEditService({
    required this.baseUrl,
    required OpenIM sdk,
  }) : _sdk = sdk;

  /// 獲取當前用戶的 token
  String get token => _sdk.token;

  /// 獲取當前用戶 ID
  String get userID => _sdk.userInfo?.userID ?? '';

  /// 編輯消息
  Future<bool> editMessage({
    required String conversationID,
    required String clientMsgID,
    required String newContent,
    String? editReason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/msg/edit_msg'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'operationID': 'edit_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'conversationID': conversationID,
          'clientMsgID': clientMsgID,
          'newContent': newContent,
          'editReason': editReason ?? '',
          'userID': userID,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['errCode'] == 0) {
          // 編輯成功，手動更新本地緩存
          await _updateLocalCache(conversationID, clientMsgID, newContent);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Edit message error: $e');
      return false;
    }
  }

  /// 獲取消息編輯歷史
  Future<List<MessageEditHistory>> getMessageEditHistory({
    required String conversationID,
    required String clientMsgID,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/msg/get_message_edit_history'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'operationID': 'history_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'conversationID': conversationID,
          'clientMsgID': clientMsgID,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['errCode'] == 0) {
          final List<dynamic> histories = result['data']['histories'] ?? [];
          return histories.map((h) => MessageEditHistory.fromJson(h)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get edit history error: $e');
      return [];
    }
  }

  /// 獲取可編輯的消息列表
  Future<List<Message>> getEditableMessages({
    required String conversationID,
    int count = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/msg/get_editable_messages'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'operationID': 'editable_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'conversationID': conversationID,
          'userID': userID,
          'count': count,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['errCode'] == 0) {
          final List<dynamic> messages = result['data']['messages'] ?? [];
          // 這裡需要將 API 返回的數據轉換為 SDK 的 Message 對象
          return messages.map((m) => _parseMessage(m)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get editable messages error: $e');
      return [];
    }
  }

  /// 驗證編輯權限
  Future<bool> validateEditPermission({
    required String conversationID,
    required String clientMsgID,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/msg/validate_edit_permission'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'operationID': 'validate_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'conversationID': conversationID,
          'clientMsgID': clientMsgID,
          'userID': userID,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['errCode'] == 0 && result['data']['canEdit'] == true;
      }
      return false;
    } catch (e) {
      print('Validate permission error: $e');
      return false;
    }
  }

  /// 監聽 WebSocket 消息編輯通知
  void listenForEditNotifications() {
    // 使用現有 SDK 的 WebSocket 連接監聽編輯通知
    _sdk.setAdvancedMsgListener(
      OnAdvancedMsgListener(
        // 監聽自定義消息類型
        onRecvCustomBusinessMessage: (msg) {
          final content = jsonDecode(msg.content ?? '{}');
          if (content['type'] == 'message_edited') {
            // 處理消息編輯通知
            _handleEditNotification(content);
          }
        },
      ),
    );
  }

  /// 處理消息編輯通知
  void _handleEditNotification(Map<String, dynamic> data) {
    // 更新本地緩存
    final conversationID = data['conversationID'];
    final clientMsgID = data['clientMsgID'];
    final newContent = data['newContent'];

    // 觸發 UI 更新
    _notifyUIUpdate(conversationID, clientMsgID, newContent);
  }

  /// 更新本地消息緩存
  Future<void> _updateLocalCache(
    String conversationID,
    String clientMsgID,
    String newContent,
  ) async {
    // 這裡需要根據實際 SDK 的緩存機制來更新
    // 可能需要調用 SDK 的內部方法或直接操作數據庫

    // 臨時方案：保存到本地存儲
    final prefs = await SharedPreferences.getInstance();
    final key = 'edited_msg_${conversationID}_$clientMsgID';
    await prefs.setString(key, newContent);
  }

  /// 通知 UI 更新
  void _notifyUIUpdate(
    String conversationID,
    String clientMsgID,
    String newContent,
  ) {
    // 使用事件總線或其他機制通知 UI
    eventBus.fire(MessageEditedEvent(
      conversationID: conversationID,
      clientMsgID: clientMsgID,
      newContent: newContent,
    ));
  }

  /// 解析消息對象
  Message _parseMessage(Map<String, dynamic> json) {
    // 需要根據實際的 Message 類結構來解析
    return Message()
      ..clientMsgID = json['clientMsgID']
      ..serverMsgID = json['serverMsgID']
      ..content = json['content']
      ..contentType = json['contentType']
      ..sendTime = json['sendTime']
      ..senderUserID = json['senderUserID']
      ..senderNickname = json['senderNickname'];
  }
}

/// 消息編輯歷史
class MessageEditHistory {
  final String editTime;
  final String editorUserID;
  final String editorNickname;
  final String oldContent;
  final String newContent;
  final String editReason;

  MessageEditHistory({
    required this.editTime,
    required this.editorUserID,
    required this.editorNickname,
    required this.oldContent,
    required this.newContent,
    required this.editReason,
  });

  factory MessageEditHistory.fromJson(Map<String, dynamic> json) {
    return MessageEditHistory(
      editTime: json['editTime'] ?? '',
      editorUserID: json['editorUserID'] ?? '',
      editorNickname: json['editorNickname'] ?? '',
      oldContent: json['oldContent'] ?? '',
      newContent: json['newContent'] ?? '',
      editReason: json['editReason'] ?? '',
    );
  }
}

/// 消息編輯事件
class MessageEditedEvent {
  final String conversationID;
  final String clientMsgID;
  final String newContent;

  MessageEditedEvent({
    required this.conversationID,
    required this.clientMsgID,
    required this.newContent,
  });
}