import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../config/server_config.dart';

class HistoryService {
  static String get baseUrl => ServerConfig.baseUrl;

  // 내 히스토리 보기
  static Future<Map<String, dynamic>> getMyHistory(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/service/my-history'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({'user_id': userId}),
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
        Uri.parse('$baseUrl/api/service/my-history'),
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
      print('📍 [CALL-$callId] selectedPlacesWithData: $selectedPlacesWithData');
      
      final List<Map<String, dynamic>> categories = [];
      for (final entry in selectedPlaces.entries) {
        final categoryName = entry.key;
        // entry.value는 현재 카테고리 내 선택 장소 목록이지만, 서버 전송 스키마에는 개수만 영향을 주지 않으므로 미사용
        
        // selectedPlacesWithData에서 매장 ID 찾기
        String? categoryId;
        
        if (selectedPlacesWithData != null && selectedPlacesWithData.containsKey(categoryName)) {
          final placesData = selectedPlacesWithData[categoryName]!;
          if (placesData.isNotEmpty) {
            // 첫 번째 매장의 id를 category_id로 사용
            categoryId = placesData[0]['id'] as String?;
            print('✅ 매장 ID를 category_id로 사용: $categoryName -> $categoryId');
          }
        }
        
        if (categoryId == null || categoryId.isEmpty) {
          print('❌ 매장 ID를 찾을 수 없음: $categoryName');
          throw Exception('카테고리 "$categoryName"의 매장 ID를 찾을 수 없습니다.');
        }
        
        // transportation 코드는 0(도보),1(대중교통),2(자동차). 전달받은 구간 정보가 없으면 1로 기본값 처리
        final String transportationCode = (transportTypes != null && transportTypes.isNotEmpty)
            ? (transportTypes.values.first.toString())
            : '1';
        categories.add({
          'category_id': categoryId,
          'category_name': categoryName,
          'duration': otherDurationMinutes ?? 60,
          'transportation': transportationCode,
        });
      }

      print('📍 최종 categories 데이터: $categories');

      final userId = TokenManager.userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('로그인이 필요합니다. user_id 없음');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/service/history'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'user_id': userId,
          'template_type': 'travel_planning',
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

  // 일정표 히스토리 "그냥" 탭에 저장
  static Future<void> saveOtherHistory(Map<String, List<Map<String, dynamic>>> selectedPlaces) async {
    try {
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
            'category': category,
            'name': placeName,
            'address': placeAddress,
            'place_id': place['id'] as String? ?? '',
          });
        }
      }

      // 장소 이름들을 "→"로 연결하여 일정표 제목 생성
      final scheduleTitle = places.map((p) => p['name'] as String).join(' → ');

      final response = await http.post(
        Uri.parse('$baseUrl/api/service/history'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.jwtHeader,
        },
        body: json.encode({
          'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD 형식
          'schedule_title': scheduleTitle,
          'places': places,
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