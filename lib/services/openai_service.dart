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
    required String playAddress, // 위치 값
    required int peopleCount,
    required List<String> selectedCategories,
  }) async {
    try {
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
          'play_address': playAddress, // 서버와 합의된 키 이름 (오타 수정)
          'peopleCount': peopleCount,
          'selectedCategories': selectedCategories
      };

      // HttpInterceptor 대신 직접 HTTP 요청 전송 (변환 방지)
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/start'),
        headers: {
          'Content-Type': 'application/json',
          'jwt': TokenManager.accessToken ?? ''
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (30초)');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // 응답에서 sessionId 추출 (다양한 위치에서 시도)
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

  /// 메시지 전송 - FastAPI /api/service/chat 호출
  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    if (_sessionId == null) {
      throw Exception('세션이 초기화되지 않았습니다.');
    }

    try {
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
          'sessionId': _sessionId,
          'message': userMessage,
      };

      // HttpInterceptor 대신 직접 HTTP 요청 전송 (변환 방지)
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/chat'),
        headers: {
          'Content-Type': 'application/json',
          'jwt': TokenManager.accessToken ?? ''
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (30초)');
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${utf8.decode(response.bodyBytes)}');

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

  /// 추천 결과 요청 - /api/confirm-results 엔드포인트 직접 호출
  Future<Map<String, dynamic>> requestRecommendations() async {
    if (_sessionId == null) {
      throw Exception('세션이 초기화되지 않았습니다.');
    }

    try {
      // 서버가 기대하는 DTO 형식으로 요청 구성
      final requestBody = {
          'sessionId': _sessionId,
          'message': '네', // "네" 응답으로 처리
      };

      final response = await HttpInterceptor.post(
        '/api/confirm-results',
        headers: {
          'Content-Type': 'application/json',
          'jwt': TokenManager.accessToken ?? ''
        },
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