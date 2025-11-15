import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/helpers/token_manager.dart';
import 'schedule_select_screen.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/app_title_widget.dart';
import '../../../data/services/history_service.dart';
import '../main/main_screen.dart';
import '../my_info/schedule_history/schedule_history_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/models/reviewable_store.dart';
import '../main/restaurant_detail_review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 홈 버튼이 활성화되도록 설정
  Map<String, dynamic>? _recentSchedule;
  bool _isLoadingHistory = false;

  // 알림 드롭다운 상태
  final GlobalKey _notificationKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  // 매장 정보 캐시 (일괄 조회 결과 저장)
  Map<String, Restaurant> _restaurantCache = {};

  @override
  void initState() {
    super.initState();
    _loadRecentSchedule();
  }

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
  }

  Future<void> _loadRecentSchedule() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final userId = TokenManager.userId;
      if (userId == null) {
        setState(() {
          _isLoadingHistory = false;
        });
        return;
      }

      final response = await HistoryService.getMyHistory(userId);
      final List<dynamic> data =
          response['data'] as List<dynamic>? ??
          response['histories'] as List<dynamic>? ??
          response['items'] as List<dynamic>? ??
          [];

      if (data.isNotEmpty && mounted) {
        final firstItem = data[0] as Map<String, dynamic>;
        final categoriesName =
            firstItem['categories_name']?.toString() ??
            firstItem['category_name']?.toString() ??
            firstItem['name']?.toString() ??
            '';
        
        String dateText = '어제';
        if (firstItem['visited_at'] != null) {
          final visitedAt = firstItem['visited_at'];
          if (visitedAt is String) {
            try {
              final date = DateTime.parse(visitedAt);
              final now = DateTime.now();
              final diff = now.difference(date).inDays;
              if (diff == 0) {
                dateText = '오늘';
              } else if (diff == 1) {
                dateText = '어제';
              } else {
                dateText = '${diff}일 전';
              }
            } catch (e) {
              dateText = '어제';
            }
          }
        }

        setState(() {
          _recentSchedule = {
            'title': categoriesName,
            'date': dateText,
            'id': firstItem['id']?.toString() ??
                firstItem['history_id']?.toString() ??
                '',
          };
          _isLoadingHistory = false;
        });
      } else {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
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

      // 모든 매장 정보를 한 번에 조회 (일괄 조회)
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
      // 캐시에서 먼저 찾기 (일괄 조회로 이미 가져온 데이터)
      Restaurant? restaurant = _restaurantCache[store.categoryId];

      // 캐시에 없으면 개별 조회 (로딩 표시)
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailReviewScreen(
            restaurant: restaurant!,
            showReviewButton: true,
          ),
        ),
      );
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
          title: const AppTitleWidget('일정표 생성'),
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
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // 인사말
              Text(
                '안녕하세요 ${TokenManager.userName ?? '사용자'}님!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '새로운 하루를 만들어봐요!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 비버 캐릭터 이미지
              Image.asset(
                'assets/images/image.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: AppTheme.textSecondaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // 오늘의 추천 카드
              _buildRecommendationCard(),
              const SizedBox(height: 16),
              // 최근 일정 카드
              _buildRecentScheduleCard(),
              const SizedBox(height: 24),
              // 메인 버튼
              _buildMainButton(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _selectedIndex,
          fromScreen: 'make_todo',
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 추천',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8126),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '내 위치 기반 추천 할 일',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const MainScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryColorWithOpacity10,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '추천 보기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScheduleCard() {
    if (_isLoadingHistory) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
          ),
        ),
      );
    }

    if (_recentSchedule == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '최근 일정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8126),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '일정이 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최근 일정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8126),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_recentSchedule!['title']} ${_recentSchedule!['date']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScheduleHistoryScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryColorWithOpacity10,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '일정 열기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '오늘 할 일 만들기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
