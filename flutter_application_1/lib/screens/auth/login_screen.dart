import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _handleLogin() async {
    if (_usernameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên đăng nhập');
      return;
    }
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (mounted) setState(() => _isLoading = false);

    if (!success && mounted) {
      _showError('Tài khoản hoặc mật khẩu không đúng');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ─── WIDE (Desktop/Web) layout ─────────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left - Brand panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(top: -80, left: -80, child: _circle(300, Colors.white.withOpacity(0.04))),
                Positioned(bottom: -60, right: -60, child: _circle(260, Colors.white.withOpacity(0.04))),
                Positioned(top: 200, right: -40, child: _circle(160, Colors.white.withOpacity(0.06))),

                // Content
                Padding(
                  padding: const EdgeInsets.all(56),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.home_repair_service_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Smart Service\nMarketplace',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nền tảng kết nối thợ chuyên nghiệp\nvà khách hàng toàn quốc.',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Features
                      ...[
                        (Icons.verified_rounded, 'Thợ được xác minh chuyên nghiệp'),
                        (Icons.schedule_rounded, 'Đặt lịch linh hoạt 24/7'),
                        (Icons.shield_rounded, 'Thanh toán an toàn, bảo đảm'),
                      ].map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item.$1, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Text(item.$2,
                                    style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right - Login form
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── NARROW (Mobile) layout ────────────────────────────────────────────────
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_repair_service_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                Text('Smart Service', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Marketplace', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 20)),
              ],
            ),
          ),
          // Form
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Đăng nhập',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Text('Chào mừng bạn trở lại!',
            style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF64748B))),
        const SizedBox(height: 36),

        // Username
        Text('Tên đăng nhập', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          style: GoogleFonts.outfit(fontSize: 14),
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: 'Nhập tên đăng nhập...',
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 20),

        // Password
        Text('Mật khẩu', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          style: GoogleFonts.outfit(fontSize: 14),
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu...',
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF9CA3AF)),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: const Color(0xFF9CA3AF)),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 28),

        // Login button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Đăng nhập'),
          ),
        ),
        const SizedBox(height: 28),

        // Divider
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('hoặc', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF9CA3AF))),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 20),

        // Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chưa có tài khoản?', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B))),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
              child: Text('Đăng ký ngay',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
