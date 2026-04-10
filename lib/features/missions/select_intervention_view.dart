import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/intervention_type.dart';
import 'package:nour/features/missions/intervention_form_view.dart';

class SelectInterventionView extends StatelessWidget {
  const SelectInterventionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار نوع المهمة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...mofawadGharadOptions.asMap().entries.map((entry) {
              return _buildInterventionCard(context, entry.value, entry.key);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionCard(
    BuildContext context,
    GharadOption option,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InterventionFormView(option: option),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            if (option.bannerPath.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.asset(
                      option.bannerPath,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        _getIconForOption(option.title),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textSecondary,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.accentGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'بدء المهمة',
                              style: TextStyle(
                                color: context.appColors.accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.arrowLeft,
                              size: 16,
                              color: context.appColors.accentGold,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForOption(String title) {
    if (title.contains('تبيليغ')) return LucideIcons.mail;
    if (title.contains('تنفيذ')) return LucideIcons.gavel;
    return LucideIcons.folderPlus;
  }
}
