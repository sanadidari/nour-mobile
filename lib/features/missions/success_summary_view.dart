import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';

class SuccessSummaryView extends StatelessWidget {
  final String dossierId;
  final String interventionType;
  final int photoCount;
  final Map<String, String> formFields;

  const SuccessSummaryView({
    super.key,
    required this.dossierId,
    required this.interventionType,
    required this.photoCount,
    required this.formFields,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: context.appColors.bgSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Animated Success Icon (or static)
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: context.appColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.checkCircle,
                    color: context.appColors.success,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Success Message
              Text(
                'تم الإرسال بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.success,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'تم تسجيل جميع بيانات العملية ورفع الصور بسلام.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textMuted,
                ),
              ),

              const SizedBox(height: 40),

              // Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.appColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.appColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص العملية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 30),

                    _buildDetailRow(
                      context,
                      LucideIcons.fileText,
                      'نوع التدخل',
                      interventionType,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      LucideIcons.hash,
                      'رقم الملف',
                      dossierId,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      LucideIcons.camera,
                      'عدد الصور الملتقطة',
                      '$photoCount صور',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      LucideIcons.clock,
                      'تاريخ الإرسال',
                      dateStr,
                    ),

                    if (formFields.isNotEmpty) ...[
                      const Divider(height: 30),
                      Text(
                        'بيانات المعاينة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...formFields.entries
                          .where((e) => e.value.isNotEmpty)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.info,
                                    size: 16,
                                    color: context.appColors.accentGold,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.key,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.appColors.textMuted,
                                          ),
                                        ),
                                        Text(
                                          e.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                context.appColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Back Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(LucideIcons.home),
                label: const Text(
                  'العودة إلى الرئيسية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label بنجاح'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.appColors.primaryNavy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: context.appColors.primaryNavy),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (value.isNotEmpty && value != '---')
          GestureDetector(
            onTap: () => _copyToClipboard(context, value, label),
            child: Icon(
              LucideIcons.copy,
              size: 16,
              color: context.appColors.textMuted.withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}
