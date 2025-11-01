import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '消息編輯測試',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MessageEditTestPage(),
    );
  }
}

class MessageEditTestPage extends StatefulWidget {
  @override
  _MessageEditTestPageState createState() => _MessageEditTestPageState();
}

class _MessageEditTestPageState extends State<MessageEditTestPage> {
  final _userIDController = TextEditingController(text: 'test_user');
  final _tokenController = TextEditingController();
  final _conversationIDController = TextEditingController(text: 'si_test_user1_test_user2');
  final _seqController = TextEditingController(text: '1');
  final _newContentController = TextEditingController(text: '編輯後的內容');
  final _editReasonController = TextEditingController(text: '修正錯誤');

  String _status = '未初始化';
  String _result = '';
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  Future<void> _initSDK() async {
    setState(() {
      _status = '初始化 SDK 中...';
    });

    try {
      // 初始化 SDK
      await OpenIM.iMManager.initSDK(
        config: IMConfig(
          apiAddr: 'http://localhost:10002',
          wsAddr: 'ws://localhost:10001',
          dataDir: './openim_data',
          logLevel: 5,
        ),
        listener: OnConnectListener(
          onConnecting: () {
            setState(() {
              _status = '連接中...';
            });
          },
          onConnectSuccess: () {
            setState(() {
              _status = '連接成功';
            });
          },
          onConnectFailed: (code, msg) {
            setState(() {
              _status = '連接失敗: $code $msg';
            });
          },
          onUserTokenExpired: () {
            setState(() {
              _status = 'Token 過期';
              _isLoggedIn = false;
            });
          },
        ),
      );

      setState(() {
        _isInitialized = true;
        _status = 'SDK 初始化成功';
      });
    } catch (e) {
      setState(() {
        _status = '初始化失敗: $e';
      });
    }
  }

  Future<void> _login() async {
    if (!_isInitialized) {
      setState(() {
        _result = '請先初始化 SDK';
      });
      return;
    }

    setState(() {
      _status = '登錄中...';
    });

    try {
      await OpenIM.iMManager.login(
        userID: _userIDController.text,
        token: _tokenController.text,
      );

      setState(() {
        _isLoggedIn = true;
        _status = '登錄成功';
        _result = '用戶 ${_userIDController.text} 已登錄';
      });
    } catch (e) {
      setState(() {
        _status = '登錄失敗';
        _result = '錯誤: $e';
      });
    }
  }

  Future<void> _validateEditPermission() async {
    if (!_isLoggedIn) {
      setState(() {
        _result = '請先登錄';
      });
      return;
    }

    setState(() {
      _status = '驗證編輯權限...';
    });

    try {
      final permission = await OpenIM.iMManager.messageManager.validateEditPermission(
        conversationID: _conversationIDController.text,
        seq: int.parse(_seqController.text),
      );

      setState(() {
        _status = '權限驗證完成';
        _result = '''
編輯權限: ${permission['canEdit'] ? '✅ 允許' : '❌ 禁止'}
原因: ${permission['reason'] ?? '無'}
剩餘時間: ${permission['timeRemaining'] ?? 0} 秒
剩餘次數: ${permission['editCountLeft'] ?? 0} 次
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '驗證失敗';
        _result = '錯誤: $e';
      });
    }
  }

  Future<void> _editMessage() async {
    if (!_isLoggedIn) {
      setState(() {
        _result = '請先登錄';
      });
      return;
    }

    setState(() {
      _status = '編輯消息中...';
    });

    try {
      await OpenIM.iMManager.messageManager.editMessage(
        conversationID: _conversationIDController.text,
        seq: int.parse(_seqController.text),
        newContent: _newContentController.text,
        editReason: _editReasonController.text,
      );

      setState(() {
        _status = '編輯成功';
        _result = '消息已編輯:\n${_newContentController.text}';
      });
    } catch (e) {
      setState(() {
        _status = '編輯失敗';
        _result = '錯誤: $e';
      });
    }
  }

  Future<void> _getEditHistory() async {
    if (!_isLoggedIn) {
      setState(() {
        _result = '請先登錄';
      });
      return;
    }

    setState(() {
      _status = '獲取編輯歷史...';
    });

    try {
      final history = await OpenIM.iMManager.messageManager.getMessageEditHistory(
        conversationID: _conversationIDController.text,
        seq: int.parse(_seqController.text),
      );

      final historyText = history.map((item) => '''
編輯者: ${item['editorNickname']} (${item['editorUserID']})
時間: ${DateTime.fromMillisecondsSinceEpoch(item['editTime'] * 1000)}
舊內容: ${item['oldContent']}
新內容: ${item['newContent']}
原因: ${item['editReason'] ?? '無'}
      ''').join('\n---\n');

      setState(() {
        _status = '獲取成功';
        _result = '編輯歷史 (${history.length} 條):\n$historyText';
      });
    } catch (e) {
      setState(() {
        _status = '獲取失敗';
        _result = '錯誤: $e';
      });
    }
  }

  Future<void> _getEditableMessages() async {
    if (!_isLoggedIn) {
      setState(() {
        _result = '請先登錄';
      });
      return;
    }

    setState(() {
      _status = '獲取可編輯消息...';
    });

    try {
      final result = await OpenIM.iMManager.messageManager.getEditableMessages(
        conversationID: _conversationIDController.text,
        pageNumber: 1,
        showNumber: 20,
      );

      final messages = (result['messages'] as List?) ?? [];
      final messageText = messages.map((msg) => '''
Seq: ${msg['seq']}
內容: ${msg['content']}
發送時間: ${DateTime.fromMillisecondsSinceEpoch(msg['sendTime'] * 1000)}
已編輯: ${msg['isEdited'] ? '是' : '否'}
編輯次數: ${msg['editCount']}
      ''').join('\n---\n');

      setState(() {
        _status = '獲取成功';
        _result = '''
可編輯消息總數: ${result['total']}
當前頁: ${result['pageNumber']}/${(result['total'] / result['showNumber']).ceil()}

消息列表:
$messageText
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '獲取失敗';
        _result = '錯誤: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenIM 消息編輯測試'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 狀態顯示
            Card(
              color: _isLoggedIn ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLoggedIn ? Icons.check_circle : Icons.warning,
                          color: _isLoggedIn ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '狀態: $_status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (!_isLoggedIn) ...[
                      SizedBox(height: 8),
                      Text('SDK 初始化: ${_isInitialized ? '✅' : '❌'}'),
                      Text('用戶登錄: ${_isLoggedIn ? '✅' : '❌'}'),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // 登錄區域
            if (!_isLoggedIn) ...[
              Text('登錄設置', style: Theme.of(context).textTheme.headline6),
              SizedBox(height: 8),
              TextField(
                controller: _userIDController,
                decoration: InputDecoration(
                  labelText: '用戶 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Token',
                  border: OutlineInputBorder(),
                  helperText: '請輸入有效的登錄 Token',
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _login,
                icon: Icon(Icons.login),
                label: Text('登錄'),
              ),
              SizedBox(height: 16),
            ],

            // 測試參數
            if (_isLoggedIn) ...[
              Text('測試參數', style: Theme.of(context).textTheme.headline6),
              SizedBox(height: 8),
              TextField(
                controller: _conversationIDController,
                decoration: InputDecoration(
                  labelText: '會話 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _seqController,
                decoration: InputDecoration(
                  labelText: '消息序號 (seq)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              TextField(
                controller: _newContentController,
                decoration: InputDecoration(
                  labelText: '新內容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 8),
              TextField(
                controller: _editReasonController,
                decoration: InputDecoration(
                  labelText: '編輯原因',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // 操作按鈕
              Text('測試操作', style: Theme.of(context).textTheme.headline6),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _validateEditPermission,
                    icon: Icon(Icons.security),
                    label: Text('驗證權限'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _editMessage,
                    icon: Icon(Icons.edit),
                    label: Text('編輯消息'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _getEditHistory,
                    icon: Icon(Icons.history),
                    label: Text('編輯歷史'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _getEditableMessages,
                    icon: Icon(Icons.list),
                    label: Text('可編輯列表'),
                  ),
                ],
              ),
            ],

            SizedBox(height: 16),

            // 結果顯示
            Text('執行結果', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result.isEmpty ? '執行結果將顯示在這裡...' : _result,
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}