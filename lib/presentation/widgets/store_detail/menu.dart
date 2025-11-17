import 'package:flutter/material.dart';
/* 관련 태그*/
class StoreMenuPreview extends StatelessWidget {
  const StoreMenuPreview({
    super.key,
    required this.menus,
    this.title = '관련 태그',
    this.maxItems = 5, // 표시 개수 선택
    this.primaryColor = const Color(0xFFFF8126),
    this.fontSize = 14, // 태그 글자 크기
    this.borderRadius = 15, // 배경 테두리 radius
  });

  final List<String> menus;
  final String title;
  final int maxItems;
  final Color primaryColor;
  final double fontSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (menus.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final visibleMenus = menus.take(maxItems).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ) ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleMenus
              .map(
                (menu) => _MenuChip(
                  label: menu,
                  color: primaryColor,
                  fontSize: fontSize,
                  borderRadius: borderRadius,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.color,
    required this.fontSize,
    required this.borderRadius,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200], // 연한 회색 배경
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color, // 텍스트 색상은 그대로 유지 (주황색 또는 파란색)
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

