import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../services/api_service.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final Booking booking;
  final bool isWorker;
  final String partnerName;

  const ChatDetailScreen({
    super.key,
    required this.booking,
    required this.isWorker,
    required this.partnerName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  bool _isLoading = true;
  int? _myUserId;
  String? _token;

  // Derive WebSocket URL from the existing ApiConfig (http → ws, https → wss)
  String get _wsUrl {
    final base = ApiConfig.baseUrl; // e.g. "http://10.0.2.2:8000"
    final wsBase = base.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    return '$wsBase/ws/chat/${widget.booking.id}?token=$_token';
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _myUserId = authProvider.user?['id'];
    _token = authProvider.token;
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectWebSocket() {
    if (_token == null) return;

    final uri = Uri.parse(_wsUrl);
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (rawData) {
        final data = jsonDecode(rawData as String) as Map<String, dynamic>;

        if (!mounted) return;

        if (data['type'] == 'history') {
          // Initial history dump from server
          final List<dynamic> msgs = data['messages'] ?? [];
          setState(() {
            _messages = msgs.map((m) => ChatMessage.fromJson(m)).toList();
            _isLoading = false;
          });
          _scrollToBottom();
        } else if (data['type'] == 'message') {
          // Real-time new message broadcast
          final msg = ChatMessage.fromJson(data);
          setState(() {
            _messages.add(msg);
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        debugPrint('[WS] Error: $error');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kết nối thất bại, thử lại...')),
          );
        }
      },
      onDone: () {
        debugPrint('[WS] Connection closed');
        if (mounted) setState(() {});
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _channel == null) return;

    _messageController.clear();
    _channel!.sink.add(jsonEncode({'message_text': text}));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.partnerName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Text(
                  'Đơn hàng #${widget.booking.id}',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(width: 6),
                // Live indicator dot
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'Trực tiếp',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final bool isMe = msg.senderId == _myUserId;
                          return _buildMessageBubble(msg, isMe, theme);
                        },
                      ),
          ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Hãy bắt đầu trò chuyện',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhắn tin để thống nhất thời gian, vị trí và công việc.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, ThemeData theme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? theme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isMe ? null : Border.all(color: const Color(0xFFF1F0EA)),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Text(
          msg.messageText,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isMe ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0EA),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send_rounded, color: theme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
