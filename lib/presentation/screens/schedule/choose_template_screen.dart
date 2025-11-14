import 'package:flutter/material.dart';
import 'template_1_screen.dart';
import 'template_2_screen.dart'; // 🔥 추가
import 'template_3_screen.dart'; // TODO(jjaga): remove import when template3 finalized
import '../../../core/theme/app_theme.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/app_title_widget.dart';

class ChooseTemplateScreen extends StatefulWidget {
  final Map<String, List<String>> selected;
  final Map<String, List<Map<String, dynamic>>>? selectedPlacesWithData;
  final Map<String, String>? categoryIdByName;
  final String? originAddress;
  final String? originDetailAddress;
  final List<Map<String, dynamic>>? orderedPlaces;

  const ChooseTemplateScreen({
    Key? key,
    required this.selected,
    this.selectedPlacesWithData,
    this.categoryIdByName,
    this.originAddress,
    this.originDetailAddress,
    this.orderedPlaces,
  }) : super(key: key);

  @override
  State<ChooseTemplateScreen> createState() => _ChooseTemplateScreenState();
}

class _ChooseTemplateScreenState extends State<ChooseTemplateScreen> {
  String? _selectedName;

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 맞게 비율 계산
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // AppBar 높이와 하단 버튼 영역 고려
    final appBarHeight = AppBar().preferredSize.height;
    final bottomBarHeight = 48.0 + 16.0 + 12.0 + 16.0; // 버튼 높이 + 패딩
    final availableHeight = screenHeight - appBarHeight - bottomBarHeight - MediaQuery.of(context).padding.top;
    
    // 카드 너비 계산 (화면 너비 - 좌우 패딩 - 간격) / 2
    final cardWidth = (screenWidth - 16 * 2 - 16) / 2;
    
    // 카드 높이를 화면 비율에 맞게 계산 (적절한 비율 유지)
    final cardHeight = availableHeight / 2.2; // 약간의 여유 공간 확보
    
    // childAspectRatio = 너비 / 높이
    final aspectRatio = cardWidth / cardHeight;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppTitleWidget('템플릿 선택'),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
        children: [
          _TemplateTile(
            name: '템플릿 1',
            description: '심플하게 볼 수 있는 일정표 템플릿 입니다.',
            emoji: '🚀',
            checked: _selectedName == '템플릿 1',
            onToggle: () {
              setState(() {
                _selectedName = _selectedName == '템플릿 1' ? null : '템플릿 1';
              });
            },
          ),
          _TemplateTile(
            name: '템플릿 2',
            description: '설훈님의 디자인적 감각이 들어간 템플릿 입니다.',
            emoji: '🌿',
            checked: _selectedName == '템플릿 2',
            onToggle: () {
              setState(() {
                _selectedName = _selectedName == '템플릿 2' ? null : '템플릿 2';
              });
            },
          ),
          _TemplateTile(
            name: '템플릿 3',
            description: '핑크핑크한 귀여운 템플릿 입니다.\n선택한 매장을 좌우로 스크롤하면서 볼 수 있습니다.',
            emoji: '✨',
            checked: _selectedName == '템플릿 3',
            onToggle: () {
              setState(() {
                _selectedName = _selectedName == '템플릿 3' ? null : '템플릿 3';
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          color: Colors.white,
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onConfirm,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '템플릿 선택하기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    if (_selectedName == null) {
      CommonDialogs.showError(
        context: context,
        message: '템플릿을 선택해 주세요.',
      );
      return;
    }

    if (_selectedName == '템플릿 1') {
      _goTemplate1(first: 50, other: 25);
    } else if (_selectedName == '템플릿 2') {
      _goTemplate2(first: 50, other: 25); // 🔥 템플릿 2로 이동
    } else if (_selectedName == '템플릿 3') {
      _goTemplate3(first: 50, other: 25);
    }
  }

  void _goTemplate1({required int first, required int other}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleBuilderScreen(
          selected: {
            for (final entry in widget.selected.entries)
              entry.key: List<String>.from(entry.value),
          },
          selectedPlacesWithData: widget.selectedPlacesWithData,
          categoryIdByName: widget.categoryIdByName,
          originAddress: widget.originAddress,
          originDetailAddress: widget.originDetailAddress,
          firstDurationMinutes: first,
          otherDurationMinutes: other,
          orderedPlaces: widget.orderedPlaces,
        ),
      ),
    );
  }

  // 🔥 템플릿 2로 이동하는 메서드 추가
  void _goTemplate2({required int first, required int other}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Template2Screen(
          selected: {
            for (final entry in widget.selected.entries)
              entry.key: List<String>.from(entry.value),
          },
          selectedPlacesWithData: widget.selectedPlacesWithData,
          categoryIdByName: widget.categoryIdByName,
          originAddress: widget.originAddress,
          originDetailAddress: widget.originDetailAddress,
          firstDurationMinutes: first,
          otherDurationMinutes: other,
          orderedPlaces: widget.orderedPlaces,
        ),
      ),
    );
  }

  void _goTemplate3({required int first, required int other}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Template3Screen(
          selected: {
            for (final entry in widget.selected.entries)
              entry.key: List<String>.from(entry.value),
          },
          selectedPlacesWithData: widget.selectedPlacesWithData,
          categoryIdByName: widget.categoryIdByName,
          originAddress: widget.originAddress,
          originDetailAddress: widget.originDetailAddress,
          firstDurationMinutes: first,
          otherDurationMinutes: other,
          orderedPlaces: widget.orderedPlaces,
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final String name;
  final String description;
  final String emoji;
  final bool checked;
  final VoidCallback onToggle;

  const _TemplateTile({
    Key? key,
    required this.name,
    required this.description,
    required this.emoji,
    required this.checked,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDDDDD), width: 2),
                  color: Colors.white,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked ? AppTheme.primaryColor : Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
