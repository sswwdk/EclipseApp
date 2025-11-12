import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 앱 전체에서 사용할 통일된 타이틀 위젯
/// 
/// 사용 예시:
/// ```dart
/// AppBar(
///   title: AppTitleWidget('커뮤니티'),
///   centerTitle: true,
/// )
/// ```
class AppTitleWidget extends StatelessWidget {
  /// 타이틀 텍스트
  final String text;
  
  /// 텍스트 정렬 (기본값: center)
  final TextAlign textAlign;
  
  /// 텍스트 색상 (기본값: primaryColor)
  final Color? color;

  const AppTitleWidget(
    this.text, {
    Key? key,
    this.textAlign = TextAlign.center,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? AppTheme.primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      textAlign: textAlign,
    );
  }
}

