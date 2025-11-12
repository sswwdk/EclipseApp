import 'dart:convert';
import '../../shared/helpers/http_interceptor.dart';
import '../../shared/helpers/token_manager.dart';
import '../../core/config/server_config.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/review.dart';

class ApiService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 메인 화면 데이터 조회 (새로운 DTO 형식)
  static Future<List<Restaurant>> getRestaurants() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/categories/',
        headers: headers,
      );

      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> categories =
          (data['categories'] as List<dynamic>?) ?? const [];
      return categories
          .whereType<Map<String, dynamic>>()
          .map((json) => Restaurant.fromMainScreenJson(json))
          .toList();
    } catch (e) {
      print('API 호출 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 특정 레스토랑 조회
  static Future<Restaurant> getRestaurant(String id) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/categories/$id',
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> root = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};
        final Map<String, dynamic> obj = (root['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(root['data'])
            : root;
        try {
          final rawReviews = obj['reviews'];
          print(
            '🧾 getRestaurant($id) raw reviews: '
            '${rawReviews is List ? json.encode(rawReviews) : rawReviews}',
          );
        } catch (e) {
          print('🧾 getRestaurant($id) raw reviews 로그 실패: $e');
        }

        // 이 API에서는 태그/리뷰만 사용한다. 나머지는 기본값으로 반환
        return Restaurant(
          id: id,
          name: obj['title'] as String? ?? '', // 🔥 추가
          image: obj['image_url'] as String?, // 🔥 추가
          subCategory: obj['sub_category'] as String?, // 🔥 추가
          detailAddress: obj['detail_address'] as String?, // 🔥 추가
          phone: obj['phone'] as String?, // 🔥 추가
          businessHour: obj['business_hour'] as String?, // 🔥 추가
          rating: _parseDouble(obj['rating']) ?? _parseDouble(obj['average_stars']) ?? 0.0,
          averageStars: _parseDouble(obj['average_stars']),
          reviews: Review.fromList(obj['reviews']),
          tags: _parseStringList(obj['tags']),
          isFavorite: obj['is_like'] ?? false,
        );
      } else if (response.statusCode == 404) {
        throw Exception('레스토랑을 찾을 수 없습니다');
      } else {
        throw Exception('HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('API 호출 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}

// 헬퍼 함수들
double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString();
  return double.tryParse(s);
}

List<String> _parseStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e.toString()).toList();
  }
  return const [];
}
