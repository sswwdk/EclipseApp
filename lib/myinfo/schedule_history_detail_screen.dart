import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/token_manager.dart';
import '../make_todo/default_template.dart';

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
            categoryIdByName: scheduleData['categoryIdByName'] as Map<String, String>?,
            originAddress: scheduleData['originAddress'] as String?,
            originDetailAddress: scheduleData['originDetailAddress'] as String?,
            firstDurationMinutes: scheduleData['firstDurationMinutes'] as int?,
            otherDurationMinutes: scheduleData['otherDurationMinutes'] as int?,
            isReadOnly: true,
            initialTransportTypes: scheduleData['transportTypes'] as Map<int, int>?,
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
    final Map<int, int> transportTypes = {};
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

    // 각 카테고리 처리
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i] as Map<String, dynamic>;
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

      if (categoryName.isNotEmpty) {
        // selectedPlaces에 추가
        if (!selectedPlaces.containsKey(categoryName)) {
          selectedPlaces[categoryName] = [];
        }
        selectedPlaces[categoryName]!.add(categoryName);

        // selectedPlacesWithData에 추가
        if (!selectedPlacesWithData.containsKey(categoryName)) {
          selectedPlacesWithData[categoryName] = [];
        }
        selectedPlacesWithData[categoryName]!.add({
          'id': categoryId,
          'title': categoryName,
          'name': categoryName,
        });

        // categoryIdByName에 추가
        if (categoryId.isNotEmpty) {
          categoryIdByName[categoryName] = categoryId;
        }

        // 교통수단 정보 저장
        if (i > 0) {
          transportTypes[i - 1] = transportation;
        }

        // 첫 번째 체류 시간 설정
        if (i == 0) {
          firstDurationMinutes = duration;
        } else {
          otherDurationMinutes = duration;
        }
      }
    }

    return {
      'selectedPlaces': selectedPlaces,
      'selectedPlacesWithData': selectedPlacesWithData,
      'categoryIdByName': categoryIdByName,
      'originAddress': originAddress,
      'originDetailAddress': originDetailAddress,
      'transportTypes': transportTypes,
      'firstDurationMinutes': firstDurationMinutes,
      'otherDurationMinutes': otherDurationMinutes,
    };
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

