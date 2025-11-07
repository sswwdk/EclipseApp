import 'package:flutter/material.dart';
import 'package:whattodo/presentation/widgets/wave_painter.dart';
import 'package:whattodo/presentation/screens/auth/signup_screen.dart';
import 'package:whattodo/presentation/screens/auth/find_account_screen.dart';
import 'package:whattodo/presentation/screens/home/main.dart';
import 'package:whattodo/data/services/user_service.dart';
import 'package:whattodo/shared/helpers/token_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 입력한 아이디를 저장
      final inputUserId = _idController.text.trim();
      
      final response = await UserService.login(
        inputUserId,
        _passwordController.text.trim(),
      );

      // 응답에서 토큰/사용자 정보 추출 및 저장
      final token1 = response['token1'];
      final token2 = response['token2'];
      
      if (token1 != null && token2 != null) {
        TokenManager.setTokens(token1, token2);
        
        // 사용자 정보에서 닉네임, ID, 이메일 추출
        String? nickname;
        String? userId;
        String? email;
        if (response['info'] != null) {
          final info = response['info'] as Map<String, dynamic>;
          nickname = info['nickname'] as String?;
          userId = info['userID'] as String? ?? inputUserId; 
          email = info['email'] as String?;
          
          // 디버깅을 위한 로그
          print('로그인 응답에서 추출된 닉네임: $nickname');
          print('로그인 응답에서 추출된 사용자 ID: $userId');
          print('로그인 응답에서 추출된 이메일: $email');
          print('전체 info 데이터: $info');
        }
        
        // 닉네임이 없으면 username 사용
        if (nickname == null && response['info'] != null) {
          final info = response['info'] as Map<String, dynamic>;
          nickname = info['username'] as String?;
        }
        
        TokenManager.setUserName(nickname);
        TokenManager.setUserId(userId);
        TokenManager.setUserEmail(email);
        
        // TokenManager에 저장된 값 확인
        print('TokenManager에 저장된 닉네임: ${TokenManager.userName}');
        print('TokenManager에 저장된 사용자 ID: ${TokenManager.userId}');
        print('TokenManager에 저장된 이메일: ${TokenManager.userEmail}');
        _showSnackBar('로그인 성공!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        _showSnackBar('토큰을 받지 못했습니다.');
      }
    } catch (e) {
      _showSnackBar('로그인 중 오류가 발생했습니다: $e');
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

  /// 로그아웃 처리
  void _handleLogout() {
    TokenManager.clearTokens();
    _showSnackBar('로그아웃되었습니다.');
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
                size: Size(MediaQuery.of(context).size.width, 250),
                painter: WavePainter(),
              ),
              
              // 메인 타이틀
              const Padding(
                padding: EdgeInsets.only(top: 40, bottom: 10),
                child: Text(
                  '오늘 뭐하지?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8126),
                  ),
                ),
              ),
              
              // 서브 타이틀
              const Text(
                '당신을 위한 맞춤형 활동 추천',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // 아이디 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _idController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    // 엔터를 누르면 비밀번호 필드로 포커스 이동
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
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
              ),
              
              const SizedBox(height: 15),
              
              // 비밀번호 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    // 엔터를 누르면 로그인 실행
                    if (!_isLoading) {
                      _handleLogin();
                    }
                  },
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
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 로그인 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 15),
              
              // 아이디/비밀번호 찾기
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindAccountScreen()),
                  );
                },
                child: const Text(
                  '아이디/비밀번호 찾기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // 또는 구분선
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        '또는',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 카카오 로그인 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // 카카오 로그인 로직
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '카카오톡으로 시작하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 회원가입
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '계정이 없으신가요? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      print('회원가입 버튼 클릭됨');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF8126),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
