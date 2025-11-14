import 'package:flutter/material.dart';
import 'community_screen.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/app_title_widget.dart';
import '../../../data/services/community_service.dart';

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedTodo;
  const CreatePostScreen({super.key, this.selectedTodo});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
        title: const AppTitleWidget('글쓰기'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isFormValid() ? _submitPost : null,
            child: Text(
              '등록',
              style: TextStyle(
                color: _isFormValid() ? const Color(0xFFFF8126) : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택된 일정표 정보
            _buildSelectedTodoInfo(),
            const SizedBox(height: 24),

            // 제목 입력
            const Text(
              '제목',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFF8126)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // 내용 입력
            const Text(
              '내용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFF8126)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 32),

            // 미리보기 섹션
            if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '미리보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewCard(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final todo = widget.selectedTodo;
    final previewPlaces = _extractPlaces(todo?['schedule']);
    final previewCategories = _extractCategories(todo?['categories']);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // 닉네임과 시간
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '방금 전',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 포스트 제목
          if (_titleController.text.isNotEmpty)
            Text(
              _titleController.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          if (_titleController.text.isNotEmpty) const SizedBox(height: 6),
          
          // 포스트 내용
          if (_contentController.text.isNotEmpty)
            Text(
              _contentController.text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          if (_contentController.text.isNotEmpty) const SizedBox(height: 12),
          
          if (todo != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF8126).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: const Color(0xFFFF8126),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        todo['date']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  if (previewCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _buildCategoryChips(previewCategories),
                    ),
                  ],
                  if (previewPlaces.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildScheduleFlowBox(previewPlaces),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // 댓글 버튼
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '댓글',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return _titleController.text.trim().isNotEmpty &&
           _contentController.text.trim().isNotEmpty;
  }

  Future<void> _submitPost() async {
    if (!_isFormValid()) {
      return;
    }

    final mergeHistoryId = widget.selectedTodo?['historyId']?.toString() ?? '';
    if (mergeHistoryId.isEmpty) {
      CommonDialogs.showError(
        context: context,
        message: '선택된 일정표가 없습니다. 일정을 선택해 주세요.',
      );
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    try {
      await CommunityService.createPost(title, content, mergeHistoryId);
      if (!mounted) return;

      CommonDialogs.showSuccess(
        context: context,
        message: '게시글이 등록되었습니다.',
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CommunityScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      CommonDialogs.showError(
        context: context,
        message: '게시글 등록에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }

  Widget _buildSelectedTodoInfo() {
    final todo = widget.selectedTodo;
    final places = _extractPlaces(todo?['schedule']);
    final categories = _extractCategories(todo?['categories']);
    final dateText = todo?['date']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF8126).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.schedule,
                color: Color(0xFFFF8126),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '선택된 일정표',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8126),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todo == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '일정표가 뜰 예정',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFF8126),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else ...[
            if (dateText.isNotEmpty)
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _buildCategoryChips(categories),
              ),
            ],
            if (places.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildScheduleFlowBox(places),
            ],
            if (places.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '선택된 일정이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<String> _extractPlaces(dynamic raw) {
    if (raw is! List) return const [];
    final result = <String>[];
    for (final item in raw) {
      if (item is Map && item['place'] != null) {
        final name = item['place'].toString().trim();
        if (name.isNotEmpty) {
          result.add(name);
        }
      }
    }
    return result;
  }

  List<String> _extractCategories(dynamic raw) {
    if (raw is! List) return const [];
    final result = <String>[];
    for (final item in raw) {
      if (item is String) {
        final name = item.trim();
        if (name.isNotEmpty) {
          result.add(name);
        }
      }
    }
    return result;
  }

  Widget _buildScheduleFlowBox(List<String> places) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF8126).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 6,
        children: _buildFlowWidgets(places),
      ),
    );
  }

  List<Widget> _buildFlowWidgets(List<String> places) {
    final List<Widget> widgets = [];
    const textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFFFF8126),
    );

    for (var i = 0; i < places.length; i++) {
      widgets.add(
        Text(
          places[i],
          style: textStyle,
        ),
      );
      if (i < places.length - 1) {
        widgets.add(const Text(
          '→',
          style: textStyle,
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildCategoryChips(List<String> categories) {
    return categories
        .map(
          (category) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        .toList();
  }
}
