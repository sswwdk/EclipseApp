import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/token_manager.dart';
import 'make_todo.dart';
import '../widgets/bottom_navigation_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // 할 일 생성 버튼이 활성화되도록 설정

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Stack(
          children: [
            // Background image with gradient fallback
            const Positioned.fill(child: _BackgroundImage()),
            // Foreground content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      '안녕하세요 ${TokenManager.userName ?? '사용자'}님!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '오늘 뭐할래요?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A21),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0xFFFF7A21).withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LocationInputScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '오늘 할 일 만들기',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _selectedIndex,
        fromScreen: 'make_todo',
      ),
    );
  }
}


class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
    );
  }
}
