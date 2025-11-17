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

  // "오늘의 추천" 카드 
  static Future<Map<String, dynamic>> getTodayRecommendations() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔍 [오늘의 추천] API 호출 시작');
      debugPrint('📍 엔드포인트: /api/categories/today-recommendations');

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/categories/today-recommendations',
        headers: headers,
      );

      debugPrint('📡 [오늘의 추천] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('📦 [오늘의 추천] 응답 데이터 타입: ${data.runtimeType}');
        debugPrint('📦 [오늘의 추천] 응답 데이터 전체: $data');

        // 응답은 배열: [히스토리 리스트, 추천 데이터]
        // data[0] = 히스토리 리스트
        // data[1] = 추천 데이터 (to_main(1) 결과 = ResponseCategoryListDTO)
        if (data is List && data.length >= 2) {
          // 첫 번째 요소: 히스토리 리스트
          final firstItem = data[0];
          debugPrint('📋 [오늘의 추천] 첫 번째 요소 타입: ${firstItem.runtimeType}');
          debugPrint('📋 [오늘의 추천] 첫 번째 요소 내용: $firstItem');
          
          final historyList = (firstItem is List) 
              ? firstItem 
              : (firstItem is Map) 
                  ? [firstItem] 
                  : [];
          
          // 두 번째 요소: 추천 데이터 (ResponseCategoryListDTO 형식)
          final secondItem = data[1];
          debugPrint('📋 [오늘의 추천] 두 번째 요소 타입: ${secondItem.runtimeType}');
          debugPrint('📋 [오늘의 추천] 두 번째 요소 내용: $secondItem');
          
          List<dynamic> recommendations = [];
          
          if (secondItem is Map<String, dynamic>) {
            // ResponseCategoryListDTO 형식: { categories: [...] }
            final categories = secondItem['categories'];
            debugPrint('📋 [오늘의 추천] categories 필드 타입: ${categories.runtimeType}');
            debugPrint('📋 [오늘의 추천] categories 필드 내용: $categories');
            
            if (categories is List) {
              recommendations = categories;
            } else if (categories != null) {
              recommendations = [categories];
            }
          } else if (secondItem is List) {
            recommendations = secondItem;
          }

          debugPrint('📊 [오늘의 추천] 파싱 결과:');
          debugPrint('   - 히스토리 개수: ${historyList.length}');
          debugPrint('   - 추천 데이터 개수: ${recommendations.length}');
          
          if (recommendations.isNotEmpty) {
            debugPrint('📊 [오늘의 추천] 추천 데이터 첫 번째 항목:');
            debugPrint('   ${recommendations[0]}');
          }

          final result = {
            'histories': historyList,  // data[0] = 히스토리 리스트
            'recommendations': recommendations,  // data[1] = 추천 데이터
          };
          
          debugPrint('✅ [오늘의 추천] API 호출 성공');
          debugPrint('═══════════════════════════════════════════════════════');
          
          return result;
        } else if (data is Map<String, dynamic>) {
          // Map 형식 응답 처리 (하위 호환성)
          debugPrint('⚠️ [오늘의 추천] 응답이 Map 형식입니다. Map 형식으로 처리합니다.');
          final historyList = (data['histories'] is List) 
              ? data['histories'] as List<dynamic>
              : [];
          final recommendations = (data['recommendations'] is List) 
              ? data['recommendations'] as List<dynamic>
              : [];
          
          debugPrint('📊 [오늘의 추천] Map 형식 파싱 결과:');
          debugPrint('   - 히스토리 개수: ${historyList.length}');
          debugPrint('   - 추천 데이터 개수: ${recommendations.length}');
          
          return {
            'histories': recommendations,
            'recommendations': historyList,
          };
        } else {
          debugPrint('⚠️ [오늘의 추천] 응답 형식이 예상과 다릅니다: ${data.runtimeType}');
          debugPrint('═══════════════════════════════════════════════════════');
          return {
            'histories': [],
            'recommendations': [],
          };
        }
      } else {
        debugPrint('❌ [오늘의 추천] 응답 오류: ${response.statusCode}');
        debugPrint('═══════════════════════════════════════════════════════');
        return {
          'recommendations': [],
          'histories': []
        };
      }
    } catch (e) {
      debugPrint('❌ [오늘의 추천] 데이터 조회 오류: $e');
      debugPrint('═══════════════════════════════════════════════════════');
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
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔍 [최근 일정] API 호출 시작');
      debugPrint('📍 엔드포인트: /api/categories');
      debugPrint('📋 limit 파라미터: $limit');

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        ...TokenManager.jwtHeader,
      };

      final response = await HttpInterceptor.get(
        '/api/categories',
        headers: headers,
      );

      debugPrint('📡 [최근 일정] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('📦 [최근 일정] 응답 데이터 타입: ${data.runtimeType}');
        debugPrint('📦 [최근 일정] 응답 데이터 전체: $data');

        // ResponseCategoryListDTO 형식: { categories: [...] }
        final Map<String, dynamic> responseData = 
            data is Map<String, dynamic> ? data : <String, dynamic>{};
        final List<dynamic> categories = 
            (responseData['categories'] as List<dynamic>?) ?? [];

        debugPrint('📊 [최근 일정] 파싱 결과:');
        debugPrint('   - 카테고리 개수: ${categories.length}');
        
        if (categories.isNotEmpty) {
          debugPrint('📊 [최근 일정] 첫 번째 카테고리:');
          debugPrint('   ${categories[0]}');
        }

        debugPrint('✅ [최근 일정] API 호출 성공');
        debugPrint('═══════════════════════════════════════════════════════');

        return {
          'categories': categories,
        };
      } else {
        debugPrint('❌ [최근 일정] 응답 오류: ${response.statusCode}');
        debugPrint('═══════════════════════════════════════════════════════');
        return {
          'categories': [],
        };
      }
    } catch (e) {
      debugPrint('❌ [최근 일정] 카테고리 조회 오류: $e');
      debugPrint('═══════════════════════════════════════════════════════');
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
          final address = review['comment'] ?? '주소 정보 없음';
          final visitCount = review['stars'] ?? 0;

          // 🔥 이미지 조회 없이 바로 객체 생성
          stores.add(
            ReviewableStore(
              categoryId: categoryId,
              categoryName: categoryName,
              categoryType: review['category_type'] ?? '',
              imageUrl: null, // 🔥 이미지 없음
              address: address,
              visitCount: visitCount is int ? visitCount : 0,
              reviewCount: 0,
              lastVisitDate: review['created_at'] != null
                  ? DateTime.parse(review['created_at'])
                  : DateTime.now(),
            ),
          );

          debugPrint('✅ ${categoryName} 추가 완료 (이미지 조회 생략)');
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
