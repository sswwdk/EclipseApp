import 'package:flutter/material.dart';
import 'profile_settings_screen.dart';
import 'delete_account_screen.dart';
import '../screens/home.dart';

class MyInfoScreen extends StatelessWidget {
  final String? fromScreen; // 어느 화면에서 왔는지 추적
  const MyInfoScreen({Key? key, this.fromScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '내 정보',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            // 뒤로 가기 시 항상 홈 화면으로 돌아가기
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
              (route) => false, // 모든 이전 화면 제거
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 프로필 정보 섹션
            _buildProfileSection(context),
            const SizedBox(height: 20),
            
            // 활동 섹션
            _buildActivitySection(),
            const SizedBox(height: 20),
            
            // 고객지원 섹션
            _buildSupportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 사진
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '프사',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 닉네임
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettingsScreen(),
                    ),
                  );
                },
                child: const Text(
                  '내 프로필',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            
            // 화살표 아이콘
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
              child: const Icon(
                Icons.chevron_right,
                color: Color(0xFFFF8126),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.favorite_outline,
            title: '찜목록',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.calendar_today_outlined,
            title: '일정표 히스토리',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.rate_review_outlined,
            title: '내가 쓴 리뷰',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.article_outlined,
            title: '내가 쓴 게시글',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: '개인정보 처리 방침',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.campaign_outlined,
            title: '공지사항',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '문의하기',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout_outlined,
            title: '회원 탈퇴',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeleteAccountScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFFFF8126),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.red : Colors.black87,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : const Color(0xFFFF8126),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.grey[200],
    );
  }
}
