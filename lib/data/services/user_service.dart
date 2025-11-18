import 'dart:convert';
import '../../shared/helpers/http_interceptor.dart';
import '../../shared/helpers/token_manager.dart';
import '../../core/config/server_config.dart';

class UserService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 로그인
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/auth/session',
        body: json.encode({'id': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        // 🔥 서버에서 반환한 에러 메시지 파싱
        Map<String, dynamic> errorBody;
        try {
          errorBody = json.decode(utf8.decode(response.bodyBytes));
        } catch (e) {
          errorBody = {};
        }

        // 서버에서 보낸 메시지가 있으면 사용, 없으면 기본 메시지
        final String errorMessage =
            errorBody['message'] ??
            errorBody['error'] ??
            _getDefaultErrorMessage(response.statusCode);

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('로그인 오류: $e');

      // 이미 Exception이 throw된 경우 그대로 전달
      if (e is Exception) {
        rethrow;
      }

      // 네트워크 연결 오류 등
      throw Exception('네트워크 연결을 확인해주세요.');
    }
  }

  // 🔥 상태 코드별 기본 에러 메시지
  static String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다.';
      case 401:
        return '아이디 또는 비밀번호가 올바르지 않습니다.';
      case 404:
        return '사용자를 찾을 수 없습니다.';
      case 409:
        return '이미 존재하는 사용자입니다.';
      case 500:
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '로그인 실패: $statusCode';
    }
  }

  // 로그아웃
  static Future<Map<String, dynamic>> logout(
    String username,
    String password,
  ) async {
    try {
      final response = await HttpInterceptor.put(
        '/api/users/session',
        body: json.encode({
          'headers': {
            'content_type': 'application/json',
            'jwt': TokenManager.accessToken,
          },
          'body': {'id': username, 'password': password},
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('로그아웃 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('로그아웃 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 아이디 찾기
  static Future<Map<String, dynamic>> findId(String email) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/auth/id',
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('아이디 찾기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('아이디 찾기 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 비밀번호 찾기
  static Future<Map<String, dynamic>> findPassword(
    String username,
    String email,
  ) async {
    try {
      final response = await HttpInterceptor.post(
        '/api/auth/password',
        body: json.encode({'username': username, 'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('비밀번호 찾기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('비밀번호 찾기 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 회원가입
  static Future<Map<String, dynamic>> signup({
    required String id,
    required String username,
    required String password,
    required String nickname,
    required String email,
    String? phone,
    String? address,
    int? sex,
    String? birth,
  }) async {
    try {
      // body 데이터 구성 (선택 필드는 null이 아닐 때만 포함)
      final Map<String, dynamic> bodyData = {
        'id': id,
        'username': username,
        'password': password,
        'nickname': nickname,
        'email': email,
      };

      // 선택 필드 추가
      if (phone != null && phone.isNotEmpty) bodyData['phone'] = phone;
      if (address != null && address.isNotEmpty) bodyData['address'] = address;
      if (sex != null) bodyData['sex'] = sex;
      if (birth != null && birth.isNotEmpty) bodyData['birth'] = birth;

      final response = await HttpInterceptor.post(
        '/api/auth/register',
        body: json.encode(bodyData),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        // 🔥 서버에서 반환한 에러 메시지 파싱
        Map<String, dynamic> errorBody;
        try {
          errorBody = json.decode(utf8.decode(response.bodyBytes));
        } catch (e) {
          errorBody = {};
        }

        final String errorMessage =
            errorBody['message'] ??
            errorBody['error'] ??
            _getDefaultErrorMessage(response.statusCode);

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('회원가입 오류: $e');

      if (e is Exception) {
        rethrow;
      }

      throw Exception('네트워크 연결을 확인해주세요.');
    }
  }

  // 회원 탈퇴
  static Future<Map<String, dynamic>> deleteUser(
    String because,
    String password,
  ) async {
    try {
      final response = await HttpInterceptor.delete(
        '/api/users/me',
        body: json.encode({'because': because, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        throw Exception('비밀번호가 일치하지 않습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('사용자를 찾을 수 없습니다.');
      } else {
        throw Exception('회원 탈퇴 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원 탈퇴 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 내 정보 보기
  static Future<Map<String, dynamic>> getMyInfo(String userId) async {
    try {
      final response = await HttpInterceptor.get('/api/users/me/$userId');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('내 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('내 정보 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 닉네임 변경
  static Future<Map<String, dynamic>> changeNickname(
    String newNickname,
    String password,
  ) async {
    try {
      final String? userId = TokenManager.userId;
      final Map<String, dynamic> body = {
        'user_id': userId,
        'change_field': newNickname,
        'password': password,
      };

      final response = await HttpInterceptor.put(
        '/api/users/me/nickname',
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('닉네임 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('닉네임 변경 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 비밀번호 변경
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final String? userId = TokenManager.userId;
      final Map<String, dynamic> body = {
        'user_id': userId,
        'password': currentPassword,
        'change_field': newPassword,
      };

      final response = await HttpInterceptor.put(
        '/api/users/me/password',
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('비밀번호 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('비밀번호 변경 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 이메일 변경
  static Future<Map<String, dynamic>> changeEmail({
    required String password,
    required String newEmail,
  }) async {
    try {
      final String? userId = TokenManager.userId;
      final Map<String, dynamic> body = {
        'user_id': userId,
        'change_field': newEmail,
        'password': password,
      };

      final response = await HttpInterceptor.put(
        '/api/users/me/email',
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('이메일 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('이메일 변경 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 주소 변경
  static Future<Map<String, dynamic>> changeAddress({
    required String password,
    required String address,
    String? detailAddress,
  }) async {
    try {
      final String? userId = TokenManager.userId;
      final Map<String, dynamic> body = {
        'user_id': userId,
        'change_field': address,
        'password': password,
      };
      if (detailAddress != null && detailAddress.isNotEmpty) {
        body['detail_address'] = detailAddress;
      }

      final response = await HttpInterceptor.put(
        '/api/users/me/address',
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('주소 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('주소 변경 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 전화번호 변경
  static Future<Map<String, dynamic>> changePhone({
    required String password,
    required String newPhone,
  }) async {
    try {
      final String? userId = TokenManager.userId;
      final Map<String, dynamic> body = {
        'user_id': userId,
        'change_field': newPhone.replaceAll("-", ""),
        'password': password,
      };

      final response = await HttpInterceptor.put(
        '/api/users/me/phone',
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('전화번호 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('전화번호 변경 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
