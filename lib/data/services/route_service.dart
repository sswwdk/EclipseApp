import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:whattodo/core/config/server_config.dart';
import 'package:whattodo/shared/helpers/token_manager.dart';

/// 이동시간 계산 결과 모델
class RouteResult {
  final int durationMinutes; // UI 표시용 (분)
  final int durationSeconds; // 🔥 서버 저장용 (원본 초 데이터)
  final int distanceMeters; // 총 거리 (미터)
  final List<RouteStep>? steps; // 경로 상세 정보 (대중교통의 경우)
  final String? summary; // 경로 요약 설명

  RouteResult({
    required this.durationMinutes,
    required this.durationSeconds, // 🔥 추가
    required this.distanceMeters,
    this.steps,
    this.summary,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    print('🔍 [RouteResult.fromJson] 파싱 시작:');
    print('   json 키: ${json.keys.toList()}');

    // 🔥 서버에서 받은 원본 초 데이터 추출
    int? durationSecondsRaw;
    bool isAlreadyInMinutes = false;

    if (json.containsKey('duration_seconds')) {
      // 명시적으로 초 단위인 경우
      final duration = json['duration_seconds'];
      if (duration is int) {
        durationSecondsRaw = duration;
      } else if (duration is String) {
        durationSecondsRaw = int.tryParse(duration);
      }
    } else if (json.containsKey('duration')) {
      // duration이 초 단위인 경우 (서버에서 보통 초 단위로 보냄)
      final duration = json['duration'];
      if (duration is int) {
        durationSecondsRaw = duration;
      } else if (duration is String) {
        durationSecondsRaw = int.tryParse(duration);
      }
    } else if (json.containsKey('duration_minutes')) {
      // 이미 분 단위인 경우
      final duration = json['duration_minutes'];
      if (duration is int) {
        durationSecondsRaw = duration; // 분 단위 값을 임시 저장
        isAlreadyInMinutes = true;
      } else if (duration is String) {
        final minutes = int.tryParse(duration);
        if (minutes != null) {
          durationSecondsRaw = minutes;
          isAlreadyInMinutes = true;
        }
      }
    } else if (json.containsKey('durationMinutes')) {
      // 이미 분 단위인 경우
      final duration = json['durationMinutes'];
      if (duration is int) {
        durationSecondsRaw = duration; // 분 단위 값을 임시 저장
        isAlreadyInMinutes = true;
      } else if (duration is String) {
        final minutes = int.tryParse(duration);
        if (minutes != null) {
          durationSecondsRaw = minutes;
          isAlreadyInMinutes = true;
        }
      }
    }

    // 🔥 원본 초 데이터와 UI용 분 데이터 분리
    int durationMinutes = 0;
    int durationSeconds = 0;

    if (durationSecondsRaw != null) {
      if (isAlreadyInMinutes) {
        // 서버에서 분으로 온 경우
        durationMinutes = durationSecondsRaw;
        durationSeconds = durationSecondsRaw * 60; // 분을 초로 변환하여 저장
        print('   서버에서 분으로 받음: ${durationMinutes}분 -> ${durationSeconds}초');
      } else {
        // 서버에서 초로 온 경우 (원본 보존!)
        durationSeconds = durationSecondsRaw; // 🔥 원본 그대로 저장
        durationMinutes = (durationSecondsRaw / 60).round(); // UI 표시용으로만 분 계산
        print(
          '   서버에서 초로 받음(원본 보존): ${durationSeconds}초 -> ${durationMinutes}분 (UI 표시용)',
        );
      }
    }

    // distance 필드명 여러 가능성 확인 (서버에서 float로 보낼 수 있음)
    double? distanceValue;
    if (json.containsKey('distance')) {
      final distance = json['distance'];
      if (distance is num) {
        distanceValue = distance.toDouble();
      } else if (distance is String) {
        distanceValue = double.tryParse(distance);
      }
    } else if (json.containsKey('distance_meters')) {
      final distance = json['distance_meters'];
      if (distance is num) {
        distanceValue = distance.toDouble();
      } else if (distance is String) {
        distanceValue = double.tryParse(distance);
      }
    } else if (json.containsKey('distanceMeters')) {
      final distance = json['distanceMeters'];
      if (distance is num) {
        distanceValue = distance.toDouble();
      } else if (distance is String) {
        distanceValue = double.tryParse(distance);
      }
    }

    int distanceMeters = (distanceValue ?? 0).round();

    // routes 필드 파싱 (서버에서 routes로 보내는 대중교통 경로 정보)
    List<RouteStep>? steps;
    final routes = json['routes'] as List<dynamic>?;
    if (routes != null && routes.isNotEmpty) {
      print('   routes 발견: ${routes.length}개');
      steps = routes
          .map((route) {
            if (route is Map<String, dynamic>) {
              return RouteStep.fromPublicTransportRoute(route);
            }
            return null;
          })
          .whereType<RouteStep>()
          .toList();
    } else {
      // 하위 호환성: 기존 steps 필드도 확인
      final stepsData = json['steps'] as List<dynamic>?;
      if (stepsData != null && stepsData.isNotEmpty) {
        steps = stepsData
            .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
            .toList();
      }
    }

    print('   durationMinutes (UI용): $durationMinutes');
    print('   durationSeconds (저장용): $durationSeconds');
    print('   distanceMeters: $distanceMeters');
    print('   steps 개수: ${steps?.length ?? 0}');

    return RouteResult(
      durationMinutes: durationMinutes, // UI 표시용
      durationSeconds: durationSeconds, // 🔥 서버 저장용 (원본)
      distanceMeters: distanceMeters,
      steps: steps,
      summary: json['summary'] as String?,
    );
  }
}

/// 경로 단계 정보 (대중교통의 경우)
class RouteStep {
  final String type; // 'walk', 'transit', 'drive'
  final int durationMinutes;
  final String? description; // 예: "2호선", "홍대입구역 1번 출구 > 홍대 CGV"

  RouteStep({
    required this.type,
    required this.durationMinutes,
    this.description,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    // duration 필드명 여러 가능성 확인 (서버에서 초 단위로 보낼 수 있음)
    int? durationSeconds;
    bool isAlreadyInMinutes = false;

    if (json.containsKey('duration_seconds')) {
      final duration = json['duration_seconds'];
      if (duration is int) {
        durationSeconds = duration;
      } else if (duration is String) {
        durationSeconds = int.tryParse(duration);
      }
    } else if (json.containsKey('duration')) {
      // duration이 초 단위인 경우
      final duration = json['duration'];
      if (duration is int) {
        durationSeconds = duration;
      } else if (duration is String) {
        durationSeconds = int.tryParse(duration);
      }
    } else if (json.containsKey('duration_minutes')) {
      final duration = json['duration_minutes'];
      if (duration is int) {
        durationSeconds = duration;
        isAlreadyInMinutes = true;
      } else if (duration is String) {
        final minutes = int.tryParse(duration);
        if (minutes != null) {
          durationSeconds = minutes;
          isAlreadyInMinutes = true;
        }
      }
    }

    // 초를 분으로 변환 (반올림), 이미 분 단위면 그대로 사용
    int durationMinutes = 0;
    if (durationSeconds != null) {
      if (isAlreadyInMinutes) {
        durationMinutes = durationSeconds;
      } else {
        durationMinutes = (durationSeconds / 60).round();
      }
    }

    return RouteStep(
      type: json['type'] as String? ?? 'unknown',
      durationMinutes: durationMinutes,
      description: json['description'] as String?,
    );
  }

  /// 대중교통 경로 정보로부터 RouteStep 생성
  /// PublicTransportationRoutesDto: {description: str, duration_min: int}
  factory RouteStep.fromPublicTransportRoute(Map<String, dynamic> json) {
    // duration_min은 이미 분 단위
    final durationMin = json['duration_min'] as int? ?? 0;
    final description = json['description'] as String? ?? '';

    // description에서 타입 추론 (예: "2호선" -> transit, "도보 5분" -> walk)
    String type = 'unknown';
    if (description.contains('호선') ||
        description.contains('지하철') ||
        description.contains('버스') ||
        description.contains('역')) {
      type = 'transit';
    } else if (description.contains('도보') || description.contains('걸어서')) {
      type = 'walk';
    } else if (description.contains('자동차') || description.contains('차로')) {
      type = 'drive';
    }

    return RouteStep(
      type: type,
      durationMinutes: durationMin,
      description: description,
    );
  }
}

/// 이동시간 계산 서비스 (T맵/카카오 API 연동)
class RouteService {
  static String get baseUrl => ServerConfig.baseUrl;

  /// 출발지와 도착지 좌표로 이동시간 계산
  ///
  /// [origin] 출발지 좌표 (위도, 경도)
  /// [destination] 도착지 좌표 (위도, 경도)
  /// [transportType] 이동수단 (0: 도보, 1: 대중교통, 2: 자동차)
  static Future<RouteResult> calculateRoute({
    required ({double lat, double lng}) origin,
    required ({double lat, double lng}) destination,
    required int transportType, // 0: 도보, 1: 대중교통, 2: 자동차
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/service/cal-route'),
            headers: {
              'Content-Type': 'application/json',
              ...TokenManager.jwtHeader,
            },
            body: json.encode({
              'origin': [origin.lng, origin.lat], // tuple 형식: [경도, 위도]
              'destination': [
                destination.lng,
                destination.lat,
              ], // tuple 형식: [경도, 위도]
              'transport_type': transportType
                  .toString(), // 문자열로 변환: "0", "1", "2"
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('이동시간 계산 요청 시간 초과');
            },
          );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        print('🔍 [RouteService] 서버 응답 데이터:');
        print('   전체 응답: $responseData');
        print(
          '   responseData 키: ${responseData is Map ? responseData.keys.toList() : 'N/A'}',
        );

        final data = responseData['data'] ?? responseData;
        print('   파싱할 data: $data');
        print(
          '   data 키: ${data is Map ? data.keys.toList() : 'N/A'}',
        );

        if (data is Map<String, dynamic>) {
          print('   duration_minutes: ${data['duration_minutes']}');
          print('   durationMinutes: ${data['durationMinutes']}');
          print('   duration: ${data['duration']}');
        }

        return RouteResult.fromJson(data as Map<String, dynamic>);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        throw Exception('이동시간 계산 실패: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('❌ 이동시간 계산 오류: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 서버 응답에서 에러 메시지 추출
  static String _extractErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      return json['message'] as String? ??
          json['error'] as String? ??
          '알 수 없는 오류';
    } catch (e) {
      return responseBody;
    }
  }
}
