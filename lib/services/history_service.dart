import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../config/server_config.dart';

class HistoryService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 내 히스토리 보기
  static Future<Map<String, dynamic>> getMyHistory(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/my-history'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('히스토리 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('히스토리 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 히스토리 삭제
  static Future<Map<String, dynamic>> deleteHistory(String userId, String historyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/service/my-history'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'history_id': historyId}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('히스토리 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('히스토리 삭제 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
