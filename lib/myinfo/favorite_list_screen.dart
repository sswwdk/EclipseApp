import 'package:flutter/material.dart';
import '../make_todo/place_detail_screen.dart';

/// 찜목록을 보여주는 화면
class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  // 카테고리별 찜 상태 (카테고리 -> 장소 인덱스 -> 찜 여부)
  Map<String, Map<int, bool>> _favoriteStates = {};
  
  // 찜 목록 데이터 (모킹 데이터)
  final Map<String, List<String>> _favoritePlaces = {
    '카페': [
      '스타벅스 강남점',
      '투썸플레이스 역삼점',
      '이디야커피 논현점',
    ],
    '음식점': [
      '맘스터치 테헤란로점',
      '맥도날드 강남점',
      '버거킹 신논현점',
    ],
    '콘텐츠': [
      // 빈 리스트로 설정하여 "텅 비었습니다" 메시지 테스트
    ],
  };

  @override
  void initState() {
    super.initState();
    
    // 카테고리가 2개 이상일 때만 TabController 생성
    if (_favoritePlaces.length > 1) {
      _tabController = TabController(
        length: _favoritePlaces.length,
        vsync: this,
      );
    }
    
    // 초기 상태 설정 (모두 찜된 상태)
    for (var category in _favoritePlaces.keys) {
      _favoriteStates[category] = {};
      for (int i = 0; i < _favoritePlaces[category]!.length; i++) {
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
  void _toggleFavorite(String category, int index) {
    setState(() {
      _favoriteStates[category]![index] = !(_favoriteStates[category]![index] ?? false);
    });
  }

  /// 카테고리별 장소 리스트 위젯 생성
  Widget _buildPlacesList(String category) {
    final places = _favoritePlaces[category] ?? [];
    
    if (places.isEmpty) {
      return Center(
        child: Text(
          '텅 텅 텅 비었습니다.',
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

        return GestureDetector(
          onTap: () {
            // 매장 상세 화면으로 이동
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailScreen(
                  placeName: place.toString(),
                  category: category,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
            children: [
              // 배경 이미지
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[400]!,
                          Colors.grey[600]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 하단 그라데이션 오버레이
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 매장 정보
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 매장 이름
                    Text(
                      place.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // 별점과 리뷰 수
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFC107),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getRandomRating()} (${_getRandomReviewCount()})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 태그
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _generateTags(category).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    
                    // 주소
                    Text(
                      _generateAddress(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 찜 버튼 (왼쪽 상단)
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(category, index),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 22,
                    ),
                  ),
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

  /// 랜덤 별점 생성 (하드코딩)
  String _getRandomRating() {
    final ratings = ['4.0', '4.2', '4.3', '4.5', '4.6', '4.7', '4.8', '4.9'];
    return ratings[DateTime.now().microsecond % ratings.length];
  }

  /// 랜덤 리뷰 수 생성 (하드코딩)
  String _getRandomReviewCount() {
    final counts = ['234', '567', '1,234', '2,456', '892', '1,567', '3,201'];
    return counts[DateTime.now().microsecond % counts.length];
  }

  /// 카테고리별 태그 생성 (하드코딩)
  List<String> _generateTags(String category) {
    switch (category) {
      case '음식점':
        return ['#맛집', '#가격 좋은', '#분위기 좋은', '#데이트 추천'];
      case '카페':
        return ['#커피 맛집', '#인테리어 예쁜', '#조용한', '#작업하기 좋은', '#디저트 맛있는'];
      case '콘텐츠':
        return ['#재미있는', '#최신작', '#평점 높은', '#추천작'];
      default:
        return ['#추천', '#인기', '#좋은 위치'];
    }
  }

  /// 더미 주소 생성 (하드코딩)
  String _generateAddress() {
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
          '찜목록',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _favoritePlaces.keys.length == 1
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(_favoritePlaces.keys.first),
                            size: 20,
                            color: const Color(0xFFFF7A21),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _favoritePlaces.keys.first,
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
                  indicatorColor: const Color(0xFFFF7A21),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: _favoritePlaces.keys.map((category) {
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
      body: _favoritePlaces.keys.length == 1
          ? _buildPlacesList(_favoritePlaces.keys.first)
          : TabBarView(
              controller: _tabController!,
              children: _favoritePlaces.keys.map((category) {
                return _buildPlacesList(category);
              }).toList(),
            ),
    );
  }
}

