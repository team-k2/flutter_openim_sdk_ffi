/// Flutter OpenIM 消息編輯測試配置
///
/// 使用方法:
/// 1. 將此文件複製到 Flutter 項目
/// 2. 在測試代碼中導入: import 'flutter_test_config.dart';
/// 3. 使用配置進行測試

class TestConfig {
  // 服務器配置
  static const String apiAddr = 'http://localhost:10002';
  static const String wsAddr = 'ws://localhost:10001';

  // 測試用戶配置
  // 注意：需要根據你的 OpenIM 服務器配置調整
  static const String testUserID = 'test_user_001';
  static const String testUserToken = 'YOUR_TOKEN_HERE'; // 需要替換

  // 測試會話和消息
  static const String testConversationID = 'si_test_user_001_test_user_002';
  static const int testMessageSeq = 1;

  // 如果你有可用的 Token，請替換這裡
  // 獲取方式：
  // 1. 使用 OpenIM Admin 面板登錄
  // 2. 從瀏覽器開發者工具獲取 Token
  // 3. 或使用 OpenIM SDK Demo 登錄後獲取
  static const String availableToken = '''
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJVc2VySUQiOiJ0ZXN0X3VzZXJfMDAxIiwiUGxhdGZvcm1JRCI6NSwiZXhwIjoxNzAwMDAwMDAwfQ.
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  '''.replaceAll('\n', '').trim();
}

/// 測試數據生成器
class TestDataGenerator {
  static String generateConversationID(String user1, String user2) {
    return 'si_${user1}_$user2';
  }

  static Map<String, dynamic> generateEditRequest({
    required String conversationID,
    required int seq,
    String? newContent,
    String? reason,
  }) {
    return {
      'conversationID': conversationID,
      'seq': seq,
      'newContent': newContent ?? '編輯測試內容 ${DateTime.now()}',
      'editReason': reason ?? '測試編輯',
    };
  }

  static List<Map<String, dynamic>> generateMockEditHistory() {
    return [
      {
        'editorUserID': 'test_user_001',
        'editorNickname': '測試用戶1',
        'editTime': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'oldContent': '原始內容',
        'newContent': '第一次編輯',
        'editReason': '修正錯誤',
      },
      {
        'editorUserID': 'test_user_001',
        'editorNickname': '測試用戶1',
        'editTime': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600,
        'oldContent': '第一次編輯',
        'newContent': '第二次編輯',
        'editReason': '優化表達',
      },
    ];
  }
}