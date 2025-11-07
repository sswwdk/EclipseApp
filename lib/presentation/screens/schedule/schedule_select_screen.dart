import 'package:flutter/material.dart';
import 'schedule_chat_screen.dart';
import '../../../core/theme/app_theme.dart';

/// 위치 입력 화면
class LocationInputScreen extends StatefulWidget {
  const LocationInputScreen({super.key});

  @override
  State<LocationInputScreen> createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _proceedToNext() {
    final location = _locationController.text.trim();
    
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치를 입력해주세요.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 위치 출력
    // ignore: avoid_print
    print('위치 : $location');

    // 인원 수 선택 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PeopleCountScreen(location: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '위치를 입력해주세요!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '서울특별시만 지원하는 서비스 입니다.\n원하는 지역(구)을 입력해주세요.\n 나중에 이거는 지도에서 찍는 걸로 바꿀지 뭘로 할지 고민해봅시다',
                    style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: '예: 강남구, 강동구, 영등포구...',
                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  onSubmitted: (_) => _proceedToNext(),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _proceedToNext,
                  child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 인원 수 선택 화면
class PeopleCountScreen extends StatefulWidget {
  final String location;
  
  const PeopleCountScreen({super.key, required this.location});

  @override
  State<PeopleCountScreen> createState() => _PeopleCountScreenState();
}

class _PeopleCountScreenState extends State<PeopleCountScreen> {
  int _count = 2;

  void _increment() => setState(() => _count++);
  void _decrement() => setState(() => _count = _count > 1 ? _count - 1 : 1);

  void _proceedToNext() {
    // 인원 수 출력
    // ignore: avoid_print
    print('인원 수 : $_count명');

    // 할 일 선택 화면으로 이동하면서 인원 수 전달
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskSelectScreen(location: widget.location, peopleCount: _count),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Text(
              '총 몇 명이 함께하시나요? (본인 포함)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '인원 수를 알려주세요.',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleIconButton(icon: Icons.remove, onTap: _decrement),
                const SizedBox(width: 28),
                Text(
                  '$_count',
                  style: const TextStyle(
                    color: Color(0xFFFF7A21),
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 28),
                _CircleIconButton(icon: Icons.add, onTap: _increment),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _proceedToNext,
                  child: const Text('할 일 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black54),
      ),
    );
  }
}

// =====================
// 할 일 선택 화면 구현
// =====================

/// 사용자가 하고 싶은 일을 복수 선택할 수 있는 화면
class TaskSelectScreen extends StatefulWidget {
  /// 이전 단계에서 선택된 위치
  final String location;
  /// 이전 단계에서 선택된 인원 수
  final int peopleCount;
  const TaskSelectScreen({super.key, required this.location, required this.peopleCount});

  @override
  State<TaskSelectScreen> createState() => _TaskSelectScreenState();
}

class _TaskSelectScreenState extends State<TaskSelectScreen> {
  // 선택 가능한 카테고리 목록 (아이콘 + 라벨)
  final List<_Category> _categories = const <_Category>[
    _Category(name: '카페', icon: Icons.local_cafe),
    _Category(name: '음식점', icon: Icons.restaurant),
    _Category(name: '콘텐츠', icon: Icons.movie_filter),
  ];

  // 사용자가 선택한 카테고리 이름 집합 (중복 선택 허용)
  final Set<String> _selected = <String>{};

  // 선택/해제 토글
  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  // 다음 단계로 진행할 수 있는지 확인
  bool get _canProceed => _selected.isNotEmpty;

  // 카테고리를 정해진 순서로 정렬하는 함수
  List<String> _sortCategories(Set<String> selected) {
    // 우선순위: 카페 -> 음식점 -> 콘텐츠
    const priorityOrder = ['카페', '음식점', '콘텐츠'];
    
    return selected.toList()
      ..sort((a, b) {
        int indexA = priorityOrder.indexOf(a);
        int indexB = priorityOrder.indexOf(b);
        
        // 우선순위 목록에 없는 경우 뒤로 배치
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;
        
        return indexA.compareTo(indexB);
      });
  }

  // 다음 단계로 진행
  void _proceedToNext() {
    if (!_canProceed) {
      // 선택하지 않았을 때 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 하나의 카테고리를 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 카테고리를 우선순위대로 정렬
    final sortedList = _sortCategories(_selected);
    
    // 선택한 카테고리 출력
    // ignore: avoid_print
    print('선택 : ${sortedList.map((e) => '"$e"').join(', ')}');

    // 채팅 화면으로 이동하여 선택한 카테고리 시각화 (정렬된 순서로 전달)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          location: widget.location,
          peopleCount: widget.peopleCount,
          selectedCategories: sortedList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '무엇을 하고 싶으신가요?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('하고 싶은 일을 골라주세요.', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  SizedBox(height: 4),
                  Text('중복 선택도 가능합니다.', style: TextStyle(fontSize: 13, color: Colors.black38)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 카테고리 선택 카드들 (가로로 3개)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: _categories
                    .map(
                      (c) => Expanded(
                        child: _CategoryCard(
                          category: c,
                          selected: _selected.contains(c.name),
                          onTap: () => _toggle(c.name),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Spacer(),
            // 하단 CTA 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed 
                        ? AppTheme.primaryColor 
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    elevation: _canProceed ? 3 : 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _canProceed ? _proceedToNext : null,
                  child: const Text('하루와 할 일 만들러 가기!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 데이터 모델 (간단한 불변 클래스)
class _Category {
  final String name;
  final IconData icon;
  const _Category({required this.name, required this.icon});
}

/// 개별 카테고리 선택 카드 위젯
class _CategoryCard extends StatelessWidget {
  final _Category category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFFFF7A21);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? accent : const Color(0x11000000), width: 2),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent.withOpacity(0.12) : const Color(0xFFF6F6F6),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(category.icon, color: selected ? accent : Colors.black38),
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


