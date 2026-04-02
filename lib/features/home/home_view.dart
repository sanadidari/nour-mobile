import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:nour/core/theme.dart';
import 'package:nour/models/news_data.dart';
import 'package:nour/features/home/news_detail_view.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF0F172A) 
          : const Color(0xFFFFFBEB),
      appBar: AppBar(
        toolbarHeight: 85,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المجلس الجهوي للمفوضين القضائيين',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                  Text(
                    'لدى محكمة الاستئناف بتطوان',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFC5942D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FULL WIDTH SLIDER WITH DOT INDICATORS
            Stack(
              children: [
                CarouselSlider(
                  carouselController: _controller,
                  options: CarouselOptions(
                    height: 250.0,
                    autoPlay: true,
                    viewportFraction: 1.0, // Full width
                    autoPlayCurve: Curves.easeInOutCubic,
                    enableInfiniteScroll: true,
                    autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _current = index;
                      });
                    },
                  ),
                  items: carouselImages.map((path) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          child: _buildImage(path, height: 250),
                        );
                      },
                    );
                  }).toList(),
                ),
                // Indicators inside the slider
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: carouselImages.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _controller.animateToPage(entry.key),
                        child: Container(
                          width: _current == entry.key ? 20.0 : 7.0,
                          height: 7.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white.withOpacity(
                              _current == entry.key ? 0.9 : 0.4,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 24, 16),
              child: Text(
                'آخر الأخبار والأنشطة',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFFC5942D),
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // BLOG LIST
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sampleNews.length,
              itemBuilder: (context, index) {
                final news = sampleNews[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 20, offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => NewsDetailView(article: news)),
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Hero(
                            tag: 'news_${news.id}',
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: _buildImage(news.imageUrl, height: 200),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 19, 
                                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                                    height: 1.3,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  news.excerpt,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15, 
                                    color: isDark ? Colors.grey[300] : Colors.black87, 
                                    height: 1.6,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC5942D).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.chevronLeft, size: 14, color: Color(0xFFC5942D)),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'إقرأ المزيد',
                                            style: TextStyle(
                                              color: Color(0xFFC5942D), 
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "${news.date.day}/${news.date.month}/${news.date.year}", 
                                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path, {required double height}) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      path,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return Container(
          height: height,
          color: Colors.grey[200],
          child: Center(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/logo.png', width: 60, height: 60),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
  }
}
