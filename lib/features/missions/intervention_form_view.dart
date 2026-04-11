import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/intervention_type.dart';
import 'package:nour/services/evidence_service.dart';
import 'package:nour/features/missions/evidence_review_view.dart';
import 'package:google_fonts/google_fonts.dart';

class InterventionFormView extends StatefulWidget {
  final GharadOption option;
  const InterventionFormView({super.key, required this.option});

  @override
  State<InterventionFormView> createState() => _InterventionFormViewState();
}

class _InterventionFormViewState extends State<InterventionFormView>
    with WidgetsBindingObserver {
  final _dossierController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  final _evidenceService = EvidenceService();
  bool _isCapturing = false;
  List<LocalEvidence> _localQueue = [];
  bool _isManualCity = false;
  bool _isManualZone = false;
  final int _maxPhotos = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (var field in widget.option.fields) {
      _controllers[field.label] = TextEditingController();
    }
    // Add location controllers
    _controllers['المدينة'] = TextEditingController();
    _controllers['المنطقة / الحي'] = TextEditingController();

    _initializeForm();
  }

  Future<void> _initializeForm() async {
    await _loadDraft();
    await _checkForLostCapture();
    await _cleanupInvalidPhotos();
  }

  Future<void> _loadDraft() async {
    final draft = await _evidenceService.loadQueuePersistence();
    if (draft.isNotEmpty) {
      final metadata = await _evidenceService.loadFormMetadata();
      setState(() {
        _localQueue = draft;
        if (metadata['dossierId'] != null &&
            metadata['dossierId']!.isNotEmpty) {
          _dossierController.text = metadata['dossierId']!;
        }
      });
    }
  }

  Future<void> _checkForLostCapture() async {
    try {
      final recovered = await _evidenceService.retrieveLostCapture();
      if (recovered != null && mounted) {
        setState(() => _localQueue.add(recovered));
        await _saveCurrentState();
      }
    } catch (_) {}
  }

  Future<void> _cleanupInvalidPhotos() async {
    final validQueue = <LocalEvidence>[];
    for (final ev in _localQueue) {
      if (await File(ev.localPath).exists()) {
        validQueue.add(ev);
      }
    }
    if (validQueue.length != _localQueue.length && mounted) {
      setState(() => _localQueue = validQueue);
      await _saveCurrentState();
    }
  }

  Future<void> _saveCurrentState() async {
    await _evidenceService.saveQueuePersistence(
      _localQueue,
      dossierId: _dossierController.text,
      interventionType: widget.option.title,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveCurrentState();
    }
    if (state == AppLifecycleState.resumed && !_isCapturing) {
      _checkForLostCapture();
      _cleanupInvalidPhotos();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dossierController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _captureInstant() async {
    if (_localQueue.length >= _maxPhotos) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الحد الأقصى هو 5 صور')));
      return;
    }
    await _saveCurrentState();
    setState(() => _isCapturing = true);
    try {
      final evidence = await _evidenceService.captureLocal();
      if (evidence != null && mounted) {
        setState(() => _localQueue.add(evidence));
        await _saveCurrentState();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ERR: $e')));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showImagePreview(LocalEvidence ev) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(ev.localPath), fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReviewScreen() async {
    if (_dossierController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال رقم الملف')));
      return;
    }
    for (var field in widget.option.fields) {
      if (!field.optional) {
        final val = _controllers[field.label]?.text.trim() ?? '';
        if (val.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('الرجاء إدخال ${field.label}')),
          );
          return;
        }
      }
    }
    if (_localQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء التقاط صورة واحدة على الأقل')),
      );
      return;
    }
    final Map<String, String> formFields = {};
    for (var entry in _controllers.entries) {
      if (entry.value.text.isNotEmpty) formFields[entry.key] = entry.value.text;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EvidenceReviewView(
          dossierId: _dossierController.text,
          interventionType: widget.option.title,
          queue: _localQueue,
          formFields: formFields,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNotification = widget.option.title.contains('التبليغ');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.option.title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION: موضوع التبليغ OU معلومات الملف
              FormSectionHeader(
                icon: LucideIcons.fileText,
                title: isNotification ? 'موضوع التبليغ' : 'معلومات الملف',
              ),
              AppTextField(
                label: isNotification ? 'المرجع / الرقم' : 'رقم الملف / المرجع',
                controller: _dossierController,
                isMandatory: true,
                icon: LucideIcons.hash,
              ),

              ...widget.option.fields.map((field) {
                // Section Header for Parties
                if (field.label.contains('طالب') ||
                    field.label.contains('الطالب')) {
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      FormSectionHeader(
                        icon: LucideIcons.users,
                        title: isNotification ? 'أطراف التبليغ' : 'أطراف الإجراء',
                      ),
                      _buildField(field),
                    ],
                  );
                }

                // Section Header for Outcome/Notes
                if (field.label == 'مآل التبليغ' ||
                    field.label == 'ملخص للإجراء' ||
                    field.label == 'ملاحظات') {
                  return Column(
                    children: [
                      if (field.label != 'ملاحظات') ...[
                        const SizedBox(height: 16),
                        FormSectionHeader(
                          icon: LucideIcons.clipboardCheck,
                          title: isNotification ? 'مآل التبليغ' : 'ملخص للإجراء',
                        ),
                      ],
                      if (field.label == 'ملاحظات') ...[
                        const SizedBox(height: 16),
                        const FormSectionHeader(
                          icon: LucideIcons.mapPin,
                          title: 'الموقع الجغرافي',
                        ),
                        _buildLocationFields(),
                        const SizedBox(height: 16),
                        const FormSectionHeader(
                          icon: LucideIcons.clipboardList,
                          title: 'ملاحظات إضافية',
                        ),
                      ],
                      _buildField(field),
                    ],
                  );
                }

                return _buildField(field);
              }),

              if (_localQueue.isNotEmpty) ...[
                const SizedBox(height: 32),
                FormSectionHeader(
                  icon: LucideIcons.camera,
                  title: 'الصور الملتقطة',
                  trailing: Text('${_localQueue.length} / $_maxPhotos'),
                ),
                const SizedBox(height: 12),
                InterventionPhotoGallery(
                  queue: _localQueue,
                  onRemove: (index) => setState(() {
                    _localQueue.removeAt(index);
                    _saveCurrentState();
                  }),
                  onPreview: _showImagePreview,
                ),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _captureInstant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(LucideIcons.camera),
                  label: Text(_isCapturing ? 'جاري...' : 'صورة'),
                ),
              ),
              if (_localQueue.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCapturing ? null : _openReviewScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(LucideIcons.send),
                    label: const Text('مراجعة'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(GharadField field) {
    // Dropdown for NOTIFICATION TYPE
    if (field.label == 'نوع التبليغ') {
      const types = [
        'تبليغ استدعاء',
        'تبليغ إنذار',
        'تبليغ إشعار',
        'تبليغ إعذار',
        'تبليغ أمر',
        'تبليغ حكم',
        'تبليغ قرار',
        'تبليغ مقرر',
      ];
      return AppDropdownField(
        label: 'نوع التبليغ *',
        value: _controllers[field.label]?.text.isNotEmpty == true
            ? _controllers[field.label]?.text
            : null,
        items: types,
        onChanged: (val) =>
            setState(() => _controllers[field.label]?.text = val ?? ''),
      );
    }

    // Dropdown for COURT (Tribunal)
    if (field.label == 'المحكمة') {
      const courts = [
        'محكمة الاستئناف بتطوان',
        'المحكمة الابتدائية بتطوان',
        'المحكمة الابتدائية بشفشاون',
        'المحكمة الابتدائية بوزان',
        'محكمة الاستئناف بطنجة',
        'المحكمة الابتدائية بطنجة',
        'المحكمة الابتدائية بالعرائش',
        'المحكمة الابتدائية بالقصر الكبير',
        'المحكمة الابتدائية بأصيلة',
        'محكمة الاستئناف بالحسيمة',
        'المحكمة الابتدائية بالحسيمة',
        'المحكمة الابتدائية بتارجيست',
        'المحكمة التجارية بطنجة',
        'المحكمة الإدارية بطنجة',
      ];
      return AppDropdownField(
        label: 'المحكمة *',
        value: _controllers[field.label]?.text.isNotEmpty == true
            ? _controllers[field.label]?.text
            : null,
        items: courts,
        onChanged: (val) =>
            setState(() => _controllers[field.label]?.text = val ?? ''),
      );
    }

    IconData? icon;
    if (field.label.contains('طالب')) icon = LucideIcons.userCheck;
    if (field.label.contains('إليه') || field.label.contains('المطلوب'))
      icon = LucideIcons.userX;
    if (field.label.contains('نوع')) icon = LucideIcons.scroll;
    if (field.label.contains('مآل') || field.label.contains('ملخص'))
      icon = LucideIcons.alignRight;
    if (field.label.contains('المحكمة')) icon = LucideIcons.landmark;

    return AppTextField(
      label: field.label,
      controller: _controllers[field.label]!,
      multiline: field.multiline,
      isMandatory: !field.optional,
      icon: icon,
    );
  }

  Widget _buildLocationFields() {
    final villeCtrl = _controllers['المدينة']!;
    final zoneCtrl = _controllers['المنطقة / الحي']!;
    final List<String> villes = [...northCityData.keys, 'أخرى (إدخال يدوي)'];

    return Column(
      children: [
        if (!_isManualCity) ...[
          AppDropdownField(
            label: 'المدينة *',
            value:
                northCityData.containsKey(villeCtrl.text) ? villeCtrl.text : null,
            items: villes,
            onChanged: (val) {
              setState(() {
                if (val == 'أخرى (إدخال يدوي)') {
                  _isManualCity = true;
                  villeCtrl.clear();
                  _isManualZone = true;
                  zoneCtrl.clear();
                } else {
                  villeCtrl.text = val ?? '';
                  _isManualZone = false;
                  zoneCtrl.text = '';
                }
              });
            },
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'اسم المدينة يدويًا *',
                  controller: villeCtrl,
                  isMandatory: true,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw),
                onPressed: () => setState(() {
                  _isManualCity = false;
                  _isManualZone = false;
                  villeCtrl.clear();
                  zoneCtrl.clear();
                }),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (!_isManualCity && villeCtrl.text.isNotEmpty) ...[
          if (!_isManualZone) ...[
            AppDropdownField(
              label: 'المنطقة / الحي *',
              value: (northCityData[villeCtrl.text]?.contains(zoneCtrl.text) ??
                      false)
                  ? zoneCtrl.text
                  : null,
              items: [
                ...(northCityData[villeCtrl.text] ?? []),
                'أخرى (إدخال يدوي)'
              ],
              onChanged: (val) {
                setState(() {
                  if (val == 'أخرى (إدخال يدوي)') {
                    _isManualZone = true;
                    zoneCtrl.clear();
                  } else {
                    zoneCtrl.text = val ?? '';
                  }
                });
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'المنطقة / الحي يدويًا *',
                    controller: zoneCtrl,
                    isMandatory: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.rotateCcw),
                  onPressed: () => setState(() {
                    _isManualZone = false;
                    zoneCtrl.clear();
                  }),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const FormSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC5942D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFC5942D)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (trailing != null) ...[const Spacer(), trailing],
        ],
      ),
    );
  }
}

class InterventionPhotoGallery extends StatelessWidget {
  final List<LocalEvidence> queue;
  final Function(int) onRemove;
  final Function(LocalEvidence) onPreview;

  const InterventionPhotoGallery({
    super.key,
    required this.queue,
    required this.onRemove,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final ev = queue[index];
        return Stack(
          children: [
            GestureDetector(
              onTap: () => onPreview(ev),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(ev.localPath),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AppDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          style: GoogleFonts.cairo(color: Colors.black, fontSize: 14),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          hint: const Text('-- اختر --'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool multiline;
  final bool isMandatory;
  final IconData? icon;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.multiline = false,
    this.isMandatory = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cleanLabel = label.replaceAll('*', '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
              ],
              Text(
                cleanLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              if (isMandatory)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: multiline ? 3 : 1,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'أدخل ${cleanLabel}...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
