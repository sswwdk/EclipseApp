import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../shared/helpers/http_interceptor.dart';
import '../../shared/helpers/token_manager.dart';
import '../../core/config/server_config.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/review.dart';
import '../../data/models/reviewable_store.dart'; // 🔥 추가

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

        final reviews = Review.fromList(obj['reviews']);

        // 이 API에서는 태그/리뷰만 사용한다. 나머지는 기본값으로 반환
        return Restaurant(
          id: id,
          name: obj['title'] as String? ?? '',
          image: obj['image_url'] as String?,
          subCategory: obj['sub_category'] as String?,
          detailAddress: obj['detail_address'] as String?,
          phone: obj['phone'] as String?,
          businessHour: obj['business_hour'] as String?,
          rating:
              _parseDouble(obj['rating']) ??
              _parseDouble(obj['average_stars']) ??
              0.0,
          averageStars: _parseDouble(obj['average_stars']),
          reviewCount:
              _parseInt(obj['review_count'] ?? obj['reviews_count']) ??
              reviews.length,
          reviews: reviews,
          tags: _parseStringList(obj['tags']),
          menuPreview: _parseStringList(obj['menu_preview']),
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

  // 🔥 추가: 리뷰 작성 가능한 매장 목록 조회
  static Future<List<ReviewableStore>> getReviewableStores({
    int limit = 6,
  }) async {
    try {
      debugPrint('🔍 리뷰 작성 가능한 매장 조회 시작...');

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/users/me/reviews/reviewable?limit=$limit',
        headers: headers,
      );

      debugPrint('📡 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('📦 응답 데이터: $data');

        final reviewList = data['review_list'] as List<dynamic>? ?? [];
        debugPrint('📝 리뷰 가능 매장 개수: ${reviewList.length}');

        if (reviewList.isEmpty) {
          debugPrint('❌ 리뷰 작성 가능한 매장이 없습니다');
          return [];
        }

        final stores = <ReviewableStore>[];

        for (final item in reviewList) {
          final review = item as Map<String, dynamic>;

          final categoryId = review['category_id'] ?? '';
          final categoryName = review['category_name'] ?? '';

          // 🔥 주소는 comment 필드에서, 방문 횟수는 stars 필드에서 가져옴
          final address = review['comment'] ?? '주소 정보 없음';
          final visitCount = review['stars'] ?? 0;

          // 기본 정보로 ReviewableStore 생성
          var store = ReviewableStore(
            categoryId: categoryId,
            categoryName: categoryName,
            categoryType: review['category_type'] ?? '',
            imageUrl: null,
            address: address, // 🔥 주소 추가
            visitCount: visitCount is int ? visitCount : 0,
            reviewCount: 0, // 사용하지 않음
            lastVisitDate: review['created_at'] != null
                ? DateTime.parse(review['created_at'])
                : DateTime.now(),
          );

          // 이미지 정보 조회 시도
          try {
            final restaurant = await getRestaurant(categoryId);
            store = store.copyWith(imageUrl: restaurant.image);
            debugPrint('✅ ${categoryName} 이미지 조회 완료');
          } catch (e) {
            debugPrint('⚠️ ${categoryName} 이미지 조회 실패: $e');
          }

          stores.add(store);
        }

        debugPrint('✅ 리뷰 작성 가능한 매장 ${stores.length}개 조회 완료');
        return stores;
      } else {
        debugPrint('❌ 응답 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ 리뷰 작성 가능한 매장 조회 오류: $e');
      return [];
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

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString());
}
