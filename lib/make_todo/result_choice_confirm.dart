import 'package:flutter/material.dart';
import '../home/home.dart';
import '../home/restaurant_detail_screen.dart';
import '../services/history_service.dart';
import '../services/api_service.dart';
import 'dart:async';

/// 선택된 장소만 모아 보여주는 화면
class SelectedPlacesScreen extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> selected;

  const SelectedPlacesScreen({Key? key, required this.selected}) : super(key: key);

  @override
  State<SelectedPlacesScreen> createState() => _SelectedPlacesScreenState();
}

class _SelectedPlacesScreenState extends State<SelectedPlacesScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final categories = widget.selected.keys.toList();
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
            itemCount: categories.fold<int>(0, (sum, c) => sum + widget.selected[c]!.length + 1),
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
            final items = widget.selected[category]!;
            if (i < running + items.length) {
              final place = items[i - running];
              // 서버 응답 형식에 따라 여러 필드명 시도
              final placeName = place['title'] as String? ?? 
                               place['name'] as String? ?? 
                               '알 수 없음';
              final placeAddress = place['address'] as String? ??
                                 place['detail_address'] as String? ??
                                 '주소 정보 없음';
              return _SummaryCard(
                title: placeName,
                address: placeAddress,
                category: category,
                place: place,  // 전체 place 데이터 전달
              );
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
              onPressed: _isSaving ? null : _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A21),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '저장하기',
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

  /// 확인하기 버튼 클릭 시 서버에 저장
  Future<void> _handleConfirm() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 서버에 "그냥" 탭에 저장
      await HistoryService.saveOtherHistory(widget.selected);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정표 히스토리 "그냥" 탭에 저장되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      print('❌ 히스토리 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
  final String address;
  final String category;
  final Map<String, dynamic> place;

  const _SummaryCard({
    required this.title,
    required this.address,
    required this.category,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // recommendation_screen.dart와 동일한 패턴으로 Restaurant 객체 생성
        final placeId = place['id'] as String? ?? '';
        final placeCategory = place['category'] as String? ?? 
                             place['sub_category'] as String? ?? 
                             category;
        final placeImage = place['image_url'] as String? ?? 
                          place['image'] as String? ?? 
                          '';
        
        final restaurant = Restaurant(
          id: placeId,
          name: title,
          detailAddress: address,
          subCategory: placeCategory,
          image: placeImage.isNotEmpty ? placeImage : null,
          rating: null,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        );
      },
      child: Container(
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
                address,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


