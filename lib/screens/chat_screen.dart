import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/mesh_service.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  final String myId;
  final String myName;
  final Peer peer;
  final DatabaseService db;
  final MeshService mesh;

  const ChatScreen({
    super.key,
    required this.myId,
    required this.myName,
    required this.peer,
    required this.db,
    required this.mesh,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Re-listen to messages and refresh
    widget.mesh.startListening(widget.myId, (senderId, text) {
      if (senderId == widget.peer.name || senderId == widget.peer.host) {
        _loadMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    final msgs = await widget.db.getMessages(widget.peer.name, widget.myId);
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;

    final msg = Message(
      id: const Uuid().v4(),
      senderId: widget.myId,
      receiverId: widget.peer.name,
      text: text,
      timestamp: DateTime.now(),
      isFromMe: true,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(msg);
      _sending = true;
    });
    _msgController.clear();
    _scrollToBottom();

    await widget.db.saveMessage(msg);
    final success =
        await widget.mesh.sendMessage(widget.peer.host, widget.myId, text);

    final newStatus = success ? MessageStatus.sent : MessageStatus.failed;
    await widget.db.updateMessageStatus(msg.id, newStatus);

    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        _messages[idx] = Message(
          id: msg.id,
          senderId: msg.senderId,
          receiverId: msg.receiverId,
          text: msg.text,
          timestamp: msg.timestamp,
          isFromMe: true,
          status: newStatus,
        );
      }
      _sending = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.bgCard,
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Clear Chat',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Delete all messages in this conversation?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.db.deleteConversation(widget.peer.name, widget.myId);
      setState(() => _messages = []);
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: Text(
                widget.peer.name.isNotEmpty
                    ? widget.peer.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peer.name,
                    style: const TextStyle(fontSize: 16)),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppTheme.online, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Online',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.online)),
                  ],
                )
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final showDate = i == 0 ||
                              !_isSameDay(_messages[i - 1].timestamp,
                                  _messages[i].timestamp);
                          return Column(
                            children: [
                              if (showDate)
                                _buildDateDivider(_messages[i].timestamp),
                              _buildMessageBubble(_messages[i]),
                            ],
                          );
                        },
                      ),
          ),

          // Input area
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 56,
              color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('Say hello to ${widget.peer.name}!',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.bgCard2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatDate(dt),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          const Expanded(child: Divider(color: AppTheme.bgCard2)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    return GestureDetector(
      onLongPress: () => _copyMessage(msg.text),
      child: Align(
        alignment:
            msg.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: msg.isFromMe ? AppTheme.myBubble : AppTheme.theirBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(msg.isFromMe ? 16 : 4),
              bottomRight: Radius.circular(msg.isFromMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: msg.isFromMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 10),
                  ),
                  if (msg.isFromMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(msg.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white60),
        );
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 12, color: Colors.white60);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.white);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.redAccent);
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard2,
        border: Border(top: BorderSide(color: Color(0xFF2A2A4A), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              focusNode: _focusNode,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle:
                    TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Today';
    if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}
