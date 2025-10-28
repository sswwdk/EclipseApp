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
        'headers': {
          'content_type': 'application/json',
          'jwt': TokenManager.accessToken,
        },
        'body': "qwerfgh",
      };

    final response = await HttpInterceptor.post(
      '/api/service/main',
      headers: headers,
      body: json.encode(requestBody),
    );
      
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final Map<String, dynamic>? body = data['body'] as Map<String, dynamic>?;
      final List<dynamic> categories = (body?['categories'] as List<dynamic>?) ?? const [];
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
      
      final response = await HttpInterceptor.get('/api/service/main/$id', headers: headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          return Restaurant.fromJson(data['data']);
        } else {
          throw Exception('API 응답 오류: ${data['message']}');
        }
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
    );
  }

  // 기존 코드와의 호환성을 위한 getter들
  String? get address => detailAddress != null ? '${si ?? ''} ${gu ?? ''} ${detailAddress ?? ''}' : null;
  String? get imageUrl => image;
  double get rating => 4.0; // 기본값
  String? get description => subCategory;
}
