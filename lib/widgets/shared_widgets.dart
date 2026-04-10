import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/core/utils.dart';

/// Carte de section avec icône et titre (Review + Detail).
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconColor;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.appColors.primaryNavy;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

/// Ligne de métadonnée avec icône, label, valeur et bouton copier.
/// Utilisé dans Evidence Review et Operation Detail.
class MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const MetadataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: context.appColors.textMuted),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textDirection: TextDirection.ltr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (value.isNotEmpty &&
            value != '---' &&
            !value.contains('غير متوفر')) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => copyToClipboard(context, value, label),
            child: Icon(
              LucideIcons.copy,
              size: 14,
              color: context.appColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget de statut de synchronisation partagé (actuellement utilisé dans le Dashboard).
class SyncStatusWidget extends StatelessWidget {
  final int pendingCount;
  final bool isSyncing;
  final String? currentDossier;
  final String? lastError;
  final VoidCallback onRetry;

  const SyncStatusWidget({
    super.key,
    required this.pendingCount,
    required this.isSyncing,
    this.currentDossier,
    this.lastError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && !isSyncing && lastError == null)
      return const SizedBox.shrink();

    final bool hasError = lastError != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: hasError
            ? context.appColors.error.withOpacity(0.08)
            : (isSyncing
                  ? context.appColors.info.withOpacity(0.1)
                  : context.appColors.warning.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? context.appColors.error.withOpacity(0.3)
              : (isSyncing
                    ? context.appColors.info.withOpacity(0.3)
                    : context.appColors.warning.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          if (isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            )
          else
            Icon(
              hasError ? LucideIcons.alertCircle : LucideIcons.cloudOff,
              color: hasError
                  ? context.appColors.error
                  : context.appColors.warning,
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSyncing
                      ? 'جاري إرسال البيانات...'
                      : (hasError
                            ? 'عذراً، حدث خطأ في الإرسال'
                            : 'بانتظار الإرسال'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: hasError
                        ? context.appColors.error
                        : (isSyncing
                              ? context.appColors.info
                              : context.appColors.warning),
                  ),
                ),
                Text(
                  isSyncing
                      ? 'جاري رفع الملف: ${currentDossier ?? "..."}'
                      : (hasError
                            ? 'فشل الإرسال. تأكد من الإنترنت وحاول مرة أخرى'
                            : 'يوجد $pendingCount مهمة في انتظار توفر الإنترنت'),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSecondary,
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'التفاصيل: $lastError',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appColors.error.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (!isSyncing)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasError
                    ? context.appColors.error
                    : context.appColors.warning,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                minimumSize: const Size(60, 32),
              ),
              child: Text(
                hasError ? 'إعادة المحاولة' : 'إرسال الآن',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
