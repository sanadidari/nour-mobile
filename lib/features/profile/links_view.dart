import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickLinksView extends StatelessWidget {
  const QuickLinksView({super.key});

  final List<Map<String, dynamic>> _links = const [
    {
      'title': 'وزارة العدل',
      'subtitle': 'الموقع الرسمي للوزارة',
      'url': 'https://www.justice.gov.ma/',
      'icon': LucideIcons.building2,
      'color': Colors.blue,
    },
    {
      'title': 'محاكم',
      'subtitle': 'تتبع القضايا والملفات',
      'url': 'https://www.mahakim.ma/',
      'icon': LucideIcons.gavel,
      'color': Colors.amber,
    },
    {
      'title': 'الأمانة العامة للحكومة',
      'subtitle': 'الجريدة الرسمية والتشريع',
      'url': 'https://www.sgg.gov.ma/',
      'icon': LucideIcons.scroll,
      'color': Colors.teal,
    },
    {
      'title': 'المجلس الأعلى للسلطة القضائية',
      'subtitle': 'المستجدات القضائية',
      'url': 'https://www.cspj.ma/',
      'icon': LucideIcons.scale,
      'color': Colors.deepPurple,
    },
    {
      'title': 'الصندوق الوطني للضمان الاجتماعي',
      'subtitle': 'بوابة المقاولات والأجراء',
      'url': 'https://www.cnss.ma/',
      'icon': LucideIcons.shieldCheck,
      'color': Colors.indigo,
    },
    {
      'title': 'المديرية العامة للضرائب',
      'subtitle': 'بوابة الخدمات الضريبية',
      'url': 'https://www.tax.gov.ma/',
      'icon': LucideIcons.percent,
      'color': Colors.redAccent,
    },
  ];

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('روابط مهنية هامة'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _links.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final link = _links[index];
          final color = link['color'] as Color;
          return InkWell(
            onTap: () => _launchUrl(link['url']),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.appColors.border),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(link['icon'], color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    link['title'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    link['subtitle'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(fontSize: 10, color: context.appColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
