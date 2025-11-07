import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_interceptor.dart';
import 'token_manager.dart';
import '../config/server_config.dart';

class ServiceApi {
  static String get baseUrl => ServerConfig.baseUrl;

  // 메인 로직 시작 (하루랑 채팅 시작 시) - OpenAIService로 위임
  static Future<Map<String, dynamic>> startMainLogic(int numPeople, String category) async {
    final svc = OpenAIService();
    final message = await svc.initialize(
      playAddress: '',
      peopleCount: numPeople,
      selectedCategories: [category],
    );
    return {
      'message': message,
      'sessionId': svc.sessionId,
      'status': 'success',
    };
  }

  // 하루랑 채팅
  static Future<Map<String, dynamic>> chatWithHaru(String prompt) async {
    final svc = OpenAIService();
    // 기존 코드와의 호환을 위해 sessionId가 없으면 초기화 보장
    if (svc.sessionId == null) {
      await svc.initialize(playAddress: '', peopleCount: 1, selectedCategories: const []);
    }
    return await svc.sendMessage(prompt);
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

/// 채팅 세션을 관리하는 서비스 (기존 OpenAIService 통합)
class OpenAIService {
  static String get baseUrl => ServerConfig.baseUrl;
  String? _sessionId;
  String? get sessionId => _sessionId;

  Future<String> initialize({
    required String playAddress,
    required int peopleCount,
    required List<String> selectedCategories,
  }) async {
    try {
      final requestBody = {
        'play_address': playAddress,
        'peopleCount': peopleCount,
        'selectedCategories': selectedCategories
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/service/start'),
        headers: {
          'Content-Type': 'application/json',
          'jwt': TokenManager.accessToken ?? ''
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 120), onTimeout: () {
        throw Exception('서버 연결 시간 초과 (120초)');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _sessionId = data['sessionId'] ?? data['body']?['sessionId'] ?? data['data']?['sessionId'];
        final message = data['message'] ?? data['body']?['message'] ?? '대화를 시작합니다!';
        return message;
      } else {
        throw Exception('초기화 실패: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      throw Exception('초기화 중 오류 발생: $e');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    if (_sessionId == null) {
      throw Exception('세션이 초기화되지 않았습니다.');
    }

    try {
      final requestBody = {
        'sessionId': _sessionId,
        'message': userMessage,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/service/chat'),
        headers: {
          'Content-Type': 'application/json',
          'jwt': TokenManager.accessToken ?? ''
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 120), onTimeout: () {
        throw Exception('서버 연결 시간 초과 (120초)');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'status': data['status'] ?? 'success',
          'message': data['message'] ?? '',
          'stage': data['stage'] ?? 'collecting_details',
          'tags': data['tags'] as List<dynamic>?,
          'progress': data['progress'] as Map<String, dynamic>?,
          'recommendations': data['recommendations'] as Map<String, dynamic>?,
          'showYesNoButtons': data['showYesNoButtons'] ?? false,
          'yesNoQuestion': data['yesNoQuestion'] as String?,
          'currentCategory': data['currentCategory'] as String?,
          'availableCategories': data['availableCategories'] as List<dynamic>?,
        };
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      throw Exception('메시지 전송 중 오류 발생: $e');
    }
  }

  Future<Map<String, dynamic>> requestRecommendations() async {
    if (_sessionId == null) {
      throw Exception('세션이 초기화되지 않았습니다.');
    }

    try {
      final requestBody = {
        'sessionId': _sessionId,
        'message': '네',
      };

      final response = await HttpInterceptor.post(
        '/api/confirm-results',
        headers: {
          'Content-Type': 'application/json',
          'jwt': TokenManager.accessToken ?? ''
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 120), onTimeout: () {
        throw Exception('서버 연결 시간 초과 (120초)');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'status': data['status'] ?? 'success',
          'message': data['message'] ?? '',
          'stage': data['stage'] ?? 'completed',
          'tags': data['tags'] as List<dynamic>?,
          'progress': data['progress'] as Map<String, dynamic>?,
          'recommendations': data['recommendations'] as Map<String, dynamic>?,
          'showYesNoButtons': data['showYesNoButtons'] ?? false,
          'yesNoQuestion': data['yesNoQuestion'] as String?,
          'currentCategory': data['currentCategory'] as String?,
          'availableCategories': data['availableCategories'] as List<dynamic>?,
        };
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('추천 결과 요청 중 오류 발생: $e');
    }
  }

  void clearSession() {
    _sessionId = null;
  }
}
