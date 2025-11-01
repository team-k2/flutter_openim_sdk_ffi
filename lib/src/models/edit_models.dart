part of '../../flutter_openim_sdk_ffi.dart';

/// 編輯權限結果
class EditPermissionResult {
  final bool canEdit;
  final String? reason;
  final int? timeRemaining;
  final int? editCountLeft;

  EditPermissionResult({
    required this.canEdit,
    this.reason,
    this.timeRemaining,
    this.editCountLeft,
  });

  factory EditPermissionResult.fromJson(Map<String, dynamic> json) {
    return EditPermissionResult(
      canEdit: json['canEdit'] ?? false,
      reason: json['reason'],
      timeRemaining: json['timeRemaining'],
      editCountLeft: json['editCountLeft'],
    );
  }

  Map<String, dynamic> toJson() => {
    'canEdit': canEdit,
    'reason': reason,
    'timeRemaining': timeRemaining,
    'editCountLeft': editCountLeft,
  };
}

/// 編輯歷史項
class EditHistory {
  final String editorUserID;
  final String editorNickname;
  final int editTime;
  final String oldContent;
  final String newContent;
  final String? editReason;

  EditHistory({
    required this.editorUserID,
    required this.editorNickname,
    required this.editTime,
    required this.oldContent,
    required this.newContent,
    this.editReason,
  });

  factory EditHistory.fromJson(Map<String, dynamic> json) {
    return EditHistory(
      editorUserID: json['editorUserID'] ?? '',
      editorNickname: json['editorNickname'] ?? '',
      editTime: json['editTime'] ?? 0,
      oldContent: json['oldContent'] ?? '',
      newContent: json['newContent'] ?? '',
      editReason: json['editReason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'editorUserID': editorUserID,
    'editorNickname': editorNickname,
    'editTime': editTime,
    'oldContent': oldContent,
    'newContent': newContent,
    'editReason': editReason,
  };
}

/// 可編輯消息結果
class EditableMessagesResult {
  final List<EditableMessage> messages;
  final int total;
  final int pageNumber;
  final int showNumber;

  EditableMessagesResult({
    required this.messages,
    required this.total,
    required this.pageNumber,
    required this.showNumber,
  });

  factory EditableMessagesResult.fromJson(Map<String, dynamic> json) {
    return EditableMessagesResult(
      messages: (json['messages'] as List?)
              ?.map((e) => EditableMessage.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      showNumber: json['showNumber'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() => {
    'messages': messages.map((e) => e.toJson()).toList(),
    'total': total,
    'pageNumber': pageNumber,
    'showNumber': showNumber,
  };
}

/// 可編輯消息
class EditableMessage {
  final int seq;
  final String content;
  final int sendTime;
  final bool isEdited;
  final int editCount;
  final int? lastEditTime;

  EditableMessage({
    required this.seq,
    required this.content,
    required this.sendTime,
    required this.isEdited,
    required this.editCount,
    this.lastEditTime,
  });

  factory EditableMessage.fromJson(Map<String, dynamic> json) {
    return EditableMessage(
      seq: json['seq'] ?? 0,
      content: json['content'] ?? '',
      sendTime: json['sendTime'] ?? 0,
      isEdited: json['isEdited'] ?? false,
      editCount: json['editCount'] ?? 0,
      lastEditTime: json['lastEditTime'],
    );
  }

  Map<String, dynamic> toJson() => {
    'seq': seq,
    'content': content,
    'sendTime': sendTime,
    'isEdited': isEdited,
    'editCount': editCount,
    'lastEditTime': lastEditTime,
  };
}