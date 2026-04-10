import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/core/utils.dart';
import 'package:nour/widgets/shared_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Écran de détail d'une opération (consultation)
class OperationDetailView extends StatefulWidget {
  final String dossierId;
  final String interventionType;
  final List<Map<String, dynamic>> items;

  const OperationDetailView({
    super.key,
    required this.dossierId,
    required this.interventionType,
    required this.items,
  });

  @override
  State<OperationDetailView> createState() => _OperationDetailViewState();
}

class _OperationDetailViewState extends State<OperationDetailView> {
  final _supabase = Supabase.instance.client;
  final Map<String, String> _imageUrls = {};
  bool _loadingUrls = true;

  @override
  void initState() {
    super.initState();
    _loadImageUrls();
  }

  Future<void> _loadImageUrls() async {
    for (var item in widget.items) {
      final path = item['image_path'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          final url = await _supabase.storage
              .from('evidence')
              .createSignedUrl(path, 3600);
          _imageUrls[path] = url;
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _loadingUrls = false);
  }

  Future<void> _shareNetworkImage(String? imagePath, String title) async {
    if (imagePath == null) return;
    try {
      final bytes = await _supabase.storage
          .from('evidence')
          .download(imagePath);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: title);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في المشاركة: $e')));
    }
  }

  void _openImageViewer(String? url, int index) {
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _FullScreenImageView(imageUrl: url, title: 'صورة ${index + 1}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = widget.items.first;
    final capturedAt = DateTime.tryParse(
      firstItem['captured_at'] ?? '',
    )?.toLocal();
    final dateStr = capturedAt != null
        ? DateFormat('yyyy/MM/dd - HH:mm').format(capturedAt)
        : '---';

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل العملية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      context.appColors.primaryNavy,
                      context.appColors.primaryNavy.withOpacity(0.85),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            getIconForType(widget.interventionType),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.interventionType.isNotEmpty
                                ? widget.interventionType
                                : 'عملية',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildHeaderInfo(
                      LucideIcons.hash,
                      'رقم الملف',
                      widget.dossierId,
                    ),
                    const SizedBox(height: 8),
                    _buildHeaderInfo(LucideIcons.clock, 'التاريخ', dateStr),
                    const SizedBox(height: 8),
                    _buildHeaderInfo(
                      LucideIcons.camera,
                      'عدد الصور',
                      '${widget.items.length}',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkCircle,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'تم الإرسال بنجاح',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes
            if (_hasNotes())
              SectionCard(
                icon: LucideIcons.fileText,
                title: 'الملاحظات',
                child: Text(
                  firstItem['notes'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),

            if (_hasNotes()) const SizedBox(height: 16),

            // Photos
            SectionCard(
              icon: LucideIcons.image,
              title: 'الصور (${widget.items.length})',
              child: _loadingUrls
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Column(
                      children: widget.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final imagePath = item['image_path'] as String?;
                        final imageUrl = imagePath != null
                            ? _imageUrls[imagePath]
                            : null;
                        final capturedAt = DateTime.tryParse(
                          item['captured_at'] ?? '',
                        )?.toLocal();
                        final dateStr = capturedAt != null
                            ? DateFormat(
                                'yyyy/MM/dd - HH:mm:ss',
                              ).format(capturedAt)
                            : '---';
                        final lat = item['latitude'];
                        final lon = item['longitude'];
                        final hasGps =
                            lat != null &&
                            lon != null &&
                            (lat != 0 || lon != 0);
                        final gpsStr = hasGps
                            ? '${(lat as num).toStringAsFixed(6)}, ${(lon as num).toStringAsFixed(6)}'
                            : extractGpsFromNotes(item['notes'] ?? '');

                        return Container(
                          margin: EdgeInsets.only(
                            bottom: index < widget.items.length - 1 ? 16 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.appColors.border),
                            color: context.appColors.bgSurface,
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _openImageViewer(imageUrl, index),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: imageUrl != null
                                      ? Stack(
                                          children: [
                                            Image.network(
                                              imageUrl,
                                              width: double.infinity,
                                              height: 220,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return Container(
                                                  height: 220,
                                                  color: context
                                                      .appColors
                                                      .bgSurface,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          progress.expectedTotalBytes !=
                                                              null
                                                          ? progress.cumulativeBytesLoaded /
                                                                progress
                                                                    .expectedTotalBytes!
                                                          : null,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 220,
                                                      color: context
                                                          .appColors
                                                          .bgSurface,
                                                      child: Center(
                                                        child: Icon(
                                                          LucideIcons.imageOff,
                                                          size: 48,
                                                          color: context
                                                              .appColors
                                                              .textMuted,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      LucideIcons.zoomIn,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'اضغط للتكبير',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          height: 220,
                                          color: context.appColors.bgSurface,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  LucideIcons.imageOff,
                                                  size: 48,
                                                  color: context
                                                      .appColors
                                                      .textMuted,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'لا يمكن تحميل الصورة',
                                                  style: TextStyle(
                                                    color: context
                                                        .appColors
                                                        .textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                context.appColors.primaryNavy,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'صورة ${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.share2,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _shareNetworkImage(
                                            imagePath,
                                            'صورة من ملف ${widget.dossierId} - ${widget.interventionType}',
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          LucideIcons.checkCircle,
                                          size: 14,
                                          color: context.appColors.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'مُرسلة',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.appColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    MetadataRow(
                                      icon: LucideIcons.clock,
                                      label: 'التوقيت',
                                      value: dateStr,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(height: 6),
                                    MetadataRow(
                                      icon: LucideIcons.mapPin,
                                      label: 'الإحداثيات',
                                      value: gpsStr.isNotEmpty
                                          ? gpsStr
                                          : 'GPS غير متوفر',
                                      color: gpsStr.isNotEmpty
                                          ? Colors.green
                                          : Colors.orange,
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
          ],
        ),
      ),
    );
  }

  bool _hasNotes() {
    final notes = widget.items.first['notes'] as String?;
    return notes != null && notes.isNotEmpty;
  }

  Widget _buildHeaderInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        if (value.isNotEmpty && value != '---') ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => copyToClipboard(context, value, label),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                LucideIcons.copy,
                size: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Écran plein écran pour consulter une image
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImageView({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.imageOff, size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'لا يمكن تحميل الصورة',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
