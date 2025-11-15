import 'package:flutter/material.dart';

/// 리뷰 알림 아이콘 버튼 위젯
/// 드롭다운을 열고 닫는 기능을 제공합니다.
class ReviewNotificationIconButton extends StatelessWidget {
  final GlobalKey iconKey;
  final bool isDropdownOpen;
  final VoidCallback onPressed;

  const ReviewNotificationIconButton({
    Key? key,
    required this.iconKey,
    required this.isDropdownOpen,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: iconKey,
      icon: Icon(
        isDropdownOpen
            ? Icons.rate_review
            : Icons.rate_review_outlined,
        color: const Color(0xFFFF8126),
      ),
      onPressed: onPressed,
    );
  }
}

