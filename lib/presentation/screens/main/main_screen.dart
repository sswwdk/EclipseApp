import 'package:flutter/material.dart';
import '../schedule/schedule_screen.dart';
import '../my_info/my_info_screen.dart';
import '../my_info/schedule_history_screen.dart';
import '../community/community_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/restaurant.dart';
import 'restaurant_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Restaurant> restaurants = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final restaurantsData = await ApiService.getRestaurants();
      setState(() {
        restaurants = restaurantsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true, // 🔥 body를 네비게이션 바 아래까지 확장
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '할 일 추천',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          // 일정표 히스토리 버튼
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFFFF8126),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScheduleHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFFF8126)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100), // 🔥 하단 패딩 추가 (네비게이션 바 공간)
        child: Column(
          children: [
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF8126),
                    ),
                  ),
                ),
              )
            else if (errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '데이터를 불러올 수 없습니다',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRestaurants,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8126),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              )
            else if (restaurants.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    '추천할 레스토랑이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ...restaurants
                  .map(
                    (restaurant) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRecommendationCard(
                        imagePlaceholder: restaurant.imageUrl ?? "레스토랑 이미지",
                        title: restaurant.name,
                        rating: restaurant.rating ?? 0.0,
                        reviewCount: 0, // API에서 리뷰 수가 없으므로 0으로 설정
                        tags: [
                          if (restaurant.description != null)
                            restaurant.description!,
                        ],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailScreen(
                                restaurant: restaurant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
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
              // 홈 버튼 - 현재 화면 유지 (아무것도 하지 않음)
              setState(() => _selectedIndex = i);
            } else if (i == 1) {
              // 할 일 생성 버튼을 누르면 make_do_start.dart의 HomeScreen으로 이동 (화면 이동용)
              setState(() => _selectedIndex = i);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else if (i == 2) {
              // 커뮤니티 버튼을 누르면 CommunityScreen으로 이동
              setState(() => _selectedIndex = i);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              );
            } else if (i == 3) {
              // 내 정보 버튼을 누르면 MyInfoScreen으로 이동
              setState(() => _selectedIndex = i);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MyInfoScreen(fromScreen: 'home'),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
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

  Widget _buildRecommendationCard({
    required String imagePlaceholder,
    required String title,
    required double rating,
    required int reviewCount,
    required List<String> tags,
    VoidCallback? onTap,
  }) {
    final bool isUrl = Uri.tryParse(imagePlaceholder)?.isAbsolute ?? false;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역: URL이면 network image로, 아니면 텍스트 플레이스홀더로 표시
            Container(
              height: 200,
              width: double.infinity,
              // ClipRRect로 상단 둥근 모서리 유지
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: isUrl
                    ? Image.network(
                        imagePlaceholder,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        // 로딩 중 인디케이터
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF8126),
                                ),
                              ),
                            ),
                          );
                        },
                        // 로드 실패 시 대체 UI
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[500],
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '이미지 로드 실패',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            imagePlaceholder,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
            ),

            // 내용 부분
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 평점
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFF8126),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating ($reviewCount)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 태그들
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: tags.map((tag) => _buildTag(tag)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8126),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '# $tag',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
