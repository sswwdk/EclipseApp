/// 서버 연결 URL 관리
/// 설훈 : 54 , 석훈 : 36
class ServerConfig {
  // 서버 기본 URL
  static const String baseUrl = 'http://192.168.14.33:8080';
  static const String communityUrl = 'http://192.168.14.33:8082';

  // API 엔드포인트
  static String get apiBaseUrl => baseUrl;
  static String get communityApiBaseUrl => communityUrl;
}
