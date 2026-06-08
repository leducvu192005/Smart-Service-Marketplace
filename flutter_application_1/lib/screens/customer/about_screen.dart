import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF7555CF),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7555CF), Color(0xFF4C35A3)],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20, left: -30,
                    child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  // Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 80, 28, 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.home_repair_service_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Smart Service',
                            style: GoogleFonts.outfit(
                              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                            ),
                          ),
                          Text(
                            'Marketplace',
                            style: GoogleFonts.outfit(
                              fontSize: 20, fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kết nối bạn với những thợ lành nghề tin cậy',
                            style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission
                  _SectionCard(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Sứ mệnh của chúng tôi',
                    content:
                        'Smart Service Marketplace được xây dựng với mong muốn đơn giản hóa việc tìm kiếm dịch vụ sửa chữa tại nhà. '
                        'Chúng tôi kết nối trực tiếp khách hàng với những thợ lành nghề, được kiểm duyệt, '
                        'mang lại sự minh bạch về giá cả và chất lượng dịch vụ.',
                  ),
                  const SizedBox(height: 16),

                  // Features
                  Text(
                    'Tính năng nổi bật',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.search_rounded,
                    iconColor: const Color(0xFF7555CF),
                    title: 'Đặt dịch vụ dễ dàng',
                    desc: 'Tìm và đặt dịch vụ sửa chữa tại nhà chỉ trong vài bước: chọn dịch vụ, chọn giờ, điền địa chỉ.',
                  ),
                  _FeatureItem(
                    icon: Icons.verified_user_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Thợ được kiểm duyệt',
                    desc: 'Tất cả thợ trên hệ thống đều được Admin xét duyệt hồ sơ, đảm bảo tay nghề và độ tin cậy.',
                  ),
                  _FeatureItem(
                    icon: Icons.chat_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Chat trực tiếp real-time',
                    desc: 'Nhắn tin thảo luận với thợ ngay sau khi đặt lịch để thống nhất yêu cầu và thời gian.',
                  ),
                  _FeatureItem(
                    icon: Icons.my_location_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Theo dõi trạng thái đơn hàng',
                    desc: 'Biết chính xác thợ đang ở đâu, đang làm gì trong suốt quá trình thực hiện dịch vụ.',
                  ),
                  _FeatureItem(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Đánh giá & Xếp hạng',
                    desc: 'Hệ thống đánh giá minh bạch giúp bạn chọn thợ tốt nhất và thợ luôn nỗ lực nâng cao chất lượng.',
                  ),
                  _FeatureItem(
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Hỗ trợ 24/7',
                    desc: 'Đội ngũ hỗ trợ sẵn sàng giải quyết mọi vấn đề phát sinh trong quá trình sử dụng dịch vụ.',
                  ),
                  const SizedBox(height: 16),

                  // How it works
                  Text(
                    'Cách thức hoạt động',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  _StepCard(step: 1, title: 'Tạo tài khoản', desc: 'Đăng ký miễn phí với email và số điện thoại của bạn.'),
                  _StepCard(step: 2, title: 'Chọn dịch vụ', desc: 'Duyệt danh mục dịch vụ và chọn loại công việc bạn cần.'),
                  _StepCard(step: 3, title: 'Đặt lịch', desc: 'Chọn thời gian, nhập địa chỉ và ghi chú yêu cầu đặc biệt.'),
                  _StepCard(step: 4, title: 'Thợ tiếp nhận', desc: 'Thợ gần nhất nhận đơn và đến đúng giờ đã hẹn.'),
                  _StepCard(step: 5, title: 'Hoàn thành & Đánh giá', desc: 'Sau khi xong việc, đánh giá thợ để giúp cộng đồng.'),
                  const SizedBox(height: 16),

                  // For workers
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7555CF), Color(0xFF4C35A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.engineering_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'Bạn là thợ lành nghề?',
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tham gia hệ thống để nhận đơn hàng, tăng thu nhập và xây dựng uy tín nghề nghiệp. '
                          'Đăng ký trong trang Hồ sơ của bạn!',
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Version info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Smart Service Marketplace',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phiên bản 1.0.0 • © 2025',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 24),
                      ],
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
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  const _SectionCard({required this.icon, required this.iconColor, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], height: 1.6)),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  const _FeatureItem({required this.icon, required this.iconColor, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F0EA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600], height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String desc;
  const _StepCard({required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF7555CF),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('$step', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              if (step < 5)
                Container(width: 2, height: 24, color: const Color(0xFF7555CF).withOpacity(0.2)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                  if (step < 5) const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
