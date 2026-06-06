import 'package:flutter/material.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final response = await _apiService.client.get('/customer/bookings');
      setState(() {
        // Sắp xếp lịch mới nhất lên đầu
        _bookings = (response.data as List).map((i) => Booking.fromJson(i)).toList().reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.grey;
      case 'accepted': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'done': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Đánh giá dịch vụ', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
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
                    decoration: InputDecoration(
                      hintText: 'Nhận xét của bạn về thợ và dịch vụ...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    setStateDialog(() => isSubmitting = true);
                    try {
                      await _apiService.client.post('/customer/reviews', data: {
                        'booking_id': bookingId,
                        'rating': rating,
                        'comment': commentController.text,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!'))
                        );
                        _fetchBookings(); // Refresh để ẩn nút đánh giá (tuỳ logic backend)
                      }
                    } catch (e) {
                      setStateDialog(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e (Có thể bạn đã đánh giá rồi)'))
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Gửi đánh giá'),
                ),
              ],
            );
          }
        );
      }
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Gửi khiếu nại / hỗ trợ', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final title = titleController.text.trim();
                    final desc = descriptionController.text.trim();
                    if (title.isEmpty || desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và mô tả'))
                      );
                      return;
                    }
                    setStateDialog(() => isSubmitting = true);
                    try {
                      await _apiService.client.post('/customer/tickets', data: {
                        'booking_id': bookingId,
                        'title': title,
                        'description': desc,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gửi khiếu nại thành công! Nhân viên hỗ trợ sẽ liên hệ sớm.'))
                        );
                      }
                    } catch (e) {
                      setStateDialog(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'))
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Gửi khiếu nại'),
                ),
              ],
            );
          }
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Các lịch đã đặt')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: _bookings.isEmpty
                  ? ListView(children: const [SizedBox(height: 100), Center(child: Text('Chưa có lịch hẹn nào.'))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                        color: _getStatusColor(booking.status).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.handyman, color: _getStatusColor(booking.status)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Booking #${booking.id} - Service ${booking.serviceId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(booking.scheduledTime.split('T')[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(booking.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                      backgroundColor: _getStatusColor(booking.status),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(booking.address, style: const TextStyle(fontSize: 14))),
                                  ],
                                ),
                                if (booking.status == 'done') ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showReviewDialog(booking.id),
                                          icon: const Icon(Icons.star, color: Colors.amber),
                                          label: const Text('Đánh giá thợ'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.amber),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showComplaintDialog(booking.id),
                                          icon: const Icon(Icons.feedback_outlined, color: Colors.red),
                                          label: const Text('Khiếu nại'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ] else if (booking.status != 'cancelled') ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showComplaintDialog(booking.id),
                                      icon: const Icon(Icons.support_agent, color: Colors.red),
                                      label: const Text('Yêu cầu hỗ trợ'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ]
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
