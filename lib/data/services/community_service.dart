import 'dart:convert';
import '../../core/config/server_config.dart';
import '../../shared/helpers/http_interceptor.dart';

class CommunityService {
  static String get communityUrl => ServerConfig.communityUrl;

  // 모든 글 조회 (커뮤니티 메인 접속)
  static Future<Map<String, dynamic>> getAllPosts({int page = 1}) async {
    try {
      final response = await HttpInterceptor.get(
        '/api/community/home/$page',
        baseUrlOverride: communityUrl,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('글 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('글 목록 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 특정 글 조회
  static Future<Map<String, dynamic>> getSpecificPost(String postId) async {
    try {
      final response = await HttpInterceptor.get(
        '/api/community/post/$postId',
        baseUrlOverride: communityUrl,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('글 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 글 작성
  static Future<String> createPost(String title, String content, String mergeHistoryId) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/community/post',
        baseUrlOverride: communityUrl,
        body: json.encode({
          'title': title,
          'body': content,
          'merge_history_id': mergeHistoryId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('글 작성 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 글 삭제
  static Future<String> deletePost(int postId, String userId) async {
    try {
      final response = await HttpInterceptor.delete(
        '/api/community/post',
        baseUrlOverride: communityUrl,
        body: json.encode({
          'post_id': postId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('글 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('글 삭제 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 내글 조회
  static Future<Map<String, dynamic>> getMyPosts(String userId) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/community/post/me',
        baseUrlOverride: communityUrl,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('내 글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('내 글 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 댓글 조회
  static Future<Map<String, dynamic>> getComments(String postId) async {
    try {
      final response = await HttpInterceptor.get(
        '/api/community/$postId/comment',
        baseUrlOverride: communityUrl,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('댓글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 댓글 작성
  static Future<String> createComment(int postId, String content) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/community/comment/$postId',
        baseUrlOverride: communityUrl,
        body: json.encode({
          'post_id': postId,
          'body': content,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('댓글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 작성 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 댓글 삭제
  static Future<String> deleteComment(String postId, String commentId) async {
    try {
      final response = await HttpInterceptor.delete(
        '/api/community/comment',
        baseUrlOverride: communityUrl,
        body: json.encode({
          'comment_id': commentId,
          'post_id': postId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('댓글 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 삭제 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 내 댓글 조회
  static Future<Map<String, dynamic>> getMyComments(String userId) async {
    try {
      final response = await HttpInterceptor.get(
        '/api/community/comment/me?user_id=$userId',
        baseUrlOverride: communityUrl,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('내 댓글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('내 댓글 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 신고하기
  static Future<Map<String, dynamic>> reportContent(String userId, String contentType, String contentId, String reason) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/community/report',
        baseUrlOverride: communityUrl,
        body: json.encode({
          'user_id': userId,
          'content_type': contentType,
          'content_id': contentId,
          'reason': reason,
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

  // 신고 내역 조회
  static Future<Map<String, dynamic>> getReportHistory(String userId) async {
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
