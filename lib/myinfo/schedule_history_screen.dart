import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/token_manager.dart';

class ScheduleHistoryScreen extends StatefulWidget {
  const ScheduleHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleHistoryScreen> createState() => _ScheduleHistoryScreenState();
}

class _ScheduleHistoryScreenState extends State<ScheduleHistoryScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<_ScheduleHistoryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = TokenManager.userId ?? '';
      if (userId.isEmpty) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _loading = false;
        });
        return;
      }

      final data = await HistoryService.getMyHistory(userId);
      if (!mounted) return;
      setState(() {
        _items = _ScheduleHistoryItem.parseList(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
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
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

    if (_items.isEmpty) {
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
        final item = _items[index];
        return _buildScheduleCard(item);
      },
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(
          color: AppTheme.dividerColor,
          thickness: 1,
        ),
      ),
      itemCount: _items.length,
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
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(item.imageUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _imagePlaceholder(loading: true);
        },
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder({bool loading = false}) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: loading
            ? const CircularProgressIndicator(color: AppTheme.primaryColor)
            : Icon(Icons.image, color: Colors.grey[400], size: 48),
      ),
    );
  }
}

class _ScheduleHistoryItem {
  final String id;
  final String dateText;
  final String? imageUrl;

  const _ScheduleHistoryItem({required this.id, required this.dateText, this.imageUrl});

  static List<_ScheduleHistoryItem> parseList(dynamic response) {
    List<dynamic> items;
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      // 가능한 키들에 유연하게 대응
      final dynamic data = response['data'] ?? response['histories'] ?? response['items'] ?? response['body'];
      if (data is List) {
        items = data;
      } else {
        items = [];
      }
    } else {
      items = [];
    }

    return items.whereType<Map<String, dynamic>>().map((m) {
      final String id = (m['id'] ?? m['history_id'] ?? '').toString();
      final String date = (m['created_at'] ?? m['createdAt'] ?? m['date'] ?? '').toString();
      final String? img = (m['image_url'] ?? m['image'] ?? m['thumbnail'] ?? m['photo'])?.toString();
      return _ScheduleHistoryItem(
        id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
        dateText: date.isEmpty ? '날짜 정보 없음' : date,
        imageUrl: (img != null && img.isNotEmpty) ? img : null,
      );
    }).toList();
  }
}


