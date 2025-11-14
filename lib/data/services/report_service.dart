import 'dart:convert';
import '../../core/config/server_config.dart';
import '../../shared/helpers/http_interceptor.dart';
import '../../shared/helpers/token_manager.dart';

class ReportService {
  static String get baseUrl => ServerConfig.baseUrl;
  static String get communityUrl => ServerConfig.communityUrl;

  /// 신고하기 (사용자/게시글/댓글 통합)
  /// [targetId] 신고 대상 ID (사용자 ID, 게시글 ID, 또는 댓글 ID)
  /// [reason] 신고 사유 텍스트
  /// [causeId] 신고 사유 ID ("0": 스팸/광고, "1": 욕설/비방, "2": 음란물, "3": 개인정보 유출, "4": 기타)
  /// [type] 신고 타입 ("0": 사용자, "1": 게시글, "2": 댓글)
  /// [reportedUserId] 신고당한 사용자 ID (게시글/댓글의 경우 작성자 ID, 사용자 신고의 경우 targetId와 동일)
  static Future<void> report(
    String targetId,
    String reason,
    String causeId,
    String type, {
    String? reportedUserId,
  }) async {
    try {
      // 신고하는 사용자 ID (현재 로그인한 사용자)
      final reporterId = TokenManager.userId;
      if (reporterId == null) {
        throw Exception('로그인이 필요합니다.');
      }
      
      // type을 정수로 변환 (0: 사용자, 1: 게시글, 2: 댓글, 3: 문의하기)
      final typeInt = int.tryParse(type) ?? 0;
      
      // type 3 (문의하기)인 경우 처리
      if (typeInt == 3) {
        // 문의하기: user_id는 null, reported_user는 문의한 사람
        final response = await HttpInterceptor.post(
          '/api/report/',
          baseUrlOverride: communityUrl,
          body: json.encode({
            'reported_user': reporterId, // 문의한 사용자 ID (reporter)
            'user_id': null, // 문의하기는 null
            'cause_id': targetId, // 문의하기의 경우 빈 값 또는 특정 값
            'type': typeInt, // 3: 문의하기
            'cause': reason, // 문의 내용
          }),
        );

        if (response.statusCode == 200) {
          final bodyBytes = response.bodyBytes;
          if (bodyBytes.isNotEmpty) {
            try {
              json.decode(utf8.decode(bodyBytes));
            } catch (e) {
              print('응답 파싱 오류 (무시됨): $e');
            }
          }
          return;
        } else {
          throw Exception('문의 접수 실패: ${response.statusCode}');
        }
      }
      
      // 신고당한 사용자 ID 결정 (type 0, 1, 2인 경우)
      // type 0 (사용자 신고): reportedUserId가 신고당한 사용자 ID
      // type 1 (게시글 신고): reportedUserId가 게시글 작성자 ID (필수)
      // type 2 (댓글 신고): reportedUserId가 댓글 작성자 ID (필수)
      if (reportedUserId == null || reportedUserId.isEmpty) {
        throw Exception('신고당한 사용자 정보가 필요합니다.');
      }
      
      // cause_id 결정: 타입에 따라 신고 대상 ID
      // type 0 (사용자 신고): targetId (사용자 ID)
      // type 1 (게시글 신고): targetId (게시글 ID)
      // type 2 (댓글 신고): targetId (댓글 ID)
      final causeIdValue = targetId;
      
      final response = await HttpInterceptor.post(
        '/api/report/',
        baseUrlOverride: communityUrl,
        body: json.encode({
          'reported_user': reportedUserId, // 신고하는 사용자 ID (reporter)
          'user_id': reporterId, // 신고당한 사용자 ID
          'cause_id': causeIdValue, // 신고 대상 ID (게시글 ID, 유저 ID, 댓글 ID)
          'type': typeInt, // 0: 사용자, 1: 게시글, 2: 댓글 (int)
          'cause': reason, // 신고 사유
        }),
      );

      if (response.statusCode == 200) {
        // 응답 본문이 있으면 파싱, 없으면 무시 (DB 저장은 성공)
        final bodyBytes = response.bodyBytes;
        if (bodyBytes.isNotEmpty) {
          try {
            json.decode(utf8.decode(bodyBytes));
          } catch (e) {
            // JSON 파싱 실패는 무시 (DB 저장은 성공했을 수 있음)
            print('응답 파싱 오류 (무시됨): $e');
          }
        }
        return;
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

