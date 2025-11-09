import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/helpers/token_manager.dart';
import 'schedule_select_screen.dart';
import '../../widgets/bottom_navigation_widget.dart';
import 'choose_template_screen.dart';

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
      backgroundColor: Colors.white, // 🔥 흰색 배경으로 변경 (네비게이션 바 주변)
      extendBody: true, // 🔥 body를 네비게이션 바 아래까지 확장
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
                      child: Column(
                        children: [
                          ElevatedButton(
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
                          const SizedBox(height: 12),
                          OutlinedButton(
                            // TODO(jjaga): remove dummy template shortcut button after QA
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF7A21),
                              side: const BorderSide(color: Color(0xFFFF7A21), width: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _openTemplatesWithDummyData,
                            child: const Text(
                              '템플릿 미리보기 (더미)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // 🔥 네비게이션 바 공간 확보 (80 -> 120)
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

  void _openTemplatesWithDummyData() {
    // TODO(jjaga): remove dummy data when real selection flow is ready
    final Map<String, List<String>> dummySelected = {
      '음식점': ['메가 맛집'],
      '카페': ['달콤 카페'],
      '콘텐츠': ['전시회 A'],
    };

    final Map<String, List<Map<String, dynamic>>> dummySelectedPlacesWithData = {
      '음식점': [
        {
          'id': 'restaurant_1',
          'name': '메가 맛집',
          'category': '음식점',
          'address': '서울시 강남구 테헤란로 123',
          'latitude': 37.498, // dummy
          'longitude': 127.027, // dummy
          'rating': '4.5',
          'image_url': 'https://picsum.photos/200/300?dummy-restaurant',
        },
      ],
      '카페': [
        {
          'id': 'cafe_1',
          'name': '달콤 카페',
          'category': '카페',
          'address': '서울시 서초구 서초대로 45',
          'latitude': 37.492, // dummy
          'longitude': 127.015, // dummy
          'rating': 4.2,
          'image_url': 'https://picsum.photos/200/300?dummy-cafe',
        },
      ],
      '콘텐츠': [
        {
          'id': 'content_1',
          'name': '전시회 A',
          'category': '콘텐츠',
          'address': '서울시 용산구 이태원로 99',
          'latitude': 37.534, // dummy
          'longitude': 126.994, // dummy
          'rating': '4.8',
          'image_url': 'https://picsum.photos/200/300?dummy-exhibit',
        },
      ],
    };

    final List<Map<String, dynamic>> dummyOrderedPlaces = [
      {
        'id': 'restaurant_1',
        'name': '메가 맛집',
        'category': '음식점',
        'address': '서울시 강남구 테헤란로 123',
        'latitude': 37.498,
        'longitude': 127.027,
        'rating': '4.5',
        'image_url': 'https://picsum.photos/200/300?dummy-restaurant',
        'detail_address': '12층',
        'data': {
          'address': '서울시 강남구 테헤란로 123',
          'latitude': 37.498,
          'longitude': 127.027,
        },
      },
      {
        'id': 'cafe_1',
        'name': '달콤 카페',
        'category': '카페',
        'address': '서울시 서초구 서초대로 45',
        'latitude': 37.492,
        'longitude': 127.015,
        'rating': 4.2,
        'image_url': 'https://picsum.photos/200/300?dummy-cafe',
        'data': {
          'address': '서울시 서초구 서초대로 45',
          'latitude': 37.492,
          'longitude': 127.015,
        },
      },
      {
        'id': 'content_1',
        'name': '전시회 A',
        'category': '콘텐츠',
        'address': '서울시 용산구 이태원로 99',
        'latitude': 37.534,
        'longitude': 126.994,
        'rating': '4.8',
        'image_url': 'https://picsum.photos/200/300?dummy-exhibit',
        'data': {
          'address': '서울시 용산구 이태원로 99',
          'latitude': 37.534,
          'longitude': 126.994,
        },
      },
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChooseTemplateScreen(
          selected: dummySelected,
          selectedPlacesWithData: dummySelectedPlacesWithData,
          categoryIdByName: {
            '음식점': 'restaurant_1',
            '카페': 'cafe_1',
            '콘텐츠': 'content_1',
          },
          originAddress: '서울시 강남구 삼성로 100',
          originDetailAddress: '삼성동 더미 오피스 20층',
          orderedPlaces: dummyOrderedPlaces,
        ),
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
