import 'package:flutter/material.dart';
import '../make_todo/recommendation_place_detail.dart';
import '../services/like_service.dart';
import '../services/token_manager.dart';

/// 찜목록을 보여주는 화면
class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _categories = ['카페', '음식점', '콘텐츠'];
  
  // 카테고리별 찜 상태 (카테고리 -> 장소 인덱스 -> 찜 여부)
  Map<String, Map<int, bool>> _favoriteStates = {};
  
  // 찜 목록 데이터 (초기값은 비어 있음)
  final Map<String, List<String>> _favoritePlaces = {
    '카페': [],
    '음식점': [],
    '콘텐츠': [],
  };

  @override
  void initState() {
    super.initState();
    
    // 항상 3개 탭(카페/음식점/콘텐츠) 고정
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
    );
    
    // 초기 상태 설정 (모두 찜된 상태)
    for (var category in _categories) {
      _favoriteStates[category] = {};
      for (int i = 0; i < (_favoritePlaces[category] ?? []).length; i++) {
        _favoriteStates[category]![i] = true; // 찜된 상태
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// 찜 버튼 토글
  void _toggleFavorite(String category, int index) async {
    final current = _favoriteStates[category]?[index] ?? false;
    final next = !current;
    setState(() {
      _favoriteStates[category]![index] = next;
    });
    try {
      final userId = TokenManager.userId ?? '';
      if (userId.isEmpty) return;
      final placeId = (_favoritePlaces[category] ?? [])[index].toString();
      if (next) {
        await LikeService.likeStore(placeId, userId);
      } else {
        await LikeService.unlikeStore(placeId, userId);
      }
    } catch (e) {
      setState(() {
        _favoriteStates[category]![index] = current; // rollback
      });
    }
  }

  /// 카테고리별 장소 리스트 위젯 생성
  Widget _buildPlacesList(String category) {
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
        final place = places[index];
        final isFavorite = _favoriteStates[category]?[index] ?? false;

        return InkWell(
          onTap: () async {
            if (!mounted) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailScreen(
                  placeName: place.toString(),
                  category: category,
                  initialFavorite: _favoriteStates[category]?[index] ?? true,
                ),
              ),
            );
            if (!mounted) return;
            if (result is bool) {
              setState(() {
                _favoriteStates[category]![index] = result;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 플레이스홀더
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: Icon(
                          _getCategoryIcon(category),
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      // 하트 버튼
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(category, index),
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
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey[600],
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 내용 영역
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8126),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#${category}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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

  // 하드코딩 데이터 제거됨

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
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '찜 목록',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController!,
            isScrollable: false,
            labelColor: const Color(0xFFFF7A21),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFFFF7A21),
            dividerColor: const Color(0xFFFF7A21),
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
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

