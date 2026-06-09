import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../widgets/web_card.dart';

class TicketManagementPage extends StatefulWidget {
  const TicketManagementPage({super.key});

  @override
  State<TicketManagementPage> createState() => _TicketManagementPageState();
}

class _TicketManagementPageState extends State<TicketManagementPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<dynamic> _tickets = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isAdmin {
    try {
      final auth = context.read<AuthProvider>();
      return auth.role == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Admin dùng endpoint /admin/tickets để xem tất cả ticket (kể cả từ customer)
      // Support dùng /support/tickets
      final endpoint = _isAdmin ? '/admin/tickets' : '/support/tickets';
      final res = await _api.client.get(endpoint);
      if (mounted) {
        setState(() {
          _tickets = res.data is List ? List<dynamic>.from(res.data) : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await _api.client.put(
        '/support/tickets/$id/status',
        data: {'status': status},
      );
      _snack('Đã cập nhật trạng thái ticket.', const Color(0xFF059669));
      _load();
    } catch (e) {
      _snack('Không thể cập nhật ticket: $e', const Color(0xFFDC2626));
    }
  }

  List<dynamic> get _filtered => _filter == 'all'
      ? _tickets
      : _tickets.where((ticket) => ticket['status'] == _filter).toList();

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openChat(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => _ChatDialog(
        ticket: ticket,
        api: _api,
        onUpdateStatus: _updateStatus,
        asInt: _asInt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _tickets
        .where((ticket) => ticket['status'] == 'pending')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: WebCard(
        title: 'Tickets hỗ trợ',
        badge: pendingCount > 0 ? '$pendingCount chờ xử lý' : null,
        badgeColor: const Color(0xFFF59E0B),
        action: _TicketToolbar(
          filter: _filter,
          onFilterChanged: (value) => setState(() => _filter = value),
          onRefresh: _load,
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : _filtered.isEmpty
            ? _emptyState()
            : Column(
                children: _filtered.map((ticket) {
                  return _TicketRow(
                    ticket: Map<String, dynamic>.from(ticket),
                    onStart: () =>
                        _updateStatus(_asInt(ticket['id']), 'in_progress'),
                    onClose: () =>
                        _updateStatus(_asInt(ticket['id']), 'closed'),
                    onChat: () => _openChat(Map<String, dynamic>.from(ticket)),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(52),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 14),
          Text(
            'Không có ticket phù hợp',
            style: GoogleFonts.outfit(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
}

class _TicketToolbar extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onRefresh;

  const _TicketToolbar({
    required this.filter,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final filters = const [
      ('all', 'Tất cả'),
      ('pending', 'Chờ'),
      ('in_progress', 'Đang xử lý'),
      ('closed', 'Đã đóng'),
    ];

    return Row(
      children: [
        for (final item in filters)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChoiceChip(
              label: Text(item.$2, style: GoogleFonts.outfit(fontSize: 12)),
              selected: filter == item.$1,
              selectedColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(
                color: filter == item.$1
                    ? Colors.white
                    : const Color(0xFF475467),
              ),
              onSelected: (_) => onFilterChanged(item.$1),
              visualDensity: VisualDensity.compact,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onStart;
  final VoidCallback onClose;
  final VoidCallback onChat;

  const _TicketRow({
    required this.ticket,
    required this.onStart,
    required this.onClose,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${ticket['status'] ?? 'pending'}';
    final style = _styleFor(status);
    final creatorName = ticket['creator_name'] as String?;
    final creatorRole = ticket['creator_role'] as String?;

    // Map role to display
    String roleLabel = '';
    Color roleColor = Colors.grey;
    if (creatorRole == 'customer') {
      roleLabel = 'Khách hàng';
      roleColor = const Color(0xFF3B82F6);
    } else if (creatorRole == 'worker') {
      roleLabel = 'Thợ';
      roleColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: style.color,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ticket #${ticket['id']}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF667085),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ticket['booking_id'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Đơn #${ticket['booking_id']}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    _TicketStatusBadge(label: style.label, color: style.color),
                    if (creatorName != null && roleLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$creatorName • $roleLabel',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: roleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${ticket['title'] ?? 'Khiếu nại'}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF101828),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ticket['description'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF667085),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Wrap(
            spacing: 8,
            children: [
              if (status == 'pending')
                OutlinedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Nhận'),
                ),
              ElevatedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Hỗ trợ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              if (status != 'closed')
                ElevatedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Đóng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static _TicketStyle _styleFor(String status) {
    return switch (status) {
      'in_progress' => const _TicketStyle('Đang xử lý', Color(0xFF2563EB)),
      'closed' => const _TicketStyle('Đã đóng', Color(0xFF059669)),
      _ => const _TicketStyle('Chờ xử lý', Color(0xFFF59E0B)),
    };
  }
}

class _TicketStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TicketStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isAgent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: message.isAgent
              ? const Color(0xFF2563EB)
              : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.outfit(
            color: message.isAgent ? Colors.white : const Color(0xFF101828),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool isAgent;
  final String text;

  const _ChatMessage({required this.isAgent, required this.text});
}

class _TicketStyle {
  final String label;
  final Color color;

  const _TicketStyle(this.label, this.color);
}

// ─── Chat Dialog kết nối API thực ──────────────────────────────────────────
class _ChatDialog extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final ApiService api;
  final Future<void> Function(int, String) onUpdateStatus;
  final int Function(dynamic) asInt;

  const _ChatDialog({
    required this.ticket,
    required this.api,
    required this.onUpdateStatus,
    required this.asInt,
  });

  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loadingMsgs = true;
  bool _sending = false;

  int? get _bookingId {
    final v = widget.ticket['booking_id'];
    if (v == null) return null;
    return v is int ? v : int.tryParse('$v');
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_bookingId == null) {
      // Không có booking → hiển thị mô tả ticket như tin nhắn đầu tiên
      setState(() {
        _messages = [
          {
            'sender_id': -1, // khách hàng
            'message_text': widget.ticket['description'] ?? 'Khách hàng cần hỗ trợ.',
            'created_at': widget.ticket['created_at'] ?? '',
          }
        ];
        _loadingMsgs = false;
      });
      return;
    }
    try {
      final res = await widget.api.client.get('/support/bookings/$_bookingId/chat');
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(res.data ?? []);
          // Nếu chưa có tin nào, thêm mô tả ticket làm tin đầu
          if (_messages.isEmpty) {
            _messages.insert(0, {
              'sender_id': -1,
              'message_text': widget.ticket['description'] ?? 'Khách hàng cần hỗ trợ.',
              'created_at': widget.ticket['created_at'] ?? '',
            });
          }
          _loadingMsgs = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMsgs = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    // Optimistic update
    setState(() {
      _messages.add({
        'sender_id': 0, // support agent (current user)
        'message_text': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    if (_bookingId != null) {
      try {
        await widget.api.client.post(
          '/support/bookings/$_bookingId/chat',
          data: {'message_text': text},
        );
      } catch (_) {
        // Tin đã hiện trên UI, bỏ qua lỗi network
      }
    }
    if (mounted) setState(() => _sending = false);
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

  bool _isAgentMsg(Map<String, dynamic> msg) {
    // sender_id == 0 là optimistic support, sender_id != -1 và khác customer là agent
    final sid = msg['sender_id'];
    if (sid == null || sid == -1) return false;
    // Giả định sender là support nếu khác với creator ticket
    final creatorId = widget.ticket['creator_id'];
    if (creatorId == null) return sid == 0;
    return sid != creatorId && sid != -1;
  }

  String _formatTime(dynamic val) {
    if (val == null || '$val'.isEmpty) return '';
    try {
      final dt = DateTime.parse('$val').toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final status = '${ticket['status'] ?? 'pending'}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 640,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF101828),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ticket['title'] ?? 'Ticket hỗ trợ'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ticket #${ticket['id']}  •  Đơn #${_bookingId ?? 'N/A'}',
                          style: GoogleFonts.outfit(color: const Color(0xFF98A2B3), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: _loadingMsgs
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có tin nhắn nào',
                        style: GoogleFonts.outfit(color: const Color(0xFF667085)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(18),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        final isAgent = _isAgentMsg(msg);
                        final text = '${msg['message_text'] ?? ''}';
                        final time = _formatTime(msg['created_at']);
                        return Align(
                          alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: isAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isAgent ? const Color(0xFF2563EB) : const Color(0xFFF2F4F7),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: Radius.circular(isAgent ? 14 : 4),
                                      bottomRight: Radius.circular(isAgent ? 4 : 14),
                                    ),
                                  ),
                                  child: Text(
                                    text,
                                    style: GoogleFonts.outfit(
                                      color: isAgent ? Colors.white : const Color(0xFF101828),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (time.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      isAgent ? 'Support • $time' : 'Khách hàng • $time',
                                      style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF98A2B3)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Input box
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.outfit(fontSize: 13),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhập phản hồi hỗ trợ...',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF98A2B3), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(46, 46),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'pending')
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onUpdateStatus(widget.asInt(ticket['id']), 'in_progress');
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 17),
                      label: const Text('Nhận xử lý'),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  const SizedBox(width: 8),
                  if (status != 'closed')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onUpdateStatus(widget.asInt(ticket['id']), 'closed');
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 17),
                      label: const Text('Đóng ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
