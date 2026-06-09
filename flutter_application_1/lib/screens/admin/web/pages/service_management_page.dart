import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/api_service.dart';
import '../widgets/web_card.dart';

class ServiceManagementPage extends StatefulWidget {
  const ServiceManagementPage({super.key});

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage> {
  final ApiService _api = ApiService();
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.client.get('/customer/categories');
      if (mounted)
        setState(() {
          _categories = res.data;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCategory(String name, String desc) async {
    try {
      await _api.client.post(
        '/admin/categories',
        data: {'name': name, 'description': desc},
      );
      _snack('✅ Tạo danh mục "$name" thành công!', Colors.green);
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  Future<void> _createService(
    int catId,
    String name,
    String desc,
    double price,
  ) async {
    try {
      await _api.client.post(
        '/admin/services',
        data: {
          'category_id': catId,
          'name': name,
          'description': desc,
          'price': price,
        },
      );
      _snack('✅ Thêm dịch vụ "$name" thành công!', Colors.green);
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  Future<void> _updateService(
    int id,
    String name,
    String desc,
    double price,
  ) async {
    try {
      await _api.client.put(
        '/admin/services/$id',
        data: {'name': name, 'description': desc, 'price': price},
      );
      _snack('✅ Cập nhật dịch vụ thành công!', Colors.green);
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  Future<void> _deleteService(int id) async {
    try {
      await _api.client.delete('/admin/services/$id');
      _snack('Đã xóa dịch vụ.', Colors.orange);
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    // Hiện confirm dialog trước
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xóa danh mục', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text(
          'Xóa danh mục "$name"?\nDanh mục phải rỗng (không có dịch vụ nào) mới có thể xóa.',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.client.delete('/admin/categories/$id');
      _snack('Đã xóa danh mục "$name".', Colors.orange);
      _load();
    } catch (e) {
      _snack('Không thể xóa: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Thêm Danh Mục Mới',
        fields: [
          _FieldDef(
            'Tên danh mục',
            nameCtrl,
            Icons.category_outlined,
            required: true,
          ),
          _FieldDef('Mô tả', descCtrl, Icons.description_outlined),
        ],
        onSave: () {
          if (nameCtrl.text.trim().isEmpty) return;
          Navigator.pop(context);
          _createCategory(nameCtrl.text.trim(), descCtrl.text.trim());
        },
      ),
    );
  }

  void _showServiceDialog({int? categoryId, Map<String, dynamic>? service}) {
    final isEdit = service != null;
    final nameCtrl = TextEditingController(text: isEdit ? service['name'] : '');
    final descCtrl = TextEditingController(
      text: isEdit ? service['description'] : '',
    );
    final priceCtrl = TextEditingController(
      text: isEdit ? service['price'].toString() : '',
    );
    showDialog(
      context: context,
      builder: (_) => _FormDialog(
        title: isEdit ? 'Sửa Dịch Vụ' : 'Thêm Dịch Vụ Mới',
        fields: [
          _FieldDef(
            'Tên dịch vụ',
            nameCtrl,
            Icons.room_service_outlined,
            required: true,
          ),
          _FieldDef('Mô tả', descCtrl, Icons.description_outlined),
          _FieldDef(
            'Giá (\$)',
            priceCtrl,
            Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
        ],
        deleteAction: isEdit
            ? () {
                Navigator.pop(context);
                _deleteService(service['id']);
              }
            : null,
        onSave: () {
          if (nameCtrl.text.trim().isEmpty) return;
          final price = double.tryParse(priceCtrl.text) ?? 0.0;
          Navigator.pop(context);
          if (isEdit) {
            _updateService(
              service['id'],
              nameCtrl.text.trim(),
              descCtrl.text.trim(),
              price,
            );
          } else {
            _createService(
              categoryId!,
              nameCtrl.text.trim(),
              descCtrl.text.trim(),
              price,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalServices = _categories.fold(
      0,
      (sum, c) => sum + ((c['services'] as List?)?.length ?? 0),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: WebCard(
        title: 'Quản Lý Dịch Vụ & Biểu Giá',
        badge: '$totalServices dịch vụ',
        badgeColor: const Color(0xFF10B981),
        action: Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Thêm Danh Mục',
                style: GoogleFonts.outfit(fontSize: 13),
              ),
              onPressed: _showCategoryDialog,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _load,
            ),
          ],
        ),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : _categories.isEmpty
            ? _empty()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _categories
                      .map(
                        (cat) => _CategorySection(
                          category: cat,
                          onAddService: () =>
                              _showServiceDialog(categoryId: cat['id']),
                          onEditService: (s) => _showServiceDialog(service: s),
                          onDeleteCategory: () => _deleteCategory(cat['id'], '${cat['name']}'),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(48),
    child: Center(
      child: Text(
        'Chưa có danh mục nào',
        style: GoogleFonts.outfit(color: Colors.grey),
      ),
    ),
  );
}

class _CategorySection extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback onAddService;
  final ValueChanged<Map<String, dynamic>> onEditService;
  final VoidCallback onDeleteCategory;

  const _CategorySection({
    required this.category,
    required this.onAddService,
    required this.onEditService,
    required this.onDeleteCategory,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final services = (cat['services'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Category header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _expanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.folder_open_rounded
                        : Icons.folder_rounded,
                    color: const Color(0xFF4F46E5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'] ?? 'Danh mục',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (cat['description'] != null)
                          Text(
                            cat['description'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${services.length} dịch vụ',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      'Thêm DV',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    onPressed: widget.onAddService,
                  ),
                  // Nút xóa danh mục
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Xóa danh mục',
                    onPressed: widget.onDeleteCategory,
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          // Services
          if (_expanded)
            ...services.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i < services.length - 1
                        ? const BorderSide(color: Color(0xFFF1F5F9))
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.room_service_outlined,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'] ?? 'Dịch vụ',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            s['description'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${s['price']}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF4F46E5),
                      ),
                      onPressed: () => widget.onEditService(s),
                      tooltip: 'Sửa',
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _FieldDef {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool required;
  final TextInputType? keyboardType;
  const _FieldDef(
    this.label,
    this.controller,
    this.icon, {
    this.required = false,
    this.keyboardType,
  });
}

class _FormDialog extends StatelessWidget {
  final String title;
  final List<_FieldDef> fields;
  final VoidCallback onSave;
  final VoidCallback? deleteAction;

  const _FormDialog({
    required this.title,
    required this.fields,
    required this.onSave,
    this.deleteAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: f.controller,
                    keyboardType: f.keyboardType,
                    decoration: InputDecoration(
                      labelText: f.label,
                      prefixIcon: Icon(f.icon, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (deleteAction != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Xóa'),
                      onPressed: deleteAction,
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: onSave, child: const Text('Lưu')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
