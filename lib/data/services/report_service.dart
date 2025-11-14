import 'dart:convert';
import '../../core/config/server_config.dart';
import '../../shared/helpers/http_interceptor.dart';

class ReportService {
  static String get baseUrl => ServerConfig.baseUrl;
  static String get communityUrl => ServerConfig.communityUrl;

  /// 신고하기 (사용자/게시글/댓글 통합)
  /// [targetId] 신고 대상 ID (사용자 ID, 게시글 ID, 또는 댓글 ID)
  /// [reason] 신고 사유 텍스트
  /// [causeId] 신고 사유 ID ("0": 스팸/광고, "1": 욕설/비방, "2": 음란물, "3": 개인정보 유출, "4": 기타)
  /// [type] 신고 타입 ("0": 사용자, "1": 게시글, "2": 댓글)
  static Future<String> report(
    String targetId,
    String reason,
    String causeId,
    String type,
  ) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/report/',
        baseUrlOverride: communityUrl,
        body: json.encode({
          'reported_user': targetId,
          'cause': reason,
          'cause_id': causeId,
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('신고 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('신고 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 신고 내역 조회
  /// [userId] 사용자 ID
  static Future<String> getReportHistory(String userId) async {
    try {
      final response = await HttpInterceptor.get(
        '/api/community/report?user_id=$userId',
        baseUrlOverride: communityUrl,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('신고 내역 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('신고 내역 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}

