import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nour/features/auth/login_view.dart';
import 'package:nour/features/main_screen.dart';
import 'package:nour/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return StreamBuilder<AuthState>(
      stream: authService.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return MainScreen();
        }

        return const LoginView();
      },
    );
  }
}
