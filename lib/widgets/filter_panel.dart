import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/intervention_type.dart';

/// Panneau de filtrage réutilisable (Dashboard + History).
class FilterPanel extends StatelessWidget {
  final TextEditingController dossierFilter;
  final TextEditingController typeFilter;
  final TextEditingController demandeurFilter;
  final TextEditingController demandeFilter;
  final TextEditingController regionFilter;
  final TextEditingController cityFilter;
  final bool isManualFilterCity;
  final bool isManualFilterZone;
  final VoidCallback onClearFilters;
  final VoidCallback onApplyFilters;
  final void Function(bool isManualCity, bool isManualZone) onManualModeChanged;

  const FilterPanel({
    super.key,
    required this.dossierFilter,
    required this.typeFilter,
    required this.demandeurFilter,
    required this.demandeFilter,
    required this.regionFilter,
    required this.cityFilter,
    required this.isManualFilterCity,
    required this.isManualFilterZone,
    required this.onClearFilters,
    required this.onApplyFilters,
    required this.onManualModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterInput(context, dossierFilter, 'رقم الملف', LucideIcons.hash)),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterInput(context, typeFilter, 'نوع الإجراء', LucideIcons.fileText)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildFilterInput(context, demandeurFilter, 'المدعي', LucideIcons.user)),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterInput(context, demandeFilter, 'المدعى عليه', LucideIcons.userX)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildFilterInput(context, regionFilter, 'المدينة', LucideIcons.mapPin)),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterInput(context, cityFilter, 'المنطقة / الحي', LucideIcons.map)),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(LucideIcons.rotateCcw, size: 14),
            label: const Text(
              'إعادة تعيين الفلاتر',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD4A537)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterInput(BuildContext context, TextEditingController controller, String hint, IconData icon) {
    if (hint == 'نوع الإجراء') {
      return _buildTypeDropdown(context, controller, hint, icon);
    }

    if (hint == 'المدينة' && !isManualFilterCity) {
      final items = northCityData.keys.toList();
      return _buildDropdownFilter(context, controller, hint, icon, [...items, 'أخرى (إدخال يدوي)'], (val) {
        if (val == 'أخرى (إدخال يدوي)') {
          onManualModeChanged(true, isManualFilterZone);
          controller.clear();
        } else {
          controller.text = val ?? '';
        }
        onApplyFilters();
      });
    }

    if (hint == 'المنطقة / الحي' && !isManualFilterZone && !isManualFilterCity) {
      final selectedVille = regionFilter.text;
      final items = (selectedVille.isNotEmpty) ? (northCityData[selectedVille] ?? []) : northCityData.values.expand((e) => e).toList();
      return _buildDropdownFilter(context, controller, hint, icon, [...items, 'أخرى (إدخال يدوي)'], (val) {
        if (val == 'أخرى (إدخال يدوي)') {
          onManualModeChanged(isManualFilterCity, true);
          controller.clear();
        } else {
          controller.text = val ?? '';
        }
        onApplyFilters();
      });
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.border),
      ),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 13),
        onChanged: (_) => onApplyFilters(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 14, color: context.appColors.accentGold),
          suffixIcon: (hint == 'المدينة' && isManualFilterCity) || (hint == 'المنطقة / الحي' && (isManualFilterZone || isManualFilterCity))
            ? IconButton(
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
                onPressed: () {
                  if (hint == 'المدينة') {
                    onManualModeChanged(false, false);
                  } else {
                    onManualModeChanged(isManualFilterCity, false);
                  }
                  controller.clear();
                  onApplyFilters();
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(BuildContext context, TextEditingController controller, String hint, IconData icon, List<String> items, Function(String?) onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.appColors.accentGold),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: items.contains(controller.text) ? (controller.text.isEmpty ? null : controller.text) : null,
              hint: Text(hint, style: const TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis)),
              underline: const SizedBox(),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('الكل', style: TextStyle(fontSize: 13, color: Colors.grey))),
                ...items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown(BuildContext context, TextEditingController controller, String hint, IconData icon) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.appColors.accentGold),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: (['التبيليغ', 'التنفيذ'].contains(controller.text)) ? controller.text : null,
              hint: Text(hint, style: const TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis)),
              underline: const SizedBox(),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('الكل', style: TextStyle(fontSize: 13, color: Colors.grey))),
                ...[
                  {'val': 'التبيليغ', 'lab': 'تبليغ'},
                  {'val': 'التنفيذ', 'lab': 'تنفيذ'},
                ].map((item) {
                  return DropdownMenuItem<String>(
                    value: item['val'],
                    child: Text(item['lab']!, style: const TextStyle(fontSize: 13)),
                  );
                }),
              ],
              onChanged: (val) {
                controller.text = val ?? '';
                onApplyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }
}
