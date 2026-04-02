import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/huissiers_data.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryView extends StatefulWidget {
  const DirectoryView({super.key});

  @override
  State<DirectoryView> createState() => _DirectoryViewState();
}

class _DirectoryViewState extends State<DirectoryView> {
  final _searchController = TextEditingController();
  List<Huissier> _filteredHuissiers = huissiersData;
  String? _selectedCourt;

  final List<String> _courts = [
    'الكل',
    'ابتدائية تطوان',
    'ابتدائية شفشاون',
    'ابتدائية وزان',
  ];

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHuissiers = huissiersData.where((h) {
        final matchesSearch = h.name.contains(query) || (h.frenchName?.toLowerCase().contains(query) ?? false) || h.phone.contains(query);
        final matchesCourt = _selectedCourt == null || _selectedCourt == 'الكل' || h.court == _selectedCourt;
        return matchesSearch && matchesCourt;
      }).toList();
    });
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildSmartPhoto(String originalPath) {
    // RESOLVEUR INTELLIGENT d'IMAGES (jfif, png, jpg, jpeg)
    final String basePath = originalPath.split('.').first;
    
    return Image.asset(
      originalPath,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          '$basePath.jfif',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              '$basePath.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  '$basePath.jpg',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل المفوضين القضائيين'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.appColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filter(),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الهاتف...',
                      prefixIcon: Icon(LucideIcons.search, size: 18, color: context.appColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _courts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final court = _courts[index];
                      final isSelected = (_selectedCourt ?? 'الكل') == court;
                      return ChoiceChip(
                        label: Text(court, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : context.appColors.textSecondary)),
                        selected: isSelected,
                        selectedColor: context.appColors.accentGold,
                        backgroundColor: context.appColors.bgSurface,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCourt = court;
                            _filter();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _filteredHuissiers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.userX, size: 48, color: context.appColors.textMuted),
                  const SizedBox(height: 16),
                  Text('لا توجد نتائج', style: TextStyle(color: context.appColors.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHuissiers.length,
              itemBuilder: (context, index) {
                final h = _filteredHuissiers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: h.photoUrl != null && h.photoUrl!.isNotEmpty
                        ? ClipOval(
                            child: _buildSmartPhoto(h.photoUrl!),
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                            ),
                          ),
                    title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.building, size: 14, color: context.appColors.textMuted),
                            const SizedBox(width: 4),
                            Text(h.court, style: TextStyle(fontSize: 12, color: context.appColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(LucideIcons.phone, size: 14, color: context.appColors.accentGold),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                h.phone,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appColors.accentGold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.phoneCall, color: Colors.green, size: 20),
                      ),
                      onPressed: () => _makeCall(h.phone),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
