import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

void main() {
  group('消息編輯單元測試', () {
    test('EditPermissionResult 序列化測試', () {
      final json = {
        'canEdit': true,
        'reason': null,
        'timeRemaining': 3600,
        'editCountLeft': 2,
      };

      final result = EditPermissionResult.fromJson(json);

      expect(result.canEdit, true);
      expect(result.timeRemaining, 3600);
      expect(result.editCountLeft, 2);

      final toJson = result.toJson();
      expect(toJson['canEdit'], true);
    });

    test('EditHistory 序列化測試', () {
      final json = {
        'editorUserID': 'user123',
        'editorNickname': 'Test User',
        'editTime': 1234567890,
        'oldContent': 'old text',
        'newContent': 'new text',
        'editReason': 'typo fix',
      };

      final history = EditHistory.fromJson(json);

      expect(history.editorUserID, 'user123');
      expect(history.oldContent, 'old text');
      expect(history.newContent, 'new text');
    });

    test('Message 編輯字段測試', () {
      final message = Message()
        ..clientMsgID = 'msg123'
        ..content = 'test content'
        ..isEdited = true
        ..editCount = 1
        ..lastEditTime = 1234567890
        ..lastEditUserID = 'editor123'
        ..originalContent = 'original';

      final json = message.toJson();

      expect(json['isEdited'], true);
      expect(json['editCount'], 1);
      expect(json['lastEditTime'], 1234567890);
      expect(json['lastEditUserID'], 'editor123');
      expect(json['originalContent'], 'original');
    });
  });
}
