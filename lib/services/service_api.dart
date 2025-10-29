import 'dart:convert';
import 'http_interceptor.dart';
import 'token_manager.dart';

class ServiceApi {
  static const String baseUrl = 'http://192.168.14.51:8080';

  // 메인 로직 시작 (하루랑 채팅 시작 시)
  static Future<Map<String, dynamic>> startMainLogic(int numPeople, String category) async {
    try {
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
        'headers': {
          'contentType': 'application/json',
          'jwt': TokenManager.accessToken,
        },
        'body': {
          'peopleCount': numPeople,
          'selectedCategories': [category],
        },
      };

      final response = await HttpInterceptor.post(
        '/api/service/start',
        body: json.encode(requestBody),
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
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
        'headers': {
          'contentType': 'application/json',
          'jwt': TokenManager.accessToken,
        },
        'body': {
          'sessionId': userId, // userId를 sessionId로 사용
          'message': prompt,
        },
      };

      final response = await HttpInterceptor.post(
        '/api/service/chat',
        body: json.encode(requestBody),
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
      final response = await HttpInterceptor.post(
        '/api/service/community',
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
      final response = await HttpInterceptor.post(
        '/api/service/person',
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
      final response = await HttpInterceptor.post(
        '/api/service/like/$storeId',
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
      final response = await HttpInterceptor.delete(
        '/api/service/like/$storeId',
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
      final response = await HttpInterceptor.post(
        '/api/service/templates',
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
      final response = await HttpInterceptor.get('/api/service/templates/$templateId');

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
