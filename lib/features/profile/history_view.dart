import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/core/utils.dart';
import 'package:nour/features/profile/operation_detail_view.dart';
import 'package:nour/services/evidence_service.dart';
import 'package:nour/widgets/filter_panel.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final _evidenceService = EvidenceService();
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  bool _showFilters = true;
  bool _isManualFilterCity = false;
  bool _isManualFilterZone = false;

  final _dossierFilter = TextEditingController();
  final _typeFilter = TextEditingController();
  final _demandeurFilter = TextEditingController();
  final _demandeFilter = TextEditingController();
  final _regionFilter = TextEditingController();
  final _cityFilter = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _dossierFilter.addListener(_applyFilters);
    _typeFilter.addListener(_applyFilters);
    _demandeurFilter.addListener(_applyFilters);
    _demandeFilter.addListener(_applyFilters);
    _regionFilter.addListener(_applyFilters);
    _cityFilter.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _dossierFilter.dispose();
    _typeFilter.dispose();
    _demandeurFilter.dispose();
    _demandeFilter.dispose();
    _regionFilter.dispose();
    _cityFilter.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await _evidenceService.getHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredHistory = applyDossierFilters(
        source: _history,
        dossier: _dossierFilter.text.trim(),
        type: _typeFilter.text.trim(),
        demandeur: _demandeurFilter.text.trim(),
        demande: _demandeFilter.text.trim(),
        ville: _regionFilter.text.trim(),
        zone: _cityFilter.text.trim(),
      );
    });
  }

  void _clearFilters() {
    _dossierFilter.clear();
    _typeFilter.clear();
    _demandeurFilter.clear();
    _demandeFilter.clear();
    _regionFilter.clear();
    _cityFilter.clear();
    setState(() {
      _showFilters = true;
      _isManualFilterCity = false;
      _isManualFilterZone = false;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? LucideIcons.filterX : LucideIcons.search),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilterPanel(
                dossierFilter: _dossierFilter,
                typeFilter: _typeFilter,
                demandeurFilter: _demandeurFilter,
                demandeFilter: _demandeFilter,
                regionFilter: _regionFilter,
                cityFilter: _cityFilter,
                isManualFilterCity: _isManualFilterCity,
                isManualFilterZone: _isManualFilterZone,
                onClearFilters: _clearFilters,
                onApplyFilters: _applyFilters,
                onManualModeChanged: (city, zone) => setState(() {
                  _isManualFilterCity = city;
                  _isManualFilterZone = zone;
                }),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: _buildHistoryList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 64, color: context.appColors.textMuted),
          const SizedBox(height: 16),
          Text('لا توجد عمليات بعد', style: TextStyle(fontSize: 18, color: context.appColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('ستظهر هنا العمليات بعد إتمام أول مهمة', style: TextStyle(fontSize: 14, color: context.appColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    // Regrouper par dossier
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var item in _filteredHistory) {
      final dossier = item['dossier_id'] ?? extractDossierFromNotes(item['notes'] ?? '');
      grouped.putIfAbsent(dossier, () => []);
      grouped[dossier]!.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dossierId = grouped.keys.elementAt(index);
        final items = grouped[dossierId]!;
        final firstItem = items.first;
        final interventionType = firstItem['intervention_type'] ?? extractTypeFromNotes(firstItem['notes'] ?? '');
        final capturedAt = DateTime.tryParse(firstItem['captured_at'] ?? '')?.toLocal();
        final dateStr = capturedAt != null ? DateFormat('yyyy/MM/dd - HH:mm').format(capturedAt) : '---';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OperationDetailView(
                  dossierId: dossierId,
                  interventionType: interventionType,
                  items: items,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.appColors.primaryNavy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(getIconForType(interventionType), color: context.appColors.primaryNavy, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              interventionType.isNotEmpty ? interventionType : 'عملية',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ملف: $dossierId',
                              style: TextStyle(fontSize: 13, color: context.appColors.accentGold, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.appColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.camera, size: 14, color: context.appColors.success),
                            const SizedBox(width: 4),
                            Text('${items.length}', style: TextStyle(color: context.appColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 14, color: context.appColors.textMuted),
                      const SizedBox(width: 6),
                      Text(dateStr, style: TextStyle(fontSize: 12, color: context.appColors.textSecondary)),
                      const Spacer(),
                      if (hasValidGps(firstItem))
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 14, color: context.appColors.success),
                            const SizedBox(width: 4),
                            Text('GPS ✓', style: TextStyle(fontSize: 12, color: context.appColors.success)),
                          ],
                        ),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.chevronLeft, size: 16, color: context.appColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
