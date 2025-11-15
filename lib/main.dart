import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드로만 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whattodo',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
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
