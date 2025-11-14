import 'package:flutter/material.dart';
import '../../../data/services/user_service.dart';
import '../../widgets/dialogs/common_dialogs.dart';

// 회원가입 화면
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isPasswordObscured = true;
  bool _isPasswordConfirmObscured = true;
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // 필수 항목 검증
    final String id = _idController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _passwordConfirmController.text.trim();
    final String nickname = _nicknameController.text.trim();
    final String email = _emailController.text.trim();
    final String name = _nameController.text.trim();
    
    if (id.isEmpty) {
      _showSnackBar('아이디를 입력하세요.');
      return;
    }
    
    if (password.isEmpty) {
      _showSnackBar('비밀번호를 입력하세요.');
      return;
    }
    
    if (confirmPassword.isEmpty) {
      _showSnackBar('비밀번호 확인을 입력하세요.');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('비밀번호와 비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    if (nickname.isEmpty) {
      _showSnackBar('닉네임을 입력하세요.');
      return;
    }
    
    if (email.isEmpty) {
      _showSnackBar('이메일을 입력하세요.');
      return;
    }
    
    if (name.isEmpty) {
      _showSnackBar('이름을 입력하세요.');
      return;
    }
    
    // 이메일 형식 검증
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('올바른 이메일 형식을 입력하세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 선택 필드 수집
      final String? phone = _phoneController.text.trim().isNotEmpty 
          ? _phoneController.text.trim() 
          : null;
      final String? address = _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : null;
      
      // 성별 변환: 'female' -> 0, 'male' -> 1, 'none' 또는 null -> null
      int? sex;
      if (_selectedGender == 'female') {
        sex = 0;
      } else if (_selectedGender == 'male') {
        sex = 1;
      }
      
      // 생년월일 형식 변환: DateTime -> 'yyyy-MM-dd'
      String? birth;
      if (_selectedDate != null) {
        birth = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      }

      // ✅ 실제 API 호출 (모든 필드 전달)
      final response = await UserService.signup(
        id: id,
        username: name,
        password: password,
        nickname: nickname,
        email: email,
        phone: phone,
        address: address,
        sex: sex,
        birth: birth,
      );
      
      if (!mounted) return;

      debugPrint('회원가입 성공: $response');
      _showSnackBar('회원가입이 완료되었습니다!', isSuccess: true);
      
      // 1초 대기 후 로그인 화면으로 이동
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      debugPrint('회원가입 실패: $e');
      _showSnackBar('회원가입에 실패했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (isSuccess) {
      CommonDialogs.showSuccess(
        context: context,
        message: message,
      );
    } else {
      CommonDialogs.showError(
        context: context,
        message: message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('회원가입 화면 빌드됨');
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
          '돌아가기',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 타이틀
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8126),
                  ),
                ),
              ),
            ),
            
            // 아이디 입력 필드 (필수)
            _buildInputField('아이디', '아이디를 입력하세요', _idController, isRequired: true),
            const SizedBox(height: 20),
            
            // 비밀번호 입력 필드 (필수)
            _buildInputField(
              '비밀번호',
              '비밀번호를 입력하세요 (8자리 이상)',
              _passwordController,
              isPassword: true,
              isRequired: true,
              obscureText: _isPasswordObscured,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordObscured = !_isPasswordObscured;
                });
              },
            ),
            const SizedBox(height: 20),

            // 비밀번호 확인 입력 필드 (필수)
            _buildInputField(
              '비밀번호 확인',
              '비밀번호를 다시 입력하세요',
              _passwordConfirmController,
              isPassword: true,
              isRequired: true,
              obscureText: _isPasswordConfirmObscured,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordConfirmObscured = !_isPasswordConfirmObscured;
                });
              },
            ),
            const SizedBox(height: 20),
            
            // 닉네임 입력 필드 (필수)
            _buildInputField('닉네임', '닉네임을 입력하세요', _nicknameController, isRequired: true),
            const SizedBox(height: 20),
            
            // 이메일 입력 필드 (필수)
            _buildInputField('이메일', '이메일을 입력하세요', _emailController, isRequired: true),
            const SizedBox(height: 20),
            
            // 이름 입력 필드 (필수)
            _buildInputField('이름', '이름을 입력하세요', _nameController, isRequired: true),
            const SizedBox(height: 20),
            
            // 전화번호 입력 필드 (선택)
            _buildInputField('전화번호', '전화번호를 입력하세요', _phoneController, isOptional: true),
            const SizedBox(height: 20),
            
            // 주소 입력 필드 (선택)
            _buildInputField('주소', '주소를 입력하세요', _addressController, isOptional: true),
            const SizedBox(height: 20),
            
            // 성별 선택 필드 (선택)
            _buildGenderField(isOptional: true),
            const SizedBox(height: 20),
            
            // 생년월일 선택 필드 (선택)
            _buildDateField(isOptional: true),
            const SizedBox(height: 40),
            
            // 회원가입 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8126),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
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
                        '회원가입',
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
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    bool isRequired = false,
    bool isOptional = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (isOptional) ...[
              const SizedBox(width: 4),
              const Text(
                '(선택)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          decoration: InputDecoration(
            hintText: hint,
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
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[500],
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '생년월일',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 4),
              const Text(
                '(선택)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFFFF8126),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일'
                        : '생년월일을 선택하세요',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFFF8126),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField({bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '성별',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 4),
              const Text(
                '(선택)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: Text(
                '성별을 선택하세요',
                style: TextStyle(color: Colors.grey[400]),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'female',
                  child: Text('여'),
                ),
                DropdownMenuItem(
                  value: 'male',
                  child: Text('남'),
                ),
                DropdownMenuItem(
                  value: 'none',
                  child: Text('선택안함'),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
