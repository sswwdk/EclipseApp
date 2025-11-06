import 'package:flutter/material.dart';
import '../home/restaurant_detail_screen.dart';
import '../home/home.dart';
import 'route_confirm.dart';
import '../services/like_service.dart';
import '../services/token_manager.dart';
import '../services/api_service.dart';
import '../widgets/common_dialogs.dart';
import 'result_choice_confirm.dart';

/// 추천 결과를 보여주는 화면
class RecommendationResultScreen extends StatefulWidget {
  final Map<String, dynamic> recommendations;
  final List<String> selectedCategories;

  const RecommendationResultScreen({
    Key? key,
    required this.recommendations,
    required this.selectedCategories,
  }) : super(key: key);

  @override
  State<RecommendationResultScreen> createState() =>
      _RecommendationResultScreenState();
}

class _RecommendationResultScreenState extends State<RecommendationResultScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // 카테고리별 찜 상태 (카테고리 -> 장소 인덱스 -> 찜 여부)
  Map<String, Map<int, bool>> _favoriteStates = {};

  // 카테고리별 선택 상태 (카테고리 -> 선택된 장소 인덱스 Set, 최대 2개)
  Map<String, Set<int>> _selectedStates = {};

  @override
  void initState() {
    super.initState();

    // 카테고리가 2개 이상일 때만 TabController 생성
    if (widget.selectedCategories.length > 1) {
      _tabController = TabController(
        length: widget.selectedCategories.length,
        vsync: this,
      );
    }

    // 초기 상태 설정
    for (var category in widget.selectedCategories) {
      _favoriteStates[category] = {};
      _selectedStates[category] = {};
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// 찜 버튼 토글
  void _toggleFavorite(String category, int index, String categoryId) async {
    final bool newState = !(_favoriteStates[category]![index] ?? false);
    setState(() {
      _favoriteStates[category]![index] = newState;
    });
    try {
      final userId = TokenManager.userId ?? '';
      if (userId.isEmpty) return;
      if (newState) {
        await LikeService.likeStore(categoryId, userId);
      } else {
        await LikeService.unlikeStore(categoryId, userId);
      }
    } catch (e) {
      // 서버 실패 시 UI 상태를 롤백
      setState(() {
        _favoriteStates[category]![index] = !newState;
      });
    }
  }

  /// 선택 버튼 토글 (카테고리별 최대 2개 선택)
  void _toggleSelection(String category, int index) {
    setState(() {
      final selected = _selectedStates[category]!;
      
      if (selected.contains(index)) {
        // 같은 항목을 다시 클릭하면 해제
        selected.remove(index);
      } else {
        // 새로운 항목 선택
        if (selected.length >= 2) {
          // 최대 2개까지만 선택 가능
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('카테고리별 최대 2개까지 선택할 수 있습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        selected.add(index);
      }
    });
  }

  /// 카테고리별 장소 리스트 위젯 생성
  Widget _buildPlacesList(String category) {
    final places = widget.recommendations[category] as List<dynamic>?;

    if (places == null || places.isEmpty) {
      return Center(
        child: Text(
          '추천 장소가 없습니다.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        // 🔥 Map으로 캐스팅하고 필드 추출
        final place = places[index] as Map<String, dynamic>;
        
        // 선택 상태 확인
        final isSelected = _selectedStates[category]?.contains(index) ?? false;
        
        // 디버깅: 선택된 항목의 서버 응답 데이터 확인
        if (isSelected) {
          final placeName = place['title'] as String? ?? place['name'] as String? ?? '알 수 없음';
          print('🔍 [선택된 항목] 추천 데이터 구조 확인 (index: $index):');
          print('   이름: $placeName');
          print('   전체 필드: ${place.keys.toList()}');
          print('   title: ${place['title']}');
          print('   name: ${place['name']}');
          print('   latitude: ${place['latitude']}');
          print('   longitude: ${place['longitude']}');
          print('   lat: ${place['lat']}');
          print('   lng: ${place['lng']}');
          print('   id: ${place['id']}');
          print('   전체 데이터: $place');
        }
        
        // 서버 응답 형식에 따라 여러 필드명 시도 (title, name 순서로)
        final placeName = place['title'] as String? ?? 
                         place['name'] as String? ?? 
                         '알 수 없음';
        final placeAddress =
            place['address'] as String? ??
            place['detail_address'] as String? ??
            '주소 정보 없음';
        final placeCategory =
            place['category'] as String? ??
            place['sub_category'] as String? ??
            category;
        // 이미지 필드도 여러 가능성 시도
        final placeImage = place['image_url'] as String? ?? 
                          place['image'] as String? ?? 
                          '';
        final placeId = place['id'] as String? ?? '';

        final isFavorite = _favoriteStates[category]?[index] ?? false;
        // isSelected는 위에서 이미 선언됨

        return InkWell(
          onTap: () {
            if (!mounted) return;
            // 추천 아이템으로부터 상세 화면에 전달할 모델 구성
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
            ).then((value) {
              if (value is bool) {
                setState(() {
                  _favoriteStates[category]![index] = value;
                });
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // 🔥 이미지 표시
                      placeImage.isNotEmpty
                          ? Image.network(
                              placeImage,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: Text(
                                    '이미지를 불러올 수 없습니다',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: Text(
                                '이미지를 불러올 수 없습니다',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                      // 찜 버튼
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(
                            category,
                            index,
                            placeId,
                          ), // 🔥 ID 전달
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey[600],
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // 선택 체크박스
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _toggleSelection(category, index),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF8126)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 매장 이름
                      Text(
                        placeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 🔥 실제 카테고리
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8126),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '# $placeCategory',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 🔥 실제 주소
                      Text(
                        placeAddress,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (!mounted) return;
            CommonDialogs.showConfirmation(
              context: context,
              title: '확인',
              content: '처음으로 돌아가시겠습니까?',
              confirmText: '확인',
              onConfirm: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              },
            );
          },
        ),
        title: const Text(
          '추천 결과',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: widget.selectedCategories.length == 1
              ? Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFFF7A21),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(widget.selectedCategories[0]),
                            size: 20,
                            color: const Color(0xFFFF7A21),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.selectedCategories[0],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF7A21),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : TabBar(
                  controller: _tabController!,
                  isScrollable: false,
                  labelColor: const Color(0xFFFF7A21),
                  unselectedLabelColor: Colors.grey[600],
                  dividerColor: const Color(0xFFFF7A21),
                  indicatorColor: const Color(0xFFFF7A21),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: widget.selectedCategories.map((category) {
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
      body: widget.selectedCategories.length == 1
          ? _buildPlacesList(widget.selectedCategories[0])
          : TabBarView(
              controller: _tabController!,
              children: widget.selectedCategories.map((category) {
                return _buildPlacesList(category);
              }).toList(),
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
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!mounted) return;
                    final Map<String, List<dynamic>> selectedByCategory = {};
                    for (final category in widget.selectedCategories) {
                      final places =
                          (widget.recommendations[category]
                              as List<dynamic>?) ??
                          [];
                      final selectedIndices = _selectedStates[category] ?? {};
                      
                      if (selectedIndices.isNotEmpty) {
                        selectedByCategory[category] = [];
                        for (final index in selectedIndices) {
                          if (index < places.length) {
                            // 🔥 실제 Map 객체를 전달
                            final place = places[index] as Map<String, dynamic>;
                            
                            // 디버깅: 선택된 모든 장소의 데이터 확인 (위경도 포함)
                            print('🔍 [$category] 선택된 장소 #${index + 1} 데이터:');
                            print('   이름: ${place['title'] ?? place['name']}');
                            print('   전체 필드: ${place.keys.toList()}');
                            print('   id: ${place['id']}');
                            print('   lat: ${place['lat']}');
                            print('   lng: ${place['lng']}');
                            print('   latitude: ${place['latitude']}');
                            print('   longitude: ${place['longitude']}');
                            print('   category_id: ${place['category_id']}');
                            
                            // 위경도가 있는지 확인
                            final hasLatLng = place['lat'] != null || place['latitude'] != null;
                            final hasLng = place['lng'] != null || place['longitude'] != null;
                            if (hasLatLng && hasLng) {
                              print('   ✅ 위경도 정보 있음');
                            } else {
                              print('   ⚠️ 위경도 정보 없음');
                            }
                            
                            selectedByCategory[category]!.add(place);
                          }
                        }
                        print('🔍 [$category] 총 ${selectedIndices.length}개 장소 선택됨');
                      }
                    }

                    if (selectedByCategory.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('선택된 장소가 없습니다.')),
                      );
                      return;
                    }
                    
                    print('🔍 RouteConfirmScreen으로 전달할 데이터:');
                    print('   카테고리 목록: ${selectedByCategory.keys.toList()}');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RouteConfirmScreen(selected: selectedByCategory),
                      ),
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
                    '일정표 제작하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // 선택된 항목만 모아 요약 화면으로 이동
                    if (!mounted) return;
                    final Map<String, List<Map<String, dynamic>>> selectedByCategory = {};
                    for (final category in widget.selectedCategories) {
                      final places =
                          (widget.recommendations[category]
                              as List<dynamic>?) ??
                          [];
                      final selectedIndices = _selectedStates[category] ?? {};
                      
                      if (selectedIndices.isNotEmpty) {
                        selectedByCategory[category] = [];
                        for (final index in selectedIndices) {
                          if (index < places.length) {
                            // Map 객체를 그대로 전달
                            final place = places[index] as Map<String, dynamic>;
                            selectedByCategory[category]!.add(place);
                          }
                        }
                      }
                    }

                    if (selectedByCategory.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('선택된 장소가 없습니다.')),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SelectedPlacesScreen(selected: selectedByCategory),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF7A21),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFFFF7A21),
                        width: 2,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '완료하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택된 장소만 모아 보여주는 화면