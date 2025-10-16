import 'package:flutter/material.dart';

// 회원가입 화면
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedGender;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
          '회원가입',
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
                  '오늘 뭐하지?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8126),
                  ),
                ),
              ),
            ),
            
            // 아이디 입력 필드
            _buildInputField('아이디', '아이디를 입력하세요', _idController),
            const SizedBox(height: 20),
            
            // 비밀번호 입력 필드
            _buildInputField('비밀번호', '비밀번호를 입력하세요', _passwordController, isPassword: true),
            const SizedBox(height: 20),
            
            // 이름 입력 필드
            _buildInputField('이름', '이름을 입력하세요', _nameController),
            const SizedBox(height: 20),
            
            // 닉네임 입력 필드
            _buildInputField('닉네임', '닉네임을 입력하세요', _nicknameController),
            const SizedBox(height: 20),
            
            // 이메일 입력 필드
            _buildInputField('이메일', '이메일을 입력하세요', _emailController),
            const SizedBox(height: 20),
            
            // 생년월일 선택 필드
            _buildDateField(),
            const SizedBox(height: 20),
            
            // 전화번호 입력 필드
            _buildInputField('전화번호', '전화번호를 입력하세요', _phoneController),
            const SizedBox(height: 20),
            
            // 성별 선택 필드
            _buildGenderField(),
            const SizedBox(height: 20),
            
            // 주소 입력 필드
            _buildInputField('주소', '주소를 입력하세요', _addressController),
            const SizedBox(height: 40),
            
            // 회원가입 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final String nickname = _nicknameController.text.trim();
                  final String email = _emailController.text.trim();
                  
                  if (nickname.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('닉네임을 입력하세요.')),
                    );
                    return;
                  }
                  
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이메일을 입력하세요.')),
                    );
                    return;
                  }
                  
                  // 이메일 형식 검증
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('올바른 이메일 형식을 입력하세요.')),
                    );
                    return;
                  }
                  
                  // TODO: 회원가입 로직에 닉네임, 이메일 포함하여 처리
                  debugPrint('회원가입 닉네임: $nickname, 이메일: $email');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8126),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
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

  Widget _buildInputField(String label, String hint, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
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
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생년월일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
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

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
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
