import 'package:flutter/material.dart';
import 'create_post_screen.dart';
import '../../../data/services/history_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../core/theme/app_theme.dart';

class _ScheduleSummary {
  final String historyId;
  final String title;
  final String dateText;
  final List<String> categories;
  final List<Map<String, dynamic>> places;

  const _ScheduleSummary({
    required this.historyId,
    required this.title,
    required this.dateText,
    required this.categories,
    required this.places,
  });
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<_ScheduleSummary> _schedules = const [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '내 일정표',
          style: TextStyle(
            color: Color(0xFFFF8126),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8126)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSchedules,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8126),
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_schedules.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadSchedules,
      color: const Color(0xFFFF8126),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _schedules.length,
        itemBuilder: (context, index) {
          final schedule = _schedules[index];
          return _buildTodoCard(schedule);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 생성된 일정표가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '일정표를 먼저 생성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard(_ScheduleSummary todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToWritePost(todo),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 화살표 아이콘
                Row(
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 제목
                Text(
                  todo.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 날짜와 시간
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      todo.dateText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 카테고리 (카페, 음식점, 콘텐츠만 표시)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: todo.categories.isEmpty
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8126).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '일정',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF8126),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]
                      : todo.categories
                          .map(
                            (category) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8126).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFF8126),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 8),
                
                // 일정 정보
                if (todo.places.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...todo.places.map((scheduleItem) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8126),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              scheduleItem['place'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWritePost(_ScheduleSummary selectedTodo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          selectedTodo: {
            'historyId': selectedTodo.historyId,
            'title': selectedTodo.title,
            'date': selectedTodo.dateText,
            'categories': selectedTodo.categories,
            'schedule': selectedTodo.places,
          },
        ),
      ),
    );
  }

  Future<void> _loadSchedules() async {
    final userId = TokenManager.userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = '로그인이 필요합니다.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HistoryService.getMyHistory(userId);
      final historyItems = _extractHistoryItems(response);

      final List<_ScheduleSummary> schedules = [];

      for (final history in historyItems) {
        try {
          final detail = await HistoryService.getHistoryDetail(
            userId,
            history.historyId,
          );
          final parsed = _parseDetail(history, detail);
          schedules.add(parsed);
        } catch (e) {
          print('❌ 일정 상세 조회 실패 (${history.historyId}): $e');
          schedules.add(_fallbackSummary(history));
        }
      }

      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '일정표를 불러오는 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  _ScheduleSummary _parseDetail(_HistoryListItem history, Map<String, dynamic> detail) {
    final data = detail['data'] ?? detail;
    final categories = (data['categories'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final places = <Map<String, dynamic>>[];
    final categoryTags = <String>{};

    for (final category in categories) {
      final name = (category['category_name'] ??
              category['name'] ??
              category['title'])
          ?.toString()
          .trim();
      if (name != null && name.isNotEmpty) {
        places.add({'place': name});
      }

      final type = _mapCategoryType(category['category_type']);
      if (type != null) {
        categoryTags.add(type);
      }
    }

    if (places.isEmpty && history.title.isNotEmpty) {
      final segments = history.title.split('→').map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final segment in segments) {
        places.add({'place': segment});
      }
    }

    return _ScheduleSummary(
      historyId: history.historyId,
      title: history.title.isNotEmpty
          ? history.title
          : places.map((e) => e['place']).whereType<String>().join(' → '),
      dateText: history.dateText,
      categories: _sortCategories(categoryTags),
      places: places,
    );
  }

  String? _mapCategoryType(dynamic rawType) {
    int type = 0;
    if (rawType is int) {
      type = rawType;
    } else if (rawType is String) {
      type = int.tryParse(rawType) ?? 0;
    }

    switch (type) {
      case 0:
        return '음식점';
      case 1:
        return '카페';
      case 2:
        return '콘텐츠';
      default:
        return null;
    }
  }

  List<_HistoryListItem> _extractHistoryItems(Map<String, dynamic> response) {
    List<dynamic> data =
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

    final List<_HistoryListItem> items = [];

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final map = item;

      final id = map['id']?.toString() ??
          map['history_id']?.toString() ??
          map['merge_history_id']?.toString();
      if (id == null || id.isEmpty) continue;

      final title = map['categories_name']?.toString() ??
          map['category_name']?.toString() ??
          map['name']?.toString() ??
          '';

      final date = _formatDate(
        map['visited_at']?.toString() ??
            map['date']?.toString() ??
            '',
      );

      items.add(_HistoryListItem(
        historyId: id,
        title: title,
        dateText: date,
      ));
    }

    return items;
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';

    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed != null) {
      final hasTimeInfo = _hasTimeComponent(raw);
      final date = '${parsed.year}-${_padTwo(parsed.month)}-${_padTwo(parsed.day)}';
      if (!hasTimeInfo) {
        return date;
      }
      final time = '${_padTwo(parsed.hour)}:${_padTwo(parsed.minute)}';
      return '$date $time';
    }

    if (raw.contains(' ')) {
      return raw.substring(0, raw.indexOf(' '));
    }
    if (raw.contains('T')) {
      return raw.split('T').first;
    }
    return raw;
  }

  bool _hasTimeComponent(String raw) {
    if (raw.contains('T')) {
      final timePart = raw.split('T').last;
      return timePart.contains(':');
    }
    if (raw.contains(' ')) {
      final timePart = raw.split(' ').last;
      return timePart.contains(':');
    }
    return false;
  }

  String _padTwo(int value) {
    if (value >= 10) return value.toString();
    return '0$value';
  }

  List<String> _sortCategories(Set<String> categories) {
    if (categories.isEmpty) return [];
    const order = ['카페', '음식점', '콘텐츠'];
    final ordered = <String>[];
    for (final name in order) {
      if (categories.contains(name)) {
        ordered.add(name);
      }
    }
    final others = categories
        .where((c) => !order.contains(c))
        .toList()
      ..sort();
    return [...ordered, ...others];
  }

  _ScheduleSummary _fallbackSummary(_HistoryListItem history) {
    final places = history.title
        .split('→')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((name) => {'place': name})
        .toList();

    return _ScheduleSummary(
      historyId: history.historyId,
      title: history.title,
      dateText: history.dateText,
      categories: const [],
      places: places,
    );
  }
}

class _HistoryListItem {
  final String historyId;
  final String title;
  final String dateText;

  const _HistoryListItem({
    required this.historyId,
    required this.title,
    required this.dateText,
  });
}
