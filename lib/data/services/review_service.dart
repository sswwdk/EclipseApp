import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/helpers/token_manager.dart';
import '../../core/config/server_config.dart';

class ReviewService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 내 리뷰 조회 (GET /api/service/my-review?user_id=X)
  static Future<Map<String, dynamic>> getMyReview(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/service/my-review?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('리뷰 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('리뷰 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 리뷰 작성 (POST /api/service/set-my-review)
  static Future<Map<String, dynamic>> setMyReview({
    required String userId,
    required String historyId,
    required int stars,
    required String comment,
    required DateTime visitedAt,
    required DateTime createdAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/set-my-review'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'user_id': userId,
          'history_id': historyId,
          'stars': stars,
          'comment': comment,
          'visited_at': visitedAt.toIso8601String(),
          'created_at': createdAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('리뷰 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('리뷰 작성 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}

