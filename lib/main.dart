import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nour/core/constants.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/core/theme_provider.dart';
import 'package:nour/features/splash/splash_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return GestureDetector(
      onTap: () {
         FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        title: 'نور للعدالة',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkPremiumTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          );
        },
        home: const SplashView(),
      ),
    );
  }
}

