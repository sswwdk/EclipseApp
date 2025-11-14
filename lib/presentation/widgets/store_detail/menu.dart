import 'package:flutter/material.dart';
/* 관련 태그*/
class StoreMenuPreview extends StatelessWidget {
  const StoreMenuPreview({
    super.key,
    required this.menus,
    this.title = '관련 태그',
    this.maxItems = 5, // 표시 개수 선택
    this.primaryColor = const Color(0xFFFF8126),
  });

  final List<String> menus;
  final String title;
  final int maxItems;
  final Color primaryColor;

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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ) ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleMenus
              .map(
                (menu) => _MenuChip(
                  label: menu,
                  color: primaryColor,
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
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

