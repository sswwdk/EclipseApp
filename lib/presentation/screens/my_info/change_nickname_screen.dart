import 'package:flutter/material.dart';
import 'package:whattodo/presentation/widgets/wave_painter.dart';
import 'package:whattodo/shared/helpers/token_manager.dart';
import 'package:whattodo/data/services/user_service.dart';

class ChangeNicknameScreen extends StatefulWidget {
  const ChangeNicknameScreen({Key? key}) : super(key: key);

  @override
  State<ChangeNicknameScreen> createState() => _ChangeNicknameScreenState();
}

class _ChangeNicknameScreenState extends State<ChangeNicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 현재 닉네임을 입력 필드에 미리 채우기
    _nicknameController.text = TokenManager.userName ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangeNickname() async {
    if (_nicknameController.text.trim().isEmpty) {
      _showSnackBar('닉네임을 입력해주세요.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요.');
      return;
    }

    if (_nicknameController.text.trim() == TokenManager.userName) {
      _showSnackBar('현재 닉네임과 동일합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> res = await UserService.changeNickname(
        _nicknameController.text.trim(),
        _passwordController.text,
      );
      final dynamic direct = res['nickname'];
      final dynamic nested = (res['data'] is Map<String, dynamic>) ? (res['data']['nickname']) : null;
      final String updated = (direct ?? nested ?? _nicknameController.text.trim()).toString();
      TokenManager.setUserName(updated);
      _showSnackBar('닉네임이 변경되었습니다.');
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('닉네임 변경 중 오류가 발생했습니다: $e');
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
                  '닉네임 변경',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8126),
                  ),
                ),
              ),
              
              // 서브 타이틀
              const Text(
                '새로운 닉네임을 입력해주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // 닉네임 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _nicknameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _handleChangeNickname();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '닉네임',
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _handleChangeNickname();
                    }
                  },
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
                    onPressed: _isLoading ? null : _handleChangeNickname,
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
