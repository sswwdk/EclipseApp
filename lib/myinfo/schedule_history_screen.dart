import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/token_manager.dart';

class ScheduleHistoryScreen extends StatefulWidget {
  const ScheduleHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleHistoryScreen> createState() => _ScheduleHistoryScreenState();
}

class _ScheduleHistoryScreenState extends State<ScheduleHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _errorMessage;
  List<_ScheduleHistoryItem> _scheduleItems = const [];
  List<_ScheduleHistoryItem> _otherItems = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = TokenManager.userId;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _loading = false;
        });
        return;
      }

      // 서버에서 히스토리 데이터 가져오기
      final response = await HistoryService.getMyHistory(userId);

      if (!mounted) return;

      // 서버 응답 파싱
      final List<_ScheduleHistoryItem> scheduleItems = [];
      final List<_ScheduleHistoryItem> otherItems = [];

      // 서버 응답 형식에 따라 파싱
      // 예상 응답 형식:
      // {
      //   "schedules": [...],  // 일정표 탭 데이터
      //   "others": [...]      // 그냥 탭 데이터
      // }
      // 또는
      // {
      //   "data": [
      //     {"type": "schedule", ...},
      //     {"type": "other", ...}
      //   ]
      // }

      final schedules = response['schedules'] as List<dynamic>? ?? [];
      final others = response['others'] as List<dynamic>? ?? [];
      
      // schedules가 없으면 data에서 type별로 분류
      if (schedules.isEmpty && others.isEmpty) {
        final data = response['data'] as List<dynamic>? ?? [];
        for (final item in data) {
          final itemMap = item as Map<String, dynamic>;
          final type = itemMap['type'] as String? ?? 'schedule';
          final id = itemMap['id']?.toString() ?? itemMap['history_id']?.toString() ?? '';
          final date = itemMap['date'] as String? ?? '';
          final scheduleTitle = itemMap['schedule_title'] as String? ?? itemMap['title'] as String? ?? '';
          
          final historyItem = _ScheduleHistoryItem(
            id: id,
            dateText: _formatDate(date),
            scheduleTitle: scheduleTitle,
          );

          if (type == 'other' || type == '그냥') {
            otherItems.add(historyItem);
          } else {
            scheduleItems.add(historyItem);
          }
        }
      } else {
        // schedules와 others로 명시적으로 분리된 경우
        for (final item in schedules) {
          final itemMap = item as Map<String, dynamic>;
          scheduleItems.add(_ScheduleHistoryItem(
            id: itemMap['id']?.toString() ?? itemMap['history_id']?.toString() ?? '',
            dateText: _formatDate(itemMap['date'] as String? ?? ''),
            scheduleTitle: itemMap['schedule_title'] as String? ?? itemMap['title'] as String? ?? '',
          ));
        }

        for (final item in others) {
          final itemMap = item as Map<String, dynamic>;
          otherItems.add(_ScheduleHistoryItem(
            id: itemMap['id']?.toString() ?? itemMap['history_id']?.toString() ?? '',
            dateText: _formatDate(itemMap['date'] as String? ?? ''),
            scheduleTitle: itemMap['schedule_title'] as String? ?? itemMap['title'] as String? ?? '',
          ));
        }
      }

      if (!mounted) return;

      setState(() {
        _scheduleItems = scheduleItems;
        _otherItems = otherItems;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      print('❌ 히스토리 로드 실패: $e');
      setState(() {
        _errorMessage = '일정표 히스토리를 불러오는 중 오류가 발생했습니다.';
        _loading = false;
      });
    }
  }

  /// 날짜 형식 변환 (YYYY-MM-DD -> YYYY.MM.DD)
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      // YYYY-MM-DD 형식을 YYYY.MM.DD로 변환
      return dateStr.replaceAll('-', '.');
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          '일정표 히스토리',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '일정표'),
                  Tab(text: '그냥'),
                ],
              ),
              Container(
                height: 1,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.primaryColor,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildScheduleTab(),
            _buildOtherTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_scheduleItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '저장된 일정표가 없습니다.',
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemBuilder: (context, index) {
        final item = _scheduleItems[index];
        return _buildScheduleCard(item);
      },
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(
          color: AppTheme.dividerColor,
          thickness: 1,
        ),
      ),
      itemCount: _scheduleItems.length,
    );
  }

  Widget _buildOtherTab() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_otherItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '저장된 내용이 없습니다.',
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemBuilder: (context, index) {
        final item = _otherItems[index];
        return _buildScheduleCard(item);
      },
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(
          color: AppTheme.dividerColor,
          thickness: 1,
        ),
      ),
      itemCount: _otherItems.length,
    );
  }

  Widget _buildScheduleCard(_ScheduleHistoryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.dateText,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // 일정표 정보
            if (item.scheduleTitle != null)
              Container(
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
                        item.scheduleTitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleHistoryItem {
  final String id;
  final String dateText;
  final String? scheduleTitle;

  const _ScheduleHistoryItem({
    required this.id,
    required this.dateText,
    this.scheduleTitle,
  });
}


