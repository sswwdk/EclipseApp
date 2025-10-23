import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class UserService {
  static const String baseUrl = 'http://192.168.14.51:8080';

  // 로그인 (상대방 서버 형식에 맞춤)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/users/login'),
        headers: headers,
        body: json.encode({
          'header': {
            'content': 'application/json',
          },
          'body': {
            'type': 'login',
            'id': username,
            'password': password,
          },
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('로그인 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('로그인 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 로그아웃
  static Future<Map<String, dynamic>> logout(String username, String password) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: headers,
        body: json.encode({
          'id': username,
          'pw': password,
          'type': 'logout',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('로그아웃 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('로그아웃 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 아이디 찾기
  static Future<Map<String, dynamic>> findId(String email) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/id'),
        headers: headers,
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('아이디 찾기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('아이디 찾기 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 비밀번호 찾기
  static Future<Map<String, dynamic>> findPassword(String username, String email) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/password'),
        headers: headers,
        body: json.encode({
          'username': username,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('비밀번호 찾기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('비밀번호 찾기 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 회원가입
  static Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/signup'),
        headers: headers,
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('회원가입 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원가입 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 회원 탈퇴
  static Future<Map<String, dynamic>> deleteUser(String userId, String password) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('회원 탈퇴 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원 탈퇴 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 내 정보 보기
  static Future<Map<String, dynamic>> getMyInfo(String userId) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('내 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('내 정보 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 선호 취향 선택
  static Future<Map<String, dynamic>> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId/preferences'),
        headers: headers,
        body: json.encode(preferences),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('선호도 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('선호도 업데이트 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
