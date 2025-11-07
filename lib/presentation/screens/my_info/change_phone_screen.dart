import 'package:flutter/material.dart';
import 'package:whattodo/presentation/widgets/wave_painter.dart';
import 'package:whattodo/data/services/user_service.dart';

class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({Key? key}) : super(key: key);

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final TextEditingController _currentPhoneController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  final TextEditingController _confirmPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _newPhoneFocusNode = FocusNode();
  final FocusNode _confirmPhoneFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 현재 전화번호를 입력 필드에 미리 채우기 (실제로는 서버에서 가져와야 함)
    _currentPhoneController.text = '010-1234-5678';
  }

  @override
  void dispose() {
    _currentPhoneController.dispose();
    _newPhoneController.dispose();
    _confirmPhoneController.dispose();
    _passwordController.dispose();
    _newPhoneFocusNode.dispose();
    _confirmPhoneFocusNode.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // 숫자만 추출
    String numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 010-XXXX-XXXX 형식으로 포맷팅
    if (numbers.length >= 11) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7, 11)}';
    } else if (numbers.length >= 7) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
    } else if (numbers.length >= 3) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3)}';
    }
    return numbers;
  }

  bool _isValidPhoneNumber(String phone) {
    String numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return numbers.length == 11 && numbers.startsWith('010');
  }

  Future<void> _handleChangePhone() async {
    if (_currentPhoneController.text.isEmpty) {
      _showSnackBar('현재 전화번호를 입력해주세요.');
      return;
    }

    if (_newPhoneController.text.isEmpty) {
      _showSnackBar('새 전화번호를 입력해주세요.');
      return;
    }

    if (!_isValidPhoneNumber(_newPhoneController.text)) {
      _showSnackBar('올바른 전화번호 형식을 입력해주세요. (010-XXXX-XXXX)');
      return;
    }

    if (_newPhoneController.text != _confirmPhoneController.text) {
      _showSnackBar('새 전화번호가 일치하지 않습니다.');
      return;
    }

    if (_currentPhoneController.text == _newPhoneController.text) {
      _showSnackBar('현재 전화번호와 새 전화번호가 동일합니다.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.changePhone(
        password: _passwordController.text,
        newPhone: _newPhoneController.text.trim(),
      );
      _showSnackBar('전화번호가 변경되었습니다.');
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('전화번호 변경 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF8126),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 웨이브 디자인
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 200),
                painter: WavePainter(),
              ),
              
              // 메인 타이틀
              const Padding(
                padding: EdgeInsets.only(top: 30, bottom: 10),
                child: Text(
                  '전화번호 변경',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8126),
                  ),
                ),
              ),
              
              // 서브 타이틀
              const Text(
                '새로운 전화번호를 입력해주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 현재 전화번호 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _currentPhoneController,
                  enabled: false, // 현재 전화번호는 수정 불가
                  decoration: InputDecoration(
                    hintText: '현재 전화번호',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
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
              ),
              
              const SizedBox(height: 15),
              
              // 새 전화번호 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _newPhoneController,
                  focusNode: _newPhoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_confirmPhoneFocusNode);
                  },
                  onChanged: (value) {
                    // 실시간으로 전화번호 포맷팅
                    String formatted = _formatPhoneNumber(value);
                    if (formatted != value) {
                      _newPhoneController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '새 전화번호 (010-XXXX-XXXX)',
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
              ),
              
              const SizedBox(height: 15),
              
              // 전화번호 확인 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _confirmPhoneController,
                  focusNode: _confirmPhoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _handleChangePhone();
                    }
                  },
                  onChanged: (value) {
                    // 실시간으로 전화번호 포맷팅
                    String formatted = _formatPhoneNumber(value);
                    if (formatted != value) {
                      _confirmPhoneController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '새 전화번호 확인',
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
              ),
              
              const SizedBox(height: 30),
              
              // 비밀번호 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '현재 비밀번호',
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
              ),
              
              const SizedBox(height: 20),
              
              // 변경하기 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleChangePhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8126),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '변경하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 취소 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8126),
                      side: const BorderSide(
                        color: Color(0xFFFF8126),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
