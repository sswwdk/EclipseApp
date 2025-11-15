import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../schedule/schedule_screen.dart';
import '../my_info/my_info_screen.dart';
import '../my_info/schedule_history/schedule_history_screen.dart';
import '../community/community_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/models/reviewable_store.dart';
import 'restaurant_detail_screen.dart';
import 'restaurant_detail_review_screen.dart';
import '../../widgets/store/store_card.dart';
import '../../widgets/app_title_widget.dart';
import '../../widgets/dialogs/common_dialogs.dart';

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

  // 🔥 매장 정보 캐시 (일괄 조회 결과 저장)
  Map<String, Restaurant> _restaurantCache = {};

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

    try {
      // 리뷰 작성 가능한 매장 조회
      final stores = await ApiService.getReviewableStores(limit: 6);

      // 🔥 모든 매장 정보를 한 번에 조회 (일괄 조회)
      if (stores.isNotEmpty) {
        final ids = stores.map((s) => s.categoryId).toList();

        try {
          // 일괄 조회 API 호출
          final restaurants = await ApiService.getRestaurantsBatch(ids);

          // 캐시에 저장
          _restaurantCache.clear();
          for (var restaurant in restaurants) {
            _restaurantCache[restaurant.id] = restaurant;
          }

          debugPrint('✅ ${restaurants.length}개 매장 정보 일괄 조회 완료');
        } catch (e) {
          debugPrint('⚠️ 일괄 조회 실패: $e');
          // 일괄 조회 실패 시 개별 조회로 폴백하지 않고 진행
          // (클릭 시점에 개별 조회)
        }
      }

      // 로딩 오버레이 제거
      _removeDropdown();

      if (!mounted) return;

      final renderBox =
          _notificationKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      // 드롭다운 너비
      const dropdownWidth = 360.0;

      // 화면 너비 가져오기
      final screenWidth = MediaQuery.of(context).size.width;

      // 위치 계산: 알림 아이콘 기준 오른쪽 정렬
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
                left: leftPosition,
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
                    child: stores.isEmpty
                        ? _buildEmptyState()
                        : _buildStoreList(stores),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isDropdownOpen = true);
    } catch (e) {
      debugPrint('❌ 드롭다운 표시 오류: $e');
      _removeDropdown();
    }
  }

  /// 로딩 오버레이 표시
  void _showLoadingOverlay() {
    final renderBox =
        _notificationKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    const dropdownWidth = 360.0;
    final screenWidth = MediaQuery.of(context).size.width;

    double leftPosition = offset.dx + size.width - dropdownWidth;
    if (leftPosition < 16) {
      leftPosition = 16;
    }
    if (leftPosition + dropdownWidth > screenWidth - 16) {
      leftPosition = screenWidth - dropdownWidth - 16;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
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

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '리뷰 작성 가능한\n매장이 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '매장을 방문하고\n리뷰를 작성해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// 매장 목록 위젯
  Widget _buildStoreList(List<ReviewableStore> stores) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8126).withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.rate_review, color: Color(0xFFFF8126), size: 20),
              const SizedBox(width: 8),
              const Text(
                '리뷰 작성 가능한 매장',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8126),
                ),
              ),
            ],
          ),
        ),
        // 매장 목록
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: stores.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final store = stores[index];
              return _buildStoreItem(store);
            },
          ),
        ),
      ],
    );
  }

  /// 매장 아이템 위젯
  Widget _buildStoreItem(ReviewableStore store) {
    return InkWell(
      onTap: () {
        _removeDropdown();
        _navigateToStoreDetail(store);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 매장 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: store.imageUrl != null && store.imageUrl!.isNotEmpty
                  ? Image.network(
                      store.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 12),
            // 매장 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.categoryName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  /// 이미지 플레이스홀더 위젯
  Widget _buildPlaceholderImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: Icon(Icons.restaurant, color: Colors.grey[400], size: 24),
    );
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
      // 🔥 캐시에서 먼저 찾기 (일괄 조회로 이미 가져온 데이터)
      Restaurant? restaurant = _restaurantCache[store.categoryId];

      // 🔥 캐시에 없으면 개별 조회 (로딩 표시)
      if (restaurant == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
            ),
          ),
        );

        restaurant = await ApiService.getRestaurant(store.categoryId);

        if (!mounted) return;
        Navigator.pop(context); // 로딩 다이얼로그 닫기
      }

      if (!mounted) return;

      // 리뷰 작성 화면으로 이동
      final shouldRefresh = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailReviewScreen(
            restaurant: restaurant!,
            showReviewButton: true,
          ),
        ),
      );

      // 리뷰 작성 후 돌아온 경우 레스토랑 목록 새로고침
      if (shouldRefresh == true) {
        _loadRestaurants();
        // 캐시도 초기화
        _restaurantCache.clear();
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
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: _notificationKey,
            icon: Icon(
              _isDropdownOpen
                  ? Icons.notifications
                  : Icons.notifications_outlined,
              color: const Color(0xFFFF8126),
            ),
            onPressed: _toggleNotificationDropdown,
          ),
          title: const AppTitleWidget('할 일 추천'),
          centerTitle: true,
          actions: [
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
                setState(() => _selectedIndex = i);
              } else if (i == 1) {
                setState(() => _selectedIndex = i);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              } else if (i == 2) {
                setState(() => _selectedIndex = i);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CommunityScreen()),
                );
              } else if (i == 3) {
                setState(() => _selectedIndex = i);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MyInfoScreen(fromScreen: 'home'),
                  ),
                );
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: '할 일 생성',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: '홈',
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

class _RoundedTopNavBar extends StatelessWidget {
  final Widget child;
  const _RoundedTopNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: child,
        ),
      ),
    );
  }
}
