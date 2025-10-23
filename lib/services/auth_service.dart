import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.14.51:8080';

  // JWT 토큰 발급
  static Future<Map<String, dynamic>> issueToken(String username, String password) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/session'),
        headers: headers,
        body: json.encode({
          'header': {
            'content': 'application/json',
            'jwt': null,
          },
          'body': {
            'id': username,
            'password': password,
          },
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('토큰 발급 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('토큰 발급 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // JWT 토큰 삭제
  static Future<Map<String, dynamic>> deleteToken(String username, String password) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/session'),
        headers: headers,
        body: json.encode({
          'header': {
            'content': 'application/json',
            'jwt': null,
          },
          'body': {
            'id': username,
            'password': password,
          },
        }),
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
