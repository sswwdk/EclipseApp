import 'dart:convert';
import 'package:whattodo/shared/helpers/http_interceptor.dart';
import 'package:whattodo/core/config/server_config.dart';

class ChatService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 채팅 보기
  static Future<Map<String, dynamic>> getChat(String userId, String otherId) async {
    try {
      final response = await HttpInterceptor.get('/api/chat/$userId/$otherId');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('채팅 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('채팅 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 채팅 목록
  static Future<Map<String, dynamic>> getChatList(String userId) async {
    try {
      final response = await HttpInterceptor.get('/api/chat/$userId');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('채팅 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('채팅 목록 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 채팅 보내기
  static Future<Map<String, dynamic>> sendChat(String senderId, String receiverId, String message) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/chat',
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('채팅 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('채팅 전송 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
