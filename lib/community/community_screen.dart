import 'package:flutter/material.dart';
import '../screens/home.dart';
import '../make_todo/make_todo_main.dart';
import '../myinfo/myinfo_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedIndex = 2; // 커뮤니티 버튼이 활성화되도록 설정

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            color: Color(0xFFFF8126),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
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
        child: Column(
          children: [
            // 커뮤니티 포스트들
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '근면한 떡볶이',
              location: '문래동',
              timeAgo: '1주 전',
              title: '망원동 이치젠 같이 가실분?',
              content: '21세 남자입니다. 너무 핫플이라서 혼자가기가 좀 그런데 같이 가실 분 구합니다.',
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '꼼꼼한 연어',
              location: '영등포동',
              timeAgo: '1주 전',
              title: '양갈비가 맛있는 판코네!',
              content: '동네는 아니고 회사 근처지만 양갈비 좋아하시는...',
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '활발한 칼국수',
              location: '신사동',
              timeAgo: '1주 전',
              title: '주문할때 최소주문금액...',
              content: '확인 어떻게 하는지 아시는분 있나요??...',
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '케밥데몬헌터',
              location: '강남구',
              timeAgo: '2주 전',
              title: '서울 근교 여행지 추천해주세요',
              content: '주말에 가족과 함께 갈 수 있는 서울 근처 여행지를 찾고 있어요...',
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '달콤한 파스타',
              location: '홍대',
              timeAgo: '2주 전',
              title: '혼자 가기 좋은 카페',
              content: '홍대 근처에서 혼자 가서 책 읽기 좋은 조용한 카페 있나요?...',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 글쓰기 기능
        },
        backgroundColor: const Color(0xFFFF8126),
        child: const Icon(
          Icons.edit,
          color: Colors.white,
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
              // 홈 버튼을 누르면 홈 화면으로 이동
              setState(() => _selectedIndex = i);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const MainScreen(),
                ),
              );
            } else if (i == 1) {
              // 할 일 생성 버튼을 누르면 할 일 생성 화면으로 이동
              setState(() => _selectedIndex = i);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
              );
            } else if (i == 2) {
              // 커뮤니티 버튼 - 현재 화면 유지
              setState(() => _selectedIndex = i);
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

  Widget _buildPostCard({
    required IconData profileImage,
    required String nickname,
    required String location,
    required String timeAgo,
    required String title,
    required String content,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profileImage,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // 닉네임과 위치, 시간
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$location $timeAgo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 포스트 제목
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          
          // 포스트 내용
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // 댓글 버튼
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '댓글',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[200],
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
