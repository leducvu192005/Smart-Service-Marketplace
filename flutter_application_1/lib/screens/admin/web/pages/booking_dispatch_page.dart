import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/api_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/web_card.dart';

class BookingDispatchPage extends StatefulWidget {
  const BookingDispatchPage({super.key});

  @override
  State<BookingDispatchPage> createState() => _BookingDispatchPageState();
}

class _BookingDispatchPageState extends State<BookingDispatchPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<dynamic> _bookings = [];
  List<dynamic> _workers = [];
  String _status = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bookings = await _api.client.get('/support/bookings');
      final workers = await _api.client.get('/support/workers');
      if (!mounted) return;
      setState(() {
        _bookings = bookings.data;
        _workers = workers.data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    var result = _status == 'all'
        ? _bookings
        : _bookings.where((b) => b['status'] == _status).toList();
    final text = _query.trim().toLowerCase();
    if (text.isNotEmpty) {
      result = result.where((b) {
        return '${b['booking_id'] ?? b['id']}'.contains(text) ||
            '${b['service_name'] ?? ''}'.toLowerCase().contains(text) ||
            '${b['address'] ?? ''}'.toLowerCase().contains(text);
      }).toList();
    }
    return result;
  }

  Future<void> _cancelBooking(int id) async {
    try {
      await _api.client.post('/support/bookings/$id/cancel');
      _snack('Đã hủy đơn #$id.', const Color(0xFFF59E0B));
      _load();
    } catch (e) {
      _snack('Không thể hủy đơn: $e', const Color(0xFFDC2626));
    }
  }

  Future<void> _confirmPayment(int id) async {
    try {
      await _api.client.post('/support/bookings/$id/confirm-payment');
      _snack(
        'Đã xác nhận thu tiền và giải ngân 90% vào ví thợ.',
        const Color(0xFF059669),
      );
      _load();
    } catch (e) {
      _snack('Không thể xác nhận thanh toán: $e', const Color(0xFFDC2626));
    }
  }

  Future<void> _reassignWorker(int bookingId, int workerId) async {
    try {
      await _api.client.post(
        '/support/bookings/$bookingId/reassign',
        queryParameters: {'new_worker_id': workerId},
      );
      _snack(
        'Đã đổi thợ điều phối cho đơn #$bookingId.',
        const Color(0xFF059669),
      );
      _load();
    } catch (e) {
      _snack('Không thể đổi thợ: $e', const Color(0xFFDC2626));
    }
  }

  Future<void> _reschedule(int bookingId, DateTime newTime) async {
    try {
      await _api.client.put(
        '/support/bookings/$bookingId/reschedule',
        data: {'scheduled_time': newTime.toIso8601String()},
      );
      _snack('Đã đổi lịch hẹn cho đơn #$bookingId.', const Color(0xFF059669));
      _load();
    } catch (e) {
      _snack('Không thể đổi lịch: $e', const Color(0xFFDC2626));
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showRescheduleDialog(int bookingId, dynamic currentTime) async {
    var current = DateTime.now();
    try {
      current = DateTime.parse('$currentTime');
    } catch (_) {}

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    _reschedule(
      bookingId,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  void _showReassignDialog(int bookingId, dynamic currentWorkerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Chọn thợ điều phối',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 460,
            child: _workers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Chưa có danh sách thợ khả dụng.',
                      style: GoogleFonts.outfit(color: const Color(0xFF667085)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _workers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final worker = _workers[index];
                      final isCurrent = worker['id'] == currentWorkerId;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(_initial(worker['full_name'])),
                        ),
                        title: Text(
                          '${worker['full_name'] ?? 'Thợ'}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'SĐT: ${worker['phone'] ?? '-'} | Đánh giá: ${worker['rating'] ?? 5.0}',
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                        trailing: isCurrent
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF059669),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _reassignWorker(bookingId, _asInt(worker['id']));
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: WebCard(
        title: 'Điều phối đơn hàng',
        badge: '${_filtered.length}',
        badgeColor: const Color(0xFF2563EB),
        action: _Toolbar(
          status: _status,
          onStatusChanged: (value) => setState(() => _status = value),
          onSearch: (value) => setState(() => _query = value),
          onRefresh: _load,
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : _filtered.isEmpty
            ? _emptyState()
            : _BookingsTable(
                bookings: _filtered,
                onCancel: (id) => _cancelBooking(id),
                onConfirmPayment: (id) => _confirmPayment(id),
                onReassign: (booking) => _showReassignDialog(
                  _asInt(booking['booking_id'] ?? booking['id']),
                  booking['worker_id'],
                ),
                onReschedule: (booking) => _showRescheduleDialog(
                  _asInt(booking['booking_id'] ?? booking['id']),
                  booking['scheduled_time'],
                ),
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(52),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Không có đơn hàng phù hợp',
            style: GoogleFonts.outfit(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
  static String _initial(dynamic value) {
    final text = '$value'.trim();
    return text.isEmpty || text == 'null'
        ? 'T'
        : text.substring(0, 1).toUpperCase();
  }
}

class _Toolbar extends StatelessWidget {
  final String status;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;

  const _Toolbar({
    required this.status,
    required this.onStatusChanged,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final filters = const [
      ('all', 'Tất cả'),
      ('pending', 'Chờ'),
      ('accepted', 'Đã nhận'),
      ('in_progress', 'Đang làm'),
      ('done', 'Xong'),
      ('cancelled', 'Hủy'),
    ];

    return Row(
      children: [
        SizedBox(
          width: 230,
          height: 38,
          child: TextField(
            onChanged: onSearch,
            style: GoogleFonts.outfit(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm mã đơn, dịch vụ, địa chỉ',
              hintStyle: GoogleFonts.outfit(
                color: const Color(0xFF98A2B3),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        for (final filter in filters)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChoiceChip(
              label: Text(filter.$2, style: GoogleFonts.outfit(fontSize: 12)),
              selected: status == filter.$1,
              selectedColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(
                color: status == filter.$1
                    ? Colors.white
                    : const Color(0xFF475467),
              ),
              onSelected: (_) => onStatusChanged(filter.$1),
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

class _BookingsTable extends StatelessWidget {
  final List<dynamic> bookings;
  final ValueChanged<int> onCancel;
  final ValueChanged<int> onConfirmPayment;
  final ValueChanged<Map<String, dynamic>> onReassign;
  final ValueChanged<Map<String, dynamic>> onReschedule;

  const _BookingsTable({
    required this.bookings,
    required this.onCancel,
    required this.onConfirmPayment,
    required this.onReassign,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(82),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(2.4),
        3: FixedColumnWidth(128),
        4: FixedColumnWidth(104),
        5: FixedColumnWidth(128),
        6: FixedColumnWidth(180),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            'Mã',
            'Dịch vụ',
            'Địa chỉ',
            'Lịch hẹn',
            'Giá',
            'Trạng thái',
            'Thao tác',
          ].map(_header).toList(),
        ),
        ...bookings.map((booking) {
          final id = _asInt(booking['booking_id'] ?? booking['id']);
          final status = '${booking['status'] ?? 'pending'}';
          final canOperate = status != 'cancelled' && status != 'done';
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
            ),
            children: [
              _cell('#$id', strong: true),
              _cell('${booking['service_name'] ?? 'Dịch vụ'}'),
              _cell('${booking['address'] ?? ''}', muted: true),
              _cell(_formatTime(booking['scheduled_time']), muted: true),
              _cell(_formatMoney(booking['price']), strong: true, green: true),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: StatusBadge(status: status),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (canOperate) ...[
                      _ActionButton(
                        icon: Icons.person_add_alt_1_rounded,
                        tooltip: 'Đổi thợ',
                        color: const Color(0xFF2563EB),
                        onTap: () =>
                            onReassign(Map<String, dynamic>.from(booking)),
                      ),
                      _ActionButton(
                        icon: Icons.schedule_rounded,
                        tooltip: 'Đổi giờ',
                        color: const Color(0xFFF59E0B),
                        onTap: () =>
                            onReschedule(Map<String, dynamic>.from(booking)),
                      ),
                      _ActionButton(
                        icon: Icons.cancel_outlined,
                        tooltip: 'Hủy đơn',
                        color: const Color(0xFFDC2626),
                        onTap: () => onCancel(id),
                      ),
                    ],
                    if (status != 'cancelled')
                      _ActionButton(
                        icon: Icons.payments_rounded,
                        tooltip: 'Xác nhận thu tiền',
                        color: const Color(0xFF059669),
                        onTap: () => onConfirmPayment(id),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: const Color(0xFF667085),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Widget _cell(
    String text, {
    bool strong = false,
    bool muted = false,
    bool green = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          color: green
              ? const Color(0xFF059669)
              : strong
              ? const Color(0xFF2563EB)
              : muted
              ? const Color(0xFF667085)
              : const Color(0xFF101828),
          fontSize: 13,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
  static String _formatMoney(dynamic value) {
    final amount = value is num ? value : num.tryParse('$value') ?? 0;
    return '${amount.toStringAsFixed(0)} đ';
  }

  static String _formatTime(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse('$value').toLocal();
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '$value';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
