import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/library_data.dart';

class MaktabaView extends StatefulWidget {
  const MaktabaView({super.key});

  @override
  State<MaktabaView> createState() => _MaktabaViewState();
}

class _MaktabaViewState extends State<MaktabaView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<LawArticle> _filteredArticles = law8103Data;
  List<GlossaryTerm> _filteredTerms = glossaryData;
  List<DecreeArticle> _filteredDecree = decreeData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _filter(String query) {
    setState(() {
      if (_tabController.index == 0) {
        _filteredArticles = law8103Data.where((a) => a.title.contains(query) || a.content.contains(query)).toList();
      } else if (_tabController.index == 1) {
        _filteredDecree = decreeData.where((d) => d.content.contains(query)).toList();
      } else {
        _filteredTerms = glossaryData.where((t) => t.termAr.contains(query) || t.termFr.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة القانونية'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: context.appColors.accentGold,
                labelColor: context.appColors.accentGold,
                unselectedLabelColor: context.appColors.textMuted,
                tabs: const [
                  Tab(text: 'قانون 81.03'),
                  Tab(text: 'المرسوم'),
                  Tab(text: 'المصطلحات'),
                ],
                onTap: (index) {
                  _searchController.clear();
                  _filter('');
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.appColors.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filter,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'بحث سريع...',
                      prefixIcon: Icon(LucideIcons.search, size: 16, color: context.appColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Law Tab
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredArticles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final art = _filteredArticles[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.appColors.accentGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('المادة ${art.id}', style: TextStyle(color: context.appColors.accentGold, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(art.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    Text(art.content, style: const TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              );
            },
          ),
          // Decree Tab
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredDecree.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final art = _filteredDecree[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('المادة ${art.id} من المرسوم', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                    Text(art.content, style: const TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              );
            },
          ),
          // Glossary Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredTerms.length,
            itemBuilder: (context, index) {
              final term = _filteredTerms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(term.termAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(term.termFr, style: TextStyle(color: context.appColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic)),
                  trailing: Icon(LucideIcons.bookOpen, size: 18, color: context.appColors.accentGold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
