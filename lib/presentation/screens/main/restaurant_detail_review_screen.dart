import 'package:flutter/material.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/models/review.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/review_service.dart';

class RestaurantDetailReviewScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailReviewScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  State<RestaurantDetailReviewScreen> createState() =>
      _RestaurantDetailReviewScreenState();
}

class _RestaurantDetailReviewScreenState
    extends State<RestaurantDetailReviewScreen> {
  List<Review> _reviews = const [];
  List<String> _tags = const [];
  bool _isFavorite = false;

  bool _isSubmitting = false;
  int _newRating = 5;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await ApiService.getRestaurant(widget.restaurant.id);
      if (!mounted) return;
      setState(() {
        _reviews = res.reviews;
        _tags = res.tags;
        _isFavorite = res.isFavorite;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('상세 정보를 불러오지 못했습니다: $e')));
    }
  }

  void _resetReviewForm() {
    _reviewController.clear();
    _newRating = 5;
  }

  Future<void> _openReviewSheet(BuildContext context) async {
    _resetReviewForm();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Material(
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                // 👈 이 부분 추가
                builder: (BuildContext context, StateSetter setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '리뷰 작성',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    _resetReviewForm();
                                    Navigator.of(sheetContext).pop();
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReviewForm(
                        sheetContext,
                        setModalState,
                      ), // 👈 setModalState 전달
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReview(BuildContext sheetContext) async {
    final content = _reviewController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 내용을 입력해주세요.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      FocusScope.of(context).unfocus();

      await ReviewService.setMyReview(
        categoryId: widget.restaurant.id,
        stars: _newRating,
        comments: content,
      );
      await _fetchDetail();
      if (!mounted) return;
      _resetReviewForm();
      Navigator.of(sheetContext).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰가 작성되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('리뷰 작성에 실패했습니다: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          restaurant.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              // TODO: LikeService 연동 필요 시 추가
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: ClipRRect(
                child:
                    (restaurant.imageUrl != null &&
                        restaurant.imageUrl!.isNotEmpty)
                    ? Image.network(
                        restaurant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.restaurant,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                  Color(0xFFFF8126),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.restaurant,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF8126),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurant.detailAddress ??
                              restaurant.address ??
                              '주소 정보 없음',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        '평점: ${(restaurant.rating ?? 0.0).toStringAsFixed(1)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
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
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map((t) => _buildTag('# $t'))
                          .toList(growable: false),
                    ),
                ],
              ),
            ),
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
                  Row(
                    children: [
                      Text(
                        '리뷰 (${_reviews.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _openReviewSheet(context),
                        icon: const Icon(Icons.edit, color: Color(0xFFFF8126)),
                        label: const Text(
                          '리뷰 작성',
                          style: TextStyle(
                            color: Color(0xFFFF8126),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        createdAt: _reviews[i].createdAt,
                      ),
                      if (i != _reviews.length - 1) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _openReviewSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8126),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '리뷰 작성',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
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

  Widget _buildReviewForm(
    BuildContext sheetContext,
    StateSetter setModalState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '별점',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 12),
            _buildSelectableStars(setModalState), // 👈 setModalState 전달
            const SizedBox(width: 8),
            Text(
              '$_newRating점',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF8126),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            hintText: '리뷰 내용을 입력해주세요.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF8126)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        _resetReviewForm();
                        Navigator.of(sheetContext).pop();
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitReview(sheetContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8126),
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('등록'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReview({
    required String nickname,
    required double rating,
    required String content,
    DateTime? createdAt,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
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
                  const Spacer(),
                  if (createdAt != null)
                    Text(
                      _formatReviewDate(createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableStars(StateSetter setModalState) {
    // 👈 파라미터 추가
    return Row(
      children: List.generate(5, (index) {
        final isFilled = index < _newRating;
        return GestureDetector(
          onTap: _isSubmitting
              ? null
              : () {
                  setModalState(() {
                    // 👈 setState 대신 setModalState 사용
                    _newRating = index + 1;
                  });
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: const Color(0xFFFF8126),
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Color(0xFFFF8126), size: 14);
        } else if (index < rating) {
          return const Icon(
            Icons.star_half,
            color: Color(0xFFFF8126),
            size: 14,
          );
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: 14);
        }
      }),
    );
  }

  String _formatReviewDate(DateTime createdAt) {
    final local = createdAt.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final date =
        '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)}';
    final time = '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
    return '$date $time';
  }
}
