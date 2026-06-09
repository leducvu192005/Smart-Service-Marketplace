import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import 'booking_form_screen.dart';

class ServicesScreen extends StatefulWidget {
  final int? categoryId;
  final String categoryName;
  final String? searchQuery;

  const ServicesScreen({
    super.key,
    this.categoryId,
    required this.categoryName,
    this.searchQuery,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ApiService _apiService = ApiService();
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final String url = widget.categoryId != null
          ? '/customer/services?category_id=${widget.categoryId}'
          : '/customer/services';
      
      final response = await _apiService.client.get(url);
      List<Service> servicesList = (response.data as List)
          .map((i) => Service.fromJson(i))
          .toList();

      if (widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty) {
        final queryLower = widget.searchQuery!.trim().toLowerCase();
        servicesList = servicesList.where((s) {
          return s.name.toLowerCase().contains(queryLower) ||
              (s.description ?? '').toLowerCase().contains(queryLower);
        }).toList();
      }

      setState(() {
        _services = servicesList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getServiceImageUrl(String name) {
    final nameLower = name.toLowerCase();

    const serviceKeywords = <List<String>, String>{
      ['dọn', 'vệ sinh', 'clean']: 'assets/images/cleaning.png',
      ['nước', 'ống', 'plumb']: 'assets/images/plumbing.png',
      ['điện', 'cáp', 'electric']: 'assets/images/electrical.png',
      ['it', 'máy tính', 'pc', 'giải pháp']: 'assets/images/it_solutions.png',
    };

    for (var entry in serviceKeywords.entries) {
      if (entry.key.any((keyword) => nameLower.contains(keyword))) {
        return entry.value;
      }
    }
    return 'assets/images/handyman.png';
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F0EA),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  itemCount: _services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    final imageUrl = _getServiceImageUrl(service.name);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingFormScreen(service: service),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                          border: Border.all(color: const Color(0xFFF1F0EA)),
                        ),
                        child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                if (service.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    service.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${_formatPrice(service.price)}/giờ',
                                  style: GoogleFonts.outfit(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingFormScreen(service: service),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6F61E8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text(
                                'Đặt ngay',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
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
                color: const Color(0xFFEFECE6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFF7F7F7F),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy dịch vụ nào',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.searchQuery != null
                  ? 'Chúng tôi không tìm thấy kết quả nào phù hợp với từ khóa "${widget.searchQuery}". Vui lòng thử lại bằng từ khóa khác.'
                  : 'Không có dịch vụ nào trong danh mục này.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
