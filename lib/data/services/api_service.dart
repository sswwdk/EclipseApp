import 'dart:convert';
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
      throw Exception('네트워크 오류: $e');
    }
  }

  // "오늘의 추천" 카드 
  static Future<Map<String, dynamic>> getTodayRecommendations() async {
    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/categories/today-recommendations',
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // 응답은 배열: [히스토리 리스트, 추천 데이터]
        // data[0] = 히스토리 리스트
        // data[1] = 추천 데이터 (to_main(1) 결과 = ResponseCategoryListDTO)
        if (data is List && data.length >= 2) {
          // 첫 번째 요소: 히스토리 리스트
          final firstItem = data[0];
          final historyList = (firstItem is List) 
              ? firstItem 
              : (firstItem is Map) 
                  ? [firstItem] 
                  : [];
          
          // 두 번째 요소: 추천 데이터 (ResponseCategoryListDTO 형식)
          final secondItem = data[1];
          List<dynamic> recommendations = [];
          
          if (secondItem is Map<String, dynamic>) {
            // ResponseCategoryListDTO 형식: { categories: [...] }
            final categories = secondItem['categories'];
            if (categories is List) {
              recommendations = categories;
            } else if (categories != null) {
              recommendations = [categories];
            }
          } else if (secondItem is List) {
            recommendations = secondItem;
          }

          return {
            'histories': historyList,  // data[0] = 히스토리 리스트
            'recommendations': recommendations,  // data[1] = 추천 데이터
          };
        } else if (data is Map<String, dynamic>) {
          // Map 형식 응답 처리 (하위 호환성)
          final historyList = (data['histories'] is List) 
              ? data['histories'] as List<dynamic>
              : [];
          final recommendations = (data['recommendations'] is List) 
              ? data['recommendations'] as List<dynamic>
              : [];
          
          return {
            'histories': recommendations,
            'recommendations': historyList,
          };
        } else {
          return {
            'histories': [],
            'recommendations': [],
          };
        }
      } else {
        return {
          'recommendations': [],
          'histories': []
        };
      }
    } catch (e) {
      return {
        'recommendations': [],
        'histories': [],
      };
    }
  }

  //  "최근 일정" 카테고리 조회 (리뷰가 있는 매장 중 평점 높은 순)
  static Future<Map<String, dynamic>> getRecentScheduleCategories({
    int limit = 10,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/categories',
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // ResponseCategoryListDTO 형식: { categories: [...] }
        final Map<String, dynamic> responseData = 
            data is Map<String, dynamic> ? data : <String, dynamic>{};
        final List<dynamic> categories = 
            (responseData['categories'] as List<dynamic>?) ?? [];

        return {
          'categories': categories,
        };
      } else {
        return {
          'categories': [],
        };
      }
    } catch (e) {
      return {
        'categories': [],
      };
    }
  }

  // 🔥 추가: 리뷰 작성 가능한 매장 목록 조회
  static Future<List<ReviewableStore>> getReviewableStores({
    int limit = 6,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/users/me/reviews/reviewable?limit=$limit',
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        final reviewList = data['review_list'] as List<dynamic>? ?? [];

        if (reviewList.isEmpty) {
          return [];
        }

        final stores = <ReviewableStore>[];

        for (final item in reviewList) {
          final review = item as Map<String, dynamic>;

          final categoryId = review['category_id'] ?? '';
          final categoryName = review['category_name'] ?? '';
          final visitCount = review['stars'] ?? 0;
          
          // 전체 주소 가져오기 (다른 곳에서처럼 getRestaurant 사용)
          String address = '주소 정보 없음';
          if (categoryId.isNotEmpty) {
            try {
              final restaurant = await getRestaurant(categoryId);
              // detailAddress 우선, 없으면 address getter 사용
              final rawAddress = restaurant.detailAddress ?? restaurant.address;
              if (rawAddress != null && rawAddress.trim().isNotEmpty) {
                address = rawAddress.trim(); // 앞뒤 공백 제거
              } else {
                address = '주소 정보 없음';
              }
            } catch (e) {
              // 실패 시 comment 필드 사용 (fallback)
              final comment = review['comment']?.toString();
              address = (comment != null && comment.trim().isNotEmpty) 
                  ? comment.trim() 
                  : '주소 정보 없음';
            }
          } else {
            // category_id가 없으면 comment 필드 사용
            final comment = review['comment']?.toString();
            address = (comment != null && comment.trim().isNotEmpty) 
                ? comment.trim() 
                : '주소 정보 없음';
          }

          stores.add(
            ReviewableStore(
              categoryId: categoryId,
              categoryName: categoryName,
              categoryType: review['category_type'] ?? '',
              imageUrl: null,
              address: address,
              visitCount: visitCount is int ? visitCount : 0,
              reviewCount: 0,
              lastVisitDate: review['created_at'] != null
                  ? DateTime.parse(review['created_at'])
                  : DateTime.now(),
            ),
          );
        }

        return stores;
      } else {
        return [];
      }
    } catch (e) {
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
