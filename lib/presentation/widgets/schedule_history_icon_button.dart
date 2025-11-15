import 'package:flutter/material.dart';

/// 일정표 히스토리 아이콘 버튼 위젯
/// 일정표 히스토리 화면으로 이동하는 기능을 제공합니다.
class ScheduleHistoryIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ScheduleHistoryIconButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.calendar_today_outlined,
        color: Color(0xFFFF8126),
      ),
      onPressed: onPressed,
    );
  }
}

