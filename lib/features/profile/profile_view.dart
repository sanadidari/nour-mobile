import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/features/auth/auth_wrapper.dart';
import 'package:nour/features/profile/history_view.dart';
import 'package:nour/services/evidence_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nour/features/auth/pro_card_scanner_view.dart';
import 'package:nour/core/theme_provider.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _evidenceService = EvidenceService();
  Map<String, int> _stats = {'photos': 0, 'dossiers': 0, 'today': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _evidenceService.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    final createdAt = user?.createdAt != null
        ? DateFormat('yyyy/MM/dd').format(DateTime.parse(user!.createdAt))
        : '---';

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: context.appColors.accentGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildProfileHeader(user, createdAt),
              if (user?.email == 'nchatwiti@gmail.com') ...[
                const SizedBox(height: 24),
                _buildAdminSection(context),
              ],
              if (user?.userMetadata?['pro_card_verified'] == false) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _openProScanner(context),
                  child: _buildVerificationWarning(),
                ),
              ],
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildMenuSection(context, authService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'لوحة التحكم (الرئيس)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'يمكنك إدارة الصور المتحركة والمقالات الإخبارية من هنا.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Open Admin Panel
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الوصول إلى لوحة التحكم...'))
              );
            },
            icon: const Icon(LucideIcons.layoutGrid, size: 18),
            label: const Text('إدارة المحتوى'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? user, String createdAt) {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${user?.userMetadata?['first_name'] ?? ''} ${user?.userMetadata?['last_name'] ?? ''}'.trim().isNotEmpty 
              ? '${user?.userMetadata?['first_name']} ${user?.userMetadata?['last_name']}'
              : (user?.email ?? 'المفوض القضائي'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: context.appColors.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appColors.accentGold.withOpacity(0.2)),
          ),
          child: Text(
            'عضو منذ $createdAt',
            style: TextStyle(fontSize: 12, color: context.appColors.accentGold, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.error.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: context.appColors.error.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(LucideIcons.alertTriangle, color: context.appColors.error, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لم يتم التحقق من البطاقة المهنية',
                      style: TextStyle(color: context.appColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'يرجى مسح بطاقتك لتفعيل حسابك بالكامل وإزالة هذه العلامة.',
                      style: TextStyle(color: context.appColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronLeft, size: 16, color: context.appColors.error.withOpacity(0.5)),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openProScanner(BuildContext context) async {
    final result = await Navigator.of(context).push<ProCardData>(
      MaterialPageRoute(builder: (context) => const ProCardScannerView()),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'pro_card_verified': true,
              'pro_number': result.proNumber,
              'first_name': result.fullName.split(' ').first,
              'last_name': result.fullName.split(' ').skip(1).join(' '),
              'tribunal': result.tribunal,
              'city': result.city,
              'dob': result.dateOfBirth,
            },
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم التحقق من البطاقة بنجاح')));
          _loadStats();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatsRow() {
    if (_isLoading) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    return Row(
      children: [
        _buildStatItem('${_stats['photos'] ?? 0}', 'صورة', LucideIcons.camera, context.appColors.info),
        const SizedBox(width: 10),
        _buildStatItem('${_stats['dossiers'] ?? 0}', 'ملف', LucideIcons.folderOpen, context.appColors.success),
        const SizedBox(width: 10),
        _buildStatItem('${_stats['today'] ?? 0}', 'اليوم', LucideIcons.calendarCheck, context.appColors.accentGold),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: context.appColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, dynamic authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4, bottom: 8),
          child: Text('الإعدادات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
        ),
        _buildMenuItem(icon: LucideIcons.history, title: 'سجل العمليات', subtitle: 'جميع المهام والصور المرسلة', color: context.appColors.info, onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryView()));
        }),
        _buildThemeSwitch(context),
        _buildMenuItem(icon: LucideIcons.settings, title: 'إعدادات الحساب', subtitle: 'البريد الإلكتروني وبيانات الحساب', color: context.appColors.warning, onTap: () => _showAccountSettings(context)),
        _buildMenuItem(icon: LucideIcons.shieldCheck, title: 'الأمان وكلمة المرور', subtitle: 'تغيير كلمة المرور', color: context.appColors.success, onTap: () => _showChangePassword(context)),
        _buildMenuItem(icon: LucideIcons.helpCircle, title: 'المساعدة والدعم', subtitle: 'الأسئلة الشائعة والتواصل', color: Color(0xFFA78BFA), onTap: () => _showHelp(context)),
        const SizedBox(height: 24),

        // Logout
        GestureDetector(
          onTap: () => _confirmLogout(context, authService),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appColors.error.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.logOut, color: context.appColors.error, size: 20),
                SizedBox(width: 10),
                Text('تسجيل الخروج', style: TextStyle(color: context.appColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('نور للعدالة - الإصدار 1.0.0', style: TextStyle(fontSize: 11, color: context.appColors.textMuted)),
        ),
      ],
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final color = const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isDark ? LucideIcons.moon : LucideIcons.sun, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوضع المظلم', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.appColors.textPrimary)),
                Text('تفعيل أو إلغاء تفعيل الوضع المظلم', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
            },
            activeColor: context.appColors.accentGold,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.appColors.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: context.appColors.textMuted)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronLeft, size: 16, color: context.appColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, dynamic authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [Icon(LucideIcons.logOut, color: context.appColors.error), SizedBox(width: 8), Text('تسجيل الخروج')]),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.appColors.error),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAccountSettings(BuildContext context) {
    final user = ref.read(authServiceProvider).currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.appColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('معلومات الحساب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
            const SizedBox(height: 20),
            _buildInfoRow(LucideIcons.mail, 'البريد الإلكتروني', user?.email ?? '---'),
            const SizedBox(height: 12),
            _buildInfoRow(LucideIcons.hash, 'معرف المستخدم', user?.id.substring(0, 8) ?? '---'),
            const SizedBox(height: 12),
            _buildInfoRow(LucideIcons.calendar, 'تاريخ التسجيل', user?.createdAt != null ? DateFormat('yyyy/MM/dd').format(DateTime.parse(user!.createdAt)) : '---'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.appColors.accentGold),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: context.appColors.textMuted)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.appColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  void _showChangePassword(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', prefixIcon: Icon(LucideIcons.lock)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')));
                return;
              }
              try {
                await Supabase.instance.client.auth.updateUser(UserAttributes(password: passwordController.text));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم تغيير كلمة المرور بنجاح')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.appColors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.appColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('المساعدة والدعم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
            const SizedBox(height: 20),
            _buildHelpItem(LucideIcons.camera, 'التقاط الصور', 'اضغط على زر الكاميرا لالتقاط صور الإثبات مع GPS تلقائي'),
            _buildHelpItem(LucideIcons.send, 'إرسال الأدلة', 'بعد التقاط الصور، اضغط "مراجعة" ثم "تأكيد وإرسال"'),
            _buildHelpItem(LucideIcons.history, 'سجل العمليات', 'يمكنك مراجعة جميع العمليات المرسلة من الملف الشخصي'),
            _buildHelpItem(LucideIcons.mapPin, 'الموقع GPS', 'تأكد من تفعيل خدمة الموقع للحصول على إحداثيات دقيقة'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.appColors.accentGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.appColors.textPrimary)),
                Text(desc, style: TextStyle(fontSize: 12, color: context.appColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
