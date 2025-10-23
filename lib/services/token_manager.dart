class TokenManager {
  static String? _accessToken;
  static String? _refreshToken;

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
      // TODO: 실제 토큰 갱신 API 호출 구현
      // 현재는 임시로 false 반환
      print('토큰 갱신 시도 중...');
      print('리프레시 토큰: ${_refreshToken!.substring(0, 10)}...');
      
      // 실제 구현 시:
      // 1. refresh token으로 새로운 access token 요청
      // 2. 응답에서 새로운 토큰들 추출
      // 3. setTokens()로 새로운 토큰들 저장
      // 4. 성공/실패 반환
      
      return false; // 임시로 실패 반환
    } catch (e) {
      print('토큰 갱신 실패: $e');
      return false;
    }
  }
}
