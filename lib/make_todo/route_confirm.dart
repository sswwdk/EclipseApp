import 'package:flutter/material.dart';
import 'default_template.dart';
import 'choose_template.dart';

class RouteConfirmScreen extends StatefulWidget {
  final Map<String, List<String>> selected; // 카테고리별 선택 목록

  const RouteConfirmScreen({Key? key, required this.selected}) : super(key: key);

  @override
  State<RouteConfirmScreen> createState() => _RouteConfirmScreenState();
}

class _RouteConfirmScreenState extends State<RouteConfirmScreen> {
  late List<_ScheduleItem> _items;
  String? _originAddress; // 출발지 주소
  String? _originDetailAddress; // 출발지 상세 주소

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
                  showDuration: false, // 미리보기에서는 시간 숨김
                  onDragHandle: item.type == _ItemType.place
                      ? (child) => ReorderableDragStartListener(index: index, child: child)
                      : null,
                  onTap: item.type == _ItemType.origin ? () => _showOriginAddressInput() : null,
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChooseTemplateScreen(
                      selected: {
                        for (final entry in widget.selected.entries) entry.key: List<String>.from(entry.value)
                      },
                      originAddress: _originAddress,
                      originDetailAddress: _originDetailAddress,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8126),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text(
                '경로 확정하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOriginAddressInput() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OriginAddressInputScreen(
          initialAddress: _originAddress,
          initialDetailAddress: _originDetailAddress,
        ),
      ),
    );

    if (result != null && result is Map<String, String?>) {
      setState(() {
        _originAddress = result['address'];
        _originDetailAddress = result['detailAddress'];
        _items = _buildScheduleItems(widget.selected);
      });
    }
  }

  List<_ScheduleItem> _buildScheduleItems(Map<String, List<String>> selected) {
    final List<_ScheduleItem> items = [];
    // 출발지(집)
    String originTitle = '현재 위치';
    String originSubtitle = '출발지';

    if (_originAddress != null && _originAddress!.isNotEmpty) {
      if (_originDetailAddress != null && _originDetailAddress!.isNotEmpty) {
        originTitle = '$_originAddress $_originDetailAddress';
      } else {
        originTitle = _originAddress!;
      }
      originSubtitle = '출발지';
    }

    items.add(_ScheduleItem(
      title: originTitle,
      subtitle: originSubtitle,
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
  final bool showDuration;
  final VoidCallback? onTap;

  const _TimelineRow({Key? key, required this.item, required this.index, this.isLast = false, this.onDragHandle, this.showDuration = true, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double leftInfoWidth = showDuration ? 56 : 20;
    final double gapBetween = showDuration ? 12 : 6;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: leftInfoWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  showDuration ? _formatDuration(item, index) : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(width: gapBetween),
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
          Expanded(
            child: GestureDetector(
              onTap: onTap,
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
                  if (item.type == _ItemType.place && onDragHandle != null)
                    onDragHandle!(const Icon(Icons.drag_handle, color: Colors.grey, size: 18)),
                  if (item.type == _ItemType.origin && onTap != null)
                    const Icon(Icons.edit, color: Colors.grey, size: 18),
                ],
              ),
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

// 출발지 주소 입력 화면 (미리보기 단계에서 사용)
class OriginAddressInputScreen extends StatefulWidget {
  final String? initialAddress;
  final String? initialDetailAddress;

  const OriginAddressInputScreen({Key? key, this.initialAddress, this.initialDetailAddress}) : super(key: key);

  @override
  State<OriginAddressInputScreen> createState() => _OriginAddressInputScreenState();
}

class _OriginAddressInputScreenState extends State<OriginAddressInputScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailAddressController = TextEditingController();
  final FocusNode _detailAddressFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';
    _detailAddressController.text = widget.initialDetailAddress ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _detailAddressController.dispose();
    _detailAddressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) {
      _showSnackBar('주소를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pop(
        context,
        {
          'address': _addressController.text.trim(),
          'detailAddress': _detailAddressController.text.trim(),
        },
      );
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('주소 저장 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '출발지 입력',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8126)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_detailAddressFocusNode),
                    decoration: InputDecoration(
                      hintText: '예: 서울시 강남구 테헤란로 123',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _detailAddressController,
                    focusNode: _detailAddressFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveAddress(),
                    decoration: InputDecoration(
                      hintText: '상세 주소 (건물명, 동/호수 등)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8126),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}


