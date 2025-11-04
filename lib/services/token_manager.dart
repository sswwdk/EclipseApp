import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';

class TokenManager {
  static String get baseUrl => ServerConfig.baseUrl;
  static String? _accessToken;
  static String? _refreshToken;
  static String? _userName;
  static String? _userId;
  static String? _userEmail;

  /// 액세스 토큰 저장
  static void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    print('토큰 저장 완료 - Access: ${accessToken.substring(0, 10)}..., Refresh: ${refreshToken.substring(0, 10)}...');
  }

  /// 액세스 토큰 가져오기
  static String? get accessToken => _accessToken;

  /// 리프레시 토큰 가져오기
  static String? get refreshToken => _refreshToken;

  /// 사용자 이름 가져오기
  static String? get userName => _userName;

  /// 사용자 ID 가져오기
  static String? get userId => _userId;

  /// 사용자 이메일 가져오기
  static String? get userEmail => _userEmail;

  /// 사용자 이름 저장
  static void setUserName(String? name) {
    _userName = name;
  }

  /// 사용자 ID 저장
  static void setUserId(String? id) {
    _userId = id;
  }

  /// 사용자 이메일 저장
  static void setUserEmail(String? email) {
    _userEmail = email;
  }

  /// JWT 헤더 생성
  static Map<String, String> get jwtHeader {
    if (_accessToken != null) {
      return {'jwt': _accessToken!};
    }
    return {};
  }

  /// 토큰이 있는지 확인
  static bool get hasTokens => _accessToken != null && _refreshToken != null;

  /// 토큰 초기화 (로그아웃 시)
  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _userName = null;
    _userId = null;
    _userEmail = null;
    print('토큰 초기화 완료');
  }

  /// 액세스 토큰 갱신
  static void updateAccessToken(String newAccessToken) {
    _accessToken = newAccessToken;
    print('액세스 토큰 갱신 완료: ${newAccessToken.substring(0, 10)}...');
  }

  /// 토큰 갱신 (refresh token 사용)
  static Future<bool> refreshTokens() async {
    if (_refreshToken == null) {
      print('리프레시 토큰이 없습니다.');
      return false;
    }

    try {
      print('토큰 갱신 시도 중...');
      
      // 서버가 요구한 DTO 포맷으로 요청
      final envelope = {
          'token': _refreshToken,
          'id': userId
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(envelope),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('토큰 갱신 시간 초과');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        final String? newAccessToken = data['token'] as String?;
        
        if (newAccessToken != null) {
          _accessToken = newAccessToken;
          print('액세스 토큰 갱신 완료: ${newAccessToken.substring(0, 10)}...');
          return true;
        } else {
          print('토큰 갱신 응답에 access_token이 없습니다.');
          return false;
        }
      } else {
        print('토큰 갱신 실패: HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('토큰 갱신 실패: $e');
      return false;
    }
  }
}
