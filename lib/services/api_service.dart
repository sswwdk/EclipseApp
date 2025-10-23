import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.14.51:8080';
  
  // 레스토랑 목록 조회 (기존 category 테이블에서)
  static Future<List<Restaurant>> getRestaurants() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/service/main'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          List<dynamic> restaurants = data['data'];
          return restaurants.map((json) => Restaurant.fromJson(json)).toList();
        } else {
          throw Exception('API 응답 오류: ${data['message']}');
        }
      } else {
        throw Exception('HTTP 오류: ${response.statusCode}');
      }
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/service/main/$id'),
        headers: headers,
      );
      
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
  
  // API 상태 확인
  static Future<bool> checkApiStatus() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.jwtHeader,
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('API 상태 확인 오류: $e');
      return false;
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

  // 기존 코드와의 호환성을 위한 getter들
  String? get address => detailAddress != null ? '${si ?? ''} ${gu ?? ''} ${detailAddress ?? ''}' : null;
  String? get imageUrl => image;
  double get rating => 4.0; // 기본값
  String? get description => subCategory;
}
