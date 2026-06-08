import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.client.get('/support/tickets');
      if (mounted) {
        setState(() {
          _tickets = res.data;
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
    final controller = TextEditingController();
    final messages = <_ChatMessage>[
      _ChatMessage(
        isAgent: false,
        text: '${ticket['description'] ?? 'Khách hàng cần hỗ trợ.'}',
      ),
      const _ChatMessage(
        isAgent: true,
        text:
            'Chào bạn, bộ phận hỗ trợ đã tiếp nhận phản ánh và đang kiểm tra thông tin.',
      ),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 620,
                height: 560,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF101828),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
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
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ticket #${ticket['id']} | Đơn #${ticket['booking_id'] ?? 'N/A'}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF98A2B3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: messages.length,
                        itemBuilder: (context, index) =>
                            _MessageBubble(message: messages[index]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Nhập phản hồi hỗ trợ',
                                hintStyle: GoogleFonts.outfit(
                                  color: const Color(0xFF98A2B3),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD0D5DD),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD0D5DD),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              setDialogState(() {
                                messages.add(
                                  _ChatMessage(isAgent: true, text: text),
                                );
                                controller.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(46, 46),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.send_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (ticket['status'] == 'pending')
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateStatus(
                                  _asInt(ticket['id']),
                                  'in_progress',
                                );
                              },
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: const Text('Nhận xử lý'),
                            ),
                          const SizedBox(width: 8),
                          if (ticket['status'] != 'closed')
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateStatus(_asInt(ticket['id']), 'closed');
                              },
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                              ),
                              label: const Text('Đóng ticket'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
