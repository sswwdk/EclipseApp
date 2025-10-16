import 'package:flutter/material.dart';
import 'make_todo_chat.dart';

class PeopleCountScreen extends StatefulWidget {
  const PeopleCountScreen({super.key});

  @override
  State<PeopleCountScreen> createState() => _PeopleCountScreenState();
}

class _PeopleCountScreenState extends State<PeopleCountScreen> {
  int _count = 2;

  void _increment() => setState(() => _count++);
  void _decrement() => setState(() => _count = _count > 1 ? _count - 1 : 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 16),
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
                    backgroundColor: const Color(0xFFFF7A21),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // 인원 수를 콘솔에 요청된 형식으로 출력
                    // 예시) 인원 수 : 2명
                    // ignore: avoid_print
                    print('인원 수 : $_count명');

                    // 할 일 선택 화면으로 이동하면서 인원 수 전달
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskSelectScreen(peopleCount: _count),
                      ),
                    );
                  },
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
  /// 이전 단계에서 선택된 인원 수
  final int peopleCount;
  const TaskSelectScreen({super.key, required this.peopleCount});

  @override
  State<TaskSelectScreen> createState() => _TaskSelectScreenState();
}

class _TaskSelectScreenState extends State<TaskSelectScreen> {
  // 선택 가능한 카테고리 목록 (아이콘 + 라벨)
  final List<_Category> _categories = const <_Category>[
    _Category(name: '음식점', icon: Icons.restaurant),
    _Category(name: '카페', icon: Icons.local_cafe),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 뒤로가기 + 서브 타이틀
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const Text('인원 수 고르기', style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
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
                    backgroundColor: const Color(0xFFFF7A21),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // 결과를 요청한 포맷으로 콘솔 출력
                    final list = _selected.toList();
                    // ignore: avoid_print
                    print('인원 수 : ${widget.peopleCount}명');
                    // ignore: avoid_print
                    print('선택 : ${list.map((e) => '"$e"').join(', ')}');

                    // 채팅 화면으로 이동하여 선택한 카테고리 시각화
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          peopleCount: widget.peopleCount,
                          selectedCategories: list,
                        ),
                      ),
                    );
                  },
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
