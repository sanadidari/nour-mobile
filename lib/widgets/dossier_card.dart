import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/core/utils.dart';

/// Carte d'un dossier dans les listes (Dashboard + History).
class DossierCard extends StatelessWidget {
  final String dossierId;
  final String interventionType;
  final int photoCount;
  final DateTime? capturedAt;
  final bool showGpsBadge;
  final VoidCallback onTap;

  const DossierCard({
    super.key,
    required this.dossierId,
    required this.interventionType,
    required this.photoCount,
    this.capturedAt,
    this.showGpsBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = capturedAt != null
        ? DateFormat('MM/dd HH:mm').format(capturedAt!)
        : '---';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.appColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getIconForType(interventionType),
                color: context.appColors.accentGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interventionType.isNotEmpty ? interventionType : 'عملية',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'ملف: $dossierId',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.accentGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$photoCount 📷',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✓ مرسل',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.appColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              LucideIcons.chevronLeft,
              size: 16,
              color: context.appColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
