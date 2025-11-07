import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/helpers/token_manager.dart';
import '../../core/config/server_config.dart';

class LikeService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 찜 보기
  static Future<Map<String, dynamic>> getLikes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/likes'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        }
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('찜 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('찜 목록 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 찜 등록 (서버 DTO: { category_id, user_id })
  static Future<Map<String, dynamic>> likeStore(String categoryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/me/likes'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'category_id': categoryId}),
      );

      if (response.statusCode == 200) {
        return{};
      } else {
        throw Exception('찜 등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('찜 등록 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 찜 취소
  static Future<Map<String, dynamic>> unlikeStore(String categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/me/likes'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'category_id': categoryId}),
      );

      if (response.statusCode == 200) {
        return {};
      } else {
        throw Exception('찜 취소 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('찜 취소 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
