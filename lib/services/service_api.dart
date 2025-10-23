import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class ServiceApi {
  static const String baseUrl = 'http://192.168.14.51:8080';

  // 메인 로직 시작 (하루랑 채팅 시작 시)
  static Future<Map<String, dynamic>> startMainLogic(int numPeople, String category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/start'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          '인원수': numPeople,
          '카테고리': category,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('메인 로직 시작 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('메인 로직 시작 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 하루랑 채팅
  static Future<Map<String, dynamic>> chatWithHaru(String prompt, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/chat'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'prompt': prompt,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('채팅 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('채팅 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 커뮤니티 공유
  static Future<Map<String, dynamic>> shareToCommunity(String content, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/community'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'content': content,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('커뮤니티 공유 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('커뮤니티 공유 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 친구에게 공유
  static Future<Map<String, dynamic>> shareWithFriend(String content, String friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/person'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'content': content,
          'friend_id': friendId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('친구 공유 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('친구 공유 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 찜하기
  static Future<Map<String, dynamic>> likeStore(String storeId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/like/$storeId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('찜하기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('찜하기 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 찜 취소
  static Future<Map<String, dynamic>> unlikeStore(String storeId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/service/like/$storeId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('찜 취소 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('찜 취소 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 템플릿 선택
  static Future<Map<String, dynamic>> selectTemplate(String templateId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/templates'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'template_id': templateId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('템플릿 선택 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('템플릿 선택 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 템플릿 조회
  static Future<Map<String, dynamic>> getTemplate(String templateId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/service/templates/$templateId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('템플릿 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('템플릿 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
