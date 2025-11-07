import 'package:flutter/material.dart';

/// 공통 다이얼로그 위젯들
class CommonDialogs {
  /// 확인/취소 다이얼로그
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = '취소',
    String confirmText = '확인',
    Color? confirmButtonColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                onCancel?.call();
              },
              child: Text(
                cancelText,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onConfirm?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor ?? const Color(0xFFFF7A21),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 정보 표시 다이얼로그
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = '확인',
    VoidCallback? onPressed,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
      },
    );
  }

  /// 커스텀 다이얼로그 (완전 커스터마이징 가능)
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        );
      },
    );
  }

  /// 뒤로가기 확인 다이얼로그
  static Future<bool?> showBackConfirmation({
    required BuildContext context,
    String title = '뒤로 가시겠습니까?',
    String content = '지금까지 대화가 삭제됩니다.',
    VoidCallback? onConfirm,
  }) {
    return showConfirmation(
      context: context,
      title: title,
      content: content,
      confirmText: '뒤로가기',
      onConfirm: onConfirm,
    );
  }

  /// 나가기 확인 다이얼로그
  static Future<bool?> showExitConfirmation({
    required BuildContext context,
    String title = '채팅을 나가시겠습니까?',
    String content = '지금까지 대화가 삭제됩니다.',
    VoidCallback? onConfirm,
  }) {
    return showConfirmation(
      context: context,
      title: title,
      content: content,
      confirmText: '나가기',
      onConfirm: onConfirm,
    );
  }

  /// 로그아웃 확인 다이얼로그
  static Future<bool?> showLogoutConfirmation({
    required BuildContext context,
    String title = '로그아웃',
    String content = '정말 로그아웃하시겠습니까?',
    VoidCallback? onConfirm,
  }) {
    return showConfirmation(
      context: context,
      title: title,
      content: content,
      confirmText: '로그아웃',
      onConfirm: onConfirm,
    );
  }

  /// 탈퇴 확인 다이얼로그
  static Future<bool?> showDeleteAccountConfirmation({
    required BuildContext context,
    String title = '정말 탈퇴하시겠습니까?',
    String content = '탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.',
    VoidCallback? onConfirm,
  }) {
    return showConfirmation(
      context: context,
      title: title,
      content: content,
      confirmText: '탈퇴하기',
      confirmButtonColor: Colors.red,
      onConfirm: onConfirm,
    );
  }

  /// 신고 확인 다이얼로그
  static Future<bool?> showReportConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    VoidCallback? onConfirm,
  }) {
    return showConfirmation(
      context: context,
      title: title,
      content: content,
      confirmText: '신고하기',
      confirmButtonColor: Colors.red,
      onConfirm: onConfirm,
    );
  }

  /// 차단 확인 다이얼로그
  static Future<bool?> showBlockConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    VoidCallback? onConfirm,
  }) {
    return showConfirmation(
      context: context,
      title: title,
      content: content,
      confirmText: '차단하기',
      confirmButtonColor: Colors.red,
      onConfirm: onConfirm,
    );
  }
}
