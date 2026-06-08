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
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
      final s = await _api.client.get('/admin/financial-stats');
      final w = await _api.client.get('/admin/withdrawals');
      final r = await _api.client.get('/admin/refunds');
      if (mounted) {
        setState(() {
          _stats = s.data;
          _withdrawals = w.data;
          _refunds = r.data;
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
        approve ? '✅ Đã phê duyệt hoàn tiền #$id' : 'Đã từ chối hoàn tiền #$id',
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
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                '\$${(_stats['total_revenue'] ?? 0).toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                const Color(0xFF4F46E5),
                const Color(0xFFEEF2FF),
              ),
              const SizedBox(width: 16),
              _FinStat(
                'Doanh Thu Ròng (10%)',
                '\$${(_stats['system_net_revenue'] ?? 0).toStringAsFixed(2)}',
                Icons.account_balance_rounded,
                const Color(0xFF10B981),
                const Color(0xFFECFDF5),
              ),
              const SizedBox(width: 16),
              _FinStat(
                'Tổng Rút Tiền',
                '\$${(_stats['total_withdrawn'] ?? 0).toStringAsFixed(2)}',
                Icons.wallet_rounded,
                const Color(0xFFF59E0B),
                const Color(0xFFFFFBEB),
              ),
              const SizedBox(width: 16),
              _FinStat(
                'Tổng Hoàn Tiền',
                '\$${(_stats['total_refunded'] ?? 0).toStringAsFixed(2)}',
                Icons.assignment_return_rounded,
                const Color(0xFFEF4444),
                const Color(0xFFFEF2F2),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                // Tab bar
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: [
                    const Tab(text: 'Tổng Quan'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Rút Tiền'),
                          if (pendingW > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingW',
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
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Hoàn Tiền'),
                          if (pendingR > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingR',
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
                    ),
                  ],
                ),
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _OverviewTab(stats: _stats),
                      _WithdrawalsTab(
                        withdrawals: _withdrawals,
                        onProcess: _processWithdrawal,
                      ),
                      _RefundsTab(refunds: _refunds, onProcess: _processRefund),
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
}

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
                      fontSize: 20,
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

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _OverviewTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Tổng doanh thu dịch vụ',
        '\$${stats['total_revenue'] ?? 0}',
        const Color(0xFF4F46E5),
      ),
      (
        'Doanh thu ròng hệ thống (10%)',
        '\$${stats['system_net_revenue'] ?? 0}',
        const Color(0xFF10B981),
      ),
      (
        'Tổng tiền đã rút (Thợ)',
        '\$${stats['total_withdrawn'] ?? 0}',
        const Color(0xFFF59E0B),
      ),
      (
        'Tổng tiền đã hoàn (Khách)',
        '\$${stats['total_refunded'] ?? 0}',
        const Color(0xFFEF4444),
      ),
      (
        'Tổng số dư ví Thợ hiện tại',
        '\$${stats['wallet_balances_sum'] ?? 0}',
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
}

class _WithdrawalsTab extends StatelessWidget {
  final List<dynamic> withdrawals;
  final Function(int, bool) onProcess;
  const _WithdrawalsTab({required this.withdrawals, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final pending = withdrawals.where((w) => w['status'] == 'pending').toList();
    final processed = withdrawals
        .where((w) => w['status'] != 'pending')
        .toList();

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  'Yêu cầu rút tiền #${w['id']}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Thợ ID: ${w['worker_id']}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${w['amount']}',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 16),
          if (isPending) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () => onProcess(w['id'], false),
              child: Text('Từ chối', style: GoogleFonts.outfit(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                elevation: 0,
              ),
              onPressed: () => onProcess(w['id'], true),
              child: Text('Duyệt Chi', style: GoogleFonts.outfit(fontSize: 12)),
            ),
          ] else
            StatusBadge(status: w['status']),
        ],
      ),
    );
  }
}

class _RefundsTab extends StatelessWidget {
  final List<dynamic> refunds;
  final Function(int, bool) onProcess;
  const _RefundsTab({required this.refunds, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final pending = refunds.where((r) => r['status'] == 'pending').toList();
    final processed = refunds.where((r) => r['status'] != 'pending').toList();

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  'Hoàn tiền Đơn #${r['booking_id']}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Lý do: ${r['reason'] ?? 'Không có'}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${r['amount']}',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          if (isPending) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () => onProcess(r['id'], false),
              child: Text('Từ chối', style: GoogleFonts.outfit(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                elevation: 0,
              ),
              onPressed: () => onProcess(r['id'], true),
              child: Text('Phê Duyệt', style: GoogleFonts.outfit(fontSize: 12)),
            ),
          ] else
            StatusBadge(status: r['status']),
        ],
      ),
    );
  }
}
