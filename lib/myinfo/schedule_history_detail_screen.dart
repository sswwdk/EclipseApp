import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/token_manager.dart';
import '../make_todo/default_template.dart';
import '../services/route_service.dart';

/// 일정표 히스토리 상세 화면
class ScheduleHistoryDetailScreen extends StatefulWidget {
  final String historyId;

  const ScheduleHistoryDetailScreen({
    Key? key,
    required this.historyId,
  }) : super(key: key);

  @override
  State<ScheduleHistoryDetailScreen> createState() => _ScheduleHistoryDetailScreenState();
}

class _ScheduleHistoryDetailScreenState extends State<ScheduleHistoryDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistoryDetail();
  }

  /// 히스토리 상세 정보 로드
  Future<void> _loadHistoryDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = TokenManager.userId;
      if (userId == null) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      // 히스토리 상세 정보 가져오기
      final detailResponse = await HistoryService.getHistoryDetail(userId, widget.historyId);
      
      if (!mounted) return;

      // 상세 정보 파싱하여 일정표 데이터로 변환
      final scheduleData = _parseHistoryDetailToScheduleData(detailResponse);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      // 일정표 상세 화면으로 이동 (읽기 전용)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleBuilderScreen(
            selected: scheduleData['selectedPlaces'] as Map<String, List<String>>,
            selectedPlacesWithData: scheduleData['selectedPlacesWithData'] as Map<String, List<Map<String, dynamic>>>?,
            orderedPlaces: scheduleData['orderedPlaces'] as List<Map<String, dynamic>>?, // 🔥 순서 유지
            categoryIdByName: scheduleData['categoryIdByName'] as Map<String, String>?,
            originAddress: scheduleData['originAddress'] as String?,
            originDetailAddress: scheduleData['originDetailAddress'] as String?,
            firstDurationMinutes: scheduleData['firstDurationMinutes'] as int?,
            otherDurationMinutes: scheduleData['otherDurationMinutes'] as int?,
            isReadOnly: true,
            initialTransportTypes: scheduleData['transportTypes'] as Map<int, int>?,
            initialRouteResults: scheduleData['routeResults'] as Map<int, RouteResult>?, // 🔥 각 구간별 경로 정보
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '일정표를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 히스토리 상세 데이터를 일정표 데이터 형식으로 변환
  Map<String, dynamic> _parseHistoryDetailToScheduleData(Map<String, dynamic> detailResponse) {
    // 서버 응답에서 데이터 추출
    final data = detailResponse['data'] ?? detailResponse;
    
    // 카테고리 정보 추출
    final categories = data['categories'] as List<dynamic>? ?? [];
    final Map<String, List<String>> selectedPlaces = {};
    final Map<String, List<Map<String, dynamic>>> selectedPlacesWithData = {};
    final Map<String, String> categoryIdByName = {};
    final List<Map<String, dynamic>> orderedPlaces = []; // 🔥 순서를 유지하는 리스트
    final Map<int, int> transportTypes = {};
    final Map<int, RouteResult> routeResults = {}; // 🔥 각 구간별 경로 정보
    String? originAddress;
    String? originDetailAddress;
    int? firstDurationMinutes;
    int? otherDurationMinutes;

    // 출발지 정보 추출
    if (data['origin_address'] != null) {
      originAddress = data['origin_address'] as String?;
    }
    if (data['origin_detail_address'] != null) {
      originDetailAddress = data['origin_detail_address'] as String?;
    }

    print('🔍 서버에서 받은 categories: $categories');
    
    // 🔥 seq 필드로 정렬 (서버 응답에 seq가 있음!)
    final sortedCategories = List<Map<String, dynamic>>.from(
      categories.map((c) => c as Map<String, dynamic>)
    );
    sortedCategories.sort((a, b) {
      final seqA = a['seq'] as int? ?? 0;
      final seqB = b['seq'] as int? ?? 0;
      return seqA.compareTo(seqB);
    });
    
    print('🔍 seq로 정렬된 categories:');
    for (int i = 0; i < sortedCategories.length; i++) {
      print('  [$i] ${sortedCategories[i]['category_name']} (seq: ${sortedCategories[i]['seq']})');
    }

    // 🔥 정렬된 순서대로 처리
    for (int i = 0; i < sortedCategories.length; i++) {
      final category = sortedCategories[i];
      final categoryName = category['category_name'] as String? ?? '';
      final categoryId = category['category_id'] as String? ?? '';
      final duration = category['duration'] as int? ?? 60;
      int transportation = 1; // 기본값: 대중교통
      if (category['transportation'] != null) {
        if (category['transportation'] is int) {
          transportation = category['transportation'] as int;
        } else if (category['transportation'] is String) {
          transportation = int.tryParse(category['transportation'] as String) ?? 1;
        }
      }

      print('🔍 [$i] categoryName: $categoryName, transportation: $transportation');
      
      if (categoryName.isEmpty) continue;

      // 🔥 서버에서 받은 주소 정보 추출
      final address = category['address'] as String? ?? 
                     category['detail_address'] as String? ??
                     category['address_detail'] as String?;
      
      // 🔥 서버에서 받은 카테고리 정보 추출 (카테고리 타입)
      final categoryType = category['category'] as String? ?? 
                          category['category_type'] as String? ??
                          categoryName; // 기본값으로 categoryName 사용

      print('🔍 [$i] 주소: $address, 카테고리: $categoryType');

      // 🔥 orderedPlaces에 순서대로 추가 (seq 순서 기준!)
      orderedPlaces.add({
        'id': categoryId,
        'name': categoryName,
        'category': categoryType, // 실제 카테고리 타입 사용
        'address': address, // 주소 정보 추가
        'detail_address': category['detail_address'] as String?,
      });

      // selectedPlaces에 추가 (하위 호환성)
      if (!selectedPlaces.containsKey(categoryType)) {
        selectedPlaces[categoryType] = [];
      }
      selectedPlaces[categoryType]!.add(categoryName);

      // selectedPlacesWithData에 추가 (하위 호환성)
      if (!selectedPlacesWithData.containsKey(categoryType)) {
        selectedPlacesWithData[categoryType] = [];
      }
      selectedPlacesWithData[categoryType]!.add({
        'id': categoryId,
        'title': categoryName,
        'name': categoryName,
        'address': address,
        'detail_address': category['detail_address'] as String?,
        'category': categoryType,
      });

      // categoryIdByName에 추가
      if (categoryId.isNotEmpty) {
        categoryIdByName[categoryName] = categoryId;
      }

      // 🔥 교통수단 정보 저장: sortedCategories[i]의 transportation은 "출발지 → i번째 장소"의 이동수단
      transportTypes[i] = transportation;

      // 🔥 서버에서 받은 경로 정보 파싱 (duration, distance, routes)
      final routeResult = _parseRouteInfo(category, duration);
      if (routeResult != null) {
        routeResults[i] = routeResult;
      }

      // 첫 번째 체류 시간 설정
      if (i == 0) {
        firstDurationMinutes = duration;
      } else {
        otherDurationMinutes = duration;
      }
    }

    print('🔍 생성된 orderedPlaces: $orderedPlaces');
    print('🔍 생성된 transportTypes: $transportTypes');
    print('🔍 생성된 routeResults: ${routeResults.keys.toList()}');

    return {
      'selectedPlaces': selectedPlaces,
      'selectedPlacesWithData': selectedPlacesWithData,
      'orderedPlaces': orderedPlaces, // 🔥 순서가 유지되는 리스트 반환
      'categoryIdByName': categoryIdByName,
      'originAddress': originAddress,
      'originDetailAddress': originDetailAddress,
      'transportTypes': transportTypes,
      'routeResults': routeResults, // 🔥 각 구간별 경로 정보
      'firstDurationMinutes': firstDurationMinutes,
      'otherDurationMinutes': otherDurationMinutes,
    };
  }

  /// 서버에서 받은 category 데이터에서 경로 정보 파싱
  RouteResult? _parseRouteInfo(Map<String, dynamic> category, int defaultDuration) {
    try {
      // duration 파싱 (초 단위 또는 분 단위)
      int? durationSeconds;
      bool isAlreadyInMinutes = false;
      
      if (category.containsKey('duration_seconds')) {
        final duration = category['duration_seconds'];
        if (duration is int) {
          durationSeconds = duration;
        } else if (duration is String) {
          durationSeconds = int.tryParse(duration);
        }
      } else if (category.containsKey('duration')) {
        // duration이 초 단위인 경우 (서버에서 보통 초 단위로 보냄)
        final duration = category['duration'];
        if (duration is int) {
          durationSeconds = duration;
        } else if (duration is String) {
          durationSeconds = int.tryParse(duration);
        }
      } else if (category.containsKey('duration_minutes')) {
        final duration = category['duration_minutes'];
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
      
      // duration을 분으로 변환
      int durationMinutes = defaultDuration;
      if (durationSeconds != null) {
        if (isAlreadyInMinutes) {
          durationMinutes = durationSeconds;
        } else {
          durationMinutes = (durationSeconds / 60).round();
        }
      }

      // distance 파싱
      double? distanceValue;
      if (category.containsKey('distance')) {
        final distance = category['distance'];
        if (distance is num) {
          distanceValue = distance.toDouble();
        } else if (distance is String) {
          distanceValue = double.tryParse(distance);
        }
      } else if (category.containsKey('distance_meters')) {
        final distance = category['distance_meters'];
        if (distance is num) {
          distanceValue = distance.toDouble();
        } else if (distance is String) {
          distanceValue = double.tryParse(distance);
        }
      }
      int distanceMeters = (distanceValue ?? 0).round();

      // routes 파싱 (대중교통 경로 정보)
      List<RouteStep>? steps;
      final routes = category['routes'] as List<dynamic>?;
      if (routes != null && routes.isNotEmpty) {
        steps = routes.map((route) {
          if (route is Map<String, dynamic>) {
            return RouteStep.fromPublicTransportRoute(route);
          }
          return null;
        }).whereType<RouteStep>().toList();
      }

      return RouteResult(
        durationMinutes: durationMinutes,
        distanceMeters: distanceMeters,
        steps: steps,
        summary: category['summary'] as String?,
      );
    } catch (e) {
      print('❌ 경로 정보 파싱 실패: $e');
      // 파싱 실패 시 기본값으로 RouteResult 생성
      return RouteResult(
        durationMinutes: defaultDuration,
        distanceMeters: 0,
        steps: null,
        summary: null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          '일정표 상세',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistoryDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}

