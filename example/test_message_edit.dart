import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

/// 訊息編輯功能測試範例
///
/// 使用方式：
/// 1. 確保已複製 macOS SDK 到專案中
/// 2. 在 Flutter 專案中引入此檔案
/// 3. 運行測試查看結果
class MessageEditTestPage extends StatefulWidget {
  @override
  _MessageEditTestPageState createState() => _MessageEditTestPageState();
}

class _MessageEditTestPageState extends State<MessageEditTestPage> {
  final TextEditingController _conversationController = TextEditingController();
  final TextEditingController _seqController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String _result = '準備測試...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 設置預設值方便測試
    _conversationController.text = 'si_userA_userB';
    _seqController.text = '1';
    _contentController.text = '這是編輯後的訊息內容';
    _reasonController.text = '修正錯誤';
  }

  // 測試編輯訊息
  Future<void> _testEditMessage() async {
    setState(() {
      _isLoading = true;
      _result = '正在測試編輯訊息...';
    });

    try {
      await OpenIM.iMManager.messageManager.editMessage(
        conversationID: _conversationController.text,
        seq: int.parse(_seqController.text),
        newContent: _contentController.text,
        editReason: _reasonController.text,
      );

      setState(() {
        _result = '✅ 編輯訊息成功！\n'
            '會話ID: ${_conversationController.text}\n'
            'Seq: ${_seqController.text}\n'
            '新內容: ${_contentController.text}';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 編輯訊息失敗：\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 測試驗證編輯權限
  Future<void> _testValidatePermission() async {
    setState(() {
      _isLoading = true;
      _result = '正在驗證編輯權限...';
    });

    try {
      final canEdit = await OpenIM.iMManager.messageManager.validateEditPermission(
        conversationID: _conversationController.text,
        seq: int.parse(_seqController.text),
      );

      setState(() {
        _result = canEdit
            ? '✅ 有編輯權限！可以編輯此訊息。'
            : '❌ 無編輯權限！無法編輯此訊息。';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 驗證權限失敗：\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 測試獲取編輯歷史
  Future<void> _testGetEditHistory() async {
    setState(() {
      _isLoading = true;
      _result = '正在獲取編輯歷史...';
    });

    try {
      final history = await OpenIM.iMManager.messageManager.getMessageEditHistory(
        conversationID: _conversationController.text,
        seq: int.parse(_seqController.text),
      );

      if (history.isEmpty) {
        setState(() {
          _result = '此訊息沒有編輯歷史';
        });
      } else {
        final historyText = history.map((edit) =>
          '時間: ${DateTime.fromMillisecondsSinceEpoch(edit['timestamp'])}\n'
          '內容: ${edit['content']}\n'
          '原因: ${edit['reason']}'
        ).join('\n---\n');

        setState(() {
          _result = '✅ 編輯歷史：\n$historyText';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ 獲取編輯歷史失敗：\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 測試獲取可編輯訊息列表
  Future<void> _testGetEditableMessages() async {
    setState(() {
      _isLoading = true;
      _result = '正在獲取可編輯訊息...';
    });

    try {
      final messages = await OpenIM.iMManager.messageManager.getEditableMessages(
        conversationID: _conversationController.text,
        pageNumber: 1,
        showNumber: 20,
      );

      if (messages.isEmpty) {
        setState(() {
          _result = '沒有可編輯的訊息';
        });
      } else {
        setState(() {
          _result = '✅ 可編輯訊息數量：${messages.length}\n'
              '訊息列表：\n' +
              messages.map((msg) => 'Seq: ${msg.seq} - ${msg.content}').join('\n');
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ 獲取可編輯訊息失敗：\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('訊息編輯功能測試'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 輸入區域
            TextField(
              controller: _conversationController,
              decoration: InputDecoration(
                labelText: '會話ID',
                hintText: 'si_userA_userB',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _seqController,
              decoration: InputDecoration(
                labelText: '訊息 Seq',
                hintText: '1',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '新內容',
                hintText: '編輯後的內容',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: '編輯原因',
                hintText: '修正錯誤',
              ),
            ),
            SizedBox(height: 16),

            // 測試按鈕
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testEditMessage,
                  child: Text('編輯訊息'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testValidatePermission,
                  child: Text('驗證權限'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testGetEditHistory,
                  child: Text('編輯歷史'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testGetEditableMessages,
                  child: Text('可編輯列表'),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 結果顯示區域
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Text(
                          _result,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _conversationController.dispose();
    _seqController.dispose();
    _contentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

// 使用範例
void main() {
  runApp(MaterialApp(
    home: MessageEditTestPage(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}