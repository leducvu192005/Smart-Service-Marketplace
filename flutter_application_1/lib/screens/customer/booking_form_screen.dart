import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';

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
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  
  // Package Selection State: 'classic', 'premium', 'platinum'
  String _selectedTier = 'classic';

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Smart currency formatter (handles VND & USD elegantly)
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

  // Get active price based on selected tier
  double _getActivePrice() {
    final basePrice = widget.service.price;
    switch (_selectedTier) {
      case 'premium':
        return basePrice * 1.2;
      case 'platinum':
        return basePrice * 1.4;
      case 'classic':
      default:
        return basePrice;
    }
  }

  // Get slashed original price based on selected tier
  double _getOriginalPrice() {
    final activePrice = _getActivePrice();
    switch (_selectedTier) {
      case 'platinum':
        return activePrice * 1.10;
      case 'premium':
        return activePrice * 1.12;
      case 'classic':
      default:
        return activePrice * 1.15;
    }
  }

  // Category specific illustration assets
  String _getHeroImage() {
    final name = widget.service.name.toLowerCase();
    if (name.contains('dọn') || name.contains('clean') || name.contains('vệ sinh')) {
      return 'assets/images/cleaner_man.png';
    } else if (name.contains('điện') || name.contains('electric') || name.contains('thiết bị')) {
      return 'assets/images/electrical.png';
    } else if (name.contains('nước') || name.contains('plumb') || name.contains('ống')) {
      return 'assets/images/plumbing.png';
    } else if (name.contains('it') || name.contains('máy tính') || name.contains('cài đặt') || name.contains('mạng')) {
      return 'assets/images/it_solutions.png';
    } else if (name.contains('sửa') || name.contains('handy') || name.contains('khoan') || name.contains('lắp')) {
      return 'assets/images/handyman.png';
    }
    return 'assets/images/cleaner_man.png';
  }

  // Category specific theme colors for the curved header
  List<Color> _getGradientColors() {
    final name = widget.service.name.toLowerCase();
    if (name.contains('dọn') || name.contains('clean') || name.contains('vệ sinh')) {
      return [const Color(0xFFFBBEDF), const Color(0xFFF7D1EB)];
    } else if (name.contains('điện') || name.contains('electric') || name.contains('thiết bị')) {
      return [const Color(0xFFFFE0B2), const Color(0xFFFFCC80)];
    } else if (name.contains('nước') || name.contains('plumb') || name.contains('ống')) {
      return [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)];
    } else if (name.contains('it') || name.contains('máy tính') || name.contains('cài đặt') || name.contains('mạng')) {
      return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
    } else if (name.contains('sửa') || name.contains('handy') || name.contains('khoan') || name.contains('lắp')) {
      return [const Color(0xFFEFEBE9), const Color(0xFFD7CCC8)];
    }
    return [const Color(0xFFFBBEDF), const Color(0xFFF7D1EB)];
  }

  // Fallback description matching standard premium copywriting
  String _getDescriptionText() {
    if (widget.service.description != null && widget.service.description!.isNotEmpty) {
      return widget.service.description!;
    }
    final name = widget.service.name.toLowerCase();
    if (name.contains('dọn') || name.contains('clean') || name.contains('vệ sinh')) {
      return 'Dịch vụ dọn dẹp nhà cửa chuyên sâu của chúng tôi mang lại sự sạch sẽ hoàn hảo cho mọi ngóc ngách trong ngôi nhà của bạn. Hãy tận hưởng không gian sống trong lành, vệ sinh và thoải mái với sự chăm sóc chuyên nghiệp mà bạn hoàn toàn có thể tin tưởng.';
    } else if (name.contains('điện') || name.contains('electric')) {
      return 'Dịch vụ sửa chữa và bảo dưỡng hệ thống điện chuyên nghiệp. Đảm bảo an toàn tuyệt đối cho gia đình bạn với đội ngũ thợ lành nghề, được đào tạo bài bản, chuẩn đoán lỗi nhanh và sửa chữa triệt để.';
    } else if (name.contains('nước') || name.contains('plumb')) {
      return 'Dịch vụ khắc phục sự cố rò rỉ nước, thông tắc đường ống và lắp đặt thiết bị vệ sinh. Chúng tôi mang đến giải pháp nhanh chóng, hiệu quả cao, sử dụng vật liệu chất lượng cao, bền bỉ với thời gian.';
    } else if (name.contains('it')) {
      return 'Dịch vụ cài đặt máy tính, sửa chữa lỗi phần mềm, phần cứng và cấu hình mạng gia đình hoặc văn phòng. Hỗ trợ chuyên nghiệp, nhanh gọn, giúp hệ thống của bạn hoạt động ổn định nhất.';
    }
    return 'Dịch vụ chuyên nghiệp chất lượng cao được thực hiện bởi đội ngũ kỹ thuật viên kinh nghiệm. Chúng tôi cam kết đem lại trải nghiệm hài lòng nhất cho quý khách hàng.';
  }

  // Handle booking form submission
  Future<void> _handleBook(StateSetter setModalState, BuildContext sheetContext) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày thực hiện dịch vụ!'))
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ thực hiện dịch vụ!'))
      );
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ thực hiện!'))
      );
      return;
    }

    final navigator = Navigator.of(sheetContext);

    setModalState(() => _isLoading = true);
    setState(() => _isLoading = true);

    try {
      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final apiService = ApiService();
      
      // We append the package tier prefix in the note so the backend preserves it seamlessly
      final String tierLabel = _selectedTier == 'classic' 
          ? 'Classic' 
          : _selectedTier == 'premium' 
              ? 'Premium' 
              : 'Platinum';
      
      final String finalNote = '[Gói $tierLabel] ${_noteController.text.trim()}';

      await apiService.client.post('/customer/bookings', data: {
        'service_id': widget.service.id,
        'scheduled_time': scheduledDateTime.toIso8601String(),
        'address': _addressController.text.trim(),
        'note': finalNote,
      });

      if (mounted) {
        setModalState(() => _isLoading = false);
        setState(() => _isLoading = false);
        
        // Close bottom sheet using pre-captured navigator
        navigator.pop();

        // Show elegant success dialog
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setModalState(() => _isLoading = false);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e'))
        );
      }
    }
  }

  // Premium success popup dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Đặt lịch thành công!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cảm ơn bạn đã tin tưởng dịch vụ của chúng tôi. Thợ sẽ liên hệ với bạn trong thời gian sớm nhất!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F61E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Quay lại trang chủ',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Opens the beautiful bottom sheet to collect Date, Time, Address, Note details
  void _showBookingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pull Handle Indicator
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
                    Text(
                      'Thông tin đặt lịch',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gói dịch vụ đã chọn: ${_selectedTier == 'classic' ? 'Classic' : _selectedTier == 'premium' ? 'Premium' : 'Platinum'}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF6F61E8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date & Time Picker Containers
                    Row(
                      children: [
                        // Date Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ngày làm việc',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF6F61E8),
                                            onPrimary: Colors.white,
                                            onSurface: Color(0xFF1E1E1E),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setModalState(() => _selectedDate = date);
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedDate == null
                                              ? 'Chọn ngày'
                                              : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: _selectedDate == null ? Colors.grey.shade500 : const Color(0xFF1E1E1E),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Time Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giờ bắt đầu',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime ?? TimeOfDay.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF6F61E8),
                                            onPrimary: Colors.white,
                                            onSurface: Color(0xFF1E1E1E),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setModalState(() => _selectedTime = time);
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_outlined, color: Colors.grey, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedTime == null
                                              ? 'Chọn giờ'
                                              : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: _selectedTime == null ? Colors.grey.shade500 : const Color(0xFF1E1E1E),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Address Textfield
                    Text(
                      'Địa chỉ thực hiện',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Số nhà, tên đường, quận/huyện...',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 22),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E1E1E)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes Textfield
                    Text(
                      'Ghi chú cho thợ (Tùy chọn)',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Nhập ghi chú hoặc yêu cầu cụ thể...',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.sticky_note_2_outlined, color: Colors.grey, size: 22),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E1E1E)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Confirm Button inside Sheet
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleBook(setModalState, sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F61E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Xác nhận đặt lịch',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final activePrice = _getActivePrice();
    final originalPrice = _getOriginalPrice();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Stack(
        children: [
          // Scrollable Body Content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Curved Backdrop Header Container with Hero Image
                  Container(
                    height: MediaQuery.of(context).size.height * 0.44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(44),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Centered Clean Cut-out Image of Serviceman
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: 0.85,
                            child: Image.asset(
                              _getHeroImage(),
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Service Description, Pricing & Tier selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row with Title details and a stylish discount tag
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.service.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E1E1E),
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.service.name.toLowerCase().contains('dọn')
                                        ? 'Dọn dẹp chu đáo, nhà cửa sáng bóng.'
                                        : 'Dịch vụ uy tín, thợ chuyên nghiệp.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Styled green badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lên đến',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Text(
                                    '30%',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Text(
                                    'Giảm',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Active Dynamic Price Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatPrice(activePrice),
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatPrice(originalPrice),
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 3. Package Selection Cards (Classic, Premium, Platinum)
                        Row(
                          children: [
                            // Classic
                            Expanded(
                              child: _buildTierCard(
                                tierKey: 'classic',
                                label: 'Classic',
                                price: widget.service.price,
                                originalPrice: widget.service.price * 1.15,
                                activeBgColor: const Color(0xFF1E1E1E),
                                activeTextColor: Colors.white,
                                inactiveBgColor: const Color(0xFFEEEEEE),
                                inactiveTextColor: const Color(0xFF555555),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Premium
                            Expanded(
                              child: _buildTierCard(
                                tierKey: 'premium',
                                label: 'Premium',
                                price: widget.service.price * 1.20,
                                originalPrice: widget.service.price * 1.20 * 1.12,
                                activeBgColor: const Color(0xFF1E1E1E),
                                activeTextColor: Colors.white,
                                inactiveBgColor: const Color(0xFFE8E3FA),
                                inactiveTextColor: const Color(0xFF7E6CF3),
                                inactiveOriginalPriceColor: const Color(0xFFAAA3DF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Platinum
                            Expanded(
                              child: _buildTierCard(
                                tierKey: 'platinum',
                                label: 'Platinum',
                                price: widget.service.price * 1.40,
                                originalPrice: widget.service.price * 1.40 * 1.10,
                                activeBgColor: const Color(0xFF1E1E1E),
                                activeTextColor: Colors.white,
                                inactiveBgColor: const Color(0xFFE1F2FF),
                                inactiveTextColor: const Color(0xFF1A8CFF),
                                inactiveOriginalPriceColor: const Color(0xFF90CAF9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // 4. Elegant Serviceman Card ("Marcus Mane")
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade100, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F5FE),
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(_getHeroImage()),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Name & Title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Marcus Mane',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Thợ chuyên nghiệp',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Call & Chat buttons
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đang kết nối cuộc gọi đến Marcus Mane...'))
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  child: const Icon(Icons.phone_outlined, color: Colors.black54, size: 20),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Mở hộp thoại chat với Marcus Mane...'))
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black54, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 5. Description Block
                        Text(
                          'Mô tả dịch vụ',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getDescriptionText(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Xem thêm...',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 140), // Spacer to avoid overlap with sticky bottom bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Overlay Back Button & Cart Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Circular Back Button
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
                // Circular Cart Button
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Giỏ hàng trống!'))
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Sticky Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Dynamic price pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: Text(
                      _formatPrice(activePrice),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Book Now Button
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _showBookingBottomSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F61E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Đặt lịch ngay',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Package tier card widget helper
  Widget _buildTierCard({
    required String tierKey,
    required String label,
    required double price,
    required double originalPrice,
    required Color activeBgColor,
    required Color activeTextColor,
    required Color inactiveBgColor,
    required Color inactiveTextColor,
    Color? inactiveOriginalPriceColor,
  }) {
    final isSelected = _selectedTier == tierKey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTier = tierKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : inactiveBgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBgColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeTextColor : inactiveTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatPrice(price),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeTextColor : inactiveTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatPrice(originalPrice),
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withOpacity(0.6)
                    : (inactiveOriginalPriceColor ?? Colors.grey.shade500),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
