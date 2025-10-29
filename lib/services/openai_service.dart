import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_interceptor.dart';
import 'token_manager.dart';

/// FastAPI 서버와 통신하는 서비스
class OpenAIService {
  // FastAPI 서버 주소
  static const String baseUrl = 'http://192.168.14.51:8080';
  
  // 현재 세션 ID
  String? _sessionId;
  
  // 세션 ID getter
  String? get sessionId => _sessionId;

  /// 대화 초기화 - FastAPI /api/service/start 호출
  Future<String> initialize({
    required int peopleCount,
    required List<String> selectedCategories,
  }) async {
    try {
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
        'headers': {
          'contentType': 'application/json',
          'jwt': TokenManager.accessToken,
        },
        'body': {
          'peopleCount': peopleCount,
          'selectedCategories': selectedCategories,
        },
      };

      // 디버깅을 위한 로그
      print('요청 본문: ${jsonEncode(requestBody)}');
      
      final response = await HttpInterceptor.post(
        '/api/service/start',
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (30초)');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _sessionId = data['sessionId'];
        return data['message'] ?? '대화를 시작합니다!';
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('초기화 중 오류 발생: $e');
    }
  }

  /// 메시지 전송 - FastAPI /api/service/chat 호출
  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    if (_sessionId == null) {
      throw Exception('세션이 초기화되지 않았습니다.');
    }

    try {
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
        'headers': {
          'contentType': 'application/json',
          'jwt': TokenManager.accessToken,
        },
        'body': {
          'sessionId': _sessionId,
          'message': userMessage,
        },
      };

      final response = await HttpInterceptor.post(
        '/api/service/chat',
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (30초)');
        },
      );

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
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('메시지 전송 중 오류 발생: $e');
    }
  }

  /// 추천 결과 요청 - /api/confirm-results 엔드포인트 직접 호출
  Future<Map<String, dynamic>> requestRecommendations() async {
    if (_sessionId == null) {
      throw Exception('세션이 초기화되지 않았습니다.');
    }

    try {
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
        'headers': {
          'contentType': 'application/json',
          'jwt': TokenManager.accessToken,
        },
        'body': {
          'sessionId': _sessionId,
          'message': '네', // "네" 응답으로 처리
        },
      };

      final response = await HttpInterceptor.post(
        '/api/confirm-results',
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (30초)');
        },
      );

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

  /// 세션 초기화
  void clearSession() {
    _sessionId = null;
  }
}