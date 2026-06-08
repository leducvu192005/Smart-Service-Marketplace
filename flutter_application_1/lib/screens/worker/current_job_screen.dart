import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class CurrentJobScreen extends StatefulWidget {
  final dynamic initialJob;
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

  Future<void> _updateStatus(String nextStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    final int bookingId = _job['booking_id'];
    try {
      final res = await _apiService.client.put(
        '/worker/bookings/$bookingId/state',
        queryParameters: {'status_update': nextStatus},
      );
      
      if (mounted) {
        setState(() {
          _job = res.data;
          _isUpdating = false;
        });

        String msg = 'Cập nhật trạng thái thành công!';
        if (nextStatus == 'done') {
          msg = 'Đã hoàn thành công việc & Nhận tiền vào ví!';
          _job = null; // Clear active job on complete
          Navigator.pop(context); // Go back to dashboard
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        String errMsg = 'Cập nhật trạng thái thất bại';
        if (e is DioException && e.response != null) {
          errMsg = e.response!.data['detail'] ?? errMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _captureAndUploadPhoto(String type) async {
    final picker = ImagePicker();
    final XFile? file = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn nguồn ảnh', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Hãy chọn chụp ảnh trực tiếp bằng camera hoặc tải lên từ thư viện.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () async {
              final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
              if (context.mounted) Navigator.pop(context, picked);
            },
            child: const Text('Thư viện'),
          ),
          ElevatedButton(
            onPressed: () async {
              final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 60);
              if (context.mounted) Navigator.pop(context, picked);
            },
            child: const Text('Máy ảnh'),
          ),
        ],
      ),
    );

    if (file == null) return;

    setState(() => _isUpdating = true);
    final int bookingId = _job['booking_id'];

    try {
      final formData = FormData.fromMap({
        'photo_type': type,
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });

      await _apiService.client.post(
        '/worker/bookings/$bookingId/upload-photos',
        data: formData,
      );

      // Refresh job data to fetch new photo URLs
      final res = await _apiService.client.get('/workers/current-job');
      if (mounted) {
        setState(() {
          _job = res.data;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải ảnh minh chứng thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải ảnh thất bại'), backgroundColor: Colors.redAccent),
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
      backgroundColor: const Color(0xFF1E293B), // Premium dark theme for worker
      appBar: AppBar(
        title: Text(
          'Đơn hàng đang thực hiện',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _job == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildStatusTracker(theme),
                      const SizedBox(height: 24),
                      _buildDetailsCard(theme),
                      const SizedBox(height: 24),
                      _buildPhotoUploadSection(),
                      const SizedBox(height: 32),
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
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có công việc đang chạy',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành toàn bộ công việc hoặc chưa nhận đơn mới.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white54,
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

    final steps = [
      {'key': 'accepted', 'label': 'Đã nhận'},
      {'key': 'on_the_way', 'label': 'Di chuyển'},
      {'key': 'arrived', 'label': 'Đến nơi'},
      {'key': 'in_progress', 'label': 'Đang làm'},
      {'key': 'done', 'label': 'Xong'},
    ];

    int currentIndex = 0;
    if (status == 'on_the_way') currentIndex = 1;
    if (status == 'arrived') currentIndex = 2;
    if (status == 'in_progress') currentIndex = 3;
    if (status == 'done') currentIndex = 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final bool isPassed = index <= currentIndex;
          final bool isCurrent = index == currentIndex;

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isPassed ? theme.primaryColor : const Color(0xFF334155),
                      child: isPassed && !isCurrent
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isPassed ? Colors.white : Colors.white54,
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step['label']!,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: isPassed ? Colors.white : Colors.white30,
                        fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < currentIndex ? theme.primaryColor : const Color(0xFF334155),
                      margin: const EdgeInsets.only(bottom: 14),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    final String serviceName = _job['service_name'];
    final String address = _job['address'];
    final String timeStr = _job['scheduled_time'];
    final double price = (_job['price'] as num?)?.toDouble() ?? 0.0;
    final String? note = _job['note'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHI TIẾT DỊCH VỤ',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white38,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFF334155)),
          const SizedBox(height: 20),
          _buildInfoRow(label: 'Địa chỉ thực hiện', value: address, icon: Icons.location_on_outlined),
          const SizedBox(height: 20),
          _buildInfoRow(label: 'Thời gian hẹn', value: _formatDateTime(timeStr), icon: Icons.calendar_today_outlined),
          const SizedBox(height: 20),
          _buildInfoRow(
            label: 'Đơn giá thanh toán',
            value: '${price.toStringAsFixed(0)}đ',
            icon: Icons.monetization_on_outlined,
            valueColor: Colors.greenAccent,
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildInfoRow(label: 'Ghi chú khách hàng', value: note, icon: Icons.notes_outlined),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value, required IconData icon, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white70),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    final status = _job['status'];
    final beforeImage = _job['before_image'];
    final afterImage = _job['after_image'];

    final bool showBeforeUpload = status == 'arrived' || status == 'in_progress' || status == 'done';
    final bool showAfterUpload = status == 'in_progress' || status == 'done';

    if (!showBeforeUpload) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HÌNH ẢNH MINH CHỨNG CÔNG VIỆC',
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (showBeforeUpload)
              Expanded(
                child: _buildPhotoSelectorCard(
                  title: 'Trước khi làm',
                  imageUrl: beforeImage,
                  onTap: () => _captureAndUploadPhoto('before'),
                  disabled: status != 'arrived',
                ),
              ),
            if (showAfterUpload) ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildPhotoSelectorCard(
                  title: 'Sau khi hoàn thành',
                  imageUrl: afterImage,
                  onTap: () => _captureAndUploadPhoto('after'),
                  disabled: status != 'in_progress',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSelectorCard({
    required String title,
    required String? imageUrl,
    required VoidCallback onTap,
    required bool disabled,
  }) {
    final fullUrl = imageUrl != null ? ApiConfig.baseUrl + imageUrl : null;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: disabled ? const Color(0xFF1E293B) : const Color(0xFF334155), width: 1.5),
        ),
        child: fullUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.redAccent)),
                ),
              )
            : Opacity(
                opacity: disabled ? 0.35 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: Colors.white70, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disabled ? 'Chờ trạng thái thích hợp' : 'Chụp hình / Tải lên',
                      style: GoogleFonts.outfit(fontSize: 9, color: Colors.white30),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    final String status = _job['status'];
    String btnText = '';
    String nextStatus = '';
    bool disabled = false;

    if (status == 'accepted') {
      btnText = 'Bắt đầu di chuyển';
      nextStatus = 'on_the_way';
    } else if (status == 'on_the_way') {
      btnText = 'Đã đến địa điểm';
      nextStatus = 'arrived';
    } else if (status == 'arrived') {
      final hasBeforePhoto = _job['before_image'] != null;
      btnText = 'Bắt đầu làm việc';
      nextStatus = 'in_progress';
      disabled = !hasBeforePhoto;
    } else if (status == 'in_progress') {
      final hasAfterPhoto = _job['after_image'] != null;
      btnText = 'Hoàn thành công việc';
      nextStatus = 'done';
      disabled = !hasAfterPhoto;
    } else {
      return const SizedBox.shrink(); // Unhandled state
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_isUpdating || disabled) ? null : () => _updateStatus(nextStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey.shade800 : theme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade900,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isUpdating
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                btnText,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: disabled ? Colors.white30 : Colors.white),
              ),
      ),
    );
  }
}
