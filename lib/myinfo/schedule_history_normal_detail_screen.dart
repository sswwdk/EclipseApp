import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/token_manager.dart';
import '../services/api_service.dart';
import '../home/restaurant_detail_screen.dart';

/// "그냥" 탭 히스토리 상세 화면 (선택한 장소 목록 표시)
class ScheduleHistoryNormalDetailScreen extends StatefulWidget {
  final String historyId;

  const ScheduleHistoryNormalDetailScreen({
    Key? key,
    required this.historyId,
  }) : super(key: key);

  @override
  State<ScheduleHistoryNormalDetailScreen> createState() => _ScheduleHistoryNormalDetailScreenState();
}

class _ScheduleHistoryNormalDetailScreenState extends State<ScheduleHistoryNormalDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, List<Map<String, dynamic>>> _selectedPlaces = {};
  String? _dateText;

  @override
  void initState() {
    super.initState();
    _loadHistoryDetail();
  }

  /// 히스토리 상세 정보 로드
  Future<void> _loadHistoryDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = TokenManager.userId;
      if (userId == null) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      // 히스토리 상세 정보 가져오기
      final detailResponse = await HistoryService.getHistoryDetail(userId, widget.historyId);
      
      if (!mounted) return;

      print('🔍 [Normal Detail] 서버 응답: $detailResponse');

      // 상세 정보 파싱
      final parsedData = _parseHistoryDetail(detailResponse);
      
      if (!mounted) return;
      
      setState(() {
        _selectedPlaces = parsedData['places'] as Map<String, List<Map<String, dynamic>>>;
        _dateText = parsedData['date'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('❌ [Normal Detail] 로드 실패: $e');
      setState(() {
        _errorMessage = '히스토리를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 히스토리 상세 데이터 파싱
  Map<String, dynamic> _parseHistoryDetail(Map<String, dynamic> detailResponse) {
    final data = detailResponse['data'] ?? detailResponse;
    
    // 날짜 정보 추출
    String? dateText;
    if (data['visited_at'] != null) {
      final visitedAt = data['visited_at'].toString();
      dateText = _formatDate(visitedAt);
    } else if (data['date'] != null) {
      dateText = _formatDate(data['date'].toString());
    }

    // 장소 정보 추출
    final Map<String, List<Map<String, dynamic>>> places = {};
    
    // categories 형식으로 저장된 경우
    if (data['categories'] != null && data['categories'] is List) {
      final categories = data['categories'] as List<dynamic>;
      
      for (final category in categories) {
        final categoryMap = category as Map<String, dynamic>;
        final categoryName = categoryMap['category_name'] as String? ?? '기타';
        final placeName = categoryMap['category_name'] as String? ?? '';
        final placeId = categoryMap['category_id'] as String? ?? '';
        
        if (placeName.isEmpty) continue;

        if (!places.containsKey(categoryName)) {
          places[categoryName] = [];
        }

        places[categoryName]!.add({
          'id': placeId,
          'title': placeName,
          'name': placeName,
          'address': '주소 정보 없음',
          'category': categoryName,
        });
      }
    }
    
    // places 형식으로 저장된 경우 (saveOtherHistory)
    else if (data['places'] != null && data['places'] is List) {
      final placesList = data['places'] as List<dynamic>;
      
      for (final place in placesList) {
        final placeMap = place as Map<String, dynamic>;
        final category = placeMap['category'] as String? ?? '기타';
        
        if (!places.containsKey(category)) {
          places[category] = [];
        }
        
        places[category]!.add({
          'id': placeMap['place_id'] as String? ?? placeMap['id'] as String? ?? '',
          'title': placeMap['name'] as String? ?? '알 수 없음',
          'name': placeMap['name'] as String? ?? '알 수 없음',
          'address': placeMap['address'] as String? ?? '주소 정보 없음',
          'category': category,
          'image_url': placeMap['image_url'] as String? ?? placeMap['image'] as String?,
        });
      }
    }

    print('🔍 [Normal Detail] 파싱된 장소: $places');

    return {
      'places': places,
      'date': dateText,
    };
  }

  /// 날짜 형식 변환
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      String datePart = dateStr;
      if (dateStr.contains('T')) {
        datePart = dateStr.split('T')[0];
      } else if (dateStr.contains(' ')) {
        datePart = dateStr.split(' ')[0];
      }
      
      if (datePart.contains('-')) {
        return datePart.replaceAll('-', '.');
      }
      return datePart;
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _dateText ?? '선택한 장소',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistoryDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : _selectedPlaces.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          '저장된 장소가 없습니다.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : _buildPlacesList(),
    );
  }

  Widget _buildPlacesList() {
    final categories = _selectedPlaces.keys.toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.fold<int>(0, (sum, c) => sum + _selectedPlaces[c]!.length + 1),
      itemBuilder: (context, i) {
        int running = 0;
        for (final category in categories) {
          // 카테고리 헤더
          if (i == running) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(_iconForCategory(category), color: const Color(0xFFFF8126)),
                  const SizedBox(width: 6),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8126),
                    ),
                  ),
                ],
              ),
            );
          }
          running += 1;
          
          // 장소 카드
          final items = _selectedPlaces[category]!;
          if (i < running + items.length) {
            final place = items[i - running];
            return _buildPlaceCard(place, category);
          }
          running += items.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, String category) {
    final placeName = place['title'] as String? ?? 
                     place['name'] as String? ?? 
                     '알 수 없음';
    final placeAddress = place['address'] as String? ??
                       place['detail_address'] as String? ??
                       '주소 정보 없음';

    return GestureDetector(
      onTap: () => _navigateToPlaceDetail(place, category),
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
                placeName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                placeAddress,
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

  void _navigateToPlaceDetail(Map<String, dynamic> place, String category) {
    final placeId = place['id'] as String? ?? '';
    final placeName = place['title'] as String? ?? place['name'] as String? ?? '알 수 없음';
    final placeAddress = place['address'] as String? ?? place['detail_address'] as String? ?? '주소 정보 없음';
    final placeCategory = place['category'] as String? ?? 
                         place['sub_category'] as String? ?? 
                         category;
    final placeImage = place['image_url'] as String? ?? 
                      place['image'] as String? ?? 
                      '';
    
    final restaurant = Restaurant(
      id: placeId,
      name: placeName,
      detailAddress: placeAddress,
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

