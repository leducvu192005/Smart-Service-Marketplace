import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/api_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/web_card.dart';

class DashboardPage extends StatefulWidget {
  final bool isAdmin;

  const DashboardPage({super.key, required this.isAdmin});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentBookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      Map<String, dynamic> stats = {};
      List<dynamic> allBookings = [];
      List<dynamic> workers = [];

      if (widget.isAdmin) {
        final dashboard = await _api.client.get('/admin/dashboard');
        stats = Map<String, dynamic>.from(dashboard.data);
      }

      final bookingRes = await _api.client.get('/support/bookings');
      allBookings = bookingRes.data as List;

      if (!widget.isAdmin) {
        final workerRes = await _api.client.get('/support/workers');
        workers = workerRes.data as List;
        // Lấy thống kê support từ API thực
        try {
          final supportStatsRes = await _api.client.get('/support/support-stats');
          final supportStats = supportStatsRes.data as Map<String, dynamic>;
          stats = {
            'total_users': 0,
            'total_workers': supportStats['total_workers'] ?? workers.length,
            'total_bookings': supportStats['total_bookings'] ?? allBookings.length,
            'total_revenue': allBookings
                .where((b) => b['status'] == 'done')
                .fold<num>(0, (sum, b) => sum + _toNum(b['price'])),
            'pending_tickets': supportStats['pending_tickets'] ?? 0,
            'pending_workers': supportStats['pending_workers'] ?? 0,
            'pending_bookings': supportStats['pending_bookings'] ?? 0,
          };
        } catch (_) {
          final supportRevenue = allBookings
              .where((booking) => booking['status'] == 'done')
              .fold<num>(0, (sum, booking) => sum + _toNum(booking['price']));
          stats = {
            'total_users': 0,
            'total_workers': workers.length,
            'total_bookings': allBookings.length,
            'total_revenue': supportRevenue,
          };
        }
      }

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _recentBookings = allBookings.take(7).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static num _toNum(dynamic value) =>
      value is num ? value : num.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroPanel(isAdmin: widget.isAdmin),
            const SizedBox(height: 20),
            _StatsGrid(stats: _stats, isAdmin: widget.isAdmin),
            const SizedBox(height: 16),
            // Pending alerts row — chỉ hiện nếu có dữ liệu
            _PendingAlertsRow(stats: _stats, isAdmin: widget.isAdmin),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: WebCard(
                    title: widget.isAdmin
                        ? 'Tầm nhìn tài chính'
                        : 'Hàng đợi vận hành',
                    child: widget.isAdmin
                        ? _FinanceSnapshot(stats: _stats)
                        : _SupportQueue(bookings: _recentBookings),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: WebCard(
                    title: widget.isAdmin
                        ? 'Quyền quản trị'
                        : 'Kịch bản xử lý nhanh',
                    child: _ActionChecklist(isAdmin: widget.isAdmin),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            WebCard(
              title: 'Đơn hàng gần đây',
              action: IconButton(
                tooltip: 'Làm mới',
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _load,
              ),
              child: _RecentBookingsTable(bookings: _recentBookings),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final bool isAdmin;

  const _HeroPanel({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final accent = isAdmin ? const Color(0xFF2563EB) : const Color(0xFF0F766E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.headset_mic_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin
                      ? 'Giao diện Super Admin'
                      : 'Giao diện Support Operator',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF101828),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin
                      ? 'Theo dõi vận hành, tài chính, dịch vụ, nhân sự và marketing trong cùng một bảng điều khiển.'
                      : 'Tập trung vào duyệt thợ, điều phối đơn, xử lý ticket và xác nhận thanh toán cho thợ.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF667085),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isAdmin;

  const _StatsGrid({required this.stats, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final revenue = stats['total_revenue'];
    final cards = [
      _StatData(
        'Khách hàng',
        '${stats['total_users'] ?? 0}',
        Icons.people_alt_rounded,
        const Color(0xFF2563EB),
      ),
      _StatData(
        'Thợ hoạt động',
        '${stats['total_workers'] ?? 0}',
        Icons.construction_rounded,
        const Color(0xFF7C3AED),
      ),
      _StatData(
        'Đơn hàng',
        '${stats['total_bookings'] ?? 0}',
        Icons.calendar_month_rounded,
        const Color(0xFFF59E0B),
      ),
      _StatData(
        isAdmin ? 'Doanh thu' : 'Đã thu hộ',
        _money(revenue),
        Icons.payments_rounded,
        const Color(0xFF059669),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: _StatCard(data: cards[i])),
          if (i < cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  static String _money(dynamic value) {
    final amount = value is num ? value : num.tryParse('$value') ?? 0;
    return '${amount.toStringAsFixed(0)} đ';
  }
}

// Widget hiển thị cảnh báo các mục đang chờ xử lý
class _PendingAlertsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isAdmin;

  const _PendingAlertsRow({required this.stats, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final alerts = <_AlertItem>[];

    if (isAdmin) {
      final pw = stats['pending_workers'] ?? 0;
      final pt = stats['pending_tickets'] ?? 0;
      final pwd = stats['pending_withdrawals'] ?? 0;
      final pr = stats['pending_refunds'] ?? 0;
      if (pw > 0) alerts.add(_AlertItem('$pw thợ chờ duyệt hồ sơ', Icons.verified_user_rounded, const Color(0xFF7C3AED)));
      if (pt > 0) alerts.add(_AlertItem('$pt ticket chờ xử lý', Icons.confirmation_number_rounded, const Color(0xFFF59E0B)));
      if (pwd > 0) alerts.add(_AlertItem('$pwd yêu cầu rút tiền', Icons.wallet_rounded, const Color(0xFF059669)));
      if (pr > 0) alerts.add(_AlertItem('$pr yêu cầu hoàn tiền', Icons.assignment_return_rounded, const Color(0xFFEF4444)));
    } else {
      final pw = stats['pending_workers'] ?? 0;
      final pt = stats['pending_tickets'] ?? 0;
      final pb = stats['pending_bookings'] ?? 0;
      if (pw > 0) alerts.add(_AlertItem('$pw thợ chờ duyệt', Icons.verified_user_rounded, const Color(0xFF7C3AED)));
      if (pt > 0) alerts.add(_AlertItem('$pt ticket chờ xử lý', Icons.confirmation_number_rounded, const Color(0xFFF59E0B)));
      if (pb > 0) alerts.add(_AlertItem('$pb đơn hàng chờ điều phối', Icons.alt_route_rounded, const Color(0xFF2563EB)));
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 10),
          Text(
            'Cần xử lý: ',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF92400E)),
          ),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: alerts.map((a) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a.icon, size: 14, color: a.color),
                  const SizedBox(width: 4),
                  Text(a.label, style: GoogleFonts.outfit(fontSize: 12, color: a.color, fontWeight: FontWeight.w600)),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem {
  final String label;
  final IconData icon;
  final Color color;
  const _AlertItem(this.label, this.icon, this.color);
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.title, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF101828),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF667085),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceSnapshot extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _FinanceSnapshot({required this.stats});

  @override
  Widget build(BuildContext context) {
    final gross = _toNum(stats['total_revenue']);
    final platformFee = gross * 0.1;
    final workerPayout = gross * 0.9;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _MoneyLine(
            label: 'Tổng doanh thu',
            value: gross,
            color: const Color(0xFF2563EB),
          ),
          _MoneyLine(
            label: 'Doanh thu nền tảng 10%',
            value: platformFee,
            color: const Color(0xFF059669),
          ),
          _MoneyLine(
            label: 'Dòng tiền giữ hộ thợ 90%',
            value: workerPayout,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  static num _toNum(dynamic value) =>
      value is num ? value : num.tryParse('$value') ?? 0;
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final num value;
  final Color color;

  const _MoneyLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF475467),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} đ',
            style: GoogleFonts.outfit(
              color: const Color(0xFF101828),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportQueue extends StatelessWidget {
  final List<dynamic> bookings;

  const _SupportQueue({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final pending = bookings.where((b) => b['status'] == 'pending').length;
    final active = bookings
        .where((b) => b['status'] == 'accepted' || b['status'] == 'in_progress')
        .length;
    final done = bookings.where((b) => b['status'] == 'done').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _QueueLine(
            label: 'Đơn chờ điều phối',
            count: pending,
            color: const Color(0xFFF59E0B),
          ),
          _QueueLine(
            label: 'Đơn đang xử lý',
            count: active,
            color: const Color(0xFF2563EB),
          ),
          _QueueLine(
            label: 'Đơn hoàn tất chờ thu tiền',
            count: done,
            color: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}

class _QueueLine extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _QueueLine({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF475467),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChecklist extends StatelessWidget {
  final bool isAdmin;

  const _ActionChecklist({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final items = isAdmin
        ? [
            (
              'Phê duyệt rút tiền và hoàn tiền',
              Icons.account_balance_wallet_rounded,
            ),
            ('Cập nhật dịch vụ và biểu giá', Icons.room_service_rounded),
            ('Quản lý nhân sự support', Icons.badge_rounded),
            ('Tạo voucher và thông báo', Icons.campaign_rounded),
          ]
        : [
            ('Duyệt hồ sơ thợ mới', Icons.verified_user_rounded),
            ('Đổi thợ hoặc đổi giờ đơn hàng', Icons.alt_route_rounded),
            ('Xác nhận thu tiền và giải ngân ví', Icons.payments_rounded),
            ('Nhận xử lý và đóng ticket', Icons.support_agent_rounded),
          ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final item in items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.$2, color: const Color(0xFF475467), size: 18),
              ),
              title: Text(
                item.$1,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF344054),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentBookingsTable extends StatelessWidget {
  final List<dynamic> bookings;

  const _RecentBookingsTable({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(42),
        child: Center(
          child: Text(
            'Chưa có đơn hàng gần đây',
            style: GoogleFonts.outfit(color: const Color(0xFF667085)),
          ),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(90),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2.4),
        3: FixedColumnWidth(132),
        4: FixedColumnWidth(128),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            'Mã đơn',
            'Dịch vụ',
            'Địa chỉ',
            'Lịch hẹn',
            'Trạng thái',
          ].map(_headerCell).toList(),
        ),
        ...bookings.map((booking) {
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
            ),
            children: [
              _bodyCell(
                '#${booking['booking_id'] ?? booking['id'] ?? '-'}',
                strong: true,
              ),
              _bodyCell('${booking['service_name'] ?? 'Dịch vụ'}'),
              _bodyCell('${booking['address'] ?? ''}', muted: true),
              _bodyCell(_formatTime(booking['scheduled_time']), muted: true),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: StatusBadge(status: '${booking['status'] ?? 'pending'}'),
              ),
            ],
          );
        }),
      ],
    );
  }

  static Widget _headerCell(String text) {
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

  static Widget _bodyCell(
    String text, {
    bool strong = false,
    bool muted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          color: strong
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

  static String _formatTime(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse('$value').toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '$value';
    }
  }
}
