import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.14.51:8080';

  // JWT 토큰 발급 (상대방 서버 형식에 맞춤)
  static Future<Map<String, dynamic>> issueToken(String username, String password) async {
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
            'username': username,
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

  // JWT 토큰 삭제
  static Future<Map<String, dynamic>> deleteToken() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('토큰 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('토큰 삭제 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
