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
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 0) {
      // 홈 버튼을 누르면 홈 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
      );
    } else if (index == 1) {
      // 할 일 생성 버튼을 누르면 할 일 생성 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else if (index == 2) {
      // 커뮤니티 버튼을 누르면 커뮤니티 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CommunityScreen(),
        ),
      );
    } else if (index == 3) {
      // 내 정보 버튼을 누르면 내 정보 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MyInfoScreen(fromScreen: fromScreen),
        ),
      );
    }
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
