import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/like_service.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/models/review.dart';
import '../../widgets/app_title_widget.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late Restaurant _restaurant;
  List<Review> _reviews = const [];
  List<String> _tags = const [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
    _isFavorite = widget.restaurant.isFavorite;
    _reviews = widget.restaurant.reviews;
    _tags = widget.restaurant.tags;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏪 [Restaurant Detail] 상세 정보 요청 시작');
    print('  → Restaurant ID: ${widget.restaurant.id}');
    print('  → Restaurant Name: ${widget.restaurant.name}');
    print('  → Restaurant Address: ${widget.restaurant.detailAddress}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      final res = await ApiService.getRestaurant(widget.restaurant.id);
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ [Restaurant Detail] 서버 응답 성공');
      print('  → Reviews 개수: ${res.reviews.length}');
      print('  → Tags 개수: ${res.tags.length}');
      print('  → Is Favorite: ${res.isFavorite}');
      print('  → Reviews 데이터:');
      for (int i = 0; i < res.reviews.length; i++) {
        print('    [$i] ${res.reviews[i].nickname}: ${res.reviews[i].content}');
      }
      print('  → Tags: ${res.tags}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (!mounted) return;
      setState(() {
        _restaurant = res;
        _reviews = res.reviews;
        _tags = res.tags;
        _isFavorite = res.isFavorite;
      });
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ [Restaurant Detail] 서버 요청 실패');
      print('  → Error: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant;
    final averageStars = restaurant.averageStars ?? restaurant.rating ?? 0.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppTitleWidget(
          restaurant.name,
          color: Colors.black,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.black),
            onPressed: () async {
              final next = !_isFavorite;
              setState(() => _isFavorite = next);
              try {
                final categoryId = restaurant.id;
                if (next) {
                  await LikeService.likeStore(categoryId);
                } else {
                  await LikeService.unlikeStore(categoryId);
                }
              } catch (e) {
                setState(() => _isFavorite = !next);
              }
            },
          ),
          const SizedBox(width: 8), // 간격 추가
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 이미지 (이미지 URL 있으면 노출, 없으면 플레이스홀더)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: ClipRRect(
                child: (restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty)
                    ? Image.network(
                        restaurant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(const Color(0xFFFF8126)),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
                      ),
              ),
            ),
            
            // 음식점 정보 섹션
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
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
                  // 주소
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF8126),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        restaurant.detailAddress ?? restaurant.address ?? '주소 정보 없음',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  // 전화번호
                  if (restaurant.phone != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xFFFF8126),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          restaurant.phone!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // 평점 (서버 값만 표시, 없으면 0)
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFF8126),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '평점: ${averageStars.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  // 영업시간
                  if (restaurant.businessHour != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFFFF8126),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restaurant.businessHour!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // 태그들 (서버에서 받은 태그 사용)
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((t) => _buildTag('# $t')).toList(),
                    ),
                ],
              ),
            ),
            
            // 리뷰 섹션 (서버 데이터 표시, 없으면 안내)
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  // 리뷰 제목
                  Text(
                    '리뷰 (${_reviews.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_reviews.isEmpty)
                    Text(
                      '아직 작성된 리뷰가 없습니다.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    )
                  else ...[
                    for (int i = 0; i < _reviews.length; i++) ...[
                      _buildReview(
                        nickname: _reviews[i].nickname,
                        rating: _reviews[i].rating,
                        content: _reviews[i].content,
                      ),
                      if (i != _reviews.length - 1) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 12),
                      ]
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF8126)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFFFF8126),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReview({
    required String nickname,
    required double rating,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아바타
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 리뷰 내용
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStarRating(rating),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(
            Icons.star,
            color: Color(0xFFFF8126),
            size: 14,
          );
        } else if (index < rating) {
          return const Icon(
            Icons.star_half,
            color: Color(0xFFFF8126),
            size: 14,
          );
        } else {
          return Icon(
            Icons.star_border,
            color: Colors.grey[400],
            size: 14,
          );
        }
      }),
    );
  }
}
