import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/helpers/token_manager.dart';
import '../../core/config/server_config.dart';

class ReviewService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 내 리뷰 조회 (GET /api/users/me/reviews)
  static Future<dynamic> getMyReview() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/reviews'),
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

  // 리뷰 작성 (POST /api/users/me/reviews)
  static Future<void> setMyReview({
    required String categoryId,
    required int stars,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/me/reviews'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'category_id': categoryId,
          'stars': stars,
          'comments': comment,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('리뷰 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('리뷰 작성 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 리뷰 삭제 (DELETE /api/users/me/reviews/{review_id})
  static Future<void> deleteMyReview(String reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/me/reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        final body = utf8.decode(response.bodyBytes);
        throw Exception('리뷰 삭제 실패: ${response.statusCode} $body');
      }
    } catch (e) {
      print('리뷰 삭제 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<int> getMyReviewCount(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/reviews/count/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['review_count'] ?? 0;
      } else {
        throw Exception('리뷰 개수 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('리뷰 개수 조회 오류: $e');
      return 0;
    }
  }
}
