import 'package:flutter/material.dart';
import '../../../data/services/like_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../data/models/restaurant.dart';
import '../main/restaurant_detail_screen.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/store/store_card.dart';
import '../../widgets/app_title_widget.dart';
import '../../../core/theme/app_theme.dart';

/// 찜목록을 보여주는 화면
class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _categories = ['카페', '음식점', '콘텐츠'];

  // 카테고리별 찜 목록 (Restaurant 객체들)
  Map<String, List<Restaurant>> _favoritePlaces = {
    '카페': [],
    '음식점': [],
    '콘텐츠': [],
  };

  // 로딩 상태
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // 항상 3개 탭(카페/음식점/콘텐츠) 고정
    _tabController = TabController(length: _categories.length, vsync: this);

    // 서버에서 찜 목록 가져오기
    _loadFavorites();
  }

  /// 서버에서 찜 목록 가져오기
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = TokenManager.userId ?? '';
      if (userId.isEmpty) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      final responseData = await LikeService.getLikes();

      if (!mounted) return;

      // 디버깅: 서버 응답 출력
      print('서버 응답 타입: ${responseData.runtimeType}');
      print('서버 응답 데이터: $responseData');

      // 서버 응답 파싱 (카테고리별로 분류)
      final Map<String, List<Restaurant>> favorites = {
        '카페': [],
        '음식점': [],
        '콘텐츠': [],
      };

      // 서버 응답 형식에 따라 데이터 파싱
      // ResponseLikeListDTO: { like_list: List[CategoryListItemDTO] }
      dynamic response = responseData;
      List<dynamic>? itemsToProcess;

      if (response is List) {
        // 리스트 형태로 직접 올 경우
        print('응답이 List 형태입니다. 항목 수: ${response.length}');
        itemsToProcess = response;
      } else if (response is Map<String, dynamic>) {
        print('응답이 Map 형태입니다. 키 목록: ${response.keys.toList()}');
        // like_list 키 확인 (서버 DTO: ResponseLikeListDTO)
        if (response.containsKey('like_list')) {
          final likeList = response['like_list'];
          print('like_list 값 타입: ${likeList.runtimeType}');
          if (likeList is List) {
            print('like_list는 List입니다. 항목 수: ${likeList.length}');
            itemsToProcess = likeList;
          }
        } else {
          // 다른 가능한 키들 확인 (하위 호환성)
          final possibleKeys = ['categories', 'data', 'items', 'likes', 'favorites'];
          for (var key in possibleKeys) {
            if (response.containsKey(key)) {
              final value = response[key];
              print('$key 키 발견, 타입: ${value.runtimeType}');
              if (value is List) {
                print('$key는 List입니다. 항목 수: ${value.length}');
                itemsToProcess = value;
                break;
              }
            }
          }
        }
      }

      print('처리할 항목 수: ${itemsToProcess?.length ?? 0}');

      // 데이터 파싱 및 카테고리별 분류
      // CategoryListItemDTO 형식: id, title, image_url, detail_address, sub_category, lat, lng, type, review_count, average_stars
      if (itemsToProcess != null && itemsToProcess.isNotEmpty) {
        print('${itemsToProcess.length}개 항목 파싱 시작');
        for (var item in itemsToProcess) {
          if (item is Map<String, dynamic>) {
            try {
              print('항목 데이터: $item');

              // CategoryListItemDTO 형식에 맞게 Restaurant 객체 생성
              final restaurant = Restaurant(
                id: item['id']?.toString() ?? '',
                name: item['title']?.toString() ?? '',
                image: item['image_url']?.toString(),
                subCategory: item['sub_category']?.toString(),
                detailAddress: item['detail_address']?.toString(),
                latitude: item['lat']?.toString(),
                longitude: item['lng']?.toString(),
                type: _mapTypeToCategory(
                  item['type'],
                ), // type int를 카테고리 문자열로 매핑
                reviewCount: _parseInt(item['review_count']),
                averageStars: _parseDouble(item['average_stars']),
                isFavorite: true, // 찜 목록이므로 항상 true
              );

              print(
                'Restaurant 파싱 성공: ${restaurant.name}, type: ${restaurant.type}, subCategory: ${restaurant.subCategory}',
              );

              // 카테고리 매핑 (type 또는 subCategory 기준)
              final type = restaurant.type ?? '';
              final subCategory = restaurant.subCategory ?? '';

              String? mappedCategory;
              if (type.contains('카페') || subCategory.contains('카페')) {
                mappedCategory = '카페';
              } else if (type.contains('음식') ||
                  subCategory.contains('음식') ||
                  subCategory.contains('식당')) {
                mappedCategory = '음식점';
              } else if (type.contains('콘텐츠') ||
                  type.contains('문화') ||
                  subCategory.contains('문화') ||
                  subCategory.contains('영화')) {
                mappedCategory = '콘텐츠';
              }

              // type이 없으면 서버의 type 필드 사용
              // 음식점: 0, 카페: 1, 컨텐츠: 2
              if (mappedCategory == null && item['type'] != null) {
                final typeInt = item['type'] is int
                    ? item['type']
                    : int.tryParse(item['type'].toString());
                if (typeInt == 0) {
                  mappedCategory = '음식점';
                } else if (typeInt == 1) {
                  mappedCategory = '카페';
                } else if (typeInt == 2) {
                  mappedCategory = '콘텐츠';
                }
              }

              print(
                '매핑된 카테고리: $mappedCategory (type: ${item['type']}, subCategory: $subCategory)',
              );

              if (mappedCategory != null &&
                  favorites.containsKey(mappedCategory)) {
                favorites[mappedCategory]!.add(restaurant);
                print('${mappedCategory}에 추가됨');
              } else {
                print(
                  '카테고리 매핑 실패 - type: ${item['type']}, subCategory: $subCategory',
                );
              }
            } catch (e, stackTrace) {
              print('Restaurant 파싱 오류: $e');
              print('스택 트레이스: $stackTrace');
              // 개별 항목 파싱 오류는 무시하고 계속 진행
            }
          } else {
            print('항목이 Map이 아닙니다. 타입: ${item.runtimeType}');
          }
        }
      } else {
        print('처리할 항목이 없습니다.');
      }

      print(
        '최종 결과 - 카페: ${favorites['카페']?.length ?? 0}, 음식점: ${favorites['음식점']?.length ?? 0}, 콘텐츠: ${favorites['콘텐츠']?.length ?? 0}',
      );

      setState(() {
        _favoritePlaces = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '찜 목록을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// 찜 버튼 토글 (찜 취소)
  Future<void> _toggleFavorite(String category, int index) async {
    final restaurant = _favoritePlaces[category]?[index];
    if (restaurant == null) return;

    // 삭제 확인 팝업 표시
    final confirmed = await CommonDialogs.showConfirmation(
      context: context,
      title: '찜 목록에서 삭제하시겠습니까?',
      content: '${restaurant.name}을(를) 삭제하시겠습니까?',
      cancelText: '취소',
      confirmText: '삭제',
      confirmButtonColor: const Color(0xFFFF7A21),
    );

    // 확인을 누른 경우에만 삭제 진행
    if (confirmed != true) return;

    try {
      final userId = TokenManager.userId ?? '';
      if (userId.isEmpty) return;

      // 서버에 찜 취소 요청
      await LikeService.unlikeStore(restaurant.id);

      // 목록에서 제거
      if (!mounted) return;
      setState(() {
        _favoritePlaces[category]!.removeAt(index);
      });
    } catch (e) {
      if (!mounted) return;
      CommonDialogs.showError(
        context: context,
        message: '찜 취소 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 카테고리별 장소 리스트 위젯 생성
  Widget _buildPlacesList(String category) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8126)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8126),
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final places = _favoritePlaces[category] ?? [];

    if (places.isEmpty) {
      return Center(
        child: Text(
          '찜 내역이 없습니다.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final restaurant = places[index];

        return StoreCard(
          title: restaurant.name,
          rating: restaurant.averageStars ?? restaurant.rating ?? 0.0,
          reviewCount: restaurant.reviewCount ?? restaurant.reviews.length,
          imageUrl: restaurant.image,
          imagePlaceholderText: category,
          tags: [
            category,
            if ((restaurant.subCategory ?? '').trim().isNotEmpty)
              restaurant.subCategory!.trim(),
          ],
          enableFavorite: true,
          isFavorite: true,
          onFavoriteToggle: () => _toggleFavorite(category, index),
          onTap: () async {
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RestaurantDetailScreen(restaurant: restaurant),
              ),
            );
            if (!mounted) return;
            await _loadFavorites();
          },
        );
      },
    );
  }

  /// type int를 카테고리 문자열로 매핑
  /// 음식점: 0, 카페: 1, 컨텐츠: 2
  String? _mapTypeToCategory(dynamic type) {
    if (type == null) return null;
    final typeInt = type is int ? type : int.tryParse(type.toString());
    if (typeInt == null) return null;

    // type 값에 따른 카테고리 매핑
    switch (typeInt) {
      case 0:
        return '음식점';
      case 1:
        return '카페';
      case 2:
        return '콘텐츠';
      default:
        return null;
    }
  }

  /// 카테고리에 따른 아이콘 반환
  IconData _getCategoryIcon(String category) {
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

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // 하드코딩 데이터 제거됨

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
        title: const AppTitleWidget('찜 목록', color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController!,
            isScrollable: false,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            dividerColor: Colors.white.withOpacity(0.3),
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            tabs: _categories.map((category) {
              return Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getCategoryIcon(category), size: 20),
                    const SizedBox(width: 6),
                    Text(category),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: _categories.map((category) {
          return _buildPlacesList(category);
        }).toList(),
      ),
    );
  }
}
