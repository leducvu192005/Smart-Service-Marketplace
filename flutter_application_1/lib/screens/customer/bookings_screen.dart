import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final ApiService _apiService = ApiService();
  List<Booking> _bookings = [];
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  // Fetch both bookings and services for dynamic mapping
  Future<void> _fetchBookings() async {
    try {
      // 1. Fetch all customer services
      final servicesResponse = await _apiService.client.get(
        '/customer/services',
      );
      final List<Service> loadedServices = (servicesResponse.data as List)
          .map((i) => Service.fromJson(i))
          .toList();

      // 2. Fetch all customer bookings
      final response = await _apiService.client.get('/customer/bookings');
      setState(() {
        _services = loadedServices;
        _bookings = (response.data as List)
            .map((i) => Booking.fromJson(i))
            .toList()
            .reversed
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Fetch worker profile details by id
  Future<Map<String, dynamic>?> _fetchWorkerDetails(int workerId) async {
    try {
      final response = await _apiService.client.get('/workers/$workerId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching worker details: $e');
      return null;
    }
  }

  // Status mapping
  Map<String, dynamic> _getStatusConfig(String status, BuildContext context) {
    switch (status) {
      case 'pending':
        return {
          'text': 'Chờ xác nhận',
          'color': Colors.orange,
          'bg': Colors.orange.withOpacity(0.08),
        };
      case 'accepted':
        return {
          'text': 'Đã nhận lịch',
          'color': Colors.blue,
          'bg': Colors.blue.withOpacity(0.08),
        };
      case 'in_progress':
        return {
          'text': 'Đang thực hiện',
          'color': const Color(0xFF6F61E8),
          'bg': const Color(0xFF6F61E8).withOpacity(0.08),
        };
      case 'done':
        return {
          'text': 'Đã hoàn thành',
          'color': Colors.green,
          'bg': Colors.green.withOpacity(0.08),
        };
      case 'cancelled':
        return {
          'text': 'Đã hủy',
          'color': Colors.red,
          'bg': Colors.red.withOpacity(0.08),
        };
      default:
        return {
          'text': 'Không xác định',
          'color': Colors.grey,
          'bg': Colors.grey.withOpacity(0.08),
        };
    }
  }

  // Parses the package tier name from the note
  String _getTierName(String? note) {
    if (note == null) return 'Classic';
    if (note.contains('[Gói Classic]')) return 'Classic';
    if (note.contains('[Gói Premium]')) return 'Premium';
    if (note.contains('[Gói Platinum]')) return 'Platinum';
    return 'Classic';
  }

  // Strips the package tier prefix from note text for presentation
  String _cleanNote(String? note) {
    if (note == null) return '';
    return note
        .replaceAll('[Gói Classic]', '')
        .replaceAll('[Gói Premium]', '')
        .replaceAll('[Gói Platinum]', '')
        .trim();
  }

  // Calculates the price based on the selected tier
  double _calculatePrice(Service service, String tier) {
    final basePrice = service.price;
    switch (tier.toLowerCase()) {
      case 'premium':
        return basePrice * 1.20;
      case 'platinum':
        return basePrice * 1.40;
      case 'classic':
      default:
        return basePrice;
    }
  }

  // Formats price into VND / USD
  String _formatPrice(double price) {
    if (price >= 1000) {
      final String str = price.toStringAsFixed(0);
      final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
      return '$resultđ';
    } else {
      return '\$${price.toStringAsFixed(0)}';
    }
  }

  // Check if status is worker-active
  bool _showWorkerInfo(String status) {
    return status == 'accepted' || status == 'in_progress' || status == 'done';
  }

  // Open the dialog for review submissions
  Future<void> _showReviewDialog(int bookingId) async {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Đánh giá dịch vụ',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trải nghiệm của bạn thế nào? Hãy chia sẻ cho chúng tôi biết nhé!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 42,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhận xét của bạn về thợ và dịch vụ...',
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(
                bottom: 16,
                left: 16,
                right: 16,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Hủy',
                          style: GoogleFonts.outfit(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setStateDialog(() => isSubmitting = true);
                                try {
                                  await _apiService.client.post(
                                    '/customer/reviews',
                                    data: {
                                      'booking_id': bookingId,
                                      'rating': rating,
                                      'comment': commentController.text,
                                    },
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cảm ơn bạn đã đánh giá!',
                                        ),
                                      ),
                                    );
                                    _fetchBookings();
                                  }
                                } catch (e) {
                                  setStateDialog(() => isSubmitting = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e')),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Gửi',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Opens a gorgeous, highly styled dialog showing details of the selected service booking
  void _showBookingDetailsBottomSheet(Booking booking) {
    final statusConfig = _getStatusConfig(booking.status, context);
    final Service? associatedService = _services.cast<Service?>().firstWhere(
      (s) => s?.id == booking.serviceId,
      orElse: () => null,
    );

    final tier = _getTierName(booking.note);
    final cleanedNote = _cleanNote(booking.note);
    final formattedPrice = associatedService != null
        ? _formatPrice(_calculatePrice(associatedService, tier))
        : 'N/A';

    final parsedDate =
        DateTime.tryParse(booking.scheduledTime) ?? DateTime.now();
    final formattedDate =
        'Ngày ${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    final formattedTime =
        '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiết đơn dịch vụ',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusConfig['bg'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusConfig['text'],
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: statusConfig['color'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFECEFF1)),
              const SizedBox(height: 16),

              // Detail fields list
              _buildDetailRow(
                icon: Icons.bookmark_added_outlined,
                label: 'Mã đặt lịch',
                value: '#${booking.id}',
                isBoldValue: true,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.handyman_outlined,
                label: 'Dịch vụ yêu cầu',
                value:
                    associatedService?.name ??
                    'ID Dịch vụ: ${booking.serviceId}',
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.layers_outlined,
                label: 'Gói dịch vụ',
                value: tier,
                valueColor: const Color(0xFF6F61E8),
                isBoldValue: true,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.payments_outlined,
                label: 'Giá trị đơn',
                value: formattedPrice,
                isBoldValue: true,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Thời gian',
                value: '$formattedTime - $formattedDate',
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Địa điểm',
                value: booking.address,
              ),
              if (cleanedNote.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Ghi chú của bạn',
                  value: cleanedNote,
                  valueStyle: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 20),

              // Dynamic Worker Assignment Details Card
              if (_showWorkerInfo(booking.status) &&
                  booking.workerId != null) ...[
                const Divider(color: Color(0xFFECEFF1)),
                const SizedBox(height: 16),
                Text(
                  'Thợ thực hiện dịch vụ',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchWorkerDetails(booking.workerId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6F61E8),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Đang tải thông tin thợ...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final workerData = snapshot.data;
                    if (workerData == null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đã phân công thợ',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  Text(
                                    'Thợ chuyên nghiệp của hệ thống',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final name = workerData['full_name'] ?? 'Worker';
                    final rating = workerData['rating'] ?? 5.0;
                    final reviews = workerData['total_reviews'] ?? 0;
                    final phone = workerData['phone'] ?? '';
                    final experience = workerData['experience_years'] ?? 3;
                    final avatarUrl = workerData['avatar_url'];

                    // Fallback local hero asset selection
                    final bool isCleaning =
                        associatedService?.name.toLowerCase().contains('dọn') ??
                        false;
                    final fallbackImage = isCleaning
                        ? 'assets/images/cleaner_man.png'
                        : 'assets/images/handyman.png';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Worker Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              image:
                                  avatarUrl != null &&
                                      avatarUrl.toString().isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : DecorationImage(
                                      image: AssetImage(fallbackImage),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Name, Role & Rating
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$experience năm kinh nghiệm',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rating.toStringAsFixed(1)} ★ ($reviews đánh giá)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Quick Contact Actions
                          InkWell(
                            onTap: () {
                              if (phone.isNotEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đang kết nối cuộc gọi đến thợ ($phone)...',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Không tìm thấy số điện thoại của thợ.',
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.phone_outlined,
                                color: Colors.black54,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Mở tin nhắn chat trực tiếp với thợ $name...',
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.black54,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else if (booking.status == 'pending') ...[
                const Divider(color: Color(0xFFECEFF1)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade100, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        color: Colors.amber.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yêu cầu đang chờ thợ nhận lịch. Chúng tôi sẽ cập nhật thông tin thợ tại đây ngay khi có người nhận việc.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Bottom sheet confirm / close button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F61E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Text details rendering helper
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBoldValue = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: valueColor ?? const Color(0xFF1E1E1E),
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
            ).merge(valueStyle),
          ),
        ),
      ],
    );
  }

  Future<void> _showComplaintDialog(int bookingId) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Gửi khiếu nại / hỗ trợ',
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final desc = descriptionController.text.trim();
                          if (title.isEmpty || desc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập đầy đủ tiêu đề và mô tả',
                                ),
                              ),
                            );
                            return;
                          }
                          setStateDialog(() => isSubmitting = true);
                          try {
                            await _apiService.client.post(
                              '/customer/tickets',
                              data: {
                                'booking_id': bookingId,
                                'title': title,
                                'description': desc,
                              },
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gửi khiếu nại thành công! Nhân viên hỗ trợ sẽ liên hệ sớm.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gửi khiếu nại'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(
          'Lịch sử đặt dịch vụ',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: _bookings.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Icon(
                          Icons.assignment_late_outlined,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Chưa có lịch hẹn nào.',
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        final statusConfig = _getStatusConfig(
                          booking.status,
                          context,
                        );

                        final Service? associatedService = _services
                            .cast<Service?>()
                            .firstWhere(
                              (s) => s?.id == booking.serviceId,
                              orElse: () => null,
                            );

                        final tier = _getTierName(booking.note);
                        final displayPrice = associatedService != null
                            ? _formatPrice(
                                _calculatePrice(associatedService, tier),
                              )
                            : '';

                        final parsedDate =
                            DateTime.tryParse(booking.scheduledTime) ??
                            DateTime.now();
                        final displayDate =
                            '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
                        final displayTime =
                            '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          booking.status,
                                        ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.handyman,
                                        color: _getStatusColor(booking.status),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Booking #${booking.id} - Service ${booking.serviceId}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            booking.scheduledTime.split('T')[0],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        booking.status.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _getStatusColor(
                                        booking.status,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        booking.address,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                if (booking.status == 'done') ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showReviewDialog(booking.id),
                                      icon: const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      label: const Text('Đánh giá thợ'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.amber,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
