import 'package:flutter/material.dart';
import '../screens/main/main_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/my_info/my_info_screen.dart';
import '../screens/community/community_screen.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final String? fromScreen;

  const BottomNavigationWidget({
    Key? key,
    required this.currentIndex,
    this.fromScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _RoundedTopNavBar(
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFFFF7A21),
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          _handleNavigation(context, index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '매장 추천',
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
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 0) {
      // 홈 버튼 - HomeScreen (schedule_screen.dart)으로 이동
      if (currentIndex != 0) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else if (index == 1) {
      // 매장 추천 버튼 - MainScreen으로 이동
      if (currentIndex != 1) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else if (index == 2) {
      // 커뮤니티 버튼 - CommunityScreen으로 이동
      if (currentIndex != 2) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CommunityScreen()),
        );
      }
    } else if (index == 3) {
      // 내 정보 버튼 - MyInfoScreen으로 이동
      if (currentIndex != 3) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MyInfoScreen(fromScreen: fromScreen ?? 'home'),
          ),
        );
      }
    }
  }
}

class _RoundedTopNavBar extends StatelessWidget {
  final Widget child;
  const _RoundedTopNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 🔥 좌우, 하단 여백 추가
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), // 🔥 반투명 배경 (블러 효과)
        borderRadius: BorderRadius.circular(24), // 🔥 모든 모서리를 둥글게
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8), // 🔥 상하 패딩만
          child: child,
        ),
      ),
    );
  }
}
