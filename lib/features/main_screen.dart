import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/features/home/home_view.dart';
import 'package:nour/features/profile/council_view.dart';
import 'package:nour/features/profile/directory_view.dart';
import 'package:nour/features/profile/maktaba_view.dart';
import 'package:nour/features/profile/links_view.dart';
import 'package:nour/features/dashboard/dashboard_view.dart';
import 'package:nour/features/profile/profile_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    const CouncilTabsView(),
    const LibraryTabsView(),
    const BailiffSpaceView(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 75, // Standard docked height
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFC5942D),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.black, // Sleek Black
              unselectedItemColor: Colors.black.withOpacity(
                0.45,
              ), // Subtle Dark Gray
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              unselectedLabelStyle: TextStyle(
                color: Colors.black.withOpacity(0.45),
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.home),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.users),
                  label: 'المجلس',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.bookOpen),
                  label: 'المكتبة',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.briefcase),
                  label: 'فضاء المفوض',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CouncilTabsView extends StatelessWidget {
  const CouncilTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('المجلس والدليل'),
          backgroundColor: const Color(0xFFC5942D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المكتب المسير'),
              Tab(text: 'دليل المفوضين'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: const TabBarView(children: [CouncilView(), DirectoryView()]),
      ),
    );
  }
}

class LibraryTabsView extends StatelessWidget {
  const LibraryTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('المكتبة القانونية'),
          backgroundColor: const Color(0xFFC5942D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'النصوص القانونية'),
              Tab(text: 'روابط مهنية'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: const TabBarView(children: [MaktabaView(), QuickLinksView()]),
      ),
    );
  }
}

class BailiffSpaceView extends StatelessWidget {
  const BailiffSpaceView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('فضاء المفوض القضائي'),
          backgroundColor: const Color(0xFFC5942D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ملفاتي'),
              Tab(text: 'حسابي'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: const TabBarView(children: [DashboardView(), ProfileView()]),
      ),
    );
  }
}
