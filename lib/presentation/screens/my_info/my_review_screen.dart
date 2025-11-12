import 'dart:collection';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/review_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../widgets/common_dialogs.dart';
import '../main/restaurant_detail_review_screen.dart';

class MyReviewScreen extends StatefulWidget {
  const MyReviewScreen({Key? key}) : super(key: key);

  @override
  State<MyReviewScreen> createState() => _MyReviewScreenState();
}

class _MyReviewScreenState extends State<MyReviewScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<MyReviewItem> _reviews = const [];
  List<_CategorySection> _sections = const [];
  final Map<String, String> _resolvedAddresses = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Widget _buildCategorySection(_CategorySection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...section.reviews.map((review) {
          final isLast = identical(review, section.reviews.last);
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: _buildReviewCard(review),
          );
        }),
      ],
    );
  }

  Future<void> _openRestaurantDetail(MyReviewItem review) async {
    if (review.categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매장 정보를 확인할 수 없어요.'),
        ),
      );
      return;
    }

    final fallbackAddress = review.restaurantAddress.isNotEmpty
        ? review.restaurantAddress
        : (_resolvedAddresses[review.categoryId] ?? '');
    final trimmedAddress = fallbackAddress.trim();
    final restaurant = Restaurant(
      id: review.categoryId,
      name: review.restaurantName,
      detailAddress: trimmedAddress.isEmpty ? null : trimmedAddress,
      rating: review.rating,
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailReviewScreen(restaurant: restaurant),
      ),
    );

    if (result == true && mounted) {
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    if (!TokenManager.hasTokens) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '로그인 정보가 없습니다. 다시 로그인해 주세요.';
        _reviews = const [];
        _sections = const [];
      });
      return;
    }

    try {
      final response = await ReviewService.getMyReview();
      final reviews = MyReviewItem.parseList(response);
      final sections = _groupByCategory(reviews);

      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _sections = sections;
        _loading = false;
      });
      _prefetchRestaurantAddresses(reviews);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '리뷰를 불러오는 데 실패했습니다: $e';
        _reviews = const [];
        _sections = const [];
      });
    }
  }

  Future<void> _prefetchRestaurantAddresses(List<MyReviewItem> reviews) async {
    final idsToFetch = reviews
        .where((review) =>
            review.categoryId.isNotEmpty &&
            review.restaurantAddress.isEmpty &&
            (_resolvedAddresses[review.categoryId]?.isEmpty ?? true))
        .map((review) => review.categoryId)
        .toSet()
        .toList();
    for (final categoryId in idsToFetch) {
      try {
        final restaurant = await ApiService.getRestaurant(categoryId);
        final address =
            (restaurant.detailAddress ?? restaurant.address ?? '').trim();
        if (!mounted) return;
        setState(() {
          _resolvedAddresses[categoryId] = address;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
        _resolvedAddresses[categoryId] = '';
        });
      }
    }
  }

  Future<void> _confirmDeleteReview(MyReviewItem review) async {
    final confirmed = await CommonDialogs.showConfirmation(
      context: context,
      title: '리뷰 삭제',
      content: '이 리뷰를 정말 삭제할까요?',
      confirmText: '삭제',
      confirmButtonColor: Colors.red,
    );
    if (confirmed == true) {
      await _deleteReview(review);
    }
  }

  Future<void> _deleteReview(MyReviewItem review) async {
    if (review.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 ID가 없어 삭제할 수 없습니다.')),
      );
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      await ReviewService.deleteMyReview(review.id);
      await _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 삭제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 삭제에 실패했습니다: $e')),
      );
    }
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
            '아직 리뷰를 작성하지 않았어요',
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == _sections.length - 1 ? 0 : 24),
          child: _buildCategorySection(section),
        );
      },
    );
  }

  Widget _buildReviewCard(MyReviewItem review) {
    final canNavigate = review.categoryId.isNotEmpty;
    final resolvedAddress = review.restaurantAddress.isNotEmpty
        ? review.restaurantAddress
        : (_resolvedAddresses[review.categoryId] ?? '');
    final displayAddress = resolvedAddress.trimLeft();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canNavigate ? () => _openRestaurantDetail(review) : null,
        child: Container(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        review.dateText,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _confirmDeleteReview(review),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

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
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: review.restaurantName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (displayAddress.isNotEmpty) ...[
                              const TextSpan(text: '\n'),
                              TextSpan(
                                text: displayAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor
                                      .withOpacity(0.9),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
              if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      review.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
  final String categoryId;
  final String categoryName;
  final int? categoryType;
  final String dateText;
  final String restaurantName;
  final String restaurantAddress;
  final double rating;
  final String content;
  final String? imageUrl;

  const MyReviewItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.dateText,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.rating,
    required this.content,
    this.imageUrl,
  });

  static List<MyReviewItem> parseList(dynamic response) {
    List<dynamic> items;
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final dynamic data = response['data'] ??
          response['reviews'] ??
          response['review_list'] ??
          response['items'] ??
          response['body'];
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
      final dynamic rawDate = m['created_at'] ??
          m['createdAt'] ??
          m['date'] ??
          m['written_at'] ??
          m['createdAt'];
      final String restaurantName = (m['category_name'] ??
              m['restaurant_name'] ??
              m['restaurantName'] ??
              m['store_name'] ??
              m['storeName'] ??
              '')
          .toString();
      final String restaurantAddress =
          (m['restaurant_address'] ?? m['restaurantAddress'] ?? m['address'] ?? '')
              .toString()
              .trim();
      final double rating =
          _parseDouble(m['rating'] ?? m['stars'] ?? m['score']) ?? 0.0;
      final String content = (m['content'] ??
              m['text'] ??
              m['review'] ??
              m['comments'] ??
              m['comment'] ??
              '')
          .toString();
      final String categoryId =
          (m['category_id'] ?? m['categoryId'] ?? m['store_id'] ?? '').toString();
      final int? categoryTypeCode =
          _parseInt(m['type'] ?? m['category_type'] ?? m['categoryType']);
      final int? categoryTypeFromString =
          _parseCategoryTypeString(m['category_type'] ?? m['categoryType']);
      final int? resolvedCategoryType =
          categoryTypeCode ?? categoryTypeFromString;
      final String categoryName =
          _categoryNameFromType(resolvedCategoryType) ??
              (m['categoryName'] ?? m['category_title'] ?? m['categoryTitle'] ?? '')
                  .toString();
      final String image = (m['image_url'] ??
              m['imageUrl'] ??
              m['restaurant_image'] ??
              m['restaurantImage'] ??
              m['image'])
          ?.toString() ??
          '';

      final resolvedCategoryName = (categoryName.isEmpty
              ? _categoryNameFromType(resolvedCategoryType) ?? '기타'
              : categoryName)
          .toString();

      return MyReviewItem(
        id: id.isEmpty
            ? DateTime.now().microsecondsSinceEpoch.toString()
            : id,
        categoryId: categoryId,
        categoryName: resolvedCategoryName,
        categoryType: resolvedCategoryType,
        dateText: _formatDate(rawDate),
        restaurantName:
            restaurantName.isEmpty ? '식당 정보 없음' : restaurantName,
        restaurantAddress: restaurantAddress,
        rating: rating,
        content: content.isEmpty ? '리뷰 내용 없음' : content,
        imageUrl: image.isEmpty ? null : image,
      );
    }).toList();
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString();
    return double.tryParse(s);
  }

  static String _formatDate(dynamic raw) {
    final dt = _parseDateTime(raw);
    if (dt == null) {
      final s = raw?.toString() ?? '';
      return s.isEmpty ? '날짜 정보 없음' : s;
    }
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${dt.year}.${twoDigits(dt.month)}.${twoDigits(dt.day)} '
        '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is num) {
      final numValue = v.toDouble();
      final absValue = numValue.abs();
      if (absValue >= 1000000000000000) {
        return DateTime.fromMicrosecondsSinceEpoch(
          numValue.toInt(),
          isUtc: true,
        ).toLocal();
      }
      if (absValue >= 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          numValue.toInt(),
          isUtc: true,
        ).toLocal();
      }
      if (absValue >= 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          (numValue * 1000).toInt(),
          isUtc: true,
        ).toLocal();
      }
    }
    var s = v.toString();
    if (s.contains(' ') && !s.contains('T')) {
      s = s.replaceFirst(' ', 'T');
    }
    final parsed = DateTime.tryParse(s);
    return parsed?.toLocal();
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static int? _parseCategoryTypeString(dynamic v) {
    if (v == null) return null;
    final value = v.toString().toLowerCase();
    switch (value) {
      case '0':
      case 'restaurant':
      case 'food':
      case '음식점':
        return 0;
      case '1':
      case 'cafe':
      case '카페':
        return 1;
      case '2':
      case 'content':
      case '콘텐츠':
        return 2;
      default:
        return int.tryParse(value);
    }
  }

  static String? _categoryNameFromType(int? type) {
    switch (type) {
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
}

class _CategorySection {
  final String title;
  final List<MyReviewItem> reviews;

  const _CategorySection({
    required this.title,
    required this.reviews,
  });
}

List<_CategorySection> _groupByCategory(List<MyReviewItem> reviews) {
  final map = LinkedHashMap<String, List<MyReviewItem>>();
  for (final review in reviews) {
    map.putIfAbsent(review.categoryName, () => []).add(review);
  }
  return map.entries
      .map(
        (entry) => _CategorySection(
          title: entry.key,
          reviews: List<MyReviewItem>.from(entry.value),
        ),
      )
      .toList();
}

