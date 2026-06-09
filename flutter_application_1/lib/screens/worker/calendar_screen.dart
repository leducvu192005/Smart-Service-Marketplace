import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/app_models.dart';

class WorkerCalendarScreen extends StatefulWidget {
  const WorkerCalendarScreen({super.key});

  @override
  State<WorkerCalendarScreen> createState() => _WorkerCalendarScreenState();
}

class _WorkerCalendarScreenState extends State<WorkerCalendarScreen> {
  final ApiService _apiService = ApiService();
  List<WorkerCalendar> _slots = [];
  bool _isLoading = true;
  final List<DateTime> _days = [];

  @override
  void initState() {
    super.initState();
    // Generate next 14 days starting from today
    final today = DateTime.now();
    for (int i = 0; i < 14; i++) {
      _days.add(today.add(Duration(days: i)));
    }
    _fetchCalendar();
  }

  Future<void> _fetchCalendar() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.client.get('/worker/calendar');
      if (mounted) {
        setState(() {
          _slots = (response.data as List)
              .map((i) => WorkerCalendar.fromJson(i))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải lịch làm việc')),
        );
      }
    }
  }

  Future<void> _toggleDayOff(DateTime date, bool currentIsOff) async {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // Show confirmation dialog with optional note
    final noteController = TextEditingController();
    final newIsOff = !currentIsOff;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            newIsOff ? 'Đăng ký ngày nghỉ' : 'Hủy đăng ký nghỉ',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                newIsOff
                    ? 'Bạn có muốn nghỉ phép vào ngày ${date.day}/${date.month}/${date.year}?'
                    : 'Bạn muốn đi làm lại vào ngày ${date.day}/${date.month}/${date.year}?',
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              if (newIsOff) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do nghỉ (Tùy chọn)',
                    hintText: 'Nhập lý do nghỉ của bạn',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newIsOff ? Colors.redAccent : Theme.of(context).primaryColor,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _apiService.client.post(
        '/worker/calendar/register-off',
        data: {
          'date': dateStr,
          'is_off': newIsOff,
          'note': noteController.text.trim(),
        },
      );
      _fetchCalendar(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newIsOff ? 'Đã đăng ký nghỉ phép thành công!' : 'Đã đăng ký đi làm lại!'),
            backgroundColor: newIsOff ? Colors.redAccent : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi cập nhật lịch làm việc')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Sleek dark worker background
      appBar: AppBar(
        title: Text(
          'Lịch làm việc của tôi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng ký lịch làm việc trong 14 ngày tới',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _days.length,
                      itemBuilder: (context, index) {
                        final date = _days[index];
                        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        
                        // Find matching slot settings
                        final slot = _slots.firstWhere(
                          (s) => s.date == dateStr,
                          orElse: () => WorkerCalendar(id: -1, workerId: -1, date: dateStr, isOff: false),
                        );
                        
                        final bool isOff = slot.isOff;
                        
                        return GestureDetector(
                          onTap: () => _toggleDayOff(date, isOff),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isOff ? const Color(0xFFE11D48).withOpacity(0.15) : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isOff ? const Color(0xFFE11D48) : const Color(0xFF334155),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${date.day}/${date.month}",
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOff ? const Color(0xFFE11D48) : const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isOff ? 'OFF' : 'ON',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getWeekdayText(date.weekday),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    if (isOff && slot.note != null && slot.note!.isNotEmpty)
                                      Text(
                                        slot.note!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: Colors.redAccent,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getWeekdayText(int day) {
    switch (day) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }
}
