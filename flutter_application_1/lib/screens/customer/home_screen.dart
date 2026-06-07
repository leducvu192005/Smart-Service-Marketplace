import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'services_screen.dart';
import 'booking_form_screen.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ApiService _apiService = ApiService();
  List<ServiceCategory> _categories = [];
  List<Service> _popularServices = [];
  List<Service> _allServices = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategoryName = 'Tất cả';
  String _currentLocation = 'Đà Nẵng, Việt Nam';
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _currentLocation = 'Đang định vị...';
    });

    try {
      // 1. Kiểm tra dịch vụ định vị (GPS)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _currentLocation = 'GPS tắt';
        });
        return;
      }

      // 2. Kiểm tra và xin quyền vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocating = false;
            _currentLocation = 'Quyền bị từ chối';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _currentLocation = 'Quyền bị khóa';
        });
        return;
      }

      // 3. Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );

      // 4. Gọi API OpenStreetMap Nominatim để giải mã tọa độ thành địa chỉ
      final dio = Dio();
      dio.options.headers['User-Agent'] = 'SmartServiceApp/1.0';

      final response = await dio
          .get(
            'https://nominatim.openstreetmap.org/reverse',
            queryParameters: {
              'format': 'json',
              'lat': position.latitude,
              'lon': position.longitude,
              'zoom': 15,
              'addressdetails': 1,
            },
          )
          .timeout(const Duration(seconds: 5));

      String address = 'Đà Nẵng, Việt Nam';
      if (response.statusCode == 200 && response.data != null) {
        final addr = response.data['address'];
        if (addr != null) {
          final city =
              addr['city'] ??
              addr['province'] ??
              addr['state'] ??
              addr['town'] ??
              '';
          final suburb =
              addr['suburb'] ??
              addr['district'] ??
              addr['quarter'] ??
              addr['city_district'] ??
              '';

          if (suburb.isNotEmpty && city.isNotEmpty) {
            address = '$suburb, $city';
          } else if (city.isNotEmpty) {
            address = city;
          } else {
            address =
                response.data['display_name']?.split(',').take(2).join(',') ??
                'Đà Nẵng, Việt Nam';
          }
        }
      }

      // Rút ngắn các tiền tố dài dòng
      address = address
          .replaceAll('Thành phố ', 'TP. ')
          .replaceAll('Quận ', 'Q. ');

      if (mounted) {
        setState(() {
          _isLocating = false;
          _currentLocation = address;
        });
      }
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      if (mounted) {
        setState(() {
          _isLocating = false;
          _currentLocation = 'Đà Nẵng, Việt Nam'; // Dự phòng an toàn
        });
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Tải danh mục dịch vụ
      List<ServiceCategory> loadedCategories = [];
      try {
        final catResponse = await _apiService.client.get(
          '/customer/categories',
        );
        loadedCategories = (catResponse.data as List)
            .map((i) => ServiceCategory.fromJson(i))
            .toList();
      } catch (catErr) {
        debugPrint('Error fetching categories: $catErr');
      }

      // 2. Tải danh sách dịch vụ
      final servResponse = await _apiService.client.get('/customer/services');
      final List<Service> loadedServices = (servResponse.data as List)
          .map((i) => Service.fromJson(i))
          .toList();

      if (mounted) {
        setState(() {
          _categories = loadedCategories;
          _allServices = loadedServices;
          _filterServices();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  void _filterServices() {
    if (_selectedCategoryName == 'All' || _selectedCategoryName == 'Tất cả') {
      _popularServices = _allServices.take(5).toList();
    } else {
      final nameLower = _selectedCategoryName.toLowerCase();
      _popularServices = _allServices.where((serv) {
        final servName = serv.name.toLowerCase();
        final servDesc = (serv.description ?? '').toLowerCase();

        if (nameLower.contains('cleaning') ||
            nameLower.contains('dọn') ||
            nameLower.contains('vệ sinh')) {
          return servName.contains('dọn') ||
              servName.contains('vệ sinh') ||
              servName.contains('clean');
        }
        if (nameLower.contains('plumb') ||
            nameLower.contains('nước') ||
            nameLower.contains('ống')) {
          return servName.contains('nước') ||
              servName.contains('ống') ||
              servName.contains('plumb');
        }
        if (nameLower.contains('electric') || nameLower.contains('điện')) {
          return servName.contains('điện') ||
              servName.contains('cáp') ||
              servName.contains('electric');
        }
        if (nameLower.contains('it') ||
            nameLower.contains('solutions') ||
            nameLower.contains('máy tính') ||
            nameLower.contains('giải pháp')) {
          return servName.contains('it') ||
              servName.contains('máy tính') ||
              servName.contains('pc');
        }
        return servName.contains(nameLower) || servDesc.contains(nameLower);
      }).toList();

      if (_popularServices.isEmpty) {
        _popularServices = _allServices.where((serv) {
          final servName = serv.name.toLowerCase();
          final servDesc = (serv.description ?? '').toLowerCase();
          return servName.contains(nameLower) || servDesc.contains(nameLower);
        }).toList();
      }

      if (_popularServices.isEmpty) {
        _popularServices = _allServices.take(3).toList();
      }
    }
  }

  List<String> get _displayCategoryNames {
    final List<String> list = ['Tất cả'];
    if (_categories.isEmpty) {
      list.addAll(['Dọn dẹp', 'Giải pháp IT', 'Sửa ống nước', 'Sửa điện']);
    } else {
      list.addAll(_categories.map((c) => c.name));
    }
    return list;
  }

  // Tối ưu hóa Mapping ảnh sử dụng Map & vòng lặp thay vì chuỗi if-else lặp lại
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final String fullName = user?['full_name'] ?? 'Khách hàng';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F4EB), Color(0xFFFBF9F4)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            color: theme.primaryColor,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    children: [
                      _buildHeader(fullName),
                      const SizedBox(height: 28),
                      _buildHeadline(),
                      const SizedBox(height: 28),
                      _buildSearchBar(),
                      const SizedBox(height: 28),
                      _buildCategoriesList(),
                      const SizedBox(height: 28),
                      _buildHeroCard(theme), // Nhận diện thiết kế 3D mới
                      const SizedBox(height: 32),
                      Text(
                        'Dịch vụ phổ biến',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _popularServices.isEmpty
                          ? _buildEmptyServicesWidget()
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _popularServices.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 1.1,
                                  ),
                              itemBuilder: (context, index) {
                                final service = _popularServices[index];
                                return _buildServiceCard(service, theme);
                              },
                            ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String fullName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F0EA)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF7555CF).withOpacity(0.1),
                child: Text(
                  fullName.isNotEmpty
                      ? fullName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7555CF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chào mừng',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    fullName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _loadCurrentLocation,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1F0EA)),
                ),
                child: _isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF7555CF),
                        ),
                      )
                    : const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF1E293B),
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentLocation,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhà thông minh,',
          style: GoogleFonts.outfit(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            height: 1.05,
          ),
        ),
        Text(
          'Dịch vụ mượt mà',
          style: GoogleFonts.playfairDisplay(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1E293B),
            height: 1.05,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0EA),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF7F7F7F), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF8E8E8E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _displayCategoryNames.map((name) {
          final bool isActive = _selectedCategoryName == name;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryName = name;
                  _filterServices();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF222222)
                      : const Color(0xFFEFECE6),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: isActive ? Colors.white : const Color(0xFF3A3A3A),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Đã tối ưu hóa giúp ảnh cô lao công nhô cao hẳn lên trên Card (Hiệu ứng 3D Pop-out)
  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 330,
      margin: const EdgeInsets.only(
        top: 40,
      ), // Tạo khoảng trống phía trên cho đầu ảnh nhô lên
      decoration: BoxDecoration(
        color: const Color(0xFFD4EFE8),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4EFE8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none, // Cho phép ảnh nhô tràn viền Container
        children: [
          // Ảnh người được cấu hình đẩy lồi lên trên qua thuộc tính top âm
          Positioned(
            right: 0,
            bottom: 0,
            top: -40,
            child: Image.asset(
              'assets/images/cleaner_lady.png',
              fit: BoxFit.contain,
              width: 220,
            ),
          ),

          // Lớp phủ Gradient mờ mịn màng
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4EFE8),
                    const Color(0xFFD4EFE8).withOpacity(0.9),
                    const Color(0xFFD4EFE8).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPillIndicator(
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time_filled,
                              size: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hỗ trợ 24/7',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPillIndicator(
                      Text(
                        'Ưu đãi 40%',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 16,
                      color: Color(0xFF55776C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vệ sinh nhanh & sạch',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF55776C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dịch vụ Dọn dẹp\nNhà cửa Nhanh chóng',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.15,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final cleaningServ = _allServices.firstWhere(
                      (s) =>
                          s.name.toLowerCase().contains('dọn') ||
                          s.name.toLowerCase().contains('clean'),
                      orElse: () => _allServices.isNotEmpty
                          ? _allServices.first
                          : Service(
                              id: 1,
                              name: 'Quick Cleaning',
                              price: 25.0,
                              categoryId: 1,
                            ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingFormScreen(service: cleaningServ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: Text(
                            'Đặt ngay',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
    );
  }

  Widget _buildPillIndicator(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildServiceCard(Service service, ThemeData theme) {
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
          border: Border.all(color: const Color(0xFFF1F0EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.asset(
                  imageUrl, // Load trực tiếp qua cục bộ chính xác
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.price.toStringAsFixed(0)}đ/giờ',
                    style: GoogleFonts.outfit(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyServicesWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        'Không tìm thấy dịch vụ nào phù hợp.',
        style: GoogleFonts.outfit(
          color: const Color.fromARGB(255, 107, 68, 68),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
