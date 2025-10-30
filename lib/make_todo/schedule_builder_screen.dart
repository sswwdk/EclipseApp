import 'package:flutter/material.dart';

class ScheduleBuilderScreen extends StatefulWidget {
  final Map<String, List<String>> selected; // 카테고리별 선택 목록

  const ScheduleBuilderScreen({Key? key, required this.selected}) : super(key: key);

  @override
  State<ScheduleBuilderScreen> createState() => _ScheduleBuilderScreenState();
}

class _ScheduleBuilderScreenState extends State<ScheduleBuilderScreen> {
  late List<_ScheduleItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _buildScheduleItems(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final List<_ScheduleItem> items = _items;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '일정표 만들기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return KeyedSubtree(
                key: ValueKey(item.id),
                child: _TimelineRow(
                  item: item,
                  index: index,
                  isLast: index == items.length - 1,
                  onDragHandle: item.type == _ItemType.place
                      ? (child) => ReorderableDragStartListener(index: index, child: child)
                      : null,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // 첫 항목(출발지)은 고정
              if (oldIndex == 0 || newIndex == 0) return;
              if (newIndex > oldIndex) newIndex -= 1;
              setState(() {
                final moved = _items.removeAt(oldIndex);
                _items.insert(newIndex, moved);
              });
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장하기 기능은 준비 중입니다.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFFF8126), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFFFF8126),
                  ),
                  child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공유하기 기능은 준비 중입니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8126),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('공유하기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ScheduleItem> _buildScheduleItems(Map<String, List<String>> selected) {
    final List<_ScheduleItem> items = [];
    // 출발지(집)
    items.add(_ScheduleItem(
      title: '집',
      subtitle: '출발지',
      icon: Icons.home_outlined,
      color: Colors.grey[700]!,
      type: _ItemType.origin,
    ));

    // 선택된 장소를 순서대로 나열 (카테고리 순서 유지)
    selected.forEach((category, places) {
      for (final place in places) {
        items.add(_ScheduleItem(
          title: place,
          subtitle: category,
          icon: _iconFor(category),
          color: const Color(0xFFFF8126),
          type: _ItemType.place,
          durationMinutes: items.length == 1 ? 45 : 20,
        ));
      }
    });

    return items;
  }

  IconData _iconFor(String category) {
    switch (category) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '콘텐츠':
        return Icons.movie_filter;
      default:
        return Icons.place;
    }
  }
}

enum _ItemType { origin, place }

class _ScheduleItem {
  final String id = UniqueKey().toString();
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final _ItemType type;
  final int? durationMinutes;

  _ScheduleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
    this.durationMinutes,
  });
}

class _TimelineRow extends StatelessWidget {
  final _ScheduleItem item;
  final int index;
  final bool isLast;
  final Widget Function(Widget child)? onDragHandle;

  const _TimelineRow({Key? key, required this.item, required this.index, this.isLast = false, this.onDragHandle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(item, index),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 타임라인 바
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8126),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 카드
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFE3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: const Color(0xFFFF8126)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (item.type == _ItemType.place)
                    (onDragHandle != null)
                        ? onDragHandle!(const Icon(Icons.drag_handle, color: Colors.grey, size: 18))
                        : const Icon(Icons.drag_handle, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(_ScheduleItem item, int index) {
    if (index == 0) return '';
    final minutes = item.durationMinutes ?? 20;
    return '약 $minutes\n분';
  }
}


