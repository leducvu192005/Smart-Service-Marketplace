import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class CurrentJobScreen extends StatefulWidget {
  final dynamic initialJob; // Optional initial job details passed from home
  const CurrentJobScreen({super.key, this.initialJob});

  @override
  State<CurrentJobScreen> createState() => _CurrentJobScreenState();
}

class _CurrentJobScreenState extends State<CurrentJobScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isUpdating = false;
  dynamic _job;

  @override
  void initState() {
    super.initState();
    if (widget.initialJob != null) {
      _job = widget.initialJob;
      _isLoading = false;
    } else {
      _fetchCurrentJob();
    }
  }

  Future<void> _fetchCurrentJob() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.client.get('/workers/current-job');
      if (mounted) {
        setState(() {
          _job = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi tải thông tin công việc hiện tại'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _updateJobStatus(int bookingId) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final res = await _apiService.client.put(
        '/workers/jobs/$bookingId/status',
      );
      if (mounted) {
        setState(() {
          _job = res.data; // Update local job state
          _isUpdating = false;
        });

        final status = res.data['status'];
        String msg = '';
        if (status == 'in_progress') {
          msg = 'Đã bắt đầu thực hiện công việc!';
        } else if (status == 'done') {
          msg = 'Đã hoàn thành công việc thành công!';
          _job = null; // Cleared as it is now in history
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái công việc thất bại'),
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
          'Công việc hiện tại',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _job == null
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Status Tracker Banner
                  _buildStatusTracker(theme),
                  const SizedBox(height: 24),

                  // Main Job Details Card
                  _buildDetailsCard(theme),
                  const Spacer(),

                  // Action Button
                  _buildActionButton(theme),
                  const SizedBox(height: 16),
                ],
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
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có công việc đang chạy',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành hoặc chưa nhận công việc nào. Hãy sang tab Tìm việc để nhận việc mới nhé!',
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

  Widget _buildStatusTracker(ThemeData theme) {
    final status = _job['status'];
    final bool isAccepted = status == 'accepted';
    final bool isInProgress = status == 'in_progress';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _buildStep(
            title: 'Đã nhận',
            isActive: isAccepted || isInProgress,
            isCompleted: isInProgress,
            theme: theme,
          ),
          Expanded(
            child: Container(
              height: 2,
              color: isInProgress ? theme.primaryColor : Colors.grey.shade200,
            ),
          ),
          _buildStep(
            title: 'Đang làm',
            isActive: isInProgress,
            isCompleted: false,
            theme: theme,
          ),
          Expanded(child: Container(height: 2, color: Colors.grey.shade200)),
          _buildStep(
            title: 'Hoàn thành',
            isActive: false,
            isCompleted: false,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required bool isActive,
    required bool isCompleted,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isCompleted
              ? theme.primaryColor
              : isActive
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : CircleAvatar(
                  radius: 6,
                  backgroundColor: isActive
                      ? theme.primaryColor
                      : Colors.grey.shade300,
                ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: isActive || isCompleted
                ? const Color(0xFF1E293B)
                : Colors.grey,
            fontWeight: isActive || isCompleted
                ? FontWeight.bold
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    final String serviceName = _job['service_name'];
    final String address = _job['address'];
    final String timeStr = _job['scheduled_time'];
    final double price = (_job['price'] as num).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Service
          Text(
            'CHI TIẾT DỊCH VỤ',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            serviceName,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),

          // Address
          _buildInfoRow(
            label: 'Địa chỉ thực hiện',
            value: address,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 20),

          // Time
          _buildInfoRow(
            label: 'Thời gian hẹn',
            value: _formatDateTime(timeStr),
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 20),

          // Price
          _buildInfoRow(
            label: 'Đơn giá thanh toán',
            value: '${price.toStringAsFixed(0)}đ',
            icon: Icons.monetization_on_outlined,
            valueColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    final int bookingId = _job['booking_id'];
    final String status = _job['status'];
    final bool isAccepted = status == 'accepted';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : () => _updateJobStatus(bookingId),
        style: ElevatedButton.styleFrom(
          backgroundColor: isAccepted ? theme.primaryColor : Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isUpdating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isAccepted ? 'Bắt đầu công việc' : 'Hoàn thành công việc',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
