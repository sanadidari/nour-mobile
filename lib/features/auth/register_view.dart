import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/features/auth/auth_wrapper.dart';
import 'package:nour/features/auth/pro_card_scanner_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';



class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  // === Controllers ===
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _proNumberController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _tribunalController = TextEditingController();
  final _countryController = TextEditingController(text: 'المغرب');

  final List<String> _moroccanCities = [
    'الدار البيضاء', 'الرباط', 'فاس', 'مراكش', 'طنجة', 'أغادير', 'مكناس', 'وجدة',
    'القنيطرة', 'تطوان', 'تمارة', 'آسفي', 'سلا', 'المحمدية', 'خريبكة', 'الجديدة',
    'بني ملال', 'الناظور', 'تارة', 'القصر الكبير', 'تارودانت', 'الخميسات', 'سطات',
    'بركان', 'الفقيه بن صالح', 'تازة', 'سيدي قاسم', 'خنيفرة', 'الصويرة', 'الداخلة',
    'العيون', 'كلميم', 'الرشيدية', 'تيزنيت', 'ورزازات', 'صفرو', 'الفنيدق', 'سيدي بنور'
  ];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _currentStep = 0; // 0 = scan Card, 1 = infos, 2 = email/password

  ProCardData? _proData;
  File? _proImage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _proNumberController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _tribunalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _openProScanner() async {
    final result = await Navigator.of(context).push<ProCardData>(
      MaterialPageRoute(builder: (context) => const ProCardScannerView()),
    );

    if (result != null && mounted) {
      setState(() {
        _proData = result;
        _proImage = result.photo;

        // Remplir les champs avec les données extraites
        if (result.proNumber.isNotEmpty) {
          _proNumberController.text = result.proNumber;
        } else if (result.cinNumber.isNotEmpty) {
          _proNumberController.text = result.cinNumber;
        }
        
        if (result.fullName.isNotEmpty) {
          final parts = result.fullName.split(' ');
          if (parts.length >= 2) {
            _firstNameController.text = parts.first;
            _lastNameController.text = parts.sublist(1).join(' ');
          } else {
            _firstNameController.text = result.fullName;
          }
        }
        
        if (result.dateOfBirth.isNotEmpty) _dobController.text = result.dateOfBirth;
        if (result.city.isNotEmpty) _cityController.text = result.city;
        if (result.country.isNotEmpty) _countryController.text = result.country;
        if (result.tribunal.isNotEmpty) _tribunalController.text = result.tribunal;

        _currentStep = 2;
      });
    }
  }

  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;

    // Resize to 800px width (sufficient for OCR/Verification)
    img.Image resized = img.copyResize(image, width: 800);
    
    // Compress to JPG at 40% quality (Very light)
    final compressedBytes = img.encodeJpg(resized, quality: 40);
    
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/pro_card_comp_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await File(path).writeAsBytes(compressedBytes);
  }

  Future<void> _signUp() async {
    // Validation complète
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _showError('الرجاء إدخال بريد إلكتروني صحيح');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمات المرور لا تطابق');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      String? proCardUrl;

      // 1. Inscription
      await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'pro_number': _proNumberController.text.trim(),
          'city': _cityController.text.trim(),
          'dob': _dobController.text.trim(),
        },
      );

      final newUserId = Supabase.instance.client.auth.currentUser?.id;

      // 2. Upload de la carte Pro compressée si elle existe
      if (_proImage != null && newUserId != null) {
        final compressed = await _compressImage(_proImage!);
        final fileName = '$newUserId/card_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('pro_cards').upload(fileName, compressed);
        proCardUrl = fileName;
      }
      
      // 3. Créer le profil final
      if (newUserId != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': newUserId,
          'email': _emailController.text.trim(),
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'pro_number': _proNumberController.text.trim(),
          'tribunal': _tribunalController.text.trim(),
          'city': _cityController.text.trim(),
          'dob': _dobController.text.trim(),
          'pro_card_url': proCardUrl,
          'is_verified': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم إنشاء الحساب بنجاح')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل مفوض قضائي جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === Stepper indicator ===
            _buildStepIndicator(),
            const SizedBox(height: 24),

            // === Step content ===
            if (_currentStep == 0) _buildCredentialsStep(),
            if (_currentStep == 1) _buildScanStep(),
            if (_currentStep == 2) _buildInfoStep(),
          ],
        ),
      ),
    );
  }

  // === ÉTAPE 0 : Email & Mot de passe ===
  Widget _buildCredentialsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إعداد الحساب الجديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
        const SizedBox(height: 20),

        // Email
        TextField(
          controller: _emailController,
          style: TextStyle(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني المهني',
            prefixIcon: Icon(LucideIcons.mail, size: 18, color: context.appColors.accentGold),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Password
        TextField(
          controller: _passwordController,
          style: TextStyle(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            prefixIcon: Icon(LucideIcons.lock, size: 18, color: context.appColors.accentGold),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: context.appColors.textMuted),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
        ),
        const SizedBox(height: 16),

        // Confirm password
        TextField(
          controller: _confirmPasswordController,
          style: TextStyle(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'تأكيد كلمة المرور',
            prefixIcon: Icon(LucideIcons.shieldCheck, size: 18, color: context.appColors.accentGold),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: context.appColors.textMuted),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          obscureText: _obscureConfirm,
        ),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
                _showError('الرجاء إدخال بريد إلكتروني صحيح');
                return;
              }
              if (_passwordController.text.length < 6) {
                _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
                return;
              }
              if (_passwordController.text != _confirmPasswordController.text) {
                _showError('كلمات المرور لا تطابق');
                return;
              }
              setState(() => _currentStep = 1);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('المتابعة للخطوة التالية', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Icon(LucideIcons.arrowLeft, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // === ÉTAPE 1 : Scanner Carte Pro ===
  Widget _buildScanStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.accentGold.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.appColors.accentGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.scanLine, size: 56, color: context.appColors.accentGold),
              ),
              const SizedBox(height: 24),
              Text(
                'مسح البطاقة المهنية',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),
              Text(
                'قم بمسح الوجه الأمامي لبطاقتك المهنية للمفوضين القضائيين لملء بياناتك تلقائياً وبدء عملية التسجيل',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: context.appColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _openProScanner,
                  icon: const Icon(LucideIcons.camera, size: 20),
                  label: const Text('بدء المسح المباشر', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _currentStep = 2),
                child: Text(
                  'التسجيل يدوياً بدون مسح',
                  style: TextStyle(color: context.appColors.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === ÉTAPE 2 : Infos personnelles ===
  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Pro Card capturée
        if (_proImage != null) ...[
          Text('بيانات البطاقة الملتقطة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appColors.success.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.file(_proImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.appColors.success.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.checkCircle, size: 16, color: context.appColors.success),
                          const SizedBox(width: 8),
                          Text('تم تأكيد المسح', style: TextStyle(fontSize: 12, color: context.appColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _openProScanner,
                        child: Text('إعادة المسح', style: TextStyle(color: context.appColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Formulaire
        Text('مراجعة بيانات المفوض', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
        const SizedBox(height: 16),

        _buildField(_proNumberController, 'رقم القيد / رقم البطاقة', LucideIcons.hash, TextInputType.text),
        _buildField(_firstNameController, 'الاسم الشخصي', LucideIcons.user, TextInputType.name),
        _buildField(_lastNameController, 'الاسم العائلي', LucideIcons.user, TextInputType.name),
        _buildField(_tribunalController, 'المحكمة المعين بها', LucideIcons.building2, TextInputType.text),
        
        // Champ Date de naissance simple (Saisie manuelle)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildField(_dobController, 'تاريخ الازدياد (YYYY/MM/DD)', LucideIcons.calendar, TextInputType.datetime),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Expanded(
                 child: DropdownButtonFormField<String>(
                   value: _moroccanCities.contains(_cityController.text) ? _cityController.text : null,
                   decoration: InputDecoration(
                     labelText: 'المدينة',
                     labelStyle: GoogleFonts.cairo(),
                     prefixIcon: Icon(LucideIcons.map, size: 18, color: _cityController.text.isNotEmpty ? context.appColors.accentGold : context.appColors.textMuted),
                     isDense: true,
                     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                   ),
                   isExpanded: true,
                   icon: Icon(LucideIcons.chevronDown, size: 18, color: context.appColors.accentGold),
                   style: GoogleFonts.cairo(color: context.appColors.textPrimary, fontSize: 13),
                   items: _moroccanCities.map((city) {
                     return DropdownMenuItem(
                       value: city,
                       child: Text(
                         city, 
                         style: GoogleFonts.cairo(color: context.appColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)
                       ),
                     );
                   }).toList(),
                   onChanged: (val) {
                     setState(() {
                       _cityController.text = val ?? '';
                     });
                   },
                   hint: Text('اختر المدينة', style: GoogleFonts.cairo(fontSize: 12)),
                   dropdownColor: context.appColors.bgCard,
                   // Style for the selected value displayed in the field
                   selectedItemBuilder: (context) {
                     return _moroccanCities.map((city) {
                       return Text(
                         city,
                         style: GoogleFonts.cairo(color: context.appColors.textPrimary, fontSize: 13),
                       );
                     }).toList();
                   },
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(child: _buildField(_countryController, 'البلد', LucideIcons.globe, TextInputType.text)),
             ],
          ),
        ),
        _buildField(_addressController, 'العنوان المهني', LucideIcons.mapPin, TextInputType.streetAddress),

        const SizedBox(height: 32),

        // Bouton créer final
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (_proNumberController.text.isEmpty || 
                  _lastNameController.text.isEmpty || 
                  _firstNameController.text.isEmpty ||
                  _tribunalController.text.isEmpty ||
                  _dobController.text.isEmpty ||
                  _cityController.text.isEmpty ||
                  _addressController.text.isEmpty) {
                _showError('الرجاء ملء جميع الحقول المطلوبة للإتمام');
                return;
              }
              _signUp();
            },
            child: _isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: context.appColors.primaryNavy))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('إتمام فتح الحساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(width: 12),
                      Icon(LucideIcons.checkCircle, size: 24),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // === Helpers ===
  Widget _buildField(TextEditingController controller, String label, IconData icon, TextInputType type) {
    final hasValue = controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: context.appColors.textPrimary),
        keyboardType: type,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: hasValue ? context.appColors.accentGold : context.appColors.textMuted),
          suffixIcon: hasValue
              ? Icon(LucideIcons.checkCircle, size: 16, color: context.appColors.success)
              : null,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.appColors.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStep(0, 'الحساب', LucideIcons.lock),
          _buildStepLine(0),
          _buildStep(1, 'التوثيق', LucideIcons.camera),
          _buildStepLine(1),
          _buildStep(2, 'البيانات', LucideIcons.user),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    final color = isCompleted ? context.appColors.success : isActive ? context.appColors.accentGold : context.appColors.textMuted;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? context.appColors.success.withOpacity(0.15)
                : isActive
                    ? context.appColors.accentGold.withOpacity(0.15)
                    : context.appColors.bgSurface,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isCompleted ? LucideIcons.check : icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isCompleted = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted ? context.appColors.success : context.appColors.border,
      ),
    );
  }
}
