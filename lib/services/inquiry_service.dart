import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../config/server_config.dart';

class InquiryService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 문의 목록
  static Future<Map<String, dynamic>> getInquiries(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inquiries/$userId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('문의 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('문의 목록 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 문의 상세
  static Future<Map<String, dynamic>> getInquiryDetail(String inquiryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inquiries/detail/$inquiryId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('문의 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('문의 상세 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 문의하기
  static Future<Map<String, dynamic>> createInquiry(String userId, String title, String content, String category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/inquiries'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'user_id': userId,
          'title': title,
          'content': content,
          'category': category,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('문의 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('문의 작성 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
