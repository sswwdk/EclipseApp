import 'package:flutter/material.dart';
import 'make_todo.dart';
import '../home/home.dart';
import '../myinfo/myinfo_screen.dart';
import '../community/community_screen.dart';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      '안녕하세요 OOO님!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '오늘 뭐할래요?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A21),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0xFFFF7A21).withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PeopleCountScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '할 일 만들러가기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
      bottomNavigationBar: _RoundedTopNavBar(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFFF7A21),
          unselectedItemColor: Colors.black54,
          onTap: (i) {
            if (i == 0) {
              // 홈 버튼을 누르면 main.dart로 돌아가기
              setState(() => _selectedIndex = i);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const MainScreen(),
                ),
              );
            } else if (i == 1) {
              // 할 일 생성 버튼 - 현재 화면 유지 (화면 이동용으로만 사용)
              // 실제 할 일 만들기는 중앙의 "할 일 만들러가기" 버튼으로만 가능
              setState(() => _selectedIndex = i);
            } else if (i == 2) {
              // 커뮤니티 버튼을 누르면 CommunityScreen으로 이동
              setState(() => _selectedIndex = i);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CommunityScreen(),
                ),
              );
            } else if (i == 3) {
              // 내 정보 버튼을 누르면 MyInfoScreen으로 이동
              setState(() => _selectedIndex = i);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyInfoScreen(),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: '할 일 생성',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: '커뮤니티',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: '내 정보',
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundedTopNavBar extends StatelessWidget {
  final Widget child;
  const _RoundedTopNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: child,
        ),
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Try to load asset image. If missing, a grey gradient remains.
        Image.asset(
          'assets/images/home_bg.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF6F6F6), Color(0xFFEDEDED)],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
