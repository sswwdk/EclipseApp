import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../config/server_config.dart';
import '../services/route_service.dart'; // 🔥 RouteResult 임포트

class HistoryService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 내 히스토리 보기
  static Future<Map<String, dynamic>> getMyHistory(
    String userId, {
    bool templateType = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/histories'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('히스토리 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('히스토리 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 히스토리 삭제
  static Future<Map<String, dynamic>> deleteHistory(
    String userId,
    String historyId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/service/histories'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'history_id': historyId}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('히스토리 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('히스토리 삭제 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 일정표 히스토리 "일정표" 탭에 저장
  static Future<void> saveSchedule({
    required Map<String, List<String>> selectedPlaces,
    Map<String, String>? categoryIdByName,
    Map<String, List<Map<String, dynamic>>>? selectedPlacesWithData,
    List<Map<String, dynamic>>? orderedPlaces, // 🔥 순서가 유지되는 장소 리스트
    String? originAddress,
    String? originDetailAddress,
    Map<int, int>? transportTypes,
    Map<int, RouteResult>? routeResults, // 🔥 실제 경로 계산 결과
    int? firstDurationMinutes,
    int? otherDurationMinutes,
  }) async {
    try {
      final callId = DateTime.now().millisecondsSinceEpoch;

      print('📍 [CALL-$callId] saveSchedule 호출됨 at ${DateTime.now()}');
      print('📍 [CALL-$callId] selectedPlaces: $selectedPlaces');
      print('📍 [CALL-$callId] orderedPlaces: $orderedPlaces');
      print('📍 [CALL-$callId] transportTypes: $transportTypes');
      print('📍 [CALL-$callId] routeResults: ${routeResults?.keys.toList()}');

      final List<Map<String, dynamic>> categories = [];

      // 🔥 orderedPlaces가 있으면 순서대로 처리 (순서 보장)
      if (orderedPlaces != null && orderedPlaces.isNotEmpty) {
        print('✅ orderedPlaces를 사용하여 순서대로 저장');

        for (int i = 0; i < orderedPlaces.length; i++) {
          final placeData = orderedPlaces[i];
          final categoryId = placeData['id'] as String?;
          final placeName = placeData['name'] as String? ?? '알 수 없음';

          if (categoryId != null && categoryId.isNotEmpty) {
            // 이동수단
            final String transportationCode =
                (transportTypes != null && transportTypes.containsKey(i))
                ? transportTypes[i]!.toString()
                : '1'; // 기본값: 대중교통

            // 🔥 실제 경로 계산 결과 사용 (초 단위)
            int durationSeconds = 0;
            int distanceMeters = 0;

            if (routeResults != null && routeResults.containsKey(i)) {
              // ✅ 원본 초 데이터를 그대로 사용 (변환하지 않음!)
              final route = routeResults[i]!;
              durationSeconds =
                  route.durationSeconds; // 🔥 durationMinutes * 60 대신 원본 사용
              distanceMeters = route.distanceMeters;
              print(
                '✅ [$i] 실제 경로 정보 사용 (원본 초): ${durationSeconds}초 (${route.durationMinutes}분 표시), ${distanceMeters}m',
              );
            } else {
              // 경로 정보가 없으면 하드코딩된 템플릿 시간 사용 (fallback)
              final int durationMinutes = i == 0
                  ? (firstDurationMinutes ?? otherDurationMinutes ?? 60)
                  : (otherDurationMinutes ?? 60);
              durationSeconds = durationMinutes * 60; // 분을 초로 변환
              print(
                '⚠️ [$i] 경로 정보 없음, 템플릿 시간 사용: ${durationMinutes}분 → ${durationSeconds}초',
              );
            }

            categories.add({
              'category_id': categoryId,
              'category_name': placeName,
              'duration': durationSeconds, // 🔥 원본 초 단위로 저장
              'distance': distanceMeters,
              'transportation': transportationCode,
            });

            print(
              '✅ [$i] 카테고리 추가: $placeName (duration: ${durationSeconds}초, distance: ${distanceMeters}m, transport: $transportationCode)',
            );
          } else {
            print('❌ [$i] 매장 ID가 없음: $placeName');
          }
        }
      } else {
        // 🔸 하위 호환성: orderedPlaces가 없으면 기존 방식 사용
        print('⚠️ orderedPlaces가 없음, 기존 방식 사용 (순서 보장 안됨)');
        int addedCategoryCount = 0;

        for (final entry in selectedPlaces.entries) {
          final categoryName = entry.key;
          final selectedPlaceNames = entry.value;

          print(
            '🔍 카테고리 처리: $categoryName, 선택된 장소 개수: ${selectedPlaceNames.length}',
          );

          if (selectedPlacesWithData != null &&
              selectedPlacesWithData.containsKey(categoryName)) {
            final placesData = selectedPlacesWithData[categoryName]!;
            print('🔍 placesData 개수: ${placesData.length}');

            for (final placeName in selectedPlaceNames) {
              Map<String, dynamic>? matchedPlace;
              for (final place in placesData) {
                final placeTitle =
                    place['title'] as String? ?? place['name'] as String? ?? '';
                if (placeTitle == placeName) {
                  matchedPlace = place;
                  break;
                }
              }

              if (matchedPlace == null && placesData.isNotEmpty) {
                matchedPlace = placesData[0];
                print('⚠️ 장소 이름 일치하지 않음, 첫 번째 항목 사용: $placeName');
              }

              if (matchedPlace != null) {
                final categoryId = matchedPlace['id'] as String?;
                final matchedPlaceName =
                    matchedPlace['title'] as String? ??
                    matchedPlace['name'] as String? ??
                    placeName;

                if (categoryId != null && categoryId.isNotEmpty) {
                  final String transportationCode =
                      (transportTypes != null &&
                          transportTypes.containsKey(addedCategoryCount))
                      ? transportTypes[addedCategoryCount]!.toString()
                      : '1';

                  // 🔥 실제 경로 계산 결과 사용 (초 단위)
                  int durationSeconds = 0;

                  if (routeResults != null &&
                      routeResults.containsKey(addedCategoryCount)) {
                    final route = routeResults[addedCategoryCount]!;
                    durationSeconds = route.durationMinutes * 60;
                    print(
                      '✅ 실제 경로 정보 사용: ${route.durationMinutes}분 → ${durationSeconds}초',
                    );
                  } else {
                    final int durationMinutes = addedCategoryCount == 0
                        ? (firstDurationMinutes ?? otherDurationMinutes ?? 60)
                        : (otherDurationMinutes ?? 60);
                    durationSeconds = durationMinutes * 60;
                    print(
                      '⚠️ 경로 정보 없음, 템플릿 시간 사용: ${durationMinutes}분 → ${durationSeconds}초',
                    );
                  }

                  categories.add({
                    'category_id': categoryId,
                    'category_name': matchedPlaceName,
                    'duration': durationSeconds, // 🔥 초 단위로 저장
                    'transportation': transportationCode,
                  });

                  print(
                    '✅ 카테고리 추가: $matchedPlaceName (duration: ${durationSeconds}초, transport: $transportationCode)',
                  );
                  addedCategoryCount += 1;
                } else {
                  print('❌ 매장 ID가 없음: $matchedPlaceName');
                }
              }
            }
          } else {
            print('⚠️ selectedPlacesWithData에 카테고리 "$categoryName"이 없음');
            if (categoryIdByName != null &&
                categoryIdByName.containsKey(categoryName)) {
              final categoryId = categoryIdByName[categoryName];
              if (categoryId != null && categoryId.isNotEmpty) {
                final String transportationCode =
                    (transportTypes != null &&
                        transportTypes.containsKey(addedCategoryCount))
                    ? transportTypes[addedCategoryCount]!.toString()
                    : '1';

                // 🔥 초 단위로 변환
                int durationSeconds = 0;
                if (routeResults != null &&
                    routeResults.containsKey(addedCategoryCount)) {
                  durationSeconds =
                      routeResults[addedCategoryCount]!.durationMinutes * 60;
                } else {
                  final int durationMinutes = addedCategoryCount == 0
                      ? (firstDurationMinutes ?? otherDurationMinutes ?? 60)
                      : (otherDurationMinutes ?? 60);
                  durationSeconds = durationMinutes * 60;
                }

                categories.add({
                  'category_id': categoryId,
                  'category_name': categoryName,
                  'duration': durationSeconds, // 🔥 초 단위
                  'transportation': transportationCode,
                });
                print(
                  '✅ categoryIdByName에서 카테고리 추가: $categoryName (duration: ${durationSeconds}초)',
                );
                addedCategoryCount += 1;
              }
            } else {
              print('❌ 카테고리 "$categoryName"의 매장 ID를 찾을 수 없음');
            }
          }
        }
      }

      if (categories.isEmpty) {
        throw Exception('저장할 카테고리가 없습니다. 매장 ID를 찾을 수 없습니다.');
      }

      print('📍 최종 categories 데이터: $categories');

      final userId = TokenManager.userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('로그인이 필요합니다. user_id 없음');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/service/histories'),
            headers: {
              'Content-Type': 'application/json',
              ...TokenManager.jwtHeader,
            },
            body: json.encode({
              'template_type': '0', // 0: 일정표
              'category': categories,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('서버 연결 시간 초과 (30초)');
            },
          );

      if (response.statusCode != 200) {
        print('❌ 서버 응답 오류: ${response.statusCode}');
        print('   응답 본문: ${response.body}');
        throw Exception('일정표 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('일정표 저장 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 히스토리 상세 조회
  static Future<Map<String, dynamic>> getHistoryDetail(
    String userId,
    String mergeHistoryId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/histories/detail/$mergeHistoryId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('히스토리 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('히스토리 상세 조회 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 일정표 히스토리 "그냥" 탭에 저장
  static Future<void> saveOtherHistory(
    Map<String, List<Map<String, dynamic>>> selectedPlaces,
  ) async {
    try {
      final userId = TokenManager.userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('로그인이 필요합니다. user_id 없음');
      }

      final List<Map<String, dynamic>> places = [];
      for (final entry in selectedPlaces.entries) {
        final category = entry.key;
        final placeList = entry.value;

        for (final place in placeList) {
          final placeName =
              place['title'] as String? ?? place['name'] as String? ?? '알 수 없음';
          final placeAddress =
              place['address'] as String? ??
              place['detail_address'] as String? ??
              '';

          places.add({
            'category_name': placeName,
            'duration': 3600, // 🔥 60분 → 3600초
            'transportation': '1',
            'category_id': place['id'] as String? ?? '',
          });
        }
      }

      final scheduleTitle = places
          .map((p) => (p['category_name'] ?? p['name'] ?? '') as String)
          .where((s) => s.isNotEmpty)
          .join(' → ');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/service/histories'),
            headers: {
              'Content-Type': 'application/json',
              ...TokenManager.jwtHeader,
            },
            body: json.encode({
              'user_id': userId,
              'template_type': '1', // 1: 그냥
              'date': DateTime.now().toIso8601String().split('T')[0],
              'schedule_title': scheduleTitle,
              'category': places,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('서버 연결 시간 초과 (30초)');
            },
          );

      if (response.statusCode != 200) {
        print('❌ 서버 응답 오류: ${response.statusCode}');
        print('   응답 본문: ${response.body}');
        throw Exception('히스토리 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('히스토리 저장 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}
