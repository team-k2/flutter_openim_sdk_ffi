import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

void main() {
  group('消息編輯集成測試', () {
    setUpAll(() async {
      print('初始化 SDK...');

      // 初始化配置
      final config = IMConfig(
        apiAddr: 'http://localhost:10002',
        wsAddr: 'ws://localhost:10001',
        dataDir: './test_data',
        logLevel: 5,
        isLogStandardOutput: true,
      );

      // 初始化 SDK
      await OpenIM.iMManager.initSDK(
        config: config,
        listener: OnConnectListener(
          onConnecting: () => print('連接中...'),
          onConnectSuccess: () => print('連接成功'),
          onConnectFailed: (code, msg) => print('連接失敗: $code $msg'),
          onKickedOffline: () => print('被踢下線'),
          onUserTokenExpired: () => print('Token 過期'),
        ),
      );

      // 登錄 (需要有效的 userID 和 token)
      await OpenIM.iMManager.login(
        userID: 'test_user',
        token: 'YOUR_TEST_TOKEN', // 需要替換為有效 token
      );
    });

    test('完整編輯流程測試', () async {
      final messageManager = OpenIM.iMManager.messageManager;

      // 測試會話 ID 和消息序號
      const conversationID = 'si_test_user1_test_user2';
      const seq = 1;

      // 1. 驗證編輯權限
      print('驗證編輯權限...');
      final permission = await messageManager.validateEditPermission(
        conversationID: conversationID,
        seq: seq,
      );

      print('編輯權限: ${permission['canEdit']}');

      if (permission['canEdit'] == true) {
        // 2. 執行編輯
        print('執行消息編輯...');
        await messageManager.editMessage(
          conversationID: conversationID,
          seq: seq,
          newContent: '編輯測試內容 ${DateTime.now()}',
          editReason: '測試編輯',
        );

        print('消息編輯成功');

        // 3. 獲取編輯歷史
        print('獲取編輯歷史...');
        final history = await messageManager.getMessageEditHistory(
          conversationID: conversationID,
          seq: seq,
        );

        print('編輯歷史數量: ${history.length}');
        for (var item in history) {
          print('  - ${item['editorNickname']}: ${item['newContent']}');
        }

        // 4. 獲取可編輯消息列表
        print('獲取可編輯消息...');
        final editableMessages = await messageManager.getEditableMessages(
          conversationID: conversationID,
          pageNumber: 1,
          showNumber: 20,
        );

        print('可編輯消息總數: ${editableMessages['total']}');
      } else {
        print('沒有編輯權限: ${permission['reason']}');
      }
    });

    tearDownAll(() async {
      await OpenIM.iMManager.logout();
      print('測試完成，已登出');
    });
  });
}
