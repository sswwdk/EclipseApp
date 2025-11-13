import 'package:flutter/material.dart';

/// 정보 표시 다이얼로그 위젯
class InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback? onPressed;

  const InfoDialog({
    Key? key,
    required this.title,
    required this.content,
    this.buttonText = '확인',
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A21),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 다이얼로그 표시
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = '확인',
    VoidCallback? onPressed,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return InfoDialog(
          title: title,
          content: content,
          buttonText: buttonText,
          onPressed: onPressed,
        );
      },
    );
  }
}

