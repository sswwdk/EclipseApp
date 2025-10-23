import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class NoticeService {
  static const String baseUrl = 'http://192.168.14.51:8080';

  // 공지사항 목록
  static Future<Map<String, dynamic>> getAllNotices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notice/all'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('공지사항 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('공지사항 목록 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 공지사항 상세
  static Future<Map<String, dynamic>> getNoticeDetail(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notice/$postId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('공지사항 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('공지사항 상세 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
