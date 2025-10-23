import 'dart:convert';
import 'package:http/http.dart' as http;

/// FastAPI 서버와 통신하는 서비스
class OpenAIService {
  // FastAPI 서버 주소
  // Android 에뮬레이터: 'http://10.0.2.2:8000'
  // iOS 시뮬레이터: 'http://localhost:8000'
  // 실제 기기: 'http://<컴퓨터_IP>:8000'
  static const String baseUrl = 'http://localhost:8000';
  
  // 현재 세션 ID
  String? _sessionId;
  
  // 세션 ID getter
  String? get sessionId => _sessionId;

  /// 대화 초기화 - FastAPI /api/start 호출
  Future<String> initialize({
    required int peopleCount,
    required List<String> selectedCategories,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/start'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'peopleCount': peopleCount,
          'selectedCategories': selectedCategories,
        }),
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

  /// 메시지 전송 - FastAPI /api/chat 호출
  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    if (_sessionId == null) {
      throw Exception('세션이 초기화되지 않았습니다.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sessionId': _sessionId,
          'message': userMessage,
        }),
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
      final response = await http.post(
        Uri.parse('$baseUrl/api/confirm-results'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sessionId': _sessionId,
          'message': '네', // "네" 응답으로 처리
        }),
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