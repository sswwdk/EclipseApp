import 'package:flutter/material.dart';
import '../login/login_screen.dart';
import '../login/find_account_screen.dart';
import '../widgets/common_dialogs.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int _selectedReason = 0; // 선택된 탈퇴 사유
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  final List<String> _withdrawalReasons = [
    '기록 삭제 목적',
    '이용이 불편하고 장애가 많아서',
    '다른 사이트가 더 좋아서',
    '사용빈도가 낮아서',
    '콘텐츠 불만',
    '기타',
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _deleteAccount() {
    if (_passwordController.text.isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요.');
      return;
    }

    // 실제 삭제 로직은 여기에 구현
    _showDeleteConfirmDialog();
  }

  void _showDeleteConfirmDialog() {
    CommonDialogs.showDeleteAccountConfirmation(
      context: context,
      onConfirm: () {
        _processAccountDeletion();
      },
    );
  }

  void _processAccountDeletion() {
    // 실제 계정 삭제 로직
    _showSnackBar('회원이 탈퇴되었습니다.');
    
    // 로그인 화면으로 이동
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF8126),
      ),
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
          '회원 탈퇴',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 탈퇴 확인 메시지
              const Center(
                child: Column(
                  children: [
                    Text(
                      '정말 떠나시는 건가요?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '한 번 더 생각해 보지 않으시겠어요?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 탈퇴 사유 요청
              const Text(
                '회원을 탈퇴하시려는 이유를 말씀해주세요.\n서비스 개선에 중요 자료로 활용하겠습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 탈퇴 사유 선택
              Column(
                children: List.generate(_withdrawalReasons.length, (index) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: _selectedReason,
                            onChanged: (int? value) {
                              setState(() {
                                _selectedReason = value!;
                              });
                            },
                            activeColor: const Color(0xFFFF8126),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedReason = index;
                                });
                              },
                              child: Text(
                                _withdrawalReasons[index],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (index < _withdrawalReasons.length - 1)
                        const SizedBox(height: 8),
                    ],
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // 경고 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.red.withOpacity(0.05),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '회원을 탈퇴하면 회원님의 모든 활동 기록과 찜 목록, 일정표 히스토리가 삭제됩니다. 삭제된 정보는 복구할 수 없으니 신중하게 결정해주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '오뭐 플러스 구독은 회원 탈퇴 시 환불이 불가합니다. 또한 환불 신청 후 환불 처리가 완료되기 전 회원을 탈퇴하는 경우 오뭐 플러스 구독여부를 확인할 수 없으므로 환불이 불가합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 비밀번호 입력
              const Text(
                '사용중인 비밀번호',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 비밀번호 재설정 링크
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // 비밀번호 찾기 화면으로 이동
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FindAccountScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 탈퇴 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8126),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '탈퇴하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
