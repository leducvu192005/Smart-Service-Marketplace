import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool isWorker;
  const ChatListScreen({super.key, required this.isWorker});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _apiService = ApiService();
  List<Booking> _chatBookings = [];
  Map<int, String> _resolvedNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isWorker) {
        // Fetch worker bookings
        final response = await _apiService.client.get('/worker/jobs/my');
        final currentJobs = (response.data as List)
            .map((i) => Booking.fromJson(i))
            .toList();

        final historyRes = await _apiService.client.get('/worker/history');
        final historyJobs = (historyRes.data as List)
            .map((i) => Booking.fromJson(i))
            .toList();

        _chatBookings = [...currentJobs, ...historyJobs];
      } else {
        // Fetch customer bookings
        final response = await _apiService.client.get('/customer/bookings');
        _chatBookings = (response.data as List)
            .map((i) => Booking.fromJson(i))
            .where((b) => b.workerId != null)
            .toList();
      }

      // Resolve names for all bookings
      // Thay thế đoạn code từ dòng 50 đến 65 bằng đoạn này:
      for (var booking in _chatBookings) {
        final targetId = widget.isWorker ? booking.id : booking.workerId;
        if (targetId != null && !_resolvedNames.containsKey(targetId)) {
          if (widget.isWorker) {
            // 1. Kiểm tra xem model của bạn dùng 'customerId' hay 'userId'
            // 2. Thêm '?? 0' (hoặc ?? booking.userId) để đảm bảo không bị null
            final customerId = booking.customerId ?? 0;

            _resolveUserName(customerId, booking.id);
          } else {
            // Thêm '!' hoặc '?? 0' để chuyển từ int? sang int một cách an toàn
            _resolveWorkerName(booking.workerId ?? 0, booking.workerId ?? 0);
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải danh sách trò chuyện')),
        );
      }
    }
  }

  Future<void> _resolveUserName(int userId, int key) async {
    try {
      final res = await _apiService.client.get('/auth/users/$userId');
      if (mounted) {
        setState(() {
          _resolvedNames[key] = res.data['full_name'] ?? 'Khách hàng';
        });
      }
    } catch (e) {
      debugPrint('Error resolving customer name: $e');
    }
  }

  Future<void> _resolveWorkerName(int workerId, int key) async {
    try {
      final res = await _apiService.client.get('/workers/$workerId');
      if (mounted) {
        setState(() {
          _resolvedNames[key] = res.data['full_name'] ?? 'Thợ';
        });
      }
    } catch (e) {
      debugPrint('Error resolving worker name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: Text(
          'Tin nhắn & Trò chuyện',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        automaticallyImplyLeading: widget.isWorker ? false : true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchChats,
        color: theme.primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chatBookings.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chatBookings.length,
                itemBuilder: (context, index) {
                  final booking = _chatBookings[index];
                  final nameKey = widget.isWorker
                      ? booking.id
                      : booking.workerId;
                  final displayName = _resolvedNames[nameKey] ?? 'Đang tải...';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF1F0EA)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Đơn hàng #${booking.id} - Trạng thái: ${booking.status}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              booking: booking,
                              isWorker: widget.isWorker,
                              partnerName: displayName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chưa có cuộc hội thoại nào',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isWorker
                ? 'Hãy nhận việc để bắt đầu trò chuyện với khách hàng!'
                : 'Đặt dịch vụ để bắt đầu kết nối trực tiếp với thợ.',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
