import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/helpers/token_manager.dart';
import '../../core/config/server_config.dart';

class CommunityService {
  static String get communityUrl => ServerConfig.communityUrl;

  // 모든 글 조회 (커뮤니티 메인 접속)
  static Future<Map<String, dynamic>> getAllPosts({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$communityUrl/api/community/home/$page'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
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
  static Future<Map<String, dynamic>> getSpecificPost(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$communityUrl/api/community/post/$query'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
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
  static Future<Map<String, dynamic>> createPost(String userId, String title, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$communityUrl/api/community/post'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'user_id': userId,
          'title': title,
          'content': content,
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
  static Future<Map<String, dynamic>> deletePost(String postId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$communityUrl/api/community/post/$postId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'user_id': userId}),
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
      final response = await http.get(
        Uri.parse('$communityUrl/api/community/post/me?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('내글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('내글 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 댓글 조회
  static Future<Map<String, dynamic>> getComments(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$communityUrl/api/community/$postId/comment'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
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
  static Future<Map<String, dynamic>> createComment(String postId, String userId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$communityUrl/api/community/$postId/comment'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'user_id': userId,
          'content': content,
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
  static Future<Map<String, dynamic>> deleteComment(String postId, String commentId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$communityUrl/api/community/$postId/comment'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'comment_id': commentId,
          'user_id': userId,
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
      final response = await http.get(
        Uri.parse('$communityUrl/api/community/comment/me?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
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
      final response = await http.post(
        Uri.parse('$communityUrl/api/community/report'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
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
      final response = await http.get(
        Uri.parse('$communityUrl/api/community/report?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
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
