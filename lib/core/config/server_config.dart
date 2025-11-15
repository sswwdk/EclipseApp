/// 서버 연결 URL 관리
/// 설훈 : 54 , 석훈 : 36
class ServerConfig {
  // 서버 기본 URL
<<<<<<< Updated upstream
  static const String baseUrl = 'http://192.168.14.33:8080';
  static const String communityUrl = 'http://3.37.111.100:8082';
  static const String communityUrl = 'http://192.168.14.33:8082';
=======
  static const String baseUrl = 'http://118.33.94.109:8080';
  static const String communityUrl = 'http://118.33.94.109:8082';
>>>>>>> Stashed changes

  // API 엔드포인트
  static String get apiBaseUrl => baseUrl;
  static String get communityApiBaseUrl => communityUrl;
}
