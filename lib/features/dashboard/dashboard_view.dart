import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/core/utils.dart';
import 'package:nour/features/profile/profile_view.dart';
import 'package:nour/features/auth/auth_wrapper.dart';
import 'package:nour/features/profile/operation_detail_view.dart';
import 'package:nour/features/missions/select_intervention_view.dart';
import 'package:nour/services/evidence_service.dart';
import 'package:nour/services/sync_service.dart';
import 'package:nour/widgets/filter_panel.dart';
import 'package:nour/widgets/dossier_card.dart';
import 'package:nour/widgets/shared_widgets.dart';
import 'package:nour/features/profile/directory_view.dart';
import 'package:nour/features/profile/maktaba_view.dart';
import 'package:nour/features/profile/links_view.dart';
import 'package:nour/features/profile/council_view.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final _evidenceService = EvidenceService();
  Map<String, int> _stats = {'photos': 0, 'dossiers': 0, 'today': 0};
  List<Map<String, dynamic>> _allHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  bool _showFilters = false;
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
    _loadData();
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

  void _applyFilters() {
    setState(() {
      _filteredHistory = applyDossierFilters(
        source: _allHistory,
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
      _isManualFilterCity = false;
      _isManualFilterZone = false;
      _applyFilters();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _evidenceService.getStats();
    final history = await _evidenceService.getHistory();
    if (mounted) {
      setState(() {
        _stats = stats;
        _allHistory = history;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(LucideIcons.power, color: context.appColors.error),
          const SizedBox(width: 8),
          const Text('تسجيل الخروج')
        ]),
        content: const Text('هل أنت متأكد من تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.appColors.error),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => _confirmLogout(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.appColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: context.appColors.error.withOpacity(0.3)),
            ),
            child: Icon(LucideIcons.power, color: context.appColors.error, size: 16),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.cover)),
            const SizedBox(width: 8),
            const Text('نور للعدالة'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: IconButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileView()));
                _loadData();
              },
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.appColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(LucideIcons.user, size: 18),
                    if (Supabase.instance.client.auth.currentUser?.userMetadata?['pro_card_verified'] == false)
                      Positioned(
                        right: -2, top: -2,
                        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: context.appColors.accentGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 12),
              SyncStatusWidget(
                pendingCount: syncState.pendingCount,
                isSyncing: syncState.isSyncing,
                currentDossier: syncState.currentDossier,
                lastError: syncState.lastError,
                onRetry: () => ref.read(syncServiceProvider.notifier).syncNow(),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildNewMissionCard(context),
              const SizedBox(height: 24),
              _buildRecentHeader(),
              const SizedBox(height: 12),
              _buildRecentList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SelectInterventionView()));
          _loadData();
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    if (hour < 12) {
      greeting = 'صباح الخير';
      icon = LucideIcons.sun;
    } else if (hour < 18) {
      greeting = 'مساء الخير';
      icon = LucideIcons.cloudSun;
    } else {
      greeting = 'مساء الخير';
      icon = LucideIcons.moon;
    }

    final fullName = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'أستاذ';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: context.appColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.appColors.textSecondary)),
                const SizedBox(height: 4),
                Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.appColors.accentGold.withOpacity(0.2), context.appColors.accentGold.withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.appColors.accentGold, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    return Row(
      children: [
        _buildStatCard('ملفات اليوم', '${_stats['today'] ?? 0}', LucideIcons.calendarCheck, context.appColors.accentGold),
        const SizedBox(width: 12),
        _buildStatCard('عدد الملفات', '${_stats['dossiers'] ?? 0}', LucideIcons.folder, context.appColors.primaryNavy),
        const SizedBox(width: 12),
        _buildStatCard('إجمالي الصور', '${_stats['photos'] ?? 0}', LucideIcons.camera, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appColors.border, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, color: context.appColors.textSecondary, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceHub(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('خدمات المساعدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            _resourceItem(context, 'المكتبة', LucideIcons.bookOpen, context.appColors.accentGold, const MaktabaView()),
            const SizedBox(width: 8),
            _resourceItem(context, 'الدليل', LucideIcons.search, context.appColors.primaryNavy, const DirectoryView()),
            const SizedBox(width: 8),
            _resourceItem(context, 'المجلس', LucideIcons.landmark, Colors.redAccent, const CouncilView()),
            const SizedBox(width: 8),
            _resourceItem(context, 'روابط', LucideIcons.globe, Colors.teal, const QuickLinksView()),
          ],
        ),
      ],
    );
  }

  Widget _resourceItem(BuildContext context, String label, IconData icon, Color color, Widget view) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => view)),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.appColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewMissionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [context.appColors.accentGold, const Color(0xFFC5942D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: context.appColors.accentGold.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SelectInterventionView()));
            _loadData();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('بدء مهمة جديدة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('التقاط صور بصمة ميدانية', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('آخر العمليات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
            Row(
              children: [
                if (_allHistory.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showFilters ? context.appColors.accentGold.withOpacity(0.1) : context.appColors.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _showFilters ? context.appColors.accentGold : context.appColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.filter, size: 14, color: _showFilters ? context.appColors.accentGold : context.appColors.textMuted),
                          const SizedBox(width: 6),
                          Text('تصفية', style: TextStyle(fontSize: 12, color: _showFilters ? context.appColors.accentGold : context.appColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (_allHistory.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileView())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.appColors.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.appColors.border),
                      ),
                      child: Text('عرض الكل', style: TextStyle(fontSize: 12, color: context.appColors.accentGold)),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_showFilters) ...[
          const SizedBox(height: 12),
          FilterPanel(
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
        ],
      ],
    );
  }

  Widget _buildRecentList() {
    if (_isLoading) {
      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_filteredHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.appColors.bgSurface, borderRadius: BorderRadius.circular(16)),
              child: Icon(LucideIcons.inbox, size: 40, color: context.appColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text('لا توجد عمليات بعد', style: TextStyle(fontSize: 16, color: context.appColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('ابدأ أول مهمة بالضغط على الزر أعلاه', style: TextStyle(fontSize: 13, color: context.appColors.textMuted)),
          ],
        ),
      );
    }

    final grouped = <String, Map<String, dynamic>>{};
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (var item in _filteredHistory) {
      final dossier = item['dossier_id'] ?? extractDossierFromNotes(item['notes'] ?? '');
      groupedItems.putIfAbsent(dossier, () => []);
      groupedItems[dossier]!.add(item);
      if (!grouped.containsKey(dossier)) {
        grouped[dossier] = {...item, 'photo_count': 1};
      } else {
        grouped[dossier]!['photo_count'] = (grouped[dossier]!['photo_count'] as int) + 1;
      }
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grouped.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final dossierId = grouped.keys.elementAt(index);
        final item = grouped[dossierId]!;
        final interventionType = item['intervention_type'] ?? extractTypeFromNotes(item['notes'] ?? '');
        final capturedAt = DateTime.tryParse(item['captured_at'] ?? '')?.toLocal();

        return DossierCard(
          dossierId: dossierId,
          interventionType: interventionType,
          photoCount: item['photo_count'] ?? 1,
          capturedAt: capturedAt,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OperationDetailView(
                  dossierId: dossierId,
                  interventionType: interventionType,
                  items: groupedItems[dossierId] ?? [item],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
