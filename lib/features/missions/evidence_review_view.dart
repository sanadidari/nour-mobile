import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/core/utils.dart';
import 'package:nour/services/evidence_service.dart';
import 'package:nour/services/sync_service.dart';
import 'package:nour/features/missions/success_summary_view.dart';
import 'package:nour/widgets/shared_widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

/// Écran de résumé avant l'envoi final
class EvidenceReviewView extends ConsumerStatefulWidget {
  final String dossierId;
  final String interventionType;
  final List<LocalEvidence> queue;
  final Map<String, String> formFields;

  const EvidenceReviewView({
    super.key,
    required this.dossierId,
    required this.interventionType,
    required this.queue,
    required this.formFields,
  });

  @override
  ConsumerState<EvidenceReviewView> createState() => _EvidenceReviewViewState();
}

class _EvidenceReviewViewState extends ConsumerState<EvidenceReviewView> {
  final _evidenceService = EvidenceService();
  bool _isSending = false;
  final Map<int, String> _addresses = {};

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      await setLocaleIdentifier('ar_MA');
    } catch (_) {}

    for (int i = 0; i < widget.queue.length; i++) {
      final pos = widget.queue[i].position;
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          String zone = (p.subLocality?.isNotEmpty == true) ? p.subLocality! : (p.thoroughfare?.isNotEmpty == true ? p.thoroughfare! : p.subAdministrativeArea ?? '');
          final list = [zone, p.locality].where((e) => e != null && e.isNotEmpty).toList();
          if (mounted) setState(() => _addresses[i] = list.join('، '));
        }
      } catch (_) {}
    }
  }

  Future<void> _shareLocalImage(LocalEvidence ev, String title) async {
    try {
      final File processed = await _evidenceService.processImage(
        File(ev.localPath),
        dossierId: widget.dossierId,
        interventionType: widget.interventionType,
        position: ev.position,
        timestamp: ev.timestamp,
      );
      await Share.shareXFiles([XFile(processed.path)], text: title);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في المشاركة: $e')));
    }
  }

  Future<void> _confirmAndSend() async {
    setState(() => _isSending = true);
    try {
      await _evidenceService.stageMissionForUpload(
        dossierId: widget.dossierId,
        interventionType: widget.interventionType,
        queue: widget.queue,
        formFields: widget.formFields,
      );

      ref.read(syncServiceProvider.notifier).refreshPendingCount();
      ref.read(syncServiceProvider.notifier).syncNow();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SuccessSummaryView(
              dossierId: widget.dossierId,
              interventionType: widget.interventionType,
              photoCount: widget.queue.length,
              formFields: widget.formFields,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('خطأ في الحفظ: $e'), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showFullImage(LocalEvidence ev, String address) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildWatermarkedImage(File(ev.localPath), ev, address, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatermarkedImage(File file, LocalEvidence ev, String address, {double? height, BoxFit fit = BoxFit.cover}) {
    final dateStr = formatDateArabic(ev.timestamp);
    String locStr = '${ev.position.latitude.toStringAsFixed(5)}, ${ev.position.longitude.toStringAsFixed(5)}';
    if (address.isNotEmpty) locStr = '$address | $locStr';

    return Stack(
      children: [
        SizedBox(width: double.infinity, height: height, child: Image.file(file, fit: fit)),
        Positioned(
          top: 10, left: 10,
          child: Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
            child: ClipOval(child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.cover)),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dateStr, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(locStr, style: GoogleFonts.cairo(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص قبل الإرسال'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight),
          onPressed: _isSending ? null : () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type d'intervention
                SectionCard(
                  icon: LucideIcons.fileText,
                  title: 'نوع التدخل',
                  child: Text(widget.interventionType, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.primaryNavy)),
                ),
                const SizedBox(height: 16),

                // Numéro de dossier
                SectionCard(
                  icon: LucideIcons.hash,
                  title: 'رقم الملف',
                  child: Text(widget.dossierId, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appColors.accentGold, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 16),

                // Champs du formulaire
                if (widget.formFields.isNotEmpty)
                  SectionCard(
                    icon: LucideIcons.clipboardList,
                    title: 'تفاصيل المعاينة',
                    child: Column(
                      children: widget.formFields.entries.map((entry) {
                        if (entry.value.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.chevronLeft, size: 16, color: context.appColors.accentGold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.key, style: TextStyle(fontSize: 12, color: context.appColors.textMuted, fontWeight: FontWeight.w500)),
                                    Text(entry.value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Photos
                SectionCard(
                  icon: LucideIcons.camera,
                  title: 'الصور الملتقطة (${widget.queue.length})',
                  child: Column(
                    children: widget.queue.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ev = entry.value;
                      final file = File(ev.localPath);
                      final dateStr = DateFormat('yyyy/MM/dd - HH:mm:ss').format(ev.timestamp);
                      final lat = ev.position.latitude.toStringAsFixed(6);
                      final lon = ev.position.longitude.toStringAsFixed(6);
                      final hasGps = ev.position.latitude != 0 || ev.position.longitude != 0;

                      return Container(
                        margin: EdgeInsets.only(bottom: index < widget.queue.length - 1 ? 16 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.appColors.border),
                          color: context.appColors.bgSurface,
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showFullImage(ev, _addresses[index] ?? ''),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: file.existsSync()
                                    ? _buildWatermarkedImage(file, ev, _addresses[index] ?? '', height: 200)
                                    : Container(
                                        height: 200,
                                        color: context.appColors.bgSurface,
                                        child: Center(child: Icon(LucideIcons.imageOff, size: 48, color: context.appColors.textMuted)),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: context.appColors.primaryNavy, borderRadius: BorderRadius.circular(20)),
                                        child: Text('صورة ${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(LucideIcons.share2, size: 18, color: Colors.blue),
                                        onPressed: () => _shareLocalImage(ev, 'صورة من ملف ${widget.dossierId} - ${widget.interventionType}'),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.zoomIn, size: 16, color: context.appColors.textMuted),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  MetadataRow(icon: LucideIcons.clock, label: 'التوقيت', value: dateStr, color: Colors.blue),
                                  const SizedBox(height: 6),
                                  MetadataRow(
                                    icon: LucideIcons.mapPin,
                                    label: 'الإحداثيات',
                                    value: hasGps ? '$lat, $lon' : 'GPS غير متوفر',
                                    color: hasGps ? Colors.green : Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Overlay pendant l'envoi
          if (_isSending)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(40),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text('جاري الإرسال...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('الرجاء عدم إغلاق التطبيق', style: TextStyle(color: context.appColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Bouton de confirmation avec dark mode fix
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSending ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.textSecondary,
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(color: context.appColors.border),
                ),
                icon: const Icon(LucideIcons.arrowRight),
                label: const Text('تعديل'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _confirmAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  elevation: 3,
                ),
                icon: const Icon(LucideIcons.send),
                label: const Text('تأكيد وإرسال', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
