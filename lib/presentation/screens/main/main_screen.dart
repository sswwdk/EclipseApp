import 'package:flutter/material.dart';
import '../schedule/schedule_screen.dart';
import '../my_info/my_info_screen.dart';
import '../my_info/schedule/schedule_history_screen.dart';
import '../community/community_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/restaurant.dart';
import 'restaurant_detail_screen.dart';
import '../../widgets/store_card.dart';
import '../../widgets/app_title_widget.dart';

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
        title: const AppTitleWidget('할 일 추천'),
        centerTitle: true,
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
                  builder: (context) => ScheduleHistoryScreen(),
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
                      child: _buildRecommendationCard(restaurant),
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

  Widget _buildRecommendationCard(Restaurant restaurant) {
    final imageUrl = restaurant.imageUrl;
    final bool isUrl =
        imageUrl != null && Uri.tryParse(imageUrl)?.isAbsolute == true;

    return StoreCard(
      title: restaurant.name,
      rating: restaurant.averageStars ?? restaurant.rating ?? 0.0,
      reviewCount: restaurant.reviewCount ?? restaurant.reviews.length,
      imageUrl: isUrl ? imageUrl : null,
      imagePlaceholderText: isUrl ? null : (imageUrl ?? '이미지를 불러올 수 없습니다'),
      tags: [
        if (restaurant.description != null) restaurant.description!,
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
