import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/report_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../widgets/dialogs/common_dialogs.dart';

class InquiryDialog extends StatefulWidget {
  const InquiryDialog({Key? key}) : super(key: key);

  @override
  State<InquiryDialog> createState() => _InquiryDialogState();
}

class _InquiryDialogState extends State<InquiryDialog> {
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    '문의하기',
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
                    // 문의 내용 입력 필드
                    const Text(
                      '문의 내용을 입력해주세요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: '문의하실 내용을 자세히 입력해주세요',
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
                      maxLines: 8,
                      maxLength: 500,
                      onChanged: (_) => setState(() {}),
                    ),
                    
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
                              '문의하신 내용은 검토 후 답변드리겠습니다. 답변은 앱 내 알림으로 전달됩니다.',
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
                      onPressed: (_contentController.text.trim().isNotEmpty && !_isSubmitting)
                          ? _submitInquiry
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
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '문의하기',
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

  Future<void> _submitInquiry() async {
    if (_contentController.text.trim().isEmpty) return;
    if (_isSubmitting) return;

    final currentUserId = TokenManager.userId;
    if (currentUserId == null) {
      if (!mounted) return;
      CommonDialogs.showError(
        context: context,
        message: '로그인이 필요합니다.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final content = _contentController.text.trim();
      
      // 신고하기와 같은 로직으로 report 테이블에 저장
      // type: 3 (문의하기), user_id: null, cause: 문의 내용
      await ReportService.report(
        '', // targetId (문의하기는 빈 값)
        content, // cause: 문의 내용
        '', // causeId (문의하기는 빈 값)
        '3', // type: 3 (문의하기)
        reportedUserId: null, // 문의하기는 reportedUserId가 null
      );
      
      if (!mounted) return;
      
      Navigator.of(context).pop(true); // 성공 시 true 반환
      
      CommonDialogs.showSuccess(
        context: context,
        message: '문의가 접수되었습니다. 검토 후 답변드리겠습니다.',
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });
      
      CommonDialogs.showError(
        context: context,
        message: '문의 접수에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }
}

