import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../customer/about_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false;
  
  // Worker profile fields
  String _fullName = '';
  String _phone = '';
  String _avatarUrl = '';
  String _address = '';
  String _city = '';
  String _district = '';
  String _jobTitle = '';
  int _experienceYears = 0;
  String _skills = '';
  String _description = '';
  bool _isAvailable = false;
  
  double _walletBalance = 0.0;
  int _totalJobs = 0;
  double _rating = 0.0;
  int _totalReviews = 0;

  // New fields for selectable skill categories
  List<dynamic> _availableSkills = [];
  List<String> _selectedSkills = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // 1. Fetch worker profile
      final res = await _apiService.client.get('/workers/me');
      final data = res.data;

      // 2. Fetch all active skill categories
      List<dynamic> categories = [];
      try {
        final catRes = await _apiService.client.get('/workers/skills/categories');
        categories = catRes.data;
      } catch (catErr) {
        debugPrint('Error fetching skills categories: $catErr');
      }

      if (mounted) {
        setState(() {
          _fullName = data['full_name'] ?? '';
          _phone = data['phone'] ?? '';
          _avatarUrl = data['avatar_url'] ?? '';
          _address = data['address'] ?? '';
          _city = data['city'] ?? '';
          _district = data['district'] ?? '';
          _jobTitle = data['job_title'] ?? '';
          _experienceYears = (data['experience_years'] as num?)?.toInt() ?? 0;
          _skills = data['skills'] ?? '';
          _description = data['description'] ?? '';
          _isAvailable = data['is_available'] ?? false;
          _walletBalance = (data['wallet_balance'] as num?)?.toDouble() ?? 0.0;
          _totalJobs = (data['total_jobs'] as num?)?.toInt() ?? 0;
          _rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          _totalReviews = (data['total_reviews'] as num?)?.toInt() ?? 0;
          
          _availableSkills = categories;
          // Parse skills from database comma-separated format
          _selectedSkills = _skills
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi tải thông tin hồ sơ thợ'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Yêu Cầu Rút Tiền', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số dư khả dụng: ${_formatPrice(_walletBalance)}',
                    style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền muốn rút (VND)',
                      prefixIcon: Icon(Icons.payments_outlined),
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
                  onPressed: isSubmitting ? null : () async {
                    final amt = double.tryParse(amountController.text) ?? 0.0;
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
                      );
                      return;
                    }
                    if (amt > _walletBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Số dư ví không đủ')),
                      );
                      return;
                    }
                    setStateDialog(() => isSubmitting = true);
                    try {
                      await _apiService.client.post('/workers/withdraw', data: {'amount': amt});
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yêu cầu rút tiền của bạn đã gửi lên Admin phê duyệt.')),
                        );
                        _fetchProfile();
                      }
                    } catch (e) {
                      setStateDialog(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi rút tiền: $e')),
                        );
                      }
                    }
                  },
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Gửi Yêu Cầu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isSaving = true);
    
    // Obtain AuthProvider instance before async call to avoid using BuildContext across async gap
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Compile selected skills back to a comma-separated string
      _skills = _selectedSkills.join(', ');

      final body = {
        'full_name': _fullName,
        'phone': _phone,
        'avatar_url': _avatarUrl,
        'address': _address,
        'city': _city,
        'district': _district,
        'job_title': _jobTitle,
        'experience_years': _experienceYears,
        'skills': _skills,
        'description': _description,
        'is_available': _isAvailable,
      };
      
      await _apiService.client.put('/workers/me', data: body);
      
      // Update global AuthProvider user cache if needed
      await authProvider.checkAuthStatus();
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(
          'Hồ sơ Thợ',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditMode ? Icons.close : Icons.edit_note, color: theme.primaryColor),
              onPressed: () {
                setState(() {
                  if (_isEditMode) {
                    _fetchProfile(); // Revert changes
                  }
                  _isEditMode = !_isEditMode;
                });
              },
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Avatar Section
                  _buildAvatarSection(theme),
                  const SizedBox(height: 32),
                  
                  // Profile Fields
                  _isEditMode ? _buildEditForm(theme) : _buildViewProfile(theme),
                  
                  const SizedBox(height: 32),
                  
                  // Save / Cancel / Logout buttons
                  if (_isEditMode) ...[
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Lưu thay đổi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => auth.logout(),
                      icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                      label: Text(
                        'Đăng xuất tài khoản',
                        style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection(ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
            child: _avatarUrl.isEmpty
                ? Text(
                    _fullName.isNotEmpty ? _fullName.substring(0, 1).toUpperCase() : 'W',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  )
                : null,
          ),
        ),
        if (_isEditMode) ...[
          const SizedBox(height: 12),
          Text(
            'Mẹo: Dán URL hình ảnh ở bên dưới để đổi avatar',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade400),
          )
        ]
      ],
    );
  }

  Widget _buildViewProfile(ThemeData theme) {
    return Column(
      children: [
        _buildInfoCard(
          title: 'Thông tin cá nhân',
          children: [
            _buildDetailRow(label: 'Họ và tên', value: _fullName, icon: Icons.person_outline),
            _buildDetailRow(label: 'Số điện thoại', value: _phone, icon: Icons.phone_android),
            _buildDetailRow(label: 'Địa chỉ email', value: _fullName.isNotEmpty ? '${_fullName.toLowerCase().replaceAll(' ', '')}@gmail.com' : '', icon: Icons.email_outlined),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: 'Hồ sơ nghề nghiệp',
          children: [
            _buildDetailRow(label: 'Công việc chuyên môn', value: _jobTitle, icon: Icons.construction_outlined),
            _buildDetailRow(label: 'Kinh nghiệm làm việc', value: '$_experienceYears năm', icon: Icons.history_edu_outlined),
            // Custom premium Wrap of Chips for skills
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_outlined, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kỹ năng chuyên sâu', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade400)),
                        const SizedBox(height: 6),
                        _selectedSkills.isEmpty
                            ? Text(
                                'Chưa cập nhật',
                                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedSkills.map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: theme.primaryColor.withOpacity(0.15)),
                                    ),
                                    child: Text(
                                      skill,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            _buildDetailRow(label: 'Mô tả thêm', value: _description, icon: Icons.description_outlined),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: 'Địa chỉ hoạt động',
          children: [
            _buildDetailRow(label: 'Khu vực cụ thể', value: _address, icon: Icons.home_outlined),
            _buildDetailRow(label: 'Quận / Huyện', value: _district, icon: Icons.location_city_outlined),
            _buildDetailRow(label: 'Tỉnh / Thành phố', value: _city, icon: Icons.map_outlined),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: 'Thống kê doanh thu & Hoạt động',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Số dư ví',
                    value: _formatPrice(_walletBalance),
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    label: 'Số việc hoàn thành',
                    value: '$_totalJobs việc',
                    icon: Icons.task_alt_outlined,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              label: 'Đánh giá trung bình',
              value: '${_rating.toStringAsFixed(1)} / 5.0 ⭐ ($_totalReviews đánh giá)',
              icon: Icons.star_outline_rounded,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_outlined, size: 20, color: Colors.purple),
              ),
              title: Text('Yêu cầu rút tiền từ ví', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text('Gửi yêu cầu rút tiền lên hệ thống quản trị', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
              trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              onTap: _showWithdrawDialog,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: 'Thông tin thêm',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, size: 20, color: Colors.teal),
              ),
              title: Text('Về chúng tôi', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text('Tính năng & thông tin ứng dụng', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
              trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Chưa cập nhật',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    return Column(
      children: [
        _buildTextField(
          label: 'Họ và tên',
          initialValue: _fullName,
          icon: Icons.person_outline,
          onSaved: (val) => _fullName = val ?? '',
          validator: (val) => val == null || val.isEmpty ? 'Vui lòng điền họ tên' : null,
        ),
        _buildTextField(
          label: 'Số điện thoại',
          initialValue: _phone,
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          onSaved: (val) => _phone = val ?? '',
        ),
        _buildTextField(
          label: 'Đường dẫn ảnh đại diện (URL)',
          initialValue: _avatarUrl,
          icon: Icons.link,
          onSaved: (val) => _avatarUrl = val ?? '',
        ),
        _buildTextField(
          label: 'Tỉnh / Thành phố',
          initialValue: _city,
          icon: Icons.map_outlined,
          onSaved: (val) => _city = val ?? '',
        ),
        _buildTextField(
          label: 'Quận / Huyện',
          initialValue: _district,
          icon: Icons.location_city_outlined,
          onSaved: (val) => _district = val ?? '',
        ),
        _buildTextField(
          label: 'Khu vực cụ thể (Địa chỉ nhà)',
          initialValue: _address,
          icon: Icons.home_outlined,
          onSaved: (val) => _address = val ?? '',
        ),
        _buildTextField(
          label: 'Công việc chuyên môn',
          initialValue: _jobTitle,
          icon: Icons.construction_outlined,
          onSaved: (val) => _jobTitle = val ?? '',
        ),
        _buildTextField(
          label: 'Kinh nghiệm làm việc (Số năm)',
          initialValue: _experienceYears.toString(),
          icon: Icons.history_edu_outlined,
          keyboardType: TextInputType.number,
          onSaved: (val) => _experienceYears = int.tryParse(val ?? '0') ?? 0,
        ),
        // Selectable skill categories instead of text entry
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_outlined, size: 18, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Kỹ năng chuyên sâu (Chọn từ danh sách)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _availableSkills.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Không tải được danh mục kỹ năng',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSkills.map<Widget>((cat) {
                          final String skillName = cat['name'] ?? '';
                          final bool isSelected = _selectedSkills.contains(skillName);
                          return FilterChip(
                            label: Text(skillName),
                            labelStyle: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            selected: isSelected,
                            selectedColor: theme.primaryColor,
                            checkmarkColor: Colors.white,
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? theme.primaryColor : Colors.grey.shade200,
                              ),
                            ),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  if (!_selectedSkills.contains(skillName)) {
                                    _selectedSkills.add(skillName);
                                  }
                                } else {
                                  _selectedSkills.remove(skillName);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
        _buildTextField(
          label: 'Mô tả chi tiết năng lực bản thân',
          initialValue: _description,
          icon: Icons.description_outlined,
          maxLines: 4,
          onSaved: (val) => _description = val ?? '',
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onSaved: onSaved,
        validator: validator,
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
