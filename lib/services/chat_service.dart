import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class ChatService {
  static const String baseUrl = 'http://192.168.14.51:8080';

  // 채팅 보기
  static Future<Map<String, dynamic>> getChat(String userId, String otherId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/$userId/$otherId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

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
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/$userId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

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
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
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
