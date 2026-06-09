import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/api_service.dart';
import '../widgets/status_badge.dart';

class FinancialPage extends StatefulWidget {
  const FinancialPage({super.key});

  @override
  State<FinancialPage> createState() => _FinancialPageState();
}

class _FinancialPageState extends State<FinancialPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic> _stats = {};
  List<dynamic> _withdrawals = [];
  List<dynamic> _refunds = [];
  List<dynamic> _revenueChart = [];
  List<dynamic> _bookingsChart = [];
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final futures = await Future.wait([
        _api.client.get('/admin/financial-stats'),
        _api.client.get('/admin/withdrawals'),
        _api.client.get('/admin/refunds'),
        _api.client.get('/admin/revenue-chart'),
        _api.client.get('/admin/bookings-chart'),
      ]);
      if (mounted) {
        setState(() {
          _stats = futures[0].data ?? {};
          _withdrawals = futures[1].data ?? [];
          _refunds = futures[2].data ?? [];
          _revenueChart = futures[3].data ?? [];
          _bookingsChart = futures[4].data ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processWithdrawal(int id, bool approve) async {
    try {
      await _api.client.post(
        '/admin/withdrawals/$id/${approve ? 'approve' : 'reject'}',
      );
      _snack(
        approve ? '✅ Đã duyệt chi rút tiền #$id' : 'Đã từ chối rút tiền #$id',
        approve ? Colors.green : Colors.orange,
      );
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  Future<void> _processRefund(int id, bool approve) async {
    try {
      await _api.client.post(
        '/admin/refunds/$id/${approve ? 'approve' : 'reject'}',
      );
      _snack(
        approve
            ? '✅ Đã phê duyệt hoàn tiền #$id'
            : 'Đã từ chối hoàn tiền #$id',
        approve ? Colors.green : Colors.orange,
      );
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final pendingW = _withdrawals.where((w) => w['status'] == 'pending').length;
    final pendingR = _refunds.where((r) => r['status'] == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Stats Row
          Row(
            children: [
              _FinStat(
                'Tổng Doanh Thu',
                _fmtVnd(_stats['total_revenue']),
                Icons.trending_up_rounded,
                const Color(0xFF4F46E5),
                const Color(0xFFEEF2FF),
              ),
              const SizedBox(width: 16),
              _FinStat(
                'Doanh Thu Ròng (10%)',
                _fmtVnd(_stats['system_net_revenue']),
                Icons.account_balance_rounded,
                const Color(0xFF10B981),
                const Color(0xFFECFDF5),
              ),
              const SizedBox(width: 16),
              _FinStat(
                'Tổng Rút Tiền',
                _fmtVnd(_stats['total_withdrawn']),
                Icons.wallet_rounded,
                const Color(0xFFF59E0B),
                const Color(0xFFFFFBEB),
              ),
              const SizedBox(width: 16),
              _FinStat(
                'Tổng Hoàn Tiền',
                _fmtVnd(_stats['total_refunded']),
                Icons.assignment_return_rounded,
                const Color(0xFFEF4444),
                const Color(0xFFFEF2F2),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _ChartCard(
                  title: '📈 Doanh Thu Theo Tháng',
                  subtitle: '12 tháng gần nhất',
                  child: _RevenueBarChart(data: _revenueChart),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: '📊 Phân Bổ Đơn Hàng',
                  subtitle: 'Theo trạng thái',
                  child: _BookingDonutChart(data: _bookingsChart),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tabs card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tab bar header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Chi Tiết Tài Chính',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _load,
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  labelColor: const Color(0xFF4F46E5),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF4F46E5),
                  indicatorSize: TabBarIndicatorSize.label,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: [
                    const Tab(text: 'Tổng Quan'),
                    _badgeTab('Rút Tiền', pendingW, Colors.orange),
                    _badgeTab('Hoàn Tiền', pendingR, Colors.red),
                    const Tab(text: 'Doanh Thu Chi Tiết'),
                  ],
                ),
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _OverviewTab(stats: _stats),
                      _WithdrawalsTab(
                        withdrawals: _withdrawals,
                        onProcess: _processWithdrawal,
                      ),
                      _RefundsTab(
                        refunds: _refunds,
                        onProcess: _processRefund,
                      ),
                      _RevenueDetailTab(data: _revenueChart),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtVnd(dynamic value) {
    final n = value is num ? value : num.tryParse('$value') ?? 0;
    return '${n.toStringAsFixed(0)} đ';
  }

  Widget _badgeTab(String label, int count, Color badgeColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Chart Card Container ────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Revenue Bar Chart ────────────────────────────────────────────────────────

class _RevenueBarChart extends StatelessWidget {
  final List<dynamic> data;
  const _RevenueBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Chưa có dữ liệu doanh thu')),
      );
    }

    final revenues = data.map<double>((d) {
      final v = d['revenue'];
      return v is num ? v.toDouble() : 0.0;
    }).toList();

    final maxRevenue = revenues.isEmpty
        ? 1.0
        : revenues.reduce(math.max).clamp(1.0, double.infinity);

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final rev = revenues[i];
                final ratio = rev / maxRevenue;
                final isLast = i == data.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (rev > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _shortMoney(rev),
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                color: isLast
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF64748B),
                                fontWeight: isLast
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 40),
                          height: (ratio * 140).clamp(4.0, 140.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isLast
                                  ? [
                                      const Color(0xFF4F46E5),
                                      const Color(0xFF818CF8),
                                    ]
                                  : [
                                      const Color(0xFF818CF8),
                                      const Color(0xFFC7D2FE),
                                    ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(data.length, (i) {
              final label = '${data[i]['label'] ?? ''}';
              // show shortened label: only month part
              final shortLabel = label.length >= 5 ? label.substring(0, 5) : label;
              final isLast = i == data.length - 1;
              return Expanded(
                child: Text(
                  shortLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    color: isLast
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF94A3B8),
                    fontWeight:
                        isLast ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _shortMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Booking Donut Chart ──────────────────────────────────────────────────────

class _BookingDonutChart extends StatelessWidget {
  final List<dynamic> data;
  const _BookingDonutChart({required this.data});

  static const _colors = [
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Chưa có dữ liệu')),
      );
    }

    final counts = data.map<int>((d) {
      final v = d['count'];
      return v is int ? v : (v is num ? v.toInt() : 0);
    }).toList();

    final total = counts.fold(0, (a, b) => a + b);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _DonutPainter(
                counts: counts,
                colors: _colors,
                total: total,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Đơn hàng',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(data.length, (i) {
              final label = data[i]['label'] ?? data[i]['status'] ?? '';
              final count = counts[i];
              final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        Text(
                          '$count ($pct%)',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> counts;
  final List<Color> colors;
  final int total;

  _DonutPainter({
    required this.counts,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 36.0;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < counts.length; i++) {
      if (counts[i] == 0) continue;
      final sweepAngle = (counts[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.02,
        sweepAngle - 0.04,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.counts != counts || oldDelegate.total != total;
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _OverviewTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Tổng doanh thu dịch vụ',
        _fmtVnd(stats['total_revenue']),
        const Color(0xFF4F46E5),
      ),
      (
        'Doanh thu ròng hệ thống (10%)',
        _fmtVnd(stats['system_net_revenue']),
        const Color(0xFF10B981),
      ),
      (
        'Tổng tiền đã rút (Thợ)',
        _fmtVnd(stats['total_withdrawn']),
        const Color(0xFFF59E0B),
      ),
      (
        'Tổng tiền đã hoàn (Khách)',
        _fmtVnd(stats['total_refunded']),
        const Color(0xFFEF4444),
      ),
      (
        'Tổng số dư ví Thợ hiện tại',
        _fmtVnd(stats['wallet_balances_sum']),
        const Color(0xFF8B5CF6),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: item.$3.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: item.$3.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    item.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: item.$3,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static String _fmtVnd(dynamic value) {
    final n = value is num ? value : num.tryParse('$value') ?? 0;
    return '${n.toStringAsFixed(0)} đ';
  }
}

// ─── Revenue Detail Tab ───────────────────────────────────────────────────────

class _RevenueDetailTab extends StatelessWidget {
  final List<dynamic> data;
  const _RevenueDetailTab({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu doanh thu',
          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        ),
      );
    }

    // Show reversed (newest first)
    final reversed = List<dynamic>.from(data.reversed);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Tháng',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    )),
              ),
              Expanded(
                flex: 2,
                child: Text('Doanh thu',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    )),
              ),
              Expanded(
                flex: 2,
                child: Text('Phí nền tảng (10%)',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    )),
              ),
              Expanded(
                child: Text('Đơn',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...reversed.map((item) {
          final rev = _toNum(item['revenue']);
          final fee = _toNum(item['platform_fee']);
          final cnt = item['bookings_count'] ?? 0;
          final hasData = rev > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasData
                  ? const Color(0xFFEEF2FF).withOpacity(0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasData
                    ? const Color(0xFF818CF8).withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item['label']}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight:
                          hasData ? FontWeight.w700 : FontWeight.normal,
                      color: hasData
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _fmtVnd(rev),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _fmtVnd(fee),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$cnt',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static num _toNum(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
  static String _fmtVnd(num v) => '${v.toStringAsFixed(0)} đ';
}

// ─── Withdrawal Tab ───────────────────────────────────────────────────────────

class _WithdrawalsTab extends StatelessWidget {
  final List<dynamic> withdrawals;
  final Function(int, bool) onProcess;
  const _WithdrawalsTab({required this.withdrawals, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final pending = withdrawals.where((w) => w['status'] == 'pending').toList();
    final processed =
        withdrawals.where((w) => w['status'] != 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Text(
            'Chờ Duyệt (${pending.length})',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...pending.map((w) => _WithdrawalCard(w: w, onProcess: onProcess)),
          const SizedBox(height: 16),
        ],
        Text(
          'Đã Xử Lý (${processed.length})',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        ...processed.map((w) => _WithdrawalCard(w: w, onProcess: onProcess)),
      ],
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final Map<String, dynamic> w;
  final Function(int, bool) onProcess;
  const _WithdrawalCard({required this.w, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final isPending = w['status'] == 'pending';
    final workerName = w['worker_name'] as String? ?? 'Thợ #${w['worker_id']}';
    final workerPhone = w['worker_phone'] as String? ?? '—';
    final walletBalance = w['worker_wallet'];
    final walletStr = walletBalance != null
        ? '${(walletBalance as num).toStringAsFixed(0)} đ'
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isPending
                ? Colors.orange.withOpacity(0.3)
                : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPending
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.wallet_outlined,
              color: isPending ? Colors.orange : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workerName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.phone_rounded,
                      size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(workerPhone,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: const Color(0xFF64748B))),
                  if (walletStr != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.account_balance_wallet_rounded,
                        size: 11, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('Số dư ví: $walletStr',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: const Color(0xFF059669))),
                  ],
                ]),
                Text(
                  'Yêu cầu #${w['id']}',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(w['amount'] as num?)?.toStringAsFixed(0) ?? '0'} đ',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 4),
              if (isPending)
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onProcess(w['id'], false),
                      child: Text('Từ chối',
                          style: GoogleFonts.outfit(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onProcess(w['id'], true),
                      child: Text('Duyệt Chi',
                          style: GoogleFonts.outfit(fontSize: 11)),
                    ),
                  ],
                )
              else
                StatusBadge(status: w['status']),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Refund Tab ───────────────────────────────────────────────────────────────

class _RefundsTab extends StatelessWidget {
  final List<dynamic> refunds;
  final Function(int, bool) onProcess;
  const _RefundsTab({required this.refunds, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final pending = refunds.where((r) => r['status'] == 'pending').toList();
    final processed =
        refunds.where((r) => r['status'] != 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Text(
            'Chờ Phê Duyệt (${pending.length})',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ...pending.map((r) => _RefundCard(r: r, onProcess: onProcess)),
          const SizedBox(height: 16),
        ],
        Text(
          'Đã Xử Lý (${processed.length})',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        ...processed.map((r) => _RefundCard(r: r, onProcess: onProcess)),
      ],
    );
  }
}

class _RefundCard extends StatelessWidget {
  final Map<String, dynamic> r;
  final Function(int, bool) onProcess;
  const _RefundCard({required this.r, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final isPending = r['status'] == 'pending';
    final customerName = r['customer_name'] as String? ?? 'Khách hàng';
    final workerName = r['worker_name'] as String? ?? '—';
    final serviceName = r['service_name'] as String? ?? 'Dịch vụ';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isPending
                ? Colors.red.withOpacity(0.3)
                : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPending
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_return_outlined,
              color: isPending ? Colors.red : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.room_service_rounded,
                      size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(serviceName,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: const Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  const Icon(Icons.construction_rounded,
                      size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(workerName,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: const Color(0xFF64748B))),
                ]),
                Text(
                  'Lý do: ${r['reason'] ?? 'Không có'}  •  Đơn #${r['booking_id']}',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(r['amount'] as num?)?.toStringAsFixed(0) ?? '0'} đ',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              if (isPending)
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onProcess(r['id'], false),
                      child: Text('Từ chối',
                          style: GoogleFonts.outfit(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onProcess(r['id'], true),
                      child: Text('Phê Duyệt',
                          style: GoogleFonts.outfit(fontSize: 11)),
                    ),
                  ],
                )
              else
                StatusBadge(status: r['status']),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _FinStat extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color, bgColor;
  const _FinStat(this.title, this.value, this.icon, this.color, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
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
