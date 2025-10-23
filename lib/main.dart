import 'package:flutter/material.dart';
import 'login/login_screen.dart';
import 'theme/app_theme.dart';

/* 추가 */
import 'home/home.dart';
/* 추가 */

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whattodo',
      theme: AppTheme.lightTheme,
      /* 추가 */
      home: const MainScreen(),
      /* 추가 */
      // 화면 전환 시 하늘색 배경 제거
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          child: child!,
        );
      },
    );
  }
}