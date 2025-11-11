import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'delete_account_screen.dart';
import 'change/change_nickname_screen.dart';
import 'change/change_password_screen.dart';
import 'change/change_email_screen.dart';
import 'change/change_address_screen.dart';
import 'change/change_phone_screen.dart';
import '../../../shared/helpers/token_manager.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '프로필 설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFFF8126)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 프로필 정보 섹션
            _buildProfileSection(),
            const SizedBox(height: 20),

            // 계정 설정 섹션
            _buildAccountSection(context),
            const SizedBox(height: 20),

            // 앱 기능 섹션
            _buildAppFeaturesSection(),
            const SizedBox(height: 20),

            // 계정 관리 섹션
            _buildAccountManagementSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final nickname = (TokenManager.userName ?? '닉네임').trim();
    final email = TokenManager.userEmail ?? 'example@gmail.com';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
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
            _buildProfileAvatar(nickname),
            const SizedBox(width: 16),
            // 닉네임과 이메일
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      // 디버깅을 위한 로그
                      print(
                        '프로필 설정 화면에서 TokenManager.userName: ${TokenManager.userName}',
                      );
                      print(
                        '프로필 설정 화면에서 TokenManager.userEmail: ${TokenManager.userEmail}',
                      );

                      return Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
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
            icon: Icons.person_outline,
            title: '닉네임 변경',
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const ChangeNicknameScreen(),
                    ),
                  )
                  .then((_) {
                    if (mounted) setState(() {}); // 돌아오면 최신 닉네임으로 리빌드
                  });
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: '비밀번호 변경',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.email_outlined,
            title: '이메일 변경',
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangeEmailScreen(),
                ),
              );

              // 이메일이 변경되었으면 화면 새로고침
              if (result == true && mounted) {
                print('프로필 화면 새로고침');
                setState(() {}); // 이 부분이 화면을 다시 그립니다
              }
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: '집주소 변경',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangeAddressScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.phone_outlined,
            title: '전화번호 변경',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePhoneScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppFeaturesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
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
            title: '개발자에게 후원하기',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.diamond_outlined,
            title: '오뭐 플러스 구독하기',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountManagementSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
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
            icon: Icons.cancel_outlined,
            title: '회원 탈퇴하기',
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF8126), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
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

  Widget _buildProfileAvatar(String name) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty
        ? trimmed.characters.first.toUpperCase()
        : '?';
    final colors = _avatarColorsFor(initial);

    return CircleAvatar(
      radius: 28,
      backgroundColor: colors.background,
      child: Text(
        initial,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  _AvatarColors _avatarColorsFor(String initial) {
    if (initial.isEmpty) {
      return _avatarColorPalettes.first;
    }
    final rune = initial.runes.first;
    final index = rune.abs() % _avatarColorPalettes.length;
    return _avatarColorPalettes[index];
  }
}

class _AvatarColors {
  final Color background;
  final Color foreground;

  const _AvatarColors(this.background, this.foreground);
}

const List<_AvatarColors> _avatarColorPalettes = [
  _AvatarColors(Color(0xFFFFE5E0), Color(0xFFFF6B57)),
  _AvatarColors(Color(0xFFE3F2FD), Color(0xFF1565C0)),
  _AvatarColors(Color(0xFFF1F8E9), Color(0xFF2E7D32)),
  _AvatarColors(Color(0xFFEDE7F6), Color(0xFF5E35B1)),
  _AvatarColors(Color(0xFFFFF3E0), Color(0xFFEF6C00)),
  _AvatarColors(Color(0xFFE0F2F1), Color(0xFF00897B)),
  _AvatarColors(Color(0xFFFFEBEE), Color(0xFFD81B60)),
  _AvatarColors(Color(0xFFF3E5F5), Color(0xFF8E24AA)),
];
