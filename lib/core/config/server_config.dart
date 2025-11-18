/// 서버 연결 URL 관리
/// 설훈 : 54 , 석훈 : 36
class ServerConfig {
  // 서버 기본 URL
  static const String baseUrl = 'http://54.116.3.178:8080';
  static const String communityUrl = 'http://3.37.111.100:8082';

  // API 엔드포인트
  static String get apiBaseUrl => baseUrl;
  static String get communityApiBaseUrl => communityUrl;
}
