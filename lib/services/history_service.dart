import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../config/server_config.dart';

class HistoryService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 내 히스토리 보기
  static Future<Map<String, dynamic>> getMyHistory(String userId, {bool templateType = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/histories'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        }
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
  static Future<Map<String, dynamic>> deleteHistory(String userId, String historyId) async {
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
    Map<String, List<Map<String, dynamic>>>? selectedPlacesWithData, // 전체 매장 데이터
    List<Map<String, dynamic>>? orderedPlaces, // 🔥 순서가 유지되는 장소 리스트
    String? originAddress,
    String? originDetailAddress,
    Map<int, int>? transportTypes,
    int? firstDurationMinutes,
    int? otherDurationMinutes,
  }) async {
    try {
      // 고유 호출 ID 생성 (중복 호출 확인용)
      final callId = DateTime.now().millisecondsSinceEpoch;
      
      // 디버깅: categoryIdByName 출력
      print('📍 [CALL-$callId] saveSchedule 호출됨 at ${DateTime.now()}');
      print('📍 [CALL-$callId] selectedPlaces: $selectedPlaces');
      print('📍 [CALL-$callId] orderedPlaces: $orderedPlaces');
      print('📍 [CALL-$callId] transportTypes: $transportTypes');
      
      final List<Map<String, dynamic>> categories = [];
      
      // 🔥 orderedPlaces가 있으면 순서대로 처리 (순서 보장)
      if (orderedPlaces != null && orderedPlaces.isNotEmpty) {
        print('✅ orderedPlaces를 사용하여 순서대로 저장');
        
        for (int i = 0; i < orderedPlaces.length; i++) {
          final placeData = orderedPlaces[i];
          final categoryId = placeData['id'] as String?;
          final placeName = placeData['name'] as String? ?? '알 수 없음';
          
          if (categoryId != null && categoryId.isNotEmpty) {
            // 이동수단: 첫 번째 장소는 출발지에서 오는 구간 (transportTypes[0])
            // i번째 장소 = transportTypes[i] (출발지 → 첫번째 장소 = transportTypes[0])
            final String transportationCode = (transportTypes != null && transportTypes.containsKey(i))
                ? transportTypes[i]!.toString()
                : '1'; // 기본값: 대중교통
            
            // 첫 장소는 firstDurationMinutes, 그 외는 otherDurationMinutes
            final int durationMinutes = i == 0
                ? (firstDurationMinutes ?? otherDurationMinutes ?? 60)
                : (otherDurationMinutes ?? 60);
            
            categories.add({
              'category_id': categoryId,
              'category_name': placeName,
              'duration': durationMinutes,
              'transportation': transportationCode,
            });
            
            print('✅ [$i] 카테고리 추가: $placeName (id: $categoryId, transport: $transportationCode)');
          } else {
            print('❌ [$i] 매장 ID가 없음: $placeName');
          }
        }
      } else {
        // 🔸 하위 호환성: orderedPlaces가 없으면 기존 방식 사용 (순서 보장 안됨)
        print('⚠️ orderedPlaces가 없음, 기존 방식 사용 (순서 보장 안됨)');
        int addedCategoryCount = 0;
        
        // selectedPlaces의 각 카테고리별로 처리
        for (final entry in selectedPlaces.entries) {
          final categoryName = entry.key;
          final selectedPlaceNames = entry.value; // 선택된 장소 이름 목록
          
          print('🔍 카테고리 처리: $categoryName, 선택된 장소 개수: ${selectedPlaceNames.length}');
          
          // selectedPlacesWithData에서 해당 카테고리의 모든 장소 데이터 찾기
          if (selectedPlacesWithData != null && selectedPlacesWithData.containsKey(categoryName)) {
            final placesData = selectedPlacesWithData[categoryName]!;
            print('🔍 placesData 개수: ${placesData.length}');
            
            // 선택된 각 장소에 대해 카테고리 항목 추가
            for (final placeName in selectedPlaceNames) {
              // placesData에서 해당 장소 이름과 일치하는 항목 찾기
              Map<String, dynamic>? matchedPlace;
              for (final place in placesData) {
                final placeTitle = place['title'] as String? ?? place['name'] as String? ?? '';
                if (placeTitle == placeName) {
                  matchedPlace = place;
                  break;
                }
              }
              
              // 일치하는 항목이 없으면 첫 번째 항목 사용 (fallback)
              if (matchedPlace == null && placesData.isNotEmpty) {
                matchedPlace = placesData[0];
                print('⚠️ 장소 이름 일치하지 않음, 첫 번째 항목 사용: $placeName');
              }
              
              if (matchedPlace != null) {
                final categoryId = matchedPlace['id'] as String?;
                final matchedPlaceName = matchedPlace['title'] as String? ?? 
                                        matchedPlace['name'] as String? ?? 
                                        placeName;
                
                if (categoryId != null && categoryId.isNotEmpty) {
                  // transportation 코드는 0(도보),1(대중교통),2(자동차)
                  final String transportationCode = (transportTypes != null && transportTypes.containsKey(addedCategoryCount))
                      ? transportTypes[addedCategoryCount]!.toString()
                      : '1';

                  // 첫 카테고리는 firstDurationMinutes, 그 외는 otherDurationMinutes 사용
                  final int durationMinutes = addedCategoryCount == 0
                      ? (firstDurationMinutes ?? otherDurationMinutes ?? 60)
                      : (otherDurationMinutes ?? 60);

                  categories.add({
                    'category_id': categoryId,
                    'category_name': matchedPlaceName,
                    'duration': durationMinutes,
                    'transportation': transportationCode,
                  });
                  
                  print('✅ 카테고리 추가: $matchedPlaceName (id: $categoryId, transport: $transportationCode)');
                  addedCategoryCount += 1;
                } else {
                  print('❌ 매장 ID가 없음: $matchedPlaceName');
                }
              }
            }
          } else {
            // selectedPlacesWithData가 없거나 해당 카테고리가 없는 경우
            print('⚠️ selectedPlacesWithData에 카테고리 "$categoryName"이 없음');
            // categoryIdByName에서 찾기 시도
            if (categoryIdByName != null && categoryIdByName.containsKey(categoryName)) {
              final categoryId = categoryIdByName[categoryName];
              if (categoryId != null && categoryId.isNotEmpty) {
                final String transportationCode = (transportTypes != null && transportTypes.containsKey(addedCategoryCount))
                    ? transportTypes[addedCategoryCount]!.toString()
                    : '1';

                final int durationMinutes = addedCategoryCount == 0
                    ? (firstDurationMinutes ?? otherDurationMinutes ?? 60)
                    : (otherDurationMinutes ?? 60);

                categories.add({
                  'category_id': categoryId,
                  'category_name': categoryName,
                  'duration': durationMinutes,
                  'transportation': transportationCode,
                });
                print('✅ categoryIdByName에서 카테고리 추가: $categoryName (id: $categoryId)');
                addedCategoryCount += 1;
              }
            } else {
              print('❌ 카테고리 "$categoryName"의 매장 ID를 찾을 수 없음');
              // throw Exception('카테고리 "$categoryName"의 매장 ID를 찾을 수 없습니다.');
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

      final response = await http.post(
        Uri.parse('$baseUrl/api/service/histories'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'template_type': '0', // 0: 일정표
          'category': categories,
        }),
      ).timeout(
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
  static Future<Map<String, dynamic>> getHistoryDetail(String userId, String mergeHistoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/histories/detail/$mergeHistoryId'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        }
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
  static Future<void> saveOtherHistory(Map<String, List<Map<String, dynamic>>> selectedPlaces) async {
    try {
      final userId = TokenManager.userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('로그인이 필요합니다. user_id 없음');
      }

      // 선택된 장소들을 서버 형식에 맞게 변환
      final List<Map<String, dynamic>> places = [];
      for (final entry in selectedPlaces.entries) {
        final category = entry.key;
        final placeList = entry.value;
        
        for (final place in placeList) {
          final placeName = place['title'] as String? ?? 
                           place['name'] as String? ?? 
                           '알 수 없음';
          final placeAddress = place['address'] as String? ??
                             place['detail_address'] as String? ??
                             '';
          
          places.add({
            'category_name': placeName,
            'duration': 60,
            'transportation': '1',
            'category_id': place['id'] as String? ?? '',
          });
        }
      }

      // 장소 이름들을 "→"로 연결하여 일정표 제목 생성
      final scheduleTitle = places
          .map((p) => (p['category_name'] ?? p['name'] ?? '') as String)
          .where((s) => s.isNotEmpty)
          .join(' → ');

      final response = await http.post(
        Uri.parse('$baseUrl/api/service/histories'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'user_id': userId,
          'template_type': '1', // 1: 그냥
          'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD 형식
          'schedule_title': scheduleTitle,
          'category': places,
        }),
      ).timeout(
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