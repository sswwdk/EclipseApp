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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // 할 일 생성 버튼이 활성화되도록 설정
  Map<String, dynamic>? _recentSchedule;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSchedule();
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
          title: const AppTitleWidget('일정표 생성'),
          centerTitle: true,
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
