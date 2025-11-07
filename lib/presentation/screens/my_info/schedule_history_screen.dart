import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/history_service.dart';
import '../../../shared/helpers/token_manager.dart';
import 'schedule_history_detail_screen.dart';
import 'schedule_history_normal_detail_screen.dart';

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

      // 디버깅: 전체 응답 출력
      print('🔍 전체 응답: $response');
      print('🔍 응답 타입: ${response.runtimeType}');
      print('🔍 응답 키들: ${response.keys.toList()}');

      // 서버 응답 형식: MergeUserHistory 객체들의 리스트
      // 각 객체는 {id, visited_at, categories_name} 형식
      // getMyHistory는 Map<String, dynamic>을 반환하므로 Map에서 데이터 추출
      List<dynamic> data = [];
      
      // Map에서 다양한 키로 데이터 찾기
      data = response['data'] as List<dynamic>? ?? 
             response['histories'] as List<dynamic>? ?? 
             response['items'] as List<dynamic>? ?? 
             response['history'] as List<dynamic>? ??
             [];
      
      // 만약 위의 키들에 없으면, Map의 모든 값이 리스트인 경우 찾기
      if (data.isEmpty) {
        for (final value in response.values) {
          if (value is List && value.isNotEmpty) {
            data = value;
            print('🔍 리스트 데이터를 다른 키에서 찾음: ${response.keys.where((k) => response[k] == value).join(", ")}');
            break;
          }
        }
      }
      
      print('🔍 파싱된 데이터 리스트: $data');
      print('🔍 데이터 개수: ${data.length}');
      
      for (final item in data) {
        try {
          // item이 Map인지 확인
          if (item is! Map<String, dynamic>) {
            print('⚠️ 아이템이 Map이 아님: $item (타입: ${item.runtimeType})');
            continue;
          }
          
          final itemMap = item;
          
          print('🔍 아이템 전체: $itemMap');
          print('🔍 아이템 키들: ${itemMap.keys.toList()}');
          
          // MergeUserHistory 형식 파싱
          final id = itemMap['id']?.toString() ?? 
                    itemMap['history_id']?.toString() ?? 
                    itemMap['merge_history_id']?.toString() ?? 
                    '';
          final categoriesName = itemMap['categories_name']?.toString() ?? 
                                itemMap['category_name']?.toString() ?? 
                                itemMap['name']?.toString() ?? 
                                '';
          
          // visited_at 파싱 (datetime 문자열 또는 ISO 형식)
          String dateStr = '';
          if (itemMap['visited_at'] != null) {
            final visitedAt = itemMap['visited_at'];
            if (visitedAt is String) {
              dateStr = visitedAt;
            } else if (visitedAt is Map) {
              // Python datetime 객체가 Map으로 올 수 있음
              // {year: 2025, month: 11, day: 5} 형식일 수 있음
              if (visitedAt.containsKey('year') && visitedAt.containsKey('month') && visitedAt.containsKey('day')) {
                final year = visitedAt['year']?.toString() ?? '';
                final month = visitedAt['month']?.toString().padLeft(2, '0') ?? '';
                final day = visitedAt['day']?.toString().padLeft(2, '0') ?? '';
                dateStr = '$year-$month-$day';
              } else {
                dateStr = visitedAt['date']?.toString() ?? visitedAt['iso']?.toString() ?? visitedAt.toString();
              }
            } else {
              dateStr = visitedAt.toString();
            }
          } else if (itemMap['date'] != null) {
            // date 필드도 확인
            dateStr = itemMap['date'].toString();
          }
          
          print('🔍 아이템 파싱 결과: id=$id, categories_name=$categoriesName, visited_at=$dateStr');
          
          // 날짜 형식 변환 (YYYY-MM-DD 형식으로 추출)
          String formattedDate = _formatDate(dateStr);
          
          final historyItem = _ScheduleHistoryItem(
            id: id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
            dateText: formattedDate.isNotEmpty ? formattedDate : '날짜 없음',
            scheduleTitle: categoriesName.isNotEmpty ? categoriesName : null,
          );
          
          // 1) 휴리스틱: 'schedule_title' 등이 있으면 기본값을 '그냥'으로 간주
          bool isScheduleType = !(itemMap.containsKey('schedule_title') || itemMap.containsKey('places'));
          
          // 2) template_type 값이 있으면 그것으로 명시적으로 덮어씀
          final templateTypeValue = itemMap['template_type'] ?? itemMap['templateType'] ?? itemMap['type'];
          if (templateTypeValue != null) {
            final String t = templateTypeValue.toString().trim().toLowerCase();
            if (t == '0' || t == 'default' || t == 'travel_planning') {
              isScheduleType = true;
            } else if (t == '1' || t == 'just' || t == 'other') {
              isScheduleType = false;
            }
          }
          
          print('🔎 분류: template_type=${templateTypeValue}, isScheduleType=$isScheduleType, has_schedule_title=${itemMap.containsKey('schedule_title')}');
          
          if (isScheduleType) {
            scheduleItems.add(historyItem);
            print('✅ 일정표 탭에 추가: $categoriesName');
          } else {
            otherItems.add(historyItem);
            print('✅ 그냥 탭에 추가: $categoriesName');
          }
        } catch (e, stackTrace) {
          print('❌ 아이템 파싱 오류: $e');
          print('   스택 트레이스: $stackTrace');
          print('   아이템: $item');
        }
      }
      
      print('🔍 최종 결과 - 일정표: ${scheduleItems.length}개, 그냥: ${otherItems.length}개');

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

  /// 날짜 형식 변환 (YYYY-MM-DD 또는 ISO 형식 -> YYYY.MM.DD)
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      // ISO 형식 (2025-11-05T00:00:00)에서 날짜 부분만 추출
      String datePart = dateStr;
      if (dateStr.contains('T')) {
        datePart = dateStr.split('T')[0];
      } else if (dateStr.contains(' ')) {
        datePart = dateStr.split(' ')[0];
      }
      
      // YYYY-MM-DD 형식을 YYYY.MM.DD로 변환
      if (datePart.contains('-')) {
        return datePart.replaceAll('-', '.');
      }
      return datePart;
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
        return _buildScheduleCard(item, isNormalTab: true); // "그냥" 탭임을 표시
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

  Widget _buildScheduleCard(_ScheduleHistoryItem item, {bool isNormalTab = false}) {
    // scheduleTitle을 화살표 또는 쉼표 기준으로 분리
    List<String> places = [];
    if (item.scheduleTitle != null && item.scheduleTitle!.isNotEmpty) {
      // "그냥" 탭은 쉼표로, "일정표" 탭은 화살표로 분리
      final separator = isNormalTab ? ',' : '→';
      places = item.scheduleTitle!.split(separator).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return InkWell(
      onTap: () => isNormalTab 
          ? _navigateToNormalDetail(item.id)  // "그냥" 탭은 새 화면으로
          : _navigateToScheduleDetail(item.id), // "일정표" 탭은 기존 화면으로
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
            // 날짜 표시
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
            // 일정표 정보 (화살표로 연결 또는 리스트 형식)
            if (places.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E8), // 연한 주황색 배경
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3), // 얇은 주황색 테두리
                    width: 1,
                  ),
                ),
                // "그냥" 탭: 리스트 형식, "일정표" 탭: 화살표 형식
                child: isNormalTab
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: places.map((place) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $place',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFF8126),
                            ),
                          ),
                        )).toList(),
                      )
                    : Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(places.length * 2 - 1, (index) {
                          if (index % 2 == 0) {
                            // 장소 이름
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
                            // 화살표
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
  void _navigateToScheduleDetail(String historyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleHistoryDetailScreen(
          historyId: historyId,
        ),
      ),
    );
  }

  /// "그냥" 탭 히스토리 상세 화면으로 이동
  void _navigateToNormalDetail(String historyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleHistoryNormalDetailScreen(
          historyId: historyId,
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


