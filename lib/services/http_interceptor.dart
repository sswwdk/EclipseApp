import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

/// HTTP 요청을 가로채서 401 에러 시 자동으로 토큰 갱신 후 재시도하는 인터셉터
class HttpInterceptor {
  static const String baseUrl = 'http://192.168.14.51:8080';

  /// GET 요청을 보내고 401 에러 시 토큰 갱신 후 재시도
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
    );

    if (response.statusCode == 401 && retryOn401) {
      return await _retryWithRefresh(() => get(endpoint, headers: headers, retryOn401: false));
    }

    return response;
  }

  /// POST 요청을 보내고 401 에러 시 토큰 갱신 후 재시도
  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool retryOn401 = true,
  }) async {
    final Object? finalBody = _attachDtoHeadersIfNeeded(body);
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
      body: finalBody,
    );

    if (response.statusCode == 401 && retryOn401) {
      return await _retryWithRefresh(() => post(endpoint, headers: headers, body: body, retryOn401: false));
    }

    return response;
  }

  /// PUT 요청을 보내고 401 에러 시 토큰 갱신 후 재시도
  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool retryOn401 = true,
  }) async {
    final Object? finalBody = _attachDtoHeadersIfNeeded(body);
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
      body: finalBody,
    );

    if (response.statusCode == 401 && retryOn401) {
      return await _retryWithRefresh(() => put(endpoint, headers: headers, body: body, retryOn401: false));
    }

    return response;
  }

  /// DELETE 요청을 보내고 401 에러 시 토큰 갱신 후 재시도
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool retryOn401 = true,
  }) async {
    final Object? finalBody = _attachDtoHeadersIfNeeded(body);
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers),
      body: finalBody,
    );

    if (response.statusCode == 401 && retryOn401) {
      return await _retryWithRefresh(() => delete(endpoint, headers: headers, body: body, retryOn401: false));
    }

    return response;
  }

  /// 헤더에 JWT 토큰 추가
  static Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      ...TokenManager.jwtHeader,
    };
    
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    
    return defaultHeaders;
  }

  /// DTO를 사용하는 엔드포인트에 JWT를 JSON 내부 `headers`에 자동 삽입
  static Object? _attachDtoHeadersIfNeeded(Object? body) {
    try {
      if (body is String && body.trim().isNotEmpty) {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) {
          // 이미 headers가 있으면 jwt만 갱신
          if (decoded.containsKey('headers') && decoded['headers'] is Map<String, dynamic>) {
            final hdr = Map<String, dynamic>.from(decoded['headers'] as Map);
            hdr['content_type'] = hdr['content_type'] ?? 'application/json';
            if (TokenManager.accessToken != null) {
              hdr['jwt'] = TokenManager.accessToken;
            }
            decoded['headers'] = hdr;
            return json.encode(decoded);
          }
          // body가 있고 headers가 없으면 headers 주입
          if (decoded.containsKey('body')) {
            decoded['headers'] = {
              'content_type': 'application/json',
              'jwt': TokenManager.accessToken,
            };
            return json.encode(decoded);
          }
        }
      }
    } catch (_) {
      // 본문이 JSON이 아니면 건드리지 않음
    }
    return body;
  }

  /// 토큰 갱신 후 요청 재시도
  static Future<http.Response> _retryWithRefresh(Future<http.Response> Function() retryRequest) async {
    print('401 에러 감지 - 토큰 갱신 시도 중...');
    
    final refreshSuccess = await TokenManager.refreshTokens();
    
    if (refreshSuccess) {
      print('토큰 갱신 성공 - 요청 재시도 중...');
      return await retryRequest();
    } else {
      print('토큰 갱신 실패 - 로그인이 필요합니다.');
      // 토큰 갱신 실패 시 원본 401 응답 반환
      return http.Response('Unauthorized', 401);
    }
  }
}
