import 'package:flutter/material.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/news_data.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NewsDetailView extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailView({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.bgSurface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'news_${article.id}',
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            backgroundColor: const Color(0xFFC5942D), // GOLD
            foregroundColor: Colors.white,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${article.date.day}/${article.date.month}/${article.date.year}",
                        style: TextStyle(
                          fontSize: 14,
                          color: context.appColors.textMuted,
                        ),
                      ),
                      const CircleAvatar(
                        backgroundColor: Color(0xFF1E3A8A),
                        radius: 12,
                        child: Icon(LucideIcons.newspaper, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const Divider(height: 40),
                  Text(
                    article.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
