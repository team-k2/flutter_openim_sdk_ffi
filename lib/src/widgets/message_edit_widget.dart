import 'package:flutter/material.dart';
import '../message_edit_service.dart';
import 'package:flutter_openim_sdk_ffi/flutter_openim_sdk_ffi.dart';

/// 消息編輯組件 - 在聊天界面中使用
class MessageEditWidget extends StatefulWidget {
  final Message message;
  final MessageEditService editService;

  const MessageEditWidget({
    Key? key,
    required this.message,
    required this.editService,
  }) : super(key: key);

  @override
  State<MessageEditWidget> createState() => _MessageEditWidgetState();
}

class _MessageEditWidgetState extends State<MessageEditWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;
  bool _canEdit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkEditPermission();
  }

  /// 檢查編輯權限
  Future<void> _checkEditPermission() async {
    final canEdit = await widget.editService.validateEditPermission(
      conversationID: widget.message.conversationID ?? '',
      clientMsgID: widget.message.clientMsgID ?? '',
    );
    if (mounted) {
      setState(() => _canEdit = canEdit);
    }
  }

  /// 開始編輯
  void _startEdit() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.message.content ?? '';
    });
  }

  /// 保存編輯
  Future<void> _saveEdit() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final success = await widget.editService.editMessage(
      conversationID: widget.message.conversationID ?? '',
      clientMsgID: widget.message.clientMsgID ?? '',
      newContent: _controller.text.trim(),
      editReason: '用戶編輯',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isEditing = false;
          // 更新消息內容
          widget.message.content = _controller.text.trim();
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('消息編輯成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('消息編輯失敗'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 取消編輯
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _controller.clear();
    });
  }

  /// 查看編輯歷史
  Future<void> _showEditHistory() async {
    final histories = await widget.editService.getMessageEditHistory(
      conversationID: widget.message.conversationID ?? '',
      clientMsgID: widget.message.clientMsgID ?? '',
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '編輯歷史',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (histories.isEmpty)
              const Text('暫無編輯歷史')
            else
              ...histories.map((history) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                history.editorNickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                history.editTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '原內容: ${history.oldContent}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('新內容: ${history.newContent}'),
                          if (history.editReason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '編輯原因: ${history.editReason}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.message.sendID == widget.editService.userID
            ? Colors.blue[50]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 消息頭部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.message.senderNickname ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (widget.message.isEdited == true)
                TextButton(
                  onPressed: _showEditHistory,
                  child: const Text(
                    '已編輯',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 消息內容
          if (_isEditing)
            Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: '編輯消息...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : _cancelEdit,
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveEdit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('保存'),
                    ),
                  ],
                ),
              ],
            )
          else
            GestureDetector(
              onLongPress: _canEdit ? _startEdit : null,
              child: Text(
                widget.message.content ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),

          // 消息時間和操作
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(widget.message.sendTime ?? 0),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (_canEdit && !_isEditing)
                IconButton(
                  onPressed: _startEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}