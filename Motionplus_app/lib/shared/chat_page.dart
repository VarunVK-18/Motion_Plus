import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String sessionId;
  final String receiverId;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.sessionId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _scrollController = ScrollController();
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = _supabase.auth.currentUser!.id;
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('session_id', widget.sessionId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final isEditing = _editingMessageId != null;
    final msgId = _editingMessageId;

    _messageController.clear();
    setState(() => _editingMessageId = null);

    try {
      if (isEditing) {
        await _supabase
            .from('messages')
            .update({'content': text})
            .eq('id', msgId!);
      } else {
        await _supabase.from('messages').insert({
          'session_id': widget.sessionId,
          'sender_id': _supabase.auth.currentUser!.id,
          'receiver_id': widget.receiverId,
          'content': text,
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteMessage(String id) async {
    try {
      await _supabase.from('messages').delete().eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error unsending: $e')));
      }
    }
  }

  void _showOptions(String id, String content, Offset position, Size size) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: Stack(
            children: [
              Positioned(
                left: position.dx,
                top: position.dy - 100 > 0
                    ? position.dy - 110
                    : position.dy + size.height + 10,
                width: 150,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPopupAction(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _editingMessageId = id;
                              _messageController.text = content;
                            });
                          },
                        ),
                        _buildPopupAction(
                          icon: Icons.history_rounded,
                          label: 'Unsend',
                          color: const Color(0xFFFF3B30),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteMessage(id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE2E8F0),
              radius: 18,
              child: Text(
                widget.receiverName[0].toUpperCase(),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF3E84DC),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.receiverName,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('session_id', widget.sessionId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == currentUserId;
                    final time = DateTime.parse(msg['created_at']).toLocal();

                    return _buildMessageBubble(
                      msg['id'],
                      msg['content'],
                      isMe,
                      time,
                      msg['is_read'] ?? false,
                      msg['created_at'] != msg['updated_at'],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String id,
    String content,
    bool isMe,
    DateTime time,
    bool isRead,
    bool isEdited,
  ) {
    final bubbleKey = GlobalKey();

    return GestureDetector(
      key: bubbleKey,
      behavior: HitTestBehavior.opaque,
      onLongPress: isMe
          ? () {
              final renderBox =
                  bubbleKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;
              _showOptions(id, content, position, size);
            }
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF3E84DC) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isMe
                    ? null
                    : Border.all(color: const Color(0xFFF1F5F9), width: 1),
              ),
              child: Text(
                content,
                style: GoogleFonts.outfit(
                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'Edited',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Text(
                    DateFormat('hh:mm a').format(time),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: isRead
                          ? const Color(0xFF3E84DC)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final isEditing = _editingMessageId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Color(0xFF3E84DC),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Editing message...',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3E84DC),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _editingMessageId = null;
                      _messageController.clear();
                    }),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isEditing
                        ? const Color(0xFF10B981)
                        : const Color(0xFF3E84DC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEditing ? Icons.check_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
