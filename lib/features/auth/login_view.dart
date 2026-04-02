import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/features/auth/auth_wrapper.dart';
import 'package:nour/features/auth/register_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(_emailController.text, _passwordController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo avec glow
              ClipOval(
                child: Image.asset('assets/images/logo.png', width: 100, height: 100, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                'نور للعدالة',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.accentGold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'فضاء المفوض القضائي',
                style: TextStyle(fontSize: 14, color: context.appColors.textMuted),
              ),

              const SizedBox(height: 40),

              // Email
              TextField(
                controller: _emailController,
                style: TextStyle(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(LucideIcons.mail, size: 18, color: context.appColors.accentGold.withOpacity(0.7)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password
              TextField(
                controller: _passwordController,
                style: TextStyle(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(LucideIcons.lock, size: 18, color: context.appColors.accentGold.withOpacity(0.7)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                      color: context.appColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),

              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: context.appColors.primaryNavy),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logIn, size: 18),
                            SizedBox(width: 8),
                            Text('تسجيل الدخول', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Register link
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterView()));
                },
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.cairo(fontSize: 14, color: context.appColors.textMuted),
                    children: [
                      const TextSpan(text: 'ليس لديك حساب؟ '),
                      TextSpan(
                        text: 'إنشاء حساب',
                        style: GoogleFonts.cairo(
                          color: context.appColors.accentGold,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: context.appColors.accentGold.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
