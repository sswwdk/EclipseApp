/* 매장 리스트 카드 형식으로 보여주는 것*/
import 'package:flutter/material.dart';

class StoreCard extends StatelessWidget {
  final String title;
  final double rating;
  final int reviewCount;
  final String? subtitle;
  final List<String> tags;
  final String? imageUrl;
  final String? imagePlaceholderText;
  final VoidCallback? onTap;
  final bool enableFavorite;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool enableSelection;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final EdgeInsetsGeometry margin;
  final double imageHeight;
  final Color accentColor;

  const StoreCard({
    Key? key,
    required this.title,
    required this.rating,
    required this.reviewCount,
    this.subtitle,
    this.tags = const [],
    this.imageUrl,
    this.imagePlaceholderText,
    this.onTap,
    this.enableFavorite = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.enableSelection = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.imageHeight = 200,
    this.accentColor = const Color(0xFFFF8126),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredTags =
        tags.where((tag) => tag.trim().isNotEmpty).toList(growable: false);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: margin,
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
              child: _buildImageSection(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _RatingReviewRow(
                    rating: rating,
                    reviewCount: reviewCount,
                  ),
                  if (filteredTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: filteredTags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '# $tag',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        _buildImage(),
        if (enableFavorite) _buildFavoriteButton(),
        if (enableSelection) _buildSelectionButton(),
      ],
    );
  }

  Widget _buildImage() {
    final hasImageUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    if (hasImageUrl) {
      return Image.network(
        imageUrl!,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: imageHeight,
      width: double.infinity,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Text(
        imagePlaceholderText ?? '이미지를 불러올 수 없습니다',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      left: 12,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onFavoriteToggle,
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
    );
  }

  Widget _buildSelectionButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onSelectToggle,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.white,
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
            color: isSelected ? Colors.white : Colors.grey[600],
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _RatingReviewRow extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingReviewRow({
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.star,
          color: Color(0xFFFF8126),
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          rating.isNaN ? '평점 정보 없음' :'${rating.toStringAsFixed(1)}점',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '리뷰 ${reviewCount.clamp(0, 9999)}개',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFFF7A21),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

