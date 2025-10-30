import 'package:flutter/material.dart';
import '../home/home.dart';

/// 선택된 장소만 모아 보여주는 화면
class SelectedPlacesScreen extends StatelessWidget {
  final Map<String, List<String>> selected;

  const SelectedPlacesScreen({Key? key, required this.selected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = selected.keys.toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '선택한 장소',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.fold<int>(0, (sum, c) => sum + selected[c]!.length + 1),
        itemBuilder: (context, i) {
          // 섹션 헤더 및 카드 렌더링
          int running = 0;
          for (final category in categories) {
            if (i == running) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(_iconForCategory(category), color: const Color(0xFFFF7A21)),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7A21),
                      ),
                    ),
                  ],
                ),
              );
            }
            running += 1; // 헤더 하나 반영
            final items = selected[category]!;
            if (i < running + items.length) {
              final place = items[i - running];
              return _SummaryCard(title: place, category: category);
            }
            running += items.length;
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('일정표 히스토리에서 확인하실 수 있습니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A21),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '확인하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '콘텐츠':
        return Icons.movie_filter;
      default:
        return Icons.place;
    }
  }
}

/// 요약 카드 (홈 카드 스타일, 버튼 없음)
class _SummaryCard extends StatelessWidget {
  final String title;
  final String category;

  const _SummaryCard({required this.title, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _address(),
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _address() {
    final addresses = [
      '서울시 강남구 테헤란로 123',
      '서울시 마포구 홍대입구역 45',
      '서울시 용산구 이태원로 78',
      '서울시 종로구 인사동길 12',
      '서울시 송파구 올림픽로 234',
      '서울시 서초구 강남대로 567',
      '서울시 영등포구 여의도동 89',
    ];
    return addresses[DateTime.now().microsecond % addresses.length];
  }
}


