import 'package:flutter/material.dart';
import 'package:whattodo/make_todo/place_detail_screen.dart';

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
  State<RecommendationResultScreen> createState() => _RecommendationResultScreenState();
}

class _RecommendationResultScreenState extends State<RecommendationResultScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  // 카테고리별 찜 상태 (카테고리 -> 장소 인덱스 -> 찜 여부)
  Map<String, Map<int, bool>> _favoriteStates = {};
  
  // 카테고리별 선택 상태 (카테고리 -> 장소 인덱스 -> 선택 여부)
  Map<String, Map<int, bool>> _selectedStates = {};

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
  void _toggleFavorite(String category, int index) {
    setState(() {
      _favoriteStates[category]![index] = !(_favoriteStates[category]![index] ?? false);
    });
  }

  /// 선택 버튼 토글
  void _toggleSelection(String category, int index) {
    setState(() {
      _selectedStates[category]![index] = !(_selectedStates[category]![index] ?? false);
    });
  }

  /// 카테고리별 장소 리스트 위젯 생성
  Widget _buildPlacesList(String category) {
    final places = widget.recommendations[category] as List<dynamic>?;
    
    if (places == null || places.isEmpty) {
      return Center(
        child: Text(
          '추천 장소가 없습니다.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
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
        final isSelected = _selectedStates[category]?[index] ?? false;

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
              
              // 선택 체크박스 (오른쪽 상단)
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
                          ? const Color(0xFFFF7A21) 
                          : Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.check,
                      color: Colors.white,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    // TODO: 일정표 제작하기 기능 구현
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('일정표 제작하기 기능은 준비 중입니다.'),
                        duration: Duration(seconds: 2),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 완료하기 기능 구현
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('완료하기 기능은 준비 중입니다.'),
                        duration: Duration(seconds: 2),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

