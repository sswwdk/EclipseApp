import 'package:flutter/material.dart';
import '../../widgets/common_dialogs.dart';

class FindAccountScreen extends StatefulWidget {
  const FindAccountScreen({Key? key}) : super(key: key);

  @override
  State<FindAccountScreen> createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountScreen> {
  int _selectedTab = 0; // 0: 아이디 찾기, 1: 비밀번호 찾기
  int _selectedMethod = 0; // 0: 이메일, 1: 전화번호
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _findAccount() {
    if (_selectedTab == 0) {
      // 아이디 찾기
      if (_selectedMethod == 0) {
        // 이메일로 찾기
        if (_emailController.text.isEmpty) {
          _showSnackBar('이메일을 입력해주세요.');
          return;
        }
        _showResultDialog('아이디 찾기', '입력하신 이메일로 아이디를 찾는 기능을 구현해주세요.');
      } else {
        // 전화번호로 찾기
        if (_phoneController.text.isEmpty) {
          _showSnackBar('전화번호를 입력해주세요.');
          return;
        }
        _showResultDialog('아이디 찾기', '입력하신 전화번호로 아이디를 찾는 기능을 구현해주세요.');
      }
    } else {
      // 비밀번호 찾기
      if (_idController.text.isEmpty) {
        _showSnackBar('아이디를 입력해주세요.');
        return;
      }
      if (_selectedMethod == 0) {
        // 이메일로 찾기
        if (_emailController.text.isEmpty) {
          _showSnackBar('이메일을 입력해주세요.');
          return;
        }
        _showResultDialog('비밀번호 찾기', '입력하신 정보로 비밀번호를 찾는 기능을 구현해주세요.');
      } else {
        // 전화번호로 찾기
        if (_phoneController.text.isEmpty) {
          _showSnackBar('전화번호를 입력해주세요.');
          return;
        }
        _showResultDialog('비밀번호 찾기', '입력하신 정보로 비밀번호를 찾는 기능을 구현해주세요.');
      }
    }
  }

  void _showResultDialog(String title, String message) {
    CommonDialogs.showInfo(
      context: context,
      title: title,
      content: message,
    );
  }

  void _showSnackBar(String message) {
    CommonDialogs.showMessage(
      context: context,
      message: message,
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
        title: Text(
          _selectedTab == 0 ? '아이디 찾기' : '비밀번호 찾기',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 탭 버튼들
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = 0;
                            _selectedMethod = 0;
                            _emailController.clear();
                            _phoneController.clear();
                            _idController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '아이디 찾기',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 0
                                  ? const Color(0xFFFF8126)
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = 1;
                            _selectedMethod = 0;
                            _emailController.clear();
                            _phoneController.clear();
                            _idController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '비밀번호 찾기',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 1
                                  ? const Color(0xFFFF8126)
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 안내 텍스트
              Text(
                _selectedTab == 0
                    ? '아이디를 찾을 방법을 선택해주세요.'
                    : '비밀번호를 찾을 방법을 선택해주세요.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 24),
              
               // 방법 선택 (라디오 버튼)
               Column(
                 children: [
                   Row(
                     children: [
                       Radio<int>(
                         value: 0,
                         groupValue: _selectedMethod,
                         onChanged: (int? value) {
                           setState(() {
                             _selectedMethod = value!;
                           });
                         },
                         activeColor: const Color(0xFFFF8126),
                       ),
                       Expanded(
                         child: GestureDetector(
                           onTap: () {
                             setState(() {
                               _selectedMethod = 0;
                             });
                           },
                           child: const Text(
                             '가입한 이메일로 찾기',
                             style: TextStyle(
                               fontSize: 14,
                               color: Colors.black87,
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                   Row(
                     children: [
                       Radio<int>(
                         value: 1,
                         groupValue: _selectedMethod,
                         onChanged: (int? value) {
                           setState(() {
                             _selectedMethod = value!;
                           });
                         },
                         activeColor: const Color(0xFFFF8126),
                       ),
                       Expanded(
                         child: GestureDetector(
                           onTap: () {
                             setState(() {
                               _selectedMethod = 1;
                             });
                           },
                           child: const Text(
                             '가입한 전화번호로 찾기',
                             style: TextStyle(
                               fontSize: 14,
                               color: Colors.black87,
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
              
              const SizedBox(height: 32),
              
              // 입력 필드들
              if (_selectedTab == 1) ...[
                // 비밀번호 찾기일 때만 아이디 입력 필드 표시
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    hintText: '아이디',
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
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 이메일 또는 전화번호 입력 필드
              TextField(
                controller: _selectedMethod == 0 ? _emailController : _phoneController,
                keyboardType: _selectedMethod == 0 ? TextInputType.emailAddress : TextInputType.phone,
                decoration: InputDecoration(
                  hintText: _selectedMethod == 0 ? '이메일' : '전화번호',
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
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 찾기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _findAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8126),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedTab == 0 ? '아이디 찾기' : '비밀번호 찾기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
