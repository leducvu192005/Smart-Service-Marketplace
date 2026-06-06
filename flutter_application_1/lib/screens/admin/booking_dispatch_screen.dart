import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class BookingDispatchScreen extends StatefulWidget {
  const BookingDispatchScreen({super.key});

  @override
  State<BookingDispatchScreen> createState() => _BookingDispatchScreenState();
}

class _BookingDispatchScreenState extends State<BookingDispatchScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _bookings = [];
  List<dynamic> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final bookingsRes = await _apiService.client.get('/support/bookings');
      final workersRes = await _apiService.client.get('/support/workers');
      setState(() {
        _bookings = bookingsRes.data;
        _workers = workersRes.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    try {
      await _apiService.client.post('/support/bookings/$bookingId/cancel');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hủy đơn hàng thành công!')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy đơn hàng: $e')),
      );
    }
  }

  Future<void> _rescheduleBooking(int bookingId, DateTime newTime) async {
    try {
      await _apiService.client.put(
        '/support/bookings/$bookingId/reschedule',
        data: {'scheduled_time': newTime.toIso8601String()},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi lịch hẹn thành công!')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đổi lịch: $e')),
      );
    }
  }

  Future<void> _reassignWorker(int bookingId, int workerId) async {
    try {
      await _apiService.client.post('/support/bookings/$bookingId/reassign', queryParameters: {'new_worker_id': workerId});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi thợ điều phối thành công!')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đổi thợ: $e')),
      );
    }
  }

  Future<void> _confirmPayment(int bookingId) async {
    try {
      await _apiService.client.post('/support/bookings/$bookingId/confirm-payment');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận thanh toán thành công! Đã giải ngân 90% vào ví thợ.')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xác nhận thanh toán: $e')),
      );
    }
  }

  Future<void> _proposeRefund(int bookingId, double amount, String reason) async {
    try {
      await _apiService.client.post(
        '/support/bookings/$bookingId/propose-refund',
        data: {'amount': amount, 'reason': reason},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi đề xuất hoàn tiền lên Admin.')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi đề xuất hoàn tiền: $e')),
      );
    }
  }

  void _showReassignDialog(int bookingId, int? currentWorkerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chọn Thợ Điều Phối', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _workers.length,
              itemBuilder: (context, index) {
                final w = _workers[index];
                final isCurrent = w['id'] == currentWorkerId;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(w['full_name'] ?? 'Thợ dịch vụ', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  subtitle: Text('SĐT: ${w['phone'] ?? "Không có"} | Đánh giá: ${w['rating'] ?? 5.0}⭐', style: GoogleFonts.outfit(fontSize: 12)),
                  trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    _reassignWorker(bookingId, w['id']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            )
          ],
        );
      },
    );
  }

  void _showRescheduleDialog(int bookingId, DateTime currentTime) {
    showDatePicker(
      context: context,
      initialDate: currentTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    ).then((pickedDate) {
      if (pickedDate != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(currentTime),
        ).then((pickedTime) {
          if (pickedTime != null) {
            final newDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _rescheduleBooking(bookingId, newDateTime);
          }
        });
      }
    });
  }

  void _showRefundDialog(int bookingId, double maxAmount) {
    final reasonController = TextEditingController();
    final amountController = TextEditingController(text: maxAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Đề Xuất Hoàn Tiền', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền hoàn (USD)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lý do hoàn tiền',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền lý do')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _proposeRefund(bookingId, amt, reason);
              },
              child: const Text('Gửi Đề Xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Điều Phối Đơn Hàng', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có đặt lịch nào trên hệ thống',
                        style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final b = _bookings[index];
                      final bookingId = b['booking_id'] ?? b['id'];
                      final serviceName = b['service_name'] ?? 'Dịch vụ tiện ích';
                      final price = (b['price'] ?? 0.0).toDouble();
                      final status = b['status'] ?? 'pending';
                      final address = b['address'] ?? '';
                      final note = b['note'] ?? '';
                      final scheduledTimeStr = b['scheduled_time'] ?? '';
                      final DateTime scheduledTime = scheduledTimeStr.isNotEmpty
                          ? DateTime.parse(scheduledTimeStr)
                          : DateTime.now();

                      Color statusColor = Colors.orange;
                      String statusText = 'Đang chờ';
                      if (status == 'accepted') {
                        statusColor = Colors.blue;
                        statusText = 'Đã nhận';
                      } else if (status == 'in_progress') {
                        statusColor = Colors.purple;
                        statusText = 'Đang làm';
                      } else if (status == 'done') {
                        statusColor = Colors.green;
                        statusText = 'Hoàn thành';
                      } else if (status == 'cancelled') {
                        statusColor = Colors.red;
                        statusText = 'Đã hủy';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: GoogleFonts.outfit(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đơn #$bookingId - $serviceName',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Hẹn lúc: ${scheduledTime.day}/${scheduledTime.month} ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')} | Giá: \$$price',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  Text(
                                    'Địa chỉ: $address',
                                    style: GoogleFonts.outfit(color: Colors.grey.shade800),
                                  ),
                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ghi chú: $note',
                                      style: GoogleFonts.outfit(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (status != 'cancelled' && status != 'done') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.person_add_alt, size: 16),
                                          label: const Text('Điều Phối Thợ'),
                                          onPressed: () => _showReassignDialog(bookingId, b['worker_id']),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.schedule, size: 16),
                                          label: const Text('Đổi Giờ'),
                                          onPressed: () => _showRescheduleDialog(bookingId, scheduledTime),
                                        ),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.cancel, size: 16),
                                          label: const Text('Hủy Lịch'),
                                          onPressed: () => _cancelBooking(bookingId),
                                        ),
                                      ],
                                      if (status != 'cancelled') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.payment, size: 16),
                                          label: const Text('Xác Nhận Thu Tiền'),
                                          onPressed: () => _confirmPayment(bookingId),
                                        ),
                                      ],
                                      if (status == 'done') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.undo, size: 16),
                                          label: const Text('Đề Xuất Hoàn Tiền'),
                                          onPressed: () => _showRefundDialog(bookingId, price),
                                        ),
                                      ],
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
