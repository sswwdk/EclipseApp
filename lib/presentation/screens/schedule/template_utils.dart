import 'package:flutter/material.dart';
import '../../../data/services/route_service.dart';
import 'schedule_screen.dart';

/// 템플릿 화면들에서 사용하는 공통 유틸리티 함수들
class TemplateUtils {
  /// 장소의 위경도를 추출하는 메서드
  static ({double lat, double lng})? getPlaceCoordinates({
    required String placeTitle,
    List<Map<String, dynamic>>? orderedPlaces,
    Map<String, List<Map<String, dynamic>>>? selectedPlacesWithData,
  }) {
    // orderedPlaces에서 먼저 찾기
    if (orderedPlaces != null) {
      for (final placeData in orderedPlaces) {
        final placeName = placeData['name'] as String? ?? '';
        if (placeName == placeTitle) {
          return _extractCoordinatesFromMap(placeData);
        }
      }
    }

    // selectedPlacesWithData에서 찾기
    if (selectedPlacesWithData != null) {
      for (final category in selectedPlacesWithData.values) {
        for (final place in category) {
          final placeName = place['name'] as String? ?? '';
          if (placeName == placeTitle) {
            return _extractCoordinatesFromMap(place);
          }
        }
      }
    }

    return null;
  }

  /// 출발지 좌표를 추출하는 메서드
  static ({double lat, double lng})? getOriginCoordinates(String? originAddress) {
    // GPS 위치 형식인지 확인: "위도: 37.505147, 경도: 126.943349"
    if (originAddress != null && originAddress.contains('위도:')) {
      final latMatch = RegExp(r'위도:\s*([\d.]+)').firstMatch(originAddress);
      final lngMatch = RegExp(r'경도:\s*([\d.]+)').firstMatch(originAddress);

      if (latMatch != null && lngMatch != null) {
        final lat = double.tryParse(latMatch.group(1)!);
        final lng = double.tryParse(lngMatch.group(1)!);
        if (lat != null && lng != null) {
          return (lat: lat, lng: lng);
        }
      }
    }
    return null;
  }

  /// Map에서 위경도를 추출하는 헬퍼 메서드
  static ({double lat, double lng})? _extractCoordinatesFromMap(Map<String, dynamic> placeData) {
    // 최상위 레벨에서 먼저 확인
    dynamic latValue = placeData['latitude'] ?? placeData['lat'];
    dynamic lngValue = placeData['longitude'] ?? placeData['lng'];

    // 최상위 레벨에 없으면 data 안에서 확인
    if (latValue == null || lngValue == null) {
      final data = placeData['data'] as Map<String, dynamic>?;
      if (data != null) {
        latValue ??= data['latitude'] ?? data['lat'];
        lngValue ??= data['longitude'] ?? data['lng'];
      }
    }

    // 문자열이면 파싱, 숫자면 그대로 사용
    double? lat;
    double? lng;

    if (latValue is String) {
      lat = double.tryParse(latValue);
    } else if (latValue is num) {
      lat = latValue.toDouble();
    }

    if (lngValue is String) {
      lng = double.tryParse(lngValue);
    } else if (lngValue is num) {
      lng = lngValue.toDouble();
    }

    if (lat != null && lng != null) {
      return (lat: lat, lng: lng);
    }
    return null;
  }

  /// 특정 구간의 경로를 계산하는 메서드
  static Future<MapEntry<int, RouteResult>?> calculateRouteForSegment({
    required int segmentIndex,
    required ({double lat, double lng}) origin,
    required ({double lat, double lng}) destination,
    required int transportType,
    String? originTitle,
    String? destinationTitle,
  }) async {
    try {
      if (originTitle != null && destinationTitle != null) {
        print('🔍 구간 $segmentIndex 경로 계산 중: $originTitle → $destinationTitle');
      }

      final route = await RouteService.calculateRoute(
        origin: origin,
        destination: destination,
        transportType: transportType,
      );

      print('✅ 구간 $segmentIndex 경로 계산 완료: ${route.durationMinutes}분, ${route.distanceMeters}m');
      return MapEntry(segmentIndex, route);
    } catch (e) {
      print('❌ 구간 $segmentIndex 경로 계산 실패: $e');
      return null;
    }
  }

  /// 일정표 정보를 텍스트로 변환
  static String buildScheduleText({
    required Map<String, List<String>> selected,
    String? originAddress,
    String? originDetailAddress,
  }) {
    final buffer = StringBuffer();

    // 출발지
    if (originAddress != null && originAddress.isNotEmpty) {
      buffer.writeln('출발지: $originAddress');
      if (originDetailAddress != null && originDetailAddress.isNotEmpty) {
        buffer.writeln('상세 주소: $originDetailAddress');
      }
    } else {
      buffer.writeln('출발지: 집');
    }

    buffer.writeln('');
    buffer.writeln('일정:');

    // 장소 목록
    int order = 1;
    selected.forEach((category, places) {
      for (final place in places) {
        buffer.writeln('$order. $place ($category)');
        order++;
      }
    });

    return buffer.toString();
  }

  /// 홈으로 돌아가기 다이얼로그 표시
  static Future<void> showGoHomeDialog({
    required BuildContext context,
    Color? accentColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '홈으로 돌아가기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '저장하지 않은 일정표는 다시 불러올 수 없습니다',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor ?? const Color(0xFFFF8126),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '홈으로 돌아가기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      // 모든 이전 화면을 제거하고 홈 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  /// 경로 계산 로딩 위젯
  static Widget buildLoadingWidget({
    required int completedRoutes,
    required int totalRoutes,
    Color? accentColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: accentColor ?? const Color(0xFFFF8126),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            '경로 정보 계산 중...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedRoutes / $totalRoutes 구간 완료',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// 템플릿 화면들의 경로 계산 로직을 관리하는 믹스인
mixin RouteCalculationMixin<T extends StatefulWidget> on State<T> {
  Map<int, RouteResult> get calculatedRoutes;
  set calculatedRoutes(Map<int, RouteResult> value);
  
  bool get isLoadingRoutes;
  set isLoadingRoutes(bool value);

  /// 모든 구간의 경로를 병렬로 계산
  Future<void> loadAllRoutes({
    required int totalSegments,
    required Future<MapEntry<int, RouteResult>?> Function(int) calculateSegment,
  }) async {
    if (totalSegments <= 0) return;

    isLoadingRoutes = true;
    if (mounted) setState(() {});

    print('🚀 모든 구간 경로 계산 시작...');

    try {
      // 모든 구간의 경로를 병렬로 계산
      final List<Future<MapEntry<int, RouteResult>?>> futures = [];

      for (int i = 0; i < totalSegments; i++) {
        futures.add(calculateSegment(i));
      }

      // 모든 경로 계산을 병렬로 실행
      final results = await Future.wait(futures);

      // 결과를 calculatedRoutes에 저장
      final newRoutes = <int, RouteResult>{};
      for (final result in results) {
        if (result != null) {
          newRoutes[result.key] = result.value;
        }
      }
      calculatedRoutes = newRoutes;

      print('✅ 총 ${calculatedRoutes.length}개 구간 경로 계산 완료');
    } catch (e) {
      print('❌ 경로 계산 중 오류: $e');
    } finally {
      if (mounted) {
        isLoadingRoutes = false;
        setState(() {});
      }
    }
  }

  /// 특정 구간의 경로를 재계산
  Future<void> recalculateRoute({
    required int segmentIndex,
    required Future<MapEntry<int, RouteResult>?> Function(int) calculateSegment,
  }) async {
    print('🔄 구간 $segmentIndex 재계산 시작...');

    try {
      final result = await calculateSegment(segmentIndex);

      if (result != null && mounted) {
        setState(() {
          calculatedRoutes[result.key] = result.value;
        });
        print('✅ 구간 $segmentIndex 재계산 완료');
      }
    } catch (e) {
      print('❌ 구간 $segmentIndex 재계산 실패: $e');
    }
  }
}
