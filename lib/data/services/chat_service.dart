import 'dart:convert';
import '../../shared/helpers/http_interceptor.dart';
import '../../core/config/server_config.dart';

class ChatService {
  static String get communityUrl => ServerConfig.communityUrl;

  // 채팅 보기
  static Future<Map<String, dynamic>> getChat(String userId) async {
    try {
      final response = await HttpInterceptor.get(
        '/api/message/$userId',
        baseUrlOverride: communityUrl,
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
  static Future<Map<String, dynamic>> getChatList() async {
    try {
      final response = await HttpInterceptor.get(
        '/api/message/',
        baseUrlOverride: communityUrl,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is List) {
          return {'data': decoded};
        }
        return {'data': decoded};
      } else {
        throw Exception('채팅 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('채팅 목록 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 채팅 보내기
  static Future<String> sendChat(String receiverId, String message) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/message/',
        body: json.encode({
          'receiver_id': receiverId,
          'message': message,
        }),
        baseUrlOverride: communityUrl,
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
