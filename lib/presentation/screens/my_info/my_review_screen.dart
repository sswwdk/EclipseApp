import 'package:flutter/material.dart';
import 'package:whattodo/core/theme/app_theme.dart';

class MyReviewScreen extends StatefulWidget {
  const MyReviewScreen({Key? key}) : super(key: key);

  @override
  State<MyReviewScreen> createState() => _MyReviewScreenState();
}

class _MyReviewScreenState extends State<MyReviewScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<MyReviewItem> _reviews = const [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // 하드코딩된 샘플 데이터
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    setState(() {
      _reviews = [
        MyReviewItem(
          id: '1',
          dateText: '2024.01.15',
          restaurantName: '리미티드 하누',
          restaurantAddress: '서울시 강남구 개포동 1197-2',
          rating: 4.5,
          content: '육즙이 정말 살아있었어요! 고기도 신선하고 서비스도 좋았습니다. 다음에 또 방문하고 싶네요.',
        ),
      ];
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          '내가 쓴 리뷰',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        color: AppTheme.primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReviews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '작성한 리뷰가 없습니다.',
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemCount: _reviews.length,
    );
  }

  Widget _buildReviewCard(MyReviewItem review) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜
            Text(
              review.dateText,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // 식당 정보 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.restaurantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (review.restaurantAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.restaurantAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 별점
            Row(
              children: [
                _buildStarRating(review.rating),
              ],
            ),
            const SizedBox(height: 12),
            
            // 리뷰 내용
            Text(
              review.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
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

class MyReviewItem {
  final String id;
  final String dateText;
  final String restaurantName;
  final String restaurantAddress;
  final double rating;
  final String content;

  const MyReviewItem({
    required this.id,
    required this.dateText,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.rating,
    required this.content,
  });

  static List<MyReviewItem> parseList(dynamic response) {
    List<dynamic> items;
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final dynamic data = response['data'] ?? response['reviews'] ?? response['items'] ?? response['body'];
      if (data is List) {
        items = data;
      } else {
        items = [];
      }
    } else {
      items = [];
    }

    return items.whereType<Map<String, dynamic>>().map((m) {
      final String id = (m['id'] ?? m['review_id'] ?? '').toString();
      final String date = (m['created_at'] ?? m['createdAt'] ?? m['date'] ?? '').toString();
      final String restaurantName = (m['restaurant_name'] ?? m['restaurantName'] ?? m['store_name'] ?? '').toString();
      final String restaurantAddress = (m['restaurant_address'] ?? m['restaurantAddress'] ?? m['address'] ?? '').toString();
      final double rating = _parseDouble(m['rating']) ?? 0.0;
      final String content = (m['content'] ?? m['text'] ?? m['review'] ?? '').toString();
      
      return MyReviewItem(
        id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
        dateText: date.isEmpty ? '날짜 정보 없음' : date,
        restaurantName: restaurantName.isEmpty ? '식당 정보 없음' : restaurantName,
        restaurantAddress: restaurantAddress,
        rating: rating,
        content: content.isEmpty ? '리뷰 내용 없음' : content,
      );
    }).toList();
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString();
    return double.tryParse(s);
  }
}

