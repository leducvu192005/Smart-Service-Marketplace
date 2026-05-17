import 'package:flutter/material.dart';
import 'services_screen.dart';
import 'booking_form_screen.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ApiService _apiService = ApiService();
  List<ServiceCategory> _categories = [];
  List<Service> _popularServices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch Categories
      final catResponse = await _apiService.client.get('/customer/categories');
      final List<ServiceCategory> loadedCategories = (catResponse.data as List)
          .map((i) => ServiceCategory.fromJson(i))
          .toList();

      // Fetch Services
      final servResponse = await _apiService.client.get('/customer/services');
      final List<Service> loadedServices = (servResponse.data as List)
          .map((i) => Service.fromJson(i))
          .toList();

      if (mounted) {
        setState(() {
          _categories = loadedCategories;
          // Hiển thị 5 dịch vụ đầu tiên làm dịch vụ phổ biến
          _popularServices = loadedServices.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  IconData _getCategoryIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('dọn')) return Icons.cleaning_services;
    if (name.contains('sửa') || name.contains('bảo dưỡng')) return Icons.build;
    if (name.contains('nước')) return Icons.water_drop;
    if (name.contains('điện')) return Icons.electrical_services;
    return Icons.handyman;
  }

  Color _getCategoryColor(String name) {
    name = name.toLowerCase();
    if (name.contains('dọn')) return Colors.blue.shade100;
    if (name.contains('sửa')) return Colors.orange.shade100;
    if (name.contains('nước')) return Colors.cyan.shade100;
    if (name.contains('điện')) return Colors.purple.shade100;
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Text(
                          'Tìm kiếm dịch vụ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm dọn dẹp, sửa chữa...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700))),
                      ],
                    ),
                  )
                else if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  // Categories Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh mục',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Tất cả', style: TextStyle(color: Theme.of(context).primaryColor)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Categories Grid
                  _categories.isEmpty
                      ? const Text('Chưa có danh mục nào.')
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _categories.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: _CategoryCard(
                                  id: cat.id,
                                  title: cat.name,
                                  icon: _getCategoryIcon(cat.name),
                                  color: _getCategoryColor(cat.name),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                  const SizedBox(height: 32),
                  const Text(
                    'Dịch vụ phổ biến',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Popular Services List
                  _popularServices.isEmpty
                      ? const Text('Chưa có dịch vụ nào.')
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _popularServices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final service = _popularServices[index];
                            return _PopularServiceCard(service: service);
                          },
                        ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final int id;
  final String title;
  final IconData icon;
  final Color color;

  const _CategoryCard({required this.id, required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ServicesScreen(categoryId: id, categoryName: title)
        ));
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Icon(icon, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PopularServiceCard extends StatelessWidget {
  final Service service;

  const _PopularServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BookingFormScreen(service: service)
        ));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20, offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.star, color: Theme.of(context).primaryColor, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (service.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('\$${service.price}/h', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BookingFormScreen(service: service)
                ));
              },
            )
          ],
        ),
      ),
    );
  }
}
