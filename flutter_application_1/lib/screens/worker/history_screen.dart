import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.client.get('/workers/history');
      if (mounted) {
        setState(() {
          _history = res.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi tải lịch sử công việc'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final date = DateTime.parse(dateTimeStr).toLocal();
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(
          'Lịch sử công việc',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        color: theme.primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final job = _history[index];
                  return _buildHistoryCard(job, theme);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_toggle_off,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa hoàn thành công việc nào',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lịch sử những công việc bạn đã hoàn thành xuất sắc sẽ xuất hiện tại đây!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(dynamic job, ThemeData theme) {
    final String serviceName = job['service_name'];
    final String address = job['address'];
    final String timeStr = job['scheduled_time'];
    final double price = (job['price'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Name, Price and Completed status tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Hoàn thành',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Thanh toán: ${price.toStringAsFixed(0)}đ',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(timeStr),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
