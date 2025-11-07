import 'package:flutter/material.dart';
import 'package:whattodo/presentation/widgets/bottom_navigation_widget.dart';
import 'package:whattodo/presentation/screens/community/todo_list_screen.dart';
import 'package:whattodo/presentation/screens/community/post_detail_screen.dart';
import 'package:whattodo/presentation/screens/community/message_screen.dart';
import 'package:whattodo/core/theme/app_theme.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Transform.rotate(
            angle: -0.5, // 오른쪽 위를 가리키도록 회전
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MessageScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 커뮤니티 포스트들
            _buildPostCard(
              profileImage: Icons.person,
              nickname: 'Suetheking',
              timeAgo: '방금 전',
              title: '아 심심해',
              content: '같이가요',
              schedule: {
                'title': '메가커피 노량진점 → 카츠진 → 영등포 CGV',
                'items': [
                  {'time': '19:00', 'place': '메가커피 노량진점'},
                  {'time': '20:30', 'place': '카츠진'},
                  {'time': '22:00', 'place': '영등포 CGV'},
                ],
              },
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '근면한 떡볶이',
              timeAgo: '1주 전',
              title: '망원동 이치젠 같이 가실분?',
              content: '21세 남자입니다. 너무 핫플이라서 혼자가기가 좀 그런데 같이 가실 분 구합니다.',
              schedule: {
                'title': '망원동 이치젠 → 망원시장 → 홍대',
                'items': [
                  {'time': '19:00', 'place': '망원동 이치젠'},
                  {'time': '21:00', 'place': '망원시장'},
                  {'time': '22:30', 'place': '홍대'},
                ],
              },
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '꼼꼼한 연어',
              timeAgo: '1주 전',
              title: '양갈비가 맛있는 판코네!',
              content: '동네는 아니고 회사 근처지만 양갈비 좋아하시는 분들 모집합니다.',
              schedule: {
                'title': '판코네 → 강남역 → 신논현',
                'items': [
                  {'time': '18:30', 'place': '판코네'},
                  {'time': '20:00', 'place': '강남역'},
                  {'time': '21:30', 'place': '신논현'},
                ],
              },
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '활발한 칼국수',
              timeAgo: '1주 전',
              title: '주문할때 최소주문금액...',
              content: '확인 어떻게 하는지 아시는분 있나요??',
              schedule: {
                'title': '홍대 스타벅스 → 홍대 클럽',
                'items': [
                  {'time': '20:00', 'place': '홍대 스타벅스'},
                  {'time': '22:00', 'place': '홍대 클럽'},
                ],
              },
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '케밥데몬헌터',
              timeAgo: '2주 전',
              title: '서울 근교 여행지 추천해주세요',
              content: '주말에 가족과 함께 갈 수 있는 서울 근처 여행지를 찾고 있어요.',
              schedule: {
                'title': '잠실 롯데월드 → 잠실 래미안 → 송파구청',
                'items': [
                  {'time': '09:00', 'place': '잠실 롯데월드'},
                  {'time': '14:00', 'place': '잠실 래미안'},
                  {'time': '17:00', 'place': '송파구청'},
                ],
              },
            ),
            _buildDivider(),
            
            _buildPostCard(
              profileImage: Icons.person,
              nickname: '달콤한 파스타',
              timeAgo: '2주 전',
              title: '혼자 가기 좋은 카페',
              content: '홍대 근처에서 혼자 가서 책 읽기 좋은 조용한 카페 있나요?',
              schedule: {
                'title': '홍대 카페 → 망원시장 → 홍대',
                'items': [
                  {'time': '14:00', 'place': '홍대 카페'},
                  {'time': '16:00', 'place': '망원시장'},
                  {'time': '18:00', 'place': '홍대'},
                ],
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TodoListScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _selectedIndex,
        fromScreen: 'community',
      ),
    );
  }

  Widget _buildPostCard({
    required IconData profileImage,
    required String nickname,
    required String timeAgo,
    required String title,
    required String content,
    Map<String, dynamic>? schedule,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: {
                  'profileImage': profileImage,
                  'nickname': nickname,
                  'timeAgo': timeAgo,
                  'title': title,
                  'content': content,
                  'schedule': schedule,
                },
              ),
            ),
          );
        },
        child: Container(
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
                  color: AppTheme.dividerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profileImage,
                  color: AppTheme.textSecondaryColor,
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
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
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
          
          // 일정표 정보 (있는 경우에만 표시)
          if (schedule != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColorWithOpacity10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColorWithOpacity20,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      schedule['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // 댓글 버튼
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '댓글',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppTheme.dividerColor,
    );
  }
}

