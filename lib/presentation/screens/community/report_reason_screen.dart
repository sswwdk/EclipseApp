import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ReportReasonDialog extends StatefulWidget {
  final String targetType; // 'user', 'post', 'comment'
  final String targetId;
  final String? targetName; // 사용자 이름 또는 게시글 제목

  const ReportReasonDialog({
    Key? key,
    required this.targetType,
    required this.targetId,
    this.targetName,
  }) : super(key: key);

  @override
  State<ReportReasonDialog> createState() => _ReportReasonDialogState();
}

class _ReportReasonDialogState extends State<ReportReasonDialog> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  final List<Map<String, String>> _reportReasons = [
    {'id': 'spam', 'title': '스팸/광고'},
    {'id': 'abuse', 'title': '욕설/비방'},
    {'id': 'inappropriate', 'title': '음란물'},
    {'id': 'privacy', 'title': '개인정보 유출'},
    {'id': 'other', 'title': '기타'},
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  String _getTargetTypeText() {
    switch (widget.targetType) {
      case 'user':
        return '사용자';
      case 'post':
        return '게시글';
      case 'comment':
        return '댓글';
      default:
        return '항목';
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.targetName ?? '항목';
    final targetTypeText = _getTargetTypeText();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '신고하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 신고 대상 정보
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$targetTypeText 신고: $targetName',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 신고 이유 선택
                    const Text(
                      '신고 사유를 선택해주세요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 신고 이유 목록
                    ..._reportReasons.map((reason) {
                      final isSelected = _selectedReason == reason['id'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedReason = reason['id'];
                                if (reason['id'] != 'other') {
                                  _customReasonController.clear();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    reason['title']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    // 기타 사유 입력 필드
                    if (_selectedReason == 'other') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customReasonController,
                        decoration: InputDecoration(
                          hintText: '신고 사유를 입력해주세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        maxLines: 3,
                        maxLength: 200,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // 안내 문구
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '신고된 내용은 검토 후 조치됩니다. 허위 신고는 제재를 받을 수 있습니다.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 버튼 영역
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReason != null &&
                              (_selectedReason != 'other' ||
                                  _customReasonController.text.trim().isNotEmpty)
                          ? _submitReport
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        '신고하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport() {
    if (_selectedReason == null) return;
    
    String reasonText = _reportReasons
        .firstWhere((r) => r['id'] == _selectedReason)['title']!;
    
    if (_selectedReason == 'other') {
      final customReason = _customReasonController.text.trim();
      if (customReason.isEmpty) return;
      reasonText = customReason;
    }

    Navigator.of(context).pop({
      'reason': reasonText,
      'reasonId': _selectedReason,
    });
  }
}

