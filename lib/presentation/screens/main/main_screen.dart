import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../my_info/schedule_history/schedule_history_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/models/reviewable_store.dart';
import 'restaurant_detail_screen.dart';
import 'restaurant_detail_review_screen.dart';
import '../../widgets/store/store_card.dart';
import '../../widgets/app_title_widget.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/reviewable_stores_dropdown.dart';
import '../../../core/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 매장 추천 화면
  List<Restaurant> restaurants = [];
  bool isLoading = true;
  String? errorMessage;

  // 알림 드롭다운 상태
  final GlobalKey _notificationKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
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

  /// 알림 드롭다운 토글
  void _toggleNotificationDropdown() {
    if (_isDropdownOpen) {
      _removeDropdown();
    } else {
      _showDropdown();
    }
  }

  /// 알림 드롭다운 표시
  void _showDropdown() async {
    // 로딩 오버레이 먼저 표시
    _showLoadingOverlay();

    // 리뷰 작성 가능한 매장 조회
    final stores = await ApiService.getReviewableStores(limit: 6);

    // 로딩 오버레이 제거
    _removeDropdown();

    if (!mounted) return;

    final renderBox =
        _notificationKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // 🔥 드롭다운 너비
    const dropdownWidth = 360.0;

    // 🔥 화면 너비 가져오기
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔥 위치 계산: 알림 아이콘 기준 오른쪽 정렬
    // 화면 왼쪽 끝을 넘지 않도록 조정
    double leftPosition = offset.dx + size.width - dropdownWidth;
    if (leftPosition < 16) {
      leftPosition = 16; // 최소 16px 여백
    }

    // 화면 오른쪽 끝을 넘지 않도록 조정
    if (leftPosition + dropdownWidth > screenWidth - 16) {
      leftPosition = screenWidth - dropdownWidth - 16;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: leftPosition, // 🔥 수정된 위치
              top: offset.dy + size.height + 8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: dropdownWidth,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ReviewableStoresDropdown(
                    stores: stores,
                    onStoreTap: (store) {
                      _removeDropdown();
                      _navigateToStoreDetail(store);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isDropdownOpen = true);
  }

  /// 로딩 오버레이 표시
  void _showLoadingOverlay() {
    final renderBox =
        _notificationKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // 🔥 드롭다운 너비
    const dropdownWidth = 360.0;

    // 🔥 화면 너비 가져오기
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔥 위치 계산
    double leftPosition = offset.dx + size.width - dropdownWidth;
    if (leftPosition < 16) {
      leftPosition = 16;
    }
    if (leftPosition + dropdownWidth > screenWidth - 16) {
      leftPosition = screenWidth - dropdownWidth - 16;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition, // 🔥 수정된 위치
        top: offset.dy + size.height + 8,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: dropdownWidth,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isDropdownOpen = true);
  }


  /// 드롭다운 제거
  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isDropdownOpen = false);
    }
  }

  /// 매장 상세 페이지로 이동
  void _navigateToStoreDetail(ReviewableStore store) async {
    try {
      final restaurant = await ApiService.getRestaurant(store.categoryId);
      if (!mounted) return;

      // 🔥 RestaurantDetailReviewScreen으로 변경
      final shouldRefresh = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailReviewScreen(
            restaurant: restaurant,
            showReviewButton: true, // 리뷰 작성 버튼 표시
          ),
        ),
      );

      // 리뷰 작성 후 돌아온 경우 레스토랑 목록 새로고침
      if (shouldRefresh == true) {
        _loadRestaurants();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('매장 정보를 불러올 수 없습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await CommonDialogs.showConfirmation(
          context: context,
          title: '앱 종료',
          content: '앱을 종료하시겠습니까?',
          confirmText: '종료',
          cancelText: '취소',
        );

        if (shouldPop == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: _notificationKey,
            icon: Icon(
              _isDropdownOpen
                  ? Icons.rate_review
                  : Icons.rate_review_outlined,
              color: Colors.white,
            ),
            onPressed: _toggleNotificationDropdown,
          ),
          title: const AppTitleWidget('매장 추천', color: Colors.white),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white,
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
            child: Container(height: 1, color: Colors.white.withOpacity(0.3)),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
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
                        const Text(
                          '데이터를 불러올 수 없습니다',
                          style: TextStyle(
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
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _selectedIndex,
          fromScreen: 'home',
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
      tags: [if (restaurant.description != null) restaurant.description!],
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                RestaurantDetailScreen(restaurant: restaurant),
          ),
        );
      },
    );
  }
}

