import 'dart:convert';
import 'http_interceptor.dart';
import 'token_manager.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.14.51:8080';
  
  // 메인 화면 데이터 조회 (새로운 DTO 형식)
  static Future<List<Restaurant>> getRestaurants() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final requestBody = {
        'body': "qwerfgh",
      };

    final response = await HttpInterceptor.post(
      '/api/service/main',
      headers: headers,
      body: json.encode(requestBody),
    );
      
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> categories = (data?['categories'] as List<dynamic>?) ?? const [];
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
        '/api/service/detail/$id',
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> root = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        final Map<String, dynamic> obj =
            (root['data'] is Map<String, dynamic>) ? Map<String, dynamic>.from(root['data']) : root;

        // 이 API에서는 태그/리뷰만 사용한다. 나머지는 기본값으로 반환
        return Restaurant(
          id: id,
          name: '',
          rating: _parseDouble(obj['rating']) ?? 0.0,
          reviews: Review.fromList(obj['reviews']),
          tags: _parseStringList(obj['tags']),
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

class Restaurant {
  final String id;
  final String name;
  final String? do_;
  final String? si;
  final String? gu;
  final String? detailAddress;
  final String? subCategory;
  final String? businessHour;
  final String? phone;
  final String? type;
  final String? image;
  final String? latitude;
  final String? longitude;
  final String? lastCrawl;
  final double? rating;
  final List<Review> reviews;
  final List<String> tags;

  Restaurant({
    required this.id,
    required this.name,
    this.do_,
    this.si,
    this.gu,
    this.detailAddress,
    this.subCategory,
    this.businessHour,
    this.phone,
    this.type,
    this.image,
    this.latitude,
    this.longitude,
    this.lastCrawl,
    this.rating,
    this.reviews = const [],
    this.tags = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      do_: json['do'],
      si: json['si'],
      gu: json['gu'],
      detailAddress: json['detail_address'],
      subCategory: json['sub_category'],
      businessHour: json['business_hour'],
      phone: json['phone'],
      type: json['type'],
      image: json['image'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      lastCrawl: json['last_crawl'],
      rating: _parseDouble(json['rating']),
      reviews: Review.fromList(json['reviews']),
      tags: _parseStringList(json['tags']),
    );
  }

  // 서버 응답 형식에 맞는 팩토리 메서드
  factory Restaurant.fromMainScreenJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['title']?.toString() ?? '',
      image: json['image_url']?.toString(),
      subCategory: json['sub_category']?.toString(),
      detailAddress: json['detail_address']?.toString(),
      phone: json['phone']?.toString(),
      do_: null,
      si: null,
      gu: null,
      businessHour: null,
      type: null,
      latitude: null,
      longitude: null,
      lastCrawl: null,
      rating: _parseDouble(json['rating']),
      reviews: Review.fromList(json['reviews']),
      tags: _parseStringList(json['tags']),
    );
  }

  // 기존 코드와의 호환성을 위한 getter들
  String? get address => detailAddress != null ? '${si ?? ''} ${gu ?? ''} ${detailAddress ?? ''}' : null;
  String? get imageUrl => image;
  String? get description => subCategory;
}

class Review {
  final String nickname;
  final double rating;
  final String content;

  Review({required this.nickname, required this.rating, required this.content});

  static List<Review> fromList(dynamic src) {
    if (src is List) {
      return src.whereType<Map<String, dynamic>>().map((m) => Review(
        nickname: (m['nickname'] ?? m['user'] ?? '익명').toString(),
        rating: _parseDouble(m['rating']) ?? 0.0,
        content: (m['content'] ?? m['text'] ?? '').toString(),
      )).toList();
    }
    return const [];
  }
}

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
