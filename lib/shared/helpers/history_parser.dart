import 'package:flutter/material.dart';
import '../../data/services/route_service.dart';

/// 히스토리 상세 데이터 파싱을 위한 헬퍼 클래스
class HistoryParser {
  /// category_type을 카테고리 이름으로 변환
  static String getCategoryNameFromType(int categoryType) {
    switch (categoryType) {
      case 0:
        return '음식점';
      case 1:
        return '카페';
      case 2:
        return '콘텐츠';
      default:
        return '기타';
    }
  }

  /// 카테고리에 따른 아이콘 반환
  static IconData getIconForCategory(String category) {
    switch (category) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '콘텐츠':
        return Icons.movie_filter;
      case '출발지':
        return Icons.home_outlined;
      default:
        return Icons.place;
    }
  }

  /// description 문자열을 파싱하여 RouteResult 객체로 변환
  static RouteResult parseDescriptionToRouteResult(
    String description,
    int defaultDuration,
  ) {
    try {
      final lines = description
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      int durationMinutes = defaultDuration;
      int distanceMeters = 0;
      List<RouteStep> steps = [];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // "대중교통 약 39분" 파싱
        if (line.startsWith('대중교통') ||
            line.startsWith('도보') && line.contains('약')) {
          final match = RegExp(r'약\s*(\d+)분').firstMatch(line);
          if (match != null) {
            durationMinutes = int.tryParse(match.group(1)!) ?? durationMinutes;
          }
          continue;
        }

        // "거리 약 11.8km" 파싱
        if (line.startsWith('거리')) {
          final kmMatch = RegExp(r'약\s*([\d.]+)km').firstMatch(line);
          final mMatch = RegExp(r'약\s*(\d+)m').firstMatch(line);

          if (kmMatch != null) {
            final km = double.tryParse(kmMatch.group(1)!) ?? 0;
            distanceMeters = (km * 1000).round();
          } else if (mMatch != null) {
            distanceMeters = int.tryParse(mMatch.group(1)!) ?? 0;
          }
          continue;
        }

        // " 도보 4분" 형태 파싱 (시간이 있는 도보)
        if (line.contains('도보') && line.contains('분')) {
          final match = RegExp(r'도보\s*(\d+)분').firstMatch(line);
          if (match != null) {
            final duration = int.tryParse(match.group(1)!) ?? 0;
            steps.add(
              RouteStep(
                type: 'walk',
                description: '도보',
                durationMinutes: duration,
              ),
            );
          }
          continue;
        }

        // "도보"만 있는 경우 (환승)
        if (line == '도보' || line.trim() == '도보') {
          steps.add(
            RouteStep(type: 'walk', description: '도보', durationMinutes: 0),
          );
          continue;
        }

        // 버스 정보 파싱
        if (line.contains('버스') && line.contains('분')) {
          final busTypeMatch = RegExp(
            r'(지선|간선|광역|순환|마을|공항|직행좌석):([\d-]+[가-힣]*)번',
          ).firstMatch(line);
          final durationMatch = RegExp(r'(\d+)분').firstMatch(line);

          String busInfo = '버스';
          if (busTypeMatch != null) {
            final busType = busTypeMatch.group(1) ?? '';
            busInfo = '$busType';
          }

          final routeMatch = RegExp(
            r':\s*([^→]+)\s*→\s*([^\d]+)',
          ).firstMatch(line);
          if (routeMatch != null) {
            final from = routeMatch.group(1)?.trim() ?? '';
            final to = routeMatch.group(2)?.trim() ?? '';
            busInfo += '\n$from → $to';
          }

          final duration = durationMatch != null
              ? int.tryParse(durationMatch.group(1)!) ?? 0
              : 0;

          if (duration > 0) {
            steps.add(
              RouteStep(
                type: 'transit',
                description: busInfo,
                durationMinutes: duration,
              ),
            );
          }
          continue;
        }

        // 지하철 정보 파싱
        if (line.contains('호선') && line.contains('분')) {
          final durationMatch = RegExp(r'(\d+)분').firstMatch(line);
          final subwayMatch = RegExp(r'(수도권\d+호선|\d+호선)').firstMatch(line);

          String subwayInfo = '지하철';
          if (subwayMatch != null) {
            subwayInfo = subwayMatch.group(1) ?? '지하철';
          }

          final routeMatch = RegExp(
            r':\s*([^→]+)\s*→\s*([^\d]+)',
          ).firstMatch(line);
          if (routeMatch != null) {
            final from = routeMatch.group(1)?.trim() ?? '';
            final to = routeMatch.group(2)?.trim() ?? '';
            subwayInfo += '\n$from → $to';
          }

          final duration = durationMatch != null
              ? int.tryParse(durationMatch.group(1)!) ?? 0
              : 0;

          if (duration > 0) {
            steps.add(
              RouteStep(
                type: 'transit',
                description: subwayInfo,
                durationMinutes: duration,
              ),
            );
          }
          continue;
        }
      }

      return RouteResult(
        durationMinutes: durationMinutes,
        durationSeconds: durationMinutes * 60,
        distanceMeters: distanceMeters,
        steps: steps.isNotEmpty ? steps : null,
        summary: description,
      );
    } catch (e) {
      return RouteResult(
        durationMinutes: defaultDuration,
        durationSeconds: defaultDuration * 60,
        distanceMeters: 0,
        steps: null,
        summary: description,
      );
    }
  }

  /// 서버에서 받은 category 데이터에서 경로 정보 파싱
  static RouteResult parseRouteInfo(
    Map<String, dynamic> category,
    int defaultDuration,
  ) {
    try {
      int? durationSeconds;
      if (category.containsKey('duration')) {
        final duration = category['duration'];
        if (duration is int) {
          durationSeconds = duration;
        } else if (duration is String) {
          durationSeconds = int.tryParse(duration);
        }
      }

      int durationMinutes = defaultDuration;
      if (durationSeconds != null) {
        durationMinutes = (durationSeconds / 60).round();
      }

      double? distanceValue;
      if (category.containsKey('distance')) {
        final distance = category['distance'];
        if (distance is num) {
          distanceValue = distance.toDouble();
        } else if (distance is String) {
          distanceValue = double.tryParse(distance);
        }
      }
      int distanceMeters = (distanceValue ?? 0).round();

      return RouteResult(
        durationMinutes: durationMinutes,
        durationSeconds: durationSeconds ?? (durationMinutes * 60),
        distanceMeters: distanceMeters,
        steps: null,
        summary: null,
      );
    } catch (e) {
      return RouteResult(
        durationMinutes: defaultDuration,
        durationSeconds: defaultDuration * 60,
        distanceMeters: 0,
        steps: null,
        summary: null,
      );
    }
  }

  /// dynamic 값을 String으로 안전하게 변환
  static String? stringFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null') {
        return null;
      }
      return trimmed;
    }
    final stringified = value.toString().trim();
    if (stringified.isEmpty || stringified == 'null') {
      return null;
    }
    return stringified;
  }

  /// dynamic 값을 double로 안전하게 변환
  static double? doubleFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// 교통수단 타입을 int로 변환
  static int parseTransportationType(dynamic transportation) {
    if (transportation == null) return 0;
    if (transportation is int) return transportation;
    if (transportation is String) {
      return int.tryParse(transportation) ?? 0;
    }
    return 0;
  }

  /// category_type을 int로 변환
  static int parseCategoryType(dynamic categoryType) {
    if (categoryType == null) return 0;
    if (categoryType is int) return categoryType;
    if (categoryType is String) {
      return int.tryParse(categoryType) ?? 0;
    }
    return 0;
  }
}
