import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _stats = {};
  List<dynamic> _withdrawals = [];
  List<dynamic> _refunds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    setState(() => _isLoading = true);
    try {
      final statsRes = await _apiService.client.get('/admin/financial-stats');
      final withdrawalsRes = await _apiService.client.get('/admin/withdrawals');
      final refundsRes = await _apiService.client.get('/admin/refunds');
      setState(() {
        _stats = statsRes.data;
        _withdrawals = withdrawalsRes.data;
        _refunds = refundsRes.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông tin tài chính: $e')),
      );
    }
  }

  Future<void> _processWithdrawal(int id, bool approve) async {
    final endpoint = approve ? 'approve' : 'reject';
    try {
      await _apiService.client.post('/admin/withdrawals/$id/$endpoint');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Đã duyệt yêu cầu rút tiền!' : 'Đã từ chối yêu cầu rút tiền.')),
      );
      _fetchFinancialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xử lý yêu cầu rút tiền: $e')),
      );
    }
  }

  Future<void> _processRefund(int id, bool approve) async {
    final endpoint = approve ? 'approve' : 'reject';
    try {
      await _apiService.client.post('/admin/refunds/$id/$endpoint');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Đã phê duyệt hoàn tiền!' : 'Đã từ chối đề xuất hoàn tiền.')),
      );
      _fetchFinancialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xử lý hoàn tiền: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quản Lý Tài Chính', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Báo cáo tổng'),
              Tab(icon: Icon(Icons.wallet_outlined), text: 'Rút tiền ví'),
              Tab(icon: Icon(Icons.assignment_return_outlined), text: 'Lệnh hoàn tiền'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildStatsTab(),
                  _buildWithdrawalsTab(),
                  _buildRefundsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return RefreshIndicator(
      onRefresh: _fetchFinancialData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Thống kê dòng tiền hệ thống', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildFinCard('Tổng doanh thu (Dịch vụ)', '\$${_stats['total_revenue'] ?? 0.0}', Colors.indigo),
          const SizedBox(height: 12),
          _buildFinCard('Doanh thu ròng hệ thống (10%)', '\$${_stats['system_net_revenue'] ?? 0.0}', Colors.green),
          const SizedBox(height: 12),
          _buildFinCard('Tổng tiền đã rút (Thợ)', '\$${_stats['total_withdrawn'] ?? 0.0}', Colors.amber),
          const SizedBox(height: 12),
          _buildFinCard('Tổng tiền đã hoàn (Khách)', '\$${_stats['total_refunded'] ?? 0.0}', Colors.red),
          const SizedBox(height: 12),
          _buildFinCard('Tổng số dư ví Thợ hiện tại', '\$${_stats['wallet_balances_sum'] ?? 0.0}', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildFinCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalsTab() {
    final pending = _withdrawals.where((w) => w['status'] == 'pending').toList();
    final processed = _withdrawals.where((w) => w['status'] != 'pending').toList();

    return RefreshIndicator(
      onRefresh: _fetchFinancialData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Yêu cầu đang chờ duyệt (${pending.length})', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          pending.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text('Không có yêu cầu rút tiền nào đang chờ', style: GoogleFonts.outfit(color: Colors.grey))),
                )
              : Column(
                  children: pending.map((w) => _buildWithdrawalItem(w, true)).toList(),
                ),
          const Divider(height: 32),
          Text('Lịch sử yêu cầu đã xử lý', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          processed.isEmpty
              ? Center(child: Text('Chưa có yêu cầu nào được xử lý', style: GoogleFonts.outfit(color: Colors.grey)))
              : Column(
                  children: processed.map((w) => _buildWithdrawalItem(w, false)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalItem(Map<String, dynamic> w, bool isPending) {
    final status = w['status'] ?? 'pending';
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Yêu cầu rút tiền #${w['id']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Text(
                  '\$${w['amount']}',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Thợ ID: ${w['worker_id']}', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),
            if (isPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _processWithdrawal(w['id'], false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Từ Chối'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _processWithdrawal(w['id'], true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Duyệt Chi'),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trạng thái:', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.outfit(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildRefundsTab() {
    final pending = _refunds.where((r) => r['status'] == 'pending').toList();
    final processed = _refunds.where((r) => r['status'] != 'pending').toList();

    return RefreshIndicator(
      onRefresh: _fetchFinancialData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Đề xuất hoàn tiền đang chờ (${pending.length})', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          pending.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text('Không có đề xuất hoàn tiền nào', style: GoogleFonts.outfit(color: Colors.grey))),
                )
              : Column(
                  children: pending.map((r) => _buildRefundItem(r, true)).toList(),
                ),
          const Divider(height: 32),
          Text('Lịch sử lệnh hoàn tiền', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          processed.isEmpty
              ? Center(child: Text('Chưa có lịch sử lệnh hoàn tiền', style: GoogleFonts.outfit(color: Colors.grey)))
              : Column(
                  children: processed.map((r) => _buildRefundItem(r, false)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildRefundItem(Map<String, dynamic> r, bool isPending) {
    final status = r['status'] ?? 'pending';
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đề xuất hoàn tiền #${r['id']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Text(
                  '\$${r['amount']}',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Đơn đặt lịch: Đơn #${r['booking_id']}', style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 13)),
            Text('Lý do: ${r['reason']}', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            if (isPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _processRefund(r['id'], false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Từ Chối'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _processRefund(r['id'], true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Phê Duyệt'),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trạng thái:', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.outfit(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
