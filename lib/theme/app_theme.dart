import 'package:flutter/material.dart';

class AppTheme {
  // 기본 색상 정의
  static const Color primaryColor = Color(0xFFFF8126);
  static const Color primaryLightColor = Color(0xFFFFA726);
  static const Color primaryDarkColor = Color(0xFFE65100);
  
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color secondaryLightColor = Color(0xFF4DB6AC);
  static const Color secondaryDarkColor = Color(0xFF00695C);
  
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textHintColor = Color(0xFF999999);
  
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFE0E0E0);
  
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // 그라데이션 색상
  static const List<Color> primaryGradient = [
    Color(0xFFFF8126),
    Color(0xFFFFA726),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF26A69A),
    Color(0xFF4DB6AC),
  ];
  
  // 투명도가 적용된 색상들
  static Color get primaryColorWithOpacity10 => primaryColor.withValues(alpha: 0.1);
  static Color get primaryColorWithOpacity20 => primaryColor.withValues(alpha: 0.2);
  static Color get primaryColorWithOpacity30 => primaryColor.withValues(alpha: 0.3);
  static Color get primaryColorWithOpacity50 => primaryColor.withValues(alpha: 0.5);
  static Color get primaryColorWithOpacity70 => primaryColor.withValues(alpha: 0.7);
  
  static Color get backgroundColorWithOpacity50 => backgroundColor.withValues(alpha: 0.5);
  static Color get backgroundColorWithOpacity80 => backgroundColor.withValues(alpha: 0.8);
  
  static Color get textPrimaryColorWithOpacity50 => textPrimaryColor.withValues(alpha: 0.5);
  static Color get textPrimaryColorWithOpacity70 => textPrimaryColor.withValues(alpha: 0.7);
  
  
  // 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // 스플래시 스크린 색상 설정
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLightColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryLightColor,
        surface: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
    );
  }
  
  
  // 색상 유틸리티 함수들
  static Color getShade(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      colors: primaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  static LinearGradient getSecondaryGradient() {
    return const LinearGradient(
      colors: secondaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  // 텍스트 스타일 정의
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textHintColor,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // 박스 그림자 정의
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
