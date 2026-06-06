import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.client.get('/customer/categories');
      setState(() {
        _categories = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh mục dịch vụ: $e')),
      );
    }
  }

  Future<void> _createCategory(String name, String desc) async {
    try {
      await _apiService.client.post('/admin/categories', data: {'name': name, 'description': desc});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo danh mục thành công!')),
      );
      _fetchCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo danh mục: $e')),
      );
    }
  }

  Future<void> _createService(int categoryId, String name, String desc, double price) async {
    try {
      await _apiService.client.post(
        '/admin/services',
        data: {
          'category_id': categoryId,
          'name': name,
          'description': desc,
          'price': price,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm dịch vụ thành công!')),
      );
      _fetchCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thêm dịch vụ: $e')),
      );
    }
  }

  Future<void> _updateService(int serviceId, String name, String desc, double price) async {
    try {
      await _apiService.client.put(
        '/admin/services/$serviceId',
        data: {
          'name': name,
          'description': desc,
          'price': price,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật dịch vụ thành công!')),
      );
      _fetchCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật dịch vụ: $e')),
      );
    }
  }

  Future<void> _deleteService(int serviceId) async {
    try {
      await _apiService.client.delete('/admin/services/$serviceId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa dịch vụ thành công!')),
      );
      _fetchCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa dịch vụ: $e')),
      );
    }
  }

  void _showCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thêm Danh Mục Mới', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop();
                  _createCategory(name, desc);
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }

  void _showServiceDialog({int? categoryId, Map<String, dynamic>? service}) {
    final isEdit = service != null;
    final nameController = TextEditingController(text: isEdit ? service['name'] : '');
    final descController = TextEditingController(text: isEdit ? service['description'] : '');
    final priceController = TextEditingController(text: isEdit ? service['price'].toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Sửa Dịch Vụ' : 'Thêm Dịch Vụ Mới', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Mô tả dịch vụ'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá tiền (USD)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
            if (isEdit)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteService(service['id']);
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (name.isNotEmpty) {
                  Navigator.of(context).pop();
                  if (isEdit) {
                    _updateService(service['id'], name, desc, price);
                  } else {
                    _createService(categoryId!, name, desc, price);
                  }
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Thêm'),
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
        title: Text('Quản Lý Dịch Vụ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Thêm Danh Mục',
            onPressed: _showCategoryDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final services = cat['services'] as List<dynamic>? ?? [];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat['name'] ?? 'Danh mục',
                                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor),
                                    ),
                                    if (cat['description'] != null)
                                      Text(
                                        cat['description'],
                                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                tooltip: 'Thêm Dịch Vụ',
                                onPressed: () => _showServiceDialog(categoryId: cat['id']),
                              )
                            ],
                          ),
                          const Divider(),
                          services.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('Chưa có dịch vụ nào trong danh mục này', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: services.length,
                                  itemBuilder: (context, sIdx) {
                                    final s = services[sIdx];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(s['name'] ?? 'Dịch vụ', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                      subtitle: Text(s['description'] ?? 'Không có mô tả', style: GoogleFonts.outfit(fontSize: 12)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('\$${s['price']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700)),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                            onPressed: () => _showServiceDialog(service: s),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                )
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
