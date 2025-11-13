import 'package:flutter/material.dart';
import 'dialogs/confirmation_dialog.dart';
import 'dialogs/info_dialog.dart';

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
    return ConfirmationDialog.show(
      context: context,
      title: title,
      content: content,
      cancelText: cancelText,
      confirmText: confirmText,
      confirmButtonColor: confirmButtonColor,
      onConfirm: onConfirm,
      onCancel: onCancel,
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
    return InfoDialog.show(
      context: context,
      title: title,
      content: content,
      buttonText: buttonText,
      onPressed: onPressed,
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

  /// 상단 스낵바 (위에서 아래로)
  static void showTopSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 1), // 🔥 1초로 변경
    Color? backgroundColor,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _TopSnackBar(
        message: message,
        backgroundColor: backgroundColor ?? const Color(0xFFFF8126),
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration + const Duration(milliseconds: 300), () {
      overlayEntry.remove();
    });
  }

  /// 성공 메시지 (상단)
  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    showTopSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.green,
    );
  }

  /// 에러 메시지 (상단)
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 1), // 🔥 1초로 변경
  }) {
    showTopSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.red,
      duration: duration,
    );
  }

  /// 정보 메시지 (상단)
  static void showMessage({
    required BuildContext context,
    required String message,
  }) {
    showTopSnackBar(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFFF8126),
    );
  }
}

/// 상단 스낵바 위젯
class _TopSnackBar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;

  const _TopSnackBar({
    required this.message,
    required this.backgroundColor,
    required this.duration,
  });

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0), // 위에서 시작
      end: Offset.zero, // 화면에 표시
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // duration 후 자동으로 사라지기
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
