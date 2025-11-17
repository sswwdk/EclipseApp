import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/helpers/token_manager.dart';
import 'schedule_select_screen.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/app_title_widget.dart';
import '../../widgets/reviewable_stores_dropdown.dart';
import '../main/main_screen.dart';
import '../my_info/schedule_history/schedule_history_screen.dart';
import '../my_info/schedule_history/schedule_history_template1_detail_screen.dart';
import '../my_info/schedule_history/schedule_history_template2_detail_screen.dart';
import '../my_info/schedule_history/schedule_history_template3_detail_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/reviewable_store.dart';
import '../../../data/models/restaurant.dart';
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

  // 오늘의 추천 데이터
  List<Restaurant> _recommendations = [];
  bool _isLoadingRecommendations = false;

  // 알림 드롭다운 상태
  final GlobalKey _notificationKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;


  @override
  void initState() {
    super.initState();
    _loadRecentSchedule();
    _loadTodayRecommendations();
  }

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
  }

  Future<void> _loadRecentSchedule() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      // /today-recommendations API에서 히스토리 리스트 가져오기
      // 응답 형식: [히스토리 리스트, 추천 데이터]
      final response = await ApiService.getTodayRecommendations();
      
      if (!mounted) return;
      
      final List<dynamic> histories =
          (response['histories'] as List<dynamic>?) ?? [];
      
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🖥️ [최근 일정] 화면 데이터 처리 시작');
      debugPrint('📝 [최근 일정] 받은 히스토리 개수: ${histories.length}');
      
      if (histories.isNotEmpty) {
        debugPrint('📝 [최근 일정] 첫 번째 히스토리 데이터:');
        debugPrint('   ${histories[0]}');
      }

      if (histories.isNotEmpty) {
        final firstHistory = histories[0] as Map<String, dynamic>;
        
        // 히스토리에서 일정 제목 추출
        final scheduleTitle =
            firstHistory['schedule_title']?.toString() ??
            firstHistory['title']?.toString() ??
            '';
        
        // categories_name 추출 (날짜 대신 표시할 텍스트)
        final categoriesName =
            firstHistory['categories_name']?.toString() ??
            firstHistory['category_name']?.toString() ??
            '';
        
        // 히스토리 ID 추출
        final historyId =
            firstHistory['id']?.toString() ??
            firstHistory['history_id']?.toString() ??
            firstHistory['merge_history_id']?.toString() ??
            '';
        
        // template_type 추출 (상세 화면 이동 시 필요)
        final templateType = firstHistory['template_type'] is int
            ? firstHistory['template_type'] as int
            : (firstHistory['template_type'] is String
                ? int.tryParse(firstHistory['template_type'] as String) ?? 0
                : 0);

        debugPrint('🖥️ [최근 일정] 화면에 표시할 데이터:');
        debugPrint('   - 제목: $scheduleTitle');
        debugPrint('   - categories_name: $categoriesName');
        debugPrint('   - ID: $historyId');
        debugPrint('   - template_type: $templateType');
        debugPrint('✅ [최근 일정] 화면 데이터 처리 완료');
        debugPrint('═══════════════════════════════════════════════════════');

        if (!mounted) return;
        
        setState(() {
          _recentSchedule = {
            'title': scheduleTitle,
            'date': categoriesName, // categories_name을 date 필드에 저장
            'id': historyId,
            'template_type': templateType, // template_type 추가
          };
          _isLoadingHistory = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 최근 일정 로드 오류: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  /// 오늘의 추천 데이터 로드
  Future<void> _loadTodayRecommendations() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final response = await ApiService.getTodayRecommendations();
      
      if (!mounted) return;

      final recommendations = response['recommendations'] as List<dynamic>? ?? [];
      
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🖥️ [오늘의 추천] 화면 데이터 처리 시작');
      debugPrint('📝 [오늘의 추천] 받은 추천 데이터 개수: ${recommendations.length}');
      
      if (recommendations.isNotEmpty) {
        debugPrint('📝 [오늘의 추천] 첫 번째 추천 데이터:');
        debugPrint('   ${recommendations[0]}');
      }
      
      // 추천 데이터를 Restaurant 객체로 변환
      final restaurants = <Restaurant>[];
      for (final item in recommendations) {
        if (item is Map<String, dynamic>) {
          try {
            // Restaurant.fromMainScreenJson 사용 (메인 화면 형식과 동일)
            final restaurant = Restaurant.fromMainScreenJson(item);
            restaurants.add(restaurant);
            debugPrint('✅ [오늘의 추천] 데이터 파싱 성공: ${restaurant.name} (ID: ${restaurant.id})');
          } catch (e) {
            debugPrint('⚠️ [오늘의 추천] 데이터 파싱 오류: $e');
            debugPrint('   데이터: $item');
          }
        } else {
          debugPrint('⚠️ [오늘의 추천] 데이터가 Map 형식이 아님: ${item.runtimeType}');
        }
      }

      debugPrint('📊 [오늘의 추천] 최종 Restaurant 개수: ${restaurants.length}');
      
      if (restaurants.isNotEmpty) {
        debugPrint('🖥️ [오늘의 추천] 화면에 표시할 데이터:');
        debugPrint('   - 첫 번째 추천: ${restaurants[0].name}');
        debugPrint('   - ID: ${restaurants[0].id}');
        debugPrint('   - 평점: ${restaurants[0].rating ?? restaurants[0].averageStars ?? "없음"}');
      } else {
        debugPrint('⚠️ [오늘의 추천] 표시할 데이터가 없습니다');
      }
      
      debugPrint('✅ [오늘의 추천] 화면 데이터 처리 완료');
      debugPrint('═══════════════════════════════════════════════════════');

      if (!mounted) return;
      
      setState(() {
        _recommendations = restaurants;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      debugPrint('❌ 오늘의 추천 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
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

      // 매장 정보는 필요할 때 개별 조회 (일괄 조회 API 없음)

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
      if (mounted) {
        setState(() => _isDropdownOpen = true);
      }
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
    if (mounted) {
      setState(() => _isDropdownOpen = true);
    }
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
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
          ),
        ),
      );

      final restaurant = await ApiService.getRestaurant(store.categoryId);

      if (!mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (!mounted) return;

      // 리뷰 작성 화면으로 이동
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailReviewScreen(
            restaurant: restaurant,
            showReviewButton: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기 (에러 시)
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
        backgroundColor: const Color(0xFFFFF5E6), // 연한 크림/피치 톤 (이미지와 조화로운 색상)
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
          title: const AppTitleWidget('오늘 뭐하지?', color: Colors.white),
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
                    builder: (context) => const ScheduleHistoryScreen(),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            
            return Stack(
              children: [
                // 배경 이미지 (z-index 낮음)
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.5), // 이미지를 중앙 위쪽에 배치
                    child: Image.asset(
                      'assets/images/image.png',
                      width: screenWidth * 1.0,
                      height: screenHeight * 0.6,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(
                          width: screenWidth * 1.2,
                          height: screenHeight * 0.9,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 160,
                            color: AppTheme.textSecondaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 컨텐츠 레이어
                Padding(
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
                        '특별한 하루를 만들어봐요!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(), // 남은 공간을 모두 차지하여 카드들을 하단으로 밀어냄
                      // 오늘의 추천 카드 (이미지 위에 겹치게)
                      _buildRecommendationCard(),
                      const SizedBox(height: 16),
                      // 최근 일정 카드 (이미지 위에 겹치게)
                      _buildRecentScheduleCard(),
                      const SizedBox(height: 24),
                      // 메인 버튼
                      _buildMainButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _selectedIndex,
          fromScreen: 'make_todo',
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    // 화면 렌더링 시점 로그
    debugPrint('🖼️ [오늘의 추천] 카드 렌더링');
    debugPrint('   - 로딩 중: $_isLoadingRecommendations');
    debugPrint('   - 추천 개수: ${_recommendations.length}');
    if (_recommendations.isNotEmpty) {
      debugPrint('   - 표시할 이름: ${_recommendations[0].name}');
    } else {
      debugPrint('   - 표시할 텍스트: "내 위치 기반 추천 할 일"');
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), // 투명도 적용
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
                _isLoadingRecommendations
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
                        ),
                      )
                    : _recommendations.isNotEmpty
                        ? Text(
                            _recommendations[0].name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text(
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
    // 화면 렌더링 시점 로그
    debugPrint('🖼️ [최근 일정] 카드 렌더링');
    debugPrint('   - 로딩 중: $_isLoadingHistory');
    debugPrint('   - 일정 데이터: $_recentSchedule');
    if (_recentSchedule != null) {
      debugPrint('   - 표시할 제목: ${_recentSchedule!['title']}');
      debugPrint('   - 표시할 날짜: ${_recentSchedule!['date']}');
    } else {
      debugPrint('   - 표시할 텍스트: "일정이 없습니다"');
    }
    
    if (_isLoadingHistory) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85), // 투명도 적용
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
          color: Colors.white.withOpacity(0.85), // 투명도 적용
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
        color: Colors.white.withOpacity(0.85), // 투명도 적용
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
                  _recentSchedule!['date']?.toString() ?? '', // categories_name 표시
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              final historyId = _recentSchedule!['id']?.toString() ?? '';
              final templateType = _recentSchedule!['template_type'] as int? ?? 0;
              
              // template_type에 따라 다른 상세 화면으로 이동
              if (templateType == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleHistoryTemplate2DetailScreen(
                      historyId: historyId,
                    ),
                  ),
                );
              } else if (templateType == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleHistoryTemplate3DetailScreen(
                      historyId: historyId,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleHistoryDetailScreen(
                      historyId: historyId,
                    ),
                  ),
                );
              }
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

