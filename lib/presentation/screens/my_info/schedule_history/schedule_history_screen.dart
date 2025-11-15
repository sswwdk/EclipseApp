import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/history_service.dart';
import '../../../../shared/helpers/token_manager.dart';
import '../../../widgets/app_title_widget.dart';
import 'schedule_history_normal_detail_screen.dart';
import 'schedule_history_template1_detail_screen.dart';
import 'schedule_history_template2_detail_screen.dart';
import 'schedule_history_template3_detail_screen.dart';

class ScheduleHistoryScreen extends StatefulWidget {
  const ScheduleHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleHistoryScreen> createState() => _ScheduleHistoryScreenState();
}

class _ScheduleHistoryScreenState extends State<ScheduleHistoryScreen>
    with SingleTickerProviderStateMixin {
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

      final response = await HistoryService.getMyHistory(userId);

      if (!mounted) return;

      final List<_ScheduleHistoryItem> scheduleItems = [];
      final List<_ScheduleHistoryItem> otherItems = [];

      List<dynamic> data = [];

      data =
          response['data'] as List<dynamic>? ??
          response['histories'] as List<dynamic>? ??
          response['items'] as List<dynamic>? ??
          response['history'] as List<dynamic>? ??
          [];

      if (data.isEmpty) {
        for (final value in response.values) {
          if (value is List && value.isNotEmpty) {
            data = value;
            break;
          }
        }
      }

      for (final item in data) {
        try {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final itemMap = item;

          final id =
              itemMap['id']?.toString() ??
              itemMap['history_id']?.toString() ??
              itemMap['merge_history_id']?.toString() ??
              '';
          final categoriesName =
              itemMap['categories_name']?.toString() ??
              itemMap['category_name']?.toString() ??
              itemMap['name']?.toString() ??
              '';

          String dateStr = '';
          if (itemMap['visited_at'] != null) {
            final visitedAt = itemMap['visited_at'];
            if (visitedAt is String) {
              dateStr = visitedAt;
            } else if (visitedAt is Map) {
              if (visitedAt.containsKey('year') &&
                  visitedAt.containsKey('month') &&
                  visitedAt.containsKey('day')) {
                final year = visitedAt['year']?.toString() ?? '';
                final month =
                    visitedAt['month']?.toString().padLeft(2, '0') ?? '';
                final day = visitedAt['day']?.toString().padLeft(2, '0') ?? '';
                dateStr = '$year-$month-$day';
              } else {
                dateStr =
                    visitedAt['date']?.toString() ??
                    visitedAt['iso']?.toString() ??
                    visitedAt.toString();
              }
            } else {
              dateStr = visitedAt.toString();
            }
          } else if (itemMap['date'] != null) {
            dateStr = itemMap['date'].toString();
          }

          String formattedDate = _formatDate(dateStr);

          // 🔥 template_type 추출
          int templateType = 0;
          final templateTypeValue =
              itemMap['template_type'] ?? itemMap['templateType'];
          if (templateTypeValue != null) {
            if (templateTypeValue is int) {
              templateType = templateTypeValue;
            } else if (templateTypeValue is String) {
              templateType = int.tryParse(templateTypeValue) ?? 0;
            }
          }

          final historyItem = _ScheduleHistoryItem(
            id: id.isNotEmpty
                ? id
                : DateTime.now().millisecondsSinceEpoch.toString(),
            dateText: formattedDate.isNotEmpty ? formattedDate : '날짜 없음',
            scheduleTitle: categoriesName.isNotEmpty ? categoriesName : null,
            templateType: templateType, // 🔥 추가
          );

          bool isScheduleType;
          if (templateTypeValue != null) {
            int? parsedInt;
            if (templateTypeValue is int) {
              parsedInt = templateTypeValue;
            } else if (templateTypeValue is String) {
              parsedInt = int.tryParse(templateTypeValue);
            }

            if (parsedInt != null) {
              // 0: "그냥" 탭, 나머지는 일정표 템플릿으로 분류
              isScheduleType = parsedInt != 0;
            } else {
              final String t = templateTypeValue
                  .toString()
                  .trim()
                  .toLowerCase();
              if (t == 'just' || t == 'other') {
                isScheduleType = false;
              } else {
                isScheduleType = true;
              }
            }
          } else {
            // 템플릿 타입 정보가 없으면 기존 휴리스틱 사용
            isScheduleType =
                !(itemMap.containsKey('schedule_title') ||
                    itemMap.containsKey('places'));
          }

          if (isScheduleType) {
            scheduleItems.add(historyItem);
          } else {
            otherItems.add(historyItem);
          }
        } catch (e, stackTrace) {
          print('❌ 아이템 파싱 오류: $e');
          print('   스택 트레이스: $stackTrace');
          print('   아이템: $item');
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

  /// 날짜 형식 변환 (ISO 형식 -> YYYY.MM.DD HH:mm)
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      DateTime dateTime;

      // ISO 형식 또는 다양한 날짜 형식 파싱
      if (dateStr.contains('T')) {
        // ISO 형식: 2025-11-05T15:30:45 또는 2025-11-05T15:30:45.000Z
        dateTime = DateTime.parse(dateStr);
      } else if (dateStr.contains(' ')) {
        // 공백 포함 형식: 2025-11-05 15:30:45
        dateTime = DateTime.parse(dateStr);
      } else {
        // 날짜만 있는 경우: 2025-11-05
        dateTime = DateTime.parse(dateStr);
      }

      // YYYY.MM.DD HH:mm 형식으로 변환 (초 제외)
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
        title: const AppTitleWidget('일정표 히스토리'),
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
                  Tab(text: '템플릿 일정표'),
                  Tab(text: '일반 일정표'),
                ],
              ),
              Container(height: 1, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.primaryColor,
        child: TabBarView(
          controller: _tabController,
          children: [_buildScheduleTab(), _buildOtherTab()],
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
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
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
        child: Divider(color: AppTheme.dividerColor, thickness: 1),
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
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
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
        return _buildScheduleCard(item, isNormalTab: true); // "그냥" 탭임을 표시
      },
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: AppTheme.dividerColor, thickness: 1),
      ),
      itemCount: _otherItems.length,
    );
  }

  Widget _buildScheduleCard(
    _ScheduleHistoryItem item, {
    bool isNormalTab = false,
  }) {
    List<String> places = [];
    if (item.scheduleTitle != null && item.scheduleTitle!.isNotEmpty) {
      final separator = isNormalTab ? ',' : '→';
      places = item.scheduleTitle!
          .split(separator)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return InkWell(
      onTap: () => isNormalTab
          ? _navigateToNormalDetail(item.id)
          : _navigateToScheduleDetail(
              item.id,
              item.templateType,
            ), // 🔥 templateType 전달
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Text(
                item.dateText,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (places.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: isNormalTab
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: places
                            .map(
                              (place) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $place',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFFF8126),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(places.length * 2 - 1, (index) {
                          if (index % 2 == 0) {
                            final placeIndex = index ~/ 2;
                            return Text(
                              places[placeIndex],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF8126),
                              ),
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '→',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFF8126),
                                ),
                              ),
                            );
                          }
                        }),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  /// 히스토리 상세 화면으로 이동 (일정표 탭)
  void _navigateToScheduleDetail(String historyId, int templateType) {
    // 🔥 template_type에 따라 다른 화면으로 이동
    if (templateType == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScheduleHistoryTemplate2DetailScreen(historyId: historyId),
        ),
      );
    } else if (templateType == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScheduleHistoryTemplate3DetailScreen(historyId: historyId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScheduleHistoryDetailScreen(historyId: historyId),
        ),
      );
    }
  }

  /// "그냥" 탭 히스토리 상세 화면으로 이동
  void _navigateToNormalDetail(String historyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScheduleHistoryNormalDetailScreen(historyId: historyId),
      ),
    );
  }
}

class _ScheduleHistoryItem {
  final String id;
  final String dateText;
  final String? scheduleTitle;
  final int templateType;

  const _ScheduleHistoryItem({
    required this.id,
    required this.dateText,
    this.scheduleTitle,
    this.templateType = 0,
  });
}
