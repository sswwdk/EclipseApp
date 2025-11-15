import 'package:flutter/material.dart';
import '../../../data/services/history_service.dart';
import '../../../data/services/service_api.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../data/services/route_service.dart';
import 'schedule_screen.dart';
import 'dart:async';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/transportation_selector_widget.dart';
import '../../widgets/app_title_widget.dart';
import 'template_utils.dart';

class ScheduleBuilderScreen extends StatefulWidget {
  final Map<String, List<String>> selected; // 카테고리별 선택 목록
  final Map<String, List<Map<String, dynamic>>>?
  selectedPlacesWithData; // 전체 매장 데이터
  final Map<String, String>? categoryIdByName; // 카테고리명 -> 카테고리ID 매핑
  final String? originAddress; // 출발지 주소
  final String? originDetailAddress; // 출발지 상세 주소
  final int? firstDurationMinutes; // 템플릿: 첫 이동 또는 첫 체류 시간
  final int? otherDurationMinutes; // 템플릿: 이후 체류 시간
  final bool isReadOnly; // 읽기 전용 모드 (편집 불가)
  final Map<int, int>? initialTransportTypes; // 초기 교통수단 정보 (읽기 전용 모드용)
  final Map<int, RouteResult>?
  initialRouteResults; // 🔥 각 구간별 경로 정보 (읽기 전용 모드용)
  final List<Map<String, dynamic>>? orderedPlaces; // 🔥 순서가 유지되는 장소 리스트

  const ScheduleBuilderScreen({
    Key? key,
    required this.selected,
    this.selectedPlacesWithData,
    this.categoryIdByName,
    this.originAddress,
    this.originDetailAddress,
    this.firstDurationMinutes,
    this.otherDurationMinutes,
    this.isReadOnly = false,
    this.initialTransportTypes,
    this.initialRouteResults,
    this.orderedPlaces,
  }) : super(key: key);

  @override
  State<ScheduleBuilderScreen> createState() => _ScheduleBuilderScreenState();
}

class _ScheduleBuilderScreenState extends State<ScheduleBuilderScreen> {
  late List<_ScheduleItem> _items;
  String? _originAddress; // 출발지 주소
  String? _originDetailAddress; // 출발지 상세 주소
  Map<int, int> _transportTypes =
      {}; // 각 구간별 교통수단 (key: segmentIndex, value: transportType)
  Map<int, RouteResult> _calculatedRoutes = {}; // 🔥 미리 계산된 모든 구간의 경로 정보
  bool _isLoadingRoutes = false; // 🔥 경로 계산 중 상태
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    // 위젯에서 전달받은 출발지 주소가 있으면 사용
    if (widget.originAddress != null) {
      _originAddress = widget.originAddress;
    }
    if (widget.originDetailAddress != null) {
      _originDetailAddress = widget.originDetailAddress;
    }

    print('🔍 [ScheduleBuilderScreen] initState');
    print('🔍 orderedPlaces: ${widget.orderedPlaces}');

    _items = _buildScheduleItems(widget.selected);

    print('🔍 [ScheduleBuilderScreen] _items 생성 완료:');
    for (int i = 0; i < _items.length; i++) {
      print('  [$i] ${_items[i].title} (${_items[i].type})');
    }

    // 교통수단 정보 설정 (읽기 전용 모드일 때는 초기값 사용, 아니면 기본값)
    if (widget.isReadOnly && widget.initialTransportTypes != null) {
      _transportTypes = Map<int, int>.from(widget.initialTransportTypes!);
      // 읽기 전용 모드에서는 이미 계산된 경로 정보 사용
      if (widget.initialRouteResults != null) {
        _calculatedRoutes = Map<int, RouteResult>.from(widget.initialRouteResults!);
      }
    } else {
      // 각 구간별로 기본 교통수단 설정 (도보)
      for (int i = 0; i < _items.length - 1; i++) {
        _transportTypes[i] = 0; // 0: 도보, 1: 대중교통, 2: 자동차
      }
      // 🔥 편집 모드일 때 모든 구간의 경로를 미리 계산
      _loadAllRoutes();
    }
  }

  /// 🔥 모든 구간의 경로를 한 번에 계산 (병렬 처리)
  Future<void> _loadAllRoutes() async {
    if (_items.length <= 1) return; // 구간이 없으면 리턴

    setState(() {
      _isLoadingRoutes = true;
    });

    print('🚀 [ScheduleBuilderScreen] 모든 구간 경로 계산 시작...');

    try {
      // 모든 구간의 경로를 병렬로 계산
      final List<Future<MapEntry<int, RouteResult>?>> futures = [];

      for (int i = 0; i < _items.length - 1; i++) {
        final originCoords = i == 0
            ? _getOriginCoordinates()
            : _getPlaceCoordinates(_items[i]);
        final destCoords = _getPlaceCoordinates(_items[i + 1]);

        if (originCoords != null && destCoords != null) {
          futures.add(_calculateRouteForSegment(i, originCoords, destCoords));
        } else {
          print('⚠️ 구간 $i 좌표 정보 없음');
        }
      }

      // 모든 경로 계산을 병렬로 실행
      final results = await Future.wait(futures);

      // 결과를 _calculatedRoutes에 저장
      for (final result in results) {
        if (result != null) {
          _calculatedRoutes[result.key] = result.value;
        }
      }

      print('✅ [ScheduleBuilderScreen] 총 ${_calculatedRoutes.length}개 구간 경로 계산 완료');
    } catch (e) {
      print('❌ [ScheduleBuilderScreen] 경로 계산 중 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
    }
  }

  /// 특정 구간의 경로를 계산하는 헬퍼 메서드
  Future<MapEntry<int, RouteResult>?> _calculateRouteForSegment(
    int segmentIndex,
    ({double lat, double lng}) origin,
    ({double lat, double lng}) destination,
  ) async {
    return TemplateUtils.calculateRouteForSegment(
      segmentIndex: segmentIndex,
      origin: origin,
      destination: destination,
      transportType: _transportTypes[segmentIndex] ?? 0,
      originTitle: _items[segmentIndex].title,
      destinationTitle: _items[segmentIndex + 1].title,
    );
  }

  /// 🔥 교통수단 변경 시 특정 구간만 재계산
  Future<void> _recalculateRoute(int segmentIndex) async {
    final originCoords = segmentIndex == 0
        ? _getOriginCoordinates()
        : _getPlaceCoordinates(_items[segmentIndex]);
    final destCoords = _getPlaceCoordinates(_items[segmentIndex + 1]);

    if (originCoords == null || destCoords == null) {
      print('⚠️ 구간 $segmentIndex 좌표 정보 없음');
      return;
    }

    print('🔄 구간 $segmentIndex 재계산 시작...');

    try {
      final result = await _calculateRouteForSegment(
        segmentIndex,
        originCoords,
        destCoords,
      );

      if (result != null && mounted) {
        setState(() {
          _calculatedRoutes[result.key] = result.value;
        });
        print('✅ 구간 $segmentIndex 재계산 완료');
      }
    } catch (e) {
      print('❌ 구간 $segmentIndex 재계산 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_ScheduleItem> items = _items;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppTitleWidget(
          widget.isReadOnly ? '일정표 상세' : '템플릿 1',
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'home') {
                _showGoHomeDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home, size: 20, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('홈으로 돌아가기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoadingRoutes
          ? TemplateUtils.buildLoadingWidget(
              completedRoutes: _calculatedRoutes.length,
              totalRoutes: _items.length - 1,
              accentColor: const Color(0xFFFF8126),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: items.length * 2 - 1,
              itemBuilder: (context, index) {
                if (index % 2 == 0) {
                  // 실제 아이템 (index를 2로 나눈 값)
                  int itemIndex = index ~/ 2;
                  final item = items[itemIndex];
                  return _TimelineRow(
                    item: item,
                    index: itemIndex,
                    isLast: itemIndex == items.length - 1,
                    showDuration: true,
                    onDragHandle: null,
                    onTap: null,
                  );
                } else {
                  // 아이템 사이의 교통수단 정보
                  int itemIndex = index ~/ 2;
                  if (itemIndex < items.length - 1) {
                    return TransportationSelectorWidget(
                      segmentIndex: itemIndex,
                      selectedTransportType:
                          _transportTypes[itemIndex] ?? 0, // 기본값: 도보
                      onTransportTypeChanged: widget.isReadOnly
                          ? null
                          : (type) {
                              // 🔥 교통수단 변경 시 해당 구간만 재계산
                              setState(() {
                                _transportTypes[itemIndex] = type;
                              });
                              _recalculateRoute(itemIndex);
                            },
                      isReadOnly: widget.isReadOnly,
                      originCoordinates: itemIndex == 0
                          ? _getOriginCoordinates()
                          : _getPlaceCoordinates(items[itemIndex]),
                      destinationCoordinates: _getPlaceCoordinates(
                        items[itemIndex + 1],
                      ),
                      initialRouteResult: _calculatedRoutes[itemIndex], // 🔥 미리 계산된 경로 정보 전달
                      style: TransportationSelectorStyle.card,
                    );
                  }
                  return const SizedBox.shrink();
                }
              },
            ),
      bottomNavigationBar: widget.isReadOnly
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Color(0xFFFF8126),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: const Color(0xFFFF8126),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF8126),
                                  ),
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  '저장하기',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSharing ? null : _handleShare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8126),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: _isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  '공유하기',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 홈으로 돌아가기 다이얼로그 표시
  Future<void> _showGoHomeDialog() async {
    await TemplateUtils.showGoHomeDialog(
      context: context,
      accentColor: const Color(0xFFFF8126),
    );
  }

  /// 저장하기 버튼 클릭 시 서버에 일정표 저장
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 🔥 이미 계산된 경로 정보 사용 (필요한 경우 누락된 구간만 재계산)
      print('🚀 경로 정보 확인 중...');
      final Map<int, RouteResult> routeResults = Map<int, RouteResult>.from(_calculatedRoutes);

      // 누락된 구간이 있으면 계산
      for (int i = 0; i < _items.length - 1; i++) {
        if (!routeResults.containsKey(i)) {
          final originCoords = i == 0
              ? _getOriginCoordinates()
              : _getPlaceCoordinates(_items[i]);
          final destCoords = _getPlaceCoordinates(_items[i + 1]);

          if (originCoords != null && destCoords != null) {
            try {
              print('🔍 누락된 구간 $i 경로 계산 중...');
              final route = await RouteService.calculateRoute(
                origin: originCoords,
                destination: destCoords,
                transportType: _transportTypes[i] ?? 0,
              );
              routeResults[i] = route;
              print('✅ 구간 $i 경로 계산 완료: ${route.durationMinutes}분');
            } catch (e) {
              print('❌ 구간 $i 경로 계산 실패: $e');
            }
          }
        }
      }

      print('🚀 총 ${routeResults.length}개 구간 경로 정보 확인 완료');

      // 서버에 저장
      await HistoryService.saveSchedule(
        selectedPlaces: widget.selected,
        selectedPlacesWithData: widget.selectedPlacesWithData,
        orderedPlaces: widget.orderedPlaces, // 🔥 순서가 유지되는 리스트 전달
        categoryIdByName: widget.categoryIdByName,
        originAddress: _originAddress,
        originDetailAddress: _originDetailAddress,
        transportTypes: _transportTypes,
        routeResults: routeResults, // 🔥 실제 경로 정보 전달
        firstDurationMinutes: widget.firstDurationMinutes,
        otherDurationMinutes: widget.otherDurationMinutes,
        templateType: 1,
      );

      if (!mounted) return;

      CommonDialogs.showSuccess(
        context: context,
        message: '일정표 히스토리에 저장되었습니다.',
      );

      // 홈 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      print('❌ 일정표 저장 실패: $e');
      CommonDialogs.showError(
        context: context,
        message: '저장 중 오류가 발생했습니다: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 공유하기 버튼 클릭 시 서버에 일정표 공유
  Future<void> _handleShare() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final userId = TokenManager.userId;
      if (userId == null) {
        if (!mounted) return;
        CommonDialogs.showError(
          context: context,
          message: '로그인이 필요합니다.',
        );
        return;
      }

      // 일정표 정보를 문자열로 변환
      final scheduleText = _buildScheduleText();

      // 커뮤니티에 공유
      await ServiceApi.shareToCommunity(scheduleText, userId);

      if (!mounted) return;

      CommonDialogs.showSuccess(
        context: context,
        message: '커뮤니티에 공유되었습니다.',
      );
    } catch (e) {
      if (!mounted) return;

      print('❌ 일정표 공유 실패: $e');
      CommonDialogs.showError(
        context: context,
        message: '공유 중 오류가 발생했습니다: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  /// 일정표 정보를 텍스트로 변환
  String _buildScheduleText() {
    return TemplateUtils.buildScheduleText(
      selected: widget.selected,
      originAddress: _originAddress,
      originDetailAddress: _originDetailAddress,
    );
  }

  // 최종 화면에서는 출발지 수정 기능이 없습니다.

  List<_ScheduleItem> _buildScheduleItems(Map<String, List<String>> selected) {
    final List<_ScheduleItem> items = [];

    items.add(
      _ScheduleItem(
        title: '출발지',
        subtitle: '',
        address: null,
        icon: Icons.home_outlined,
        color: Colors.grey[700]!,
        type: _ItemType.origin,
        time: null,
      ),
    );

    // 🔥 orderedPlaces가 있으면 순서대로 사용, 없으면 기존 방식
    if (widget.orderedPlaces != null && widget.orderedPlaces!.isNotEmpty) {
      print('🔍 [_buildScheduleItems] orderedPlaces 사용');

      // 순서가 유지되는 리스트 사용
      for (int i = 0; i < widget.orderedPlaces!.length; i++) {
        final placeData = widget.orderedPlaces![i];
        print('🔍 [_buildScheduleItems] [$i] placeData: $placeData');

        final placeName = placeData['name'] as String? ?? '알 수 없음';
        final category = placeData['category'] as String? ?? '기타';

        // 🔥 주소 정보 추출 개선 - 여러 키를 확인
        String? address;

        // 1. 최상위 레벨에서 주소 확인
        address = placeData['address'] as String?;

        // 2. detail_address 확인
        if (address == null || address.isEmpty) {
          address = placeData['detail_address'] as String?;
        }

        // 3. data 객체 안에서 확인
        if (address == null || address.isEmpty) {
          final data = placeData['data'] as Map<String, dynamic>?;
          if (data != null) {
            address = data['address'] as String?;
            if (address == null || address.isEmpty) {
              address = data['detail_address'] as String?;
            }
          }
        }

        print('🔍 [_buildScheduleItems] [$i] 추출된 주소: $address');

        items.add(
          _ScheduleItem(
            title: placeName,
            subtitle: category,
            address: address, // 🔥 개선된 주소 정보
            icon: _iconFor(category),
            color: const Color(0xFFFF8126),
            type: _ItemType.place,
            durationMinutes: items.length == 1
                ? (widget.firstDurationMinutes ?? 45)
                : (widget.otherDurationMinutes ?? 20),
            time: null,
          ),
        );
      }
    } else {
      print('🔍 [_buildScheduleItems] 기존 방식 사용 (selected)');

      // 기존 방식: 카테고리별로 그룹화됨 (하위 호환성)
      // 이 경우 주소 정보를 가져오려면 selectedPlacesWithData를 사용해야 함
      selected.forEach((category, places) {
        for (final placeName in places) {
          // selectedPlacesWithData에서 해당 장소의 데이터 찾기
          String? address;

          if (widget.selectedPlacesWithData != null) {
            final categoryPlaces = widget.selectedPlacesWithData![category];
            if (categoryPlaces != null) {
              final placeData = categoryPlaces.firstWhere(
                (p) => p['name'] == placeName,
                orElse: () => <String, dynamic>{},
              );

              if (placeData.isNotEmpty) {
                address = placeData['address'] as String?;
                if (address == null || address.isEmpty) {
                  address = placeData['detail_address'] as String?;
                }
              }
            }
          }

          items.add(
            _ScheduleItem(
              title: placeName,
              subtitle: category,
              address: address, // 🔥 주소 정보 추가
              icon: _iconFor(category),
              color: const Color(0xFFFF8126),
              type: _ItemType.place,
              durationMinutes: items.length == 1
                  ? (widget.firstDurationMinutes ?? 45)
                  : (widget.otherDurationMinutes ?? 20),
              time: null,
            ),
          );
        }
      });
    }

    return items;
  }

  IconData _iconFor(String category) {
    switch (category) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '콘텐츠':
        return Icons.movie_filter;
      default:
        return Icons.place;
    }
  }

  /// 장소의 위경도를 가져오는 헬퍼 메서드
  ({double lat, double lng})? _getPlaceCoordinates(_ScheduleItem item) {
    return TemplateUtils.getPlaceCoordinates(
      placeTitle: item.title,
      orderedPlaces: widget.orderedPlaces,
      selectedPlacesWithData: widget.selectedPlacesWithData,
    );
  }

  /// 출발지 좌표를 가져오는 헬퍼 메서드
  ({double lat, double lng})? _getOriginCoordinates() {
    return TemplateUtils.getOriginCoordinates(_originAddress);
  }
}

enum _ItemType { origin, place }

class _ScheduleItem {
  final String id = UniqueKey().toString();
  final String title;
  final String subtitle;
  final String? address; // 🔥 주소 정보 추가
  final IconData icon;
  final Color color;
  final _ItemType type;
  final int? durationMinutes;
  final String? time;

  _ScheduleItem({
    required this.title,
    required this.subtitle,
    this.address,
    required this.icon,
    required this.color,
    required this.type,
    this.durationMinutes,
    this.time,
  });
}

class _TimelineRow extends StatelessWidget {
  final _ScheduleItem item;
  final int index;
  final bool isLast;
  final Widget Function(Widget child)? onDragHandle;
  final bool showDuration;
  final VoidCallback? onTap;

  const _TimelineRow({
    Key? key,
    required this.item,
    required this.index,
    this.isLast = false,
    this.onDragHandle,
    this.showDuration = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 모든 항목의 박스 크기를 동일하게 유지
    final double timeWidth = 0;
    final double gapWidth = 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.time ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: gapWidth),
          // 타임라인 바
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8126),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[300]!.withOpacity(0.3),
                        Colors.grey[300]!,
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 카드
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.type == _ItemType.origin
                      ? Colors.white
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.type == _ItemType.origin
                        ? const Color(0xFFFF8126).withOpacity(0.6)
                        : const Color(0xFFFF8126),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.type == _ItemType.origin
                            ? Colors.grey[200]
                            : const Color(0xFFFFEFE3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.type == _ItemType.origin
                            ? Colors.grey[700]
                            : const Color(0xFFFF8126),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          if (item.type != _ItemType.origin) ...[
                            const SizedBox(height: 4),
                            // 🔥 카테고리 정보 표시
                            if (item.subtitle.isNotEmpty) ...[
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            // 🔥 주소 정보 표시
                            Text(
                              item.address ?? '주소 정보 없음',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.address != null
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 출발지 주소 입력 화면
class OriginAddressInputScreen extends StatefulWidget {
  final String? initialAddress;
  final String? initialDetailAddress;

  const OriginAddressInputScreen({
    Key? key,
    this.initialAddress,
    this.initialDetailAddress,
  }) : super(key: key);

  @override
  State<OriginAddressInputScreen> createState() =>
      _OriginAddressInputScreenState();
}

class _OriginAddressInputScreenState extends State<OriginAddressInputScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailAddressController =
      TextEditingController();
  final FocusNode _detailAddressFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';
    _detailAddressController.text = widget.initialDetailAddress ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _detailAddressController.dispose();
    _detailAddressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) {
      _showSnackBar('주소를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 주소 저장
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      Navigator.pop(context, {
        'address': _addressController.text.trim(),
        'detailAddress': _detailAddressController.text.trim(),
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('주소 저장 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    CommonDialogs.showMessage(
      context: context,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppTitleWidget('출발지 입력'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8126)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // 구분선
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '또는 주소 직접 입력',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 주소 입력 필드
                  Text(
                    '주소',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(
                        context,
                      ).requestFocus(_detailAddressFocusNode);
                    },
                    decoration: InputDecoration(
                      hintText: '예: 서울시 강남구 테헤란로 123',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFFFF8126),
                        ),
                        onPressed: () {
                          // TODO: 주소 검색 기능 구현 (카카오 주소 API 등)
                          _showSnackBar('주소 검색 기능은 준비 중입니다.\n직접 입력해주세요.');
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 상세 주소 입력 필드
                  Text(
                    '상세 주소 (건물명, 동/호수 등)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _detailAddressController,
                    focusNode: _detailAddressFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isLoading) {
                        _saveAddress();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '예: 스타벅스 강남점, 삼성역 1번 출구',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 저장하기 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8126),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '저장하기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
