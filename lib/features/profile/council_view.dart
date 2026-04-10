import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/huissiers_data.dart';

class CouncilMember {
  final String name;
  final String role;
  final IconData icon;

  const CouncilMember({
    required this.name,
    required this.role,
    this.icon = LucideIcons.user,
  });
}

class CouncilView extends StatelessWidget {
  const CouncilView({super.key});

  final List<CouncilMember> _members = const [
    CouncilMember(
      name: 'ذ/ نور الدين الشطويطي',
      role: 'رئيس المجلس',
      icon: LucideIcons.crown,
    ),
    CouncilMember(
      name: 'ذ/ محمد علي الحسني',
      role: 'نائب الرئيس',
      icon: LucideIcons.userCheck,
    ),
    CouncilMember(name: 'ذ/ محمد علي بن صالح', role: 'الكاتب العام'),
    CouncilMember(name: 'ذ/ عمر العياشي', role: 'أمين المال'),
    CouncilMember(name: 'ذ/ عادل أكبادي', role: 'نائب أمين المال'),
    CouncilMember(name: 'ذ/ جمال السباعي', role: 'نائب الكاتب العام'),
    CouncilMember(name: 'ذ/ حفيظ موسى', role: 'مستشار'),
    CouncilMember(name: 'ذ/ محمد الأزرق', role: 'مستشار'),
    CouncilMember(name: 'ذ/ عبد الواحد البعبوع', role: 'مستشار'),
  ];

  Widget _buildSmartPhoto(
    BuildContext context,
    String? originalPath,
    bool isPresident,
  ) {
    if (originalPath == null || originalPath.isEmpty) {
      return _buildPlaceholder(context, isPresident);
    }

    final String basePath = originalPath.split('.').first;

    return Image.asset(
      originalPath,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          '$basePath.jfif',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              '$basePath.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  '$basePath.jpg',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(context, isPresident);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isPresident) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: context.appColors.border.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المكتب المسير للمجلس')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Council Header
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.appColors.primaryNavy,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.primaryNavy.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'المجلس الجهوي للمفوضين القضائيين',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'لدى الدائرة الاستئنافية بتطوان',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Members List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = _members[index];
                final isPresident = index == 0;

                final String searchName = member.name
                    .replaceAll(RegExp(r'^ذ[ة]?/\s*'), '')
                    .trim();
                final huissierMatches = huissiersData.where((h) {
                  final n1 = h.name.replaceAll(' ', '');
                  final n2 = searchName.replaceAll(' ', '');
                  return n1 == n2;
                });
                final String? photoUrl = huissierMatches.isNotEmpty
                    ? huissierMatches.first.photoUrl
                    : null;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPresident
                          ? context.appColors.accentGold
                          : context.appColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: _buildSmartPhoto(context, photoUrl, isPresident),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              member.role,
                              style: TextStyle(
                                color: context.appColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Contact Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.appColors.border),
              ),
              child: Column(
                children: [
                  _contactRow(
                    context,
                    LucideIcons.mapPin,
                    'شارع علي يعتة، مركز الولاية (ولاية سنتر)، الطابق 4، تطوان',
                  ),
                  const Divider(height: 24),
                  _contactRow(
                    context,
                    LucideIcons.mail,
                    'crhj.tetouan@gmail.com',
                  ),
                  const Divider(height: 24),
                  _contactRow(context, LucideIcons.phone, '0539.70.00.00'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.appColors.accentGold),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
