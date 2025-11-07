import 'package:flutter/material.dart';
import 'template_1_screen.dart';
import 'template_2_screen.dart'; // 🔥 추가
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_dialogs.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '템플릿 선택',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
        children: [
          _TemplateTile(
            name: '기본 템플릿',
            description: '빠르게 이동하며 더 많은 장소 방문',
            emoji: '🚀',
            checked: _selectedName == '기본 템플릿',
            onToggle: () {
              setState(() {
                _selectedName = _selectedName == '기본 템플릿' ? null : '기본 템플릿';
              });
            },
          ),
          _TemplateTile(
            name: '플로우 템플릿',
            description: '충분한 휴식을 포함한 느긋한 동선',
            emoji: '🌿',
            checked: _selectedName == '플로우 템플릿',
            onToggle: () {
              setState(() {
                _selectedName = _selectedName == '플로우 템플릿' ? null : '플로우 템플릿';
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _onConfirm,
              child: const Text(
                '템플릿 선택하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    if (_selectedName == '기본 템플릿') {
      _goTemplate1(first: 50, other: 25);
    } else if (_selectedName == '플로우 템플릿') {
      _goTemplate2(first: 50, other: 25); // 🔥 템플릿 2로 이동
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
