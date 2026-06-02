import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';

class BookingFormScreen extends StatefulWidget {
  final Service service;
  
  const BookingFormScreen({super.key, required this.service});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  
  Future<void> _handleBook() async {
    if (_selectedDate == null || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời gian và địa chỉ')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.client.post('/customer/bookings', data: {
        'service_id': widget.service.id,
        'scheduled_time': _selectedDate!.toIso8601String(),
        'address': _addressController.text,
        'note': _noteController.text,
      });
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo lịch thành công!')));
        Navigator.pop(context); // Go back to services list
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt dịch vụ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(widget.service.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('\$${widget.service.price} / hr', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Hẹn thời gian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.grey),
                    const SizedBox(width: 16),
                    Text(_selectedDate == null ? 'Chọn ngày' : _selectedDate!.toLocal().toString().split(' ')[0], style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Địa chỉ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CustomTextField(hint: 'Nhập chi tiết số nhà, tên đường...', icon: Icons.location_on, controller: _addressController),
            const SizedBox(height: 24),
            const Text('Ghi chú (Tùy chọn)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CustomTextField(hint: 'Nhập ghi chú hoặc yêu cầu đặc biệt cho thợ...', icon: Icons.notes, controller: _noteController),
            const SizedBox(height: 48),
            PrimaryButton(text: 'Xác nhận Đặt lịch', onPressed: _handleBook, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}
