import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/history_service.dart';
import '../../../../shared/helpers/token_manager.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/restaurant.dart';
import '../../main/restaurant_detail_review_screen.dart';
import '../../../widgets/app_title_widget.dart';

/// "그냥" 탭 히스토리 상세 화면 (선택한 장소 목록 표시)
class ScheduleHistoryNormalDetailScreen extends StatefulWidget {
  final String historyId;

  const ScheduleHistoryNormalDetailScreen({Key? key, required this.historyId})
    : super(key: key);

  @override
  State<ScheduleHistoryNormalDetailScreen> createState() =>
      _ScheduleHistoryNormalDetailScreenState();
}

class _ScheduleHistoryNormalDetailScreenState
    extends State<ScheduleHistoryNormalDetailScreen> {
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
      final detailResponse = await HistoryService.getHistoryDetail(
        userId,
        widget.historyId,
      );

      if (!mounted) return;

      print('🔍 [Normal Detail] 서버 응답: $detailResponse');

      // 상세 정보 파싱
      final parsedData = _parseHistoryDetail(detailResponse);

      if (!mounted) return;

      setState(() {
        _selectedPlaces =
            parsedData['places'] as Map<String, List<Map<String, dynamic>>>;
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
  Map<String, dynamic> _parseHistoryDetail(
    Map<String, dynamic> detailResponse,
  ) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📦 [Normal Detail] 전체 서버 응답:');
    print(detailResponse);
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final data = detailResponse['data'] ?? detailResponse;

    print('📦 [Normal Detail] data 부분:');
    print(data);
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 날짜 정보 추출
    String? dateText;
    if (data['visited_at'] != null) {
      final visitedAt = data['visited_at'].toString();
      dateText = _formatDate(visitedAt);
      print('📅 [Normal Detail] visited_at: $visitedAt → $dateText');
    } else if (data['date'] != null) {
      dateText = _formatDate(data['date'].toString());
      print('📅 [Normal Detail] date: ${data['date']} → $dateText');
    }

    // 장소 정보 추출
    final Map<String, List<Map<String, dynamic>>> places = {};

    // categories 형식으로 저장된 경우
    if (data['categories'] != null && data['categories'] is List) {
      print('🏷️ [Normal Detail] categories 형식으로 파싱 시작');
      final categories = data['categories'] as List<dynamic>;
      print('🏷️ [Normal Detail] categories 개수: ${categories.length}');

      for (int idx = 0; idx < categories.length; idx++) {
        final category = categories[idx];
        print('━━━ Category ${idx + 1} ━━━');
        print('원본 데이터: $category');

        final categoryMap = category as Map<String, dynamic>;
        print('사용 가능한 필드들: ${categoryMap.keys.toList()}');

        // category_type을 실제 카테고리로 변환 (String 또는 int 처리)
        final categoryTypeRaw = categoryMap['category_type'];
        int categoryType = 0;
        if (categoryTypeRaw is int) {
          categoryType = categoryTypeRaw;
        } else if (categoryTypeRaw is String) {
          categoryType = int.tryParse(categoryTypeRaw) ?? 0;
        }
        final categoryName = _getCategoryNameFromType(categoryType);
        final placeName = categoryMap['category_name'] as String? ?? '';
        final placeId = categoryMap['category_id'] as String? ?? '';
        final placeAddress =
            categoryMap['category_detail_address'] as String? ?? '주소 정보 없음';
        final subCategory = categoryMap['sub_category'] as String? ?? '';

        print('  → categoryType: $categoryType');
        print('  → categoryName: $categoryName');
        print('  → placeName: $placeName');
        print('  → placeId: $placeId');
        print('  → placeAddress: $placeAddress');
        print('  → subCategory: $subCategory');

        if (placeName.isEmpty) {
          print('  ⚠️ placeName이 비어있어서 스킵');
          continue;
        }

        if (!places.containsKey(categoryName)) {
          places[categoryName] = [];
        }

        places[categoryName]!.add({
          'id': placeId,
          'title': placeName,
          'name': placeName,
          'address': placeAddress,
          'category': categoryName,
          'sub_category': subCategory,
        });
        print('  ✅ 추가됨');
      }
    }
    // places 형식으로 저장된 경우 (saveOtherHistory)
    else if (data['places'] != null && data['places'] is List) {
      print('📍 [Normal Detail] places 형식으로 파싱 시작');
      final placesList = data['places'] as List<dynamic>;
      print('📍 [Normal Detail] places 개수: ${placesList.length}');

      for (int idx = 0; idx < placesList.length; idx++) {
        final place = placesList[idx];
        print('━━━ Place ${idx + 1} ━━━');
        print('원본 데이터: $place');

        final placeMap = place as Map<String, dynamic>;
        print('사용 가능한 필드들: ${placeMap.keys.toList()}');

        final category = placeMap['category'] as String? ?? '기타';
        final placeId =
            placeMap['place_id'] as String? ?? placeMap['id'] as String? ?? '';
        final placeName = placeMap['name'] as String? ?? '알 수 없음';
        final placeAddress = placeMap['address'] as String? ?? '주소 정보 없음';
        final placeImage =
            placeMap['image_url'] as String? ??
            placeMap['image'] as String? ??
            '';

        print('  → category: $category');
        print('  → placeId: $placeId');
        print('  → placeName: $placeName');
        print('  → placeAddress: $placeAddress');
        print('  → placeImage: $placeImage');

        if (!places.containsKey(category)) {
          places[category] = [];
        }

        places[category]!.add({
          'id': placeId,
          'title': placeName,
          'name': placeName,
          'address': placeAddress,
          'category': category,
          'image_url': placeImage,
        });
        print('  ✅ 추가됨');
      }
    } else {
      print('⚠️ [Normal Detail] categories도 places도 없음!');
      print('data의 키들: ${data.keys.toList()}');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 [Normal Detail] 최종 파싱된 장소: $places');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return {'places': places, 'date': dateText};
  }

  /// category_type을 카테고리 이름으로 변환
  String _getCategoryNameFromType(int categoryType) {
    switch (categoryType) {
      case 0:
        return '음식점';
      case 1:
        return '카페';
      case 2:
        return '콘텐츠';
      default:
        return '기타';
    }
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
        title: AppTitleWidget(_dateText ?? '선택한 장소'),
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
      itemCount: categories.fold<int>(
        0,
        (sum, c) => sum + _selectedPlaces[c]!.length + 1,
      ),
      itemBuilder: (context, i) {
        int running = 0;
        for (final category in categories) {
          // 카테고리 헤더
          if (i == running) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _iconForCategory(category),
                    color: const Color(0xFFFF8126),
                  ),
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
    final placeName =
        place['title'] as String? ?? place['name'] as String? ?? '알 수 없음';
    final placeAddress =
        place['address'] as String? ??
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

  Future<void> _navigateToPlaceDetail(
    Map<String, dynamic> place,
    String category,
  ) async {
    final placeId = place['id'] as String? ?? '';

    if (placeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매장 정보를 불러올 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // 🔥 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );

      // 🔥 매장 상세 정보 API 호출 (이미지 포함)
      print('🔍 [Normal Detail] 매장 상세 정보 조회 시작: $placeId');
      final detailedRestaurant = await ApiService.getRestaurant(placeId);
      print('✅ [Normal Detail] 매장 상세 정보 조회 완료: ${detailedRestaurant.image}');

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      // 🔥 API에서 받은 전체 정보로 Restaurant 객체 생성
      final placeName =
          place['title'] as String? ?? place['name'] as String? ?? '알 수 없음';
      final placeAddress =
          place['address'] as String? ??
          place['detail_address'] as String? ??
          '주소 정보 없음';
      final placeCategory =
          place['category'] as String? ??
          place['sub_category'] as String? ??
          category;

      final restaurant = Restaurant(
        id: placeId,
        name: detailedRestaurant.name.isNotEmpty
            ? detailedRestaurant.name
            : placeName,
        detailAddress: detailedRestaurant.detailAddress ?? placeAddress,
        subCategory: detailedRestaurant.subCategory ?? placeCategory,
        image: detailedRestaurant.image, // 🔥 API에서 받은 이미지 사용
        phone: detailedRestaurant.phone,
        rating: detailedRestaurant.rating,
        businessHour: detailedRestaurant.businessHour,
      );

      print(
        '🏪 [Normal Detail] Restaurant 객체 생성 완료: image = ${restaurant.image}',
      );

      // 🔥 상세 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailReviewScreen(
            restaurant: restaurant,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      print('❌ [Normal Detail] 매장 상세 화면 이동 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('매장 정보를 불러오는 데 실패했습니다: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
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
