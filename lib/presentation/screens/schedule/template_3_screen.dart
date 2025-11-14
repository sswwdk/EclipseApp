import 'package:flutter/material.dart';
import '../../../data/services/route_service.dart';
import '../../../data/services/history_service.dart';
import '../../../data/services/service_api.dart';
import '../../../data/models/restaurant.dart';
import '../../../shared/helpers/token_manager.dart';
import '../main/main_screen.dart';
import '../main/restaurant_detail_screen.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../widgets/transportation_selector_widget.dart';
import '../../widgets/app_title_widget.dart';
import 'template_utils.dart';

class Template3Screen extends StatefulWidget {
  final Map<String, List<String>> selected;
  final Map<String, List<Map<String, dynamic>>>? selectedPlacesWithData;
  final Map<String, String>? categoryIdByName;
  final String? originAddress;
  final String? originDetailAddress;
  final int? firstDurationMinutes;
  final int? otherDurationMinutes;
  final bool isReadOnly;
  final Map<int, int>? initialTransportTypes;
  final Map<int, RouteResult>? initialRouteResults;
  final List<Map<String, dynamic>>? orderedPlaces;

  const Template3Screen({
    super.key,
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
  });

  @override
  State<Template3Screen> createState() => _Template3ScreenState();
}

class _Template3ScreenState extends State<Template3Screen> {
  late final List<_TimelineStop> _stops;
  late final List<String> _selectedTransportKeys;
  Map<int, RouteResult> _calculatedRoutes = {}; // 🔥 각 구간별 경로 정보
  bool _isLoadingRoutes = false; // 🔥 경로 계산 중 상태
  bool _isSaving = false; // 🔥 저장 중 상태
  bool _isSharing = false; // 🔥 공유 중 상태

  static const List<_TransportOption> _transportOptions = [
    _TransportOption(
      key: 'walk',
      label: '도보',
      icon: Icons.directions_walk_outlined,
    ),
    _TransportOption(
      key: 'public',
      label: '대중교통',
      icon: Icons.directions_transit_outlined,
    ),
    _TransportOption(
      key: 'car',
      label: '자동차',
      icon: Icons.directions_car_filled_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _stops = _buildStops();
    _selectedTransportKeys = List<String>.generate(
      _stops.length > 1 ? _stops.length - 1 : 0,
      (_) => _transportOptions.first.key,
    );
    
    // 🔥 읽기 전용 모드일 때는 초기 경로 정보 사용, 아니면 계산
    if (widget.isReadOnly && widget.initialRouteResults != null) {
      _calculatedRoutes = Map<int, RouteResult>.from(widget.initialRouteResults!);
    } else if (!widget.isReadOnly) {
      // 편집 모드일 때 모든 구간의 경로를 미리 계산
      _loadAllRoutes();
    }
  }

  /// 🔥 모든 구간의 경로를 한 번에 계산 (병렬 처리)
  Future<void> _loadAllRoutes() async {
    if (_stops.length <= 1) return; // 구간이 없으면 리턴

    setState(() {
      _isLoadingRoutes = true;
    });

    print('🚀 [Template3Screen] 모든 구간 경로 계산 시작...');

    try {
      // 모든 구간의 경로를 병렬로 계산
      final List<Future<MapEntry<int, RouteResult>?>> futures = [];

      for (int i = 0; i < _stops.length - 1; i++) {
        final originCoords = i == 0
            ? _getOriginCoordinates()
            : _getPlaceCoordinates(_stops[i]);
        final destCoords = _getPlaceCoordinates(_stops[i + 1]);

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

      print('✅ [Template3Screen] 총 ${_calculatedRoutes.length}개 구간 경로 계산 완료');
    } catch (e) {
      print('❌ [Template3Screen] 경로 계산 중 오류: $e');
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
    // 선택된 이동수단을 int로 변환 (walk: 0, public: 1, car: 2)
    int transportType = 0;
    final selectedKey = _selectedTransportKeys[segmentIndex];
    if (selectedKey == 'public') {
      transportType = 1;
    } else if (selectedKey == 'car') {
      transportType = 2;
    }

    return TemplateUtils.calculateRouteForSegment(
      segmentIndex: segmentIndex,
      origin: origin,
      destination: destination,
      transportType: transportType,
      originTitle: _stops[segmentIndex].title,
      destinationTitle: _stops[segmentIndex + 1].title,
    );
  }

  /// 🔥 교통수단 변경 시 특정 구간만 재계산
  Future<void> _recalculateRoute(int segmentIndex) async {
    final originCoords = segmentIndex == 0
        ? _getOriginCoordinates()
        : _getPlaceCoordinates(_stops[segmentIndex]);
    final destCoords = _getPlaceCoordinates(_stops[segmentIndex + 1]);

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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    const backgroundColor = Color(0xFFFFF7F7);
    const accentColor = Color(0xFFFB7C9E);
    const trackColor = Color(0xFFFBC5D4);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const AppTitleWidget('템플릿 3'),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: accentColor,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: accentColor,
            ),
            onSelected: (value) {
              if (value == 'home') {
                _showGoHomeDialog();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home_outlined, size: 20, color: Colors.black87),
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
              totalRoutes: _stops.length - 1,
              accentColor: const Color(0xFFFB7C9E),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTimelineSection(trackColor, accentColor, textTheme),
                        const SizedBox(height: 32),
                        if (_stops.length > 1)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '이동수단 및 소요시간',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(
                                _stops.length - 1,
                                (index) => _buildTransportSelector(
                                  index,
                                  accentColor,
                                  textTheme,
                                ),
                              ),
                            ],
                          )
                        else
                          _buildEmptyTransportPlaceholder(textTheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: widget.isReadOnly
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0x1AFB7C9E)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFFB7C9E), width: 2),
                          foregroundColor: const Color(0xFFFB7C9E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFB7C9E),
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
                          backgroundColor: const Color(0xFFFB7C9E),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  Widget _buildTimelineSection(
    Color trackColor,
    Color accentColor,
    TextTheme textTheme,
  ) {
    if (_stops.isEmpty) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _stops.length; i++) ...[
                _buildTimelineStop(
                  context,
                  _stops[i],
                  i == 0,
                  i == _stops.length - 1,
                  trackColor,
                  accentColor,
                  textTheme,
                ),
                if (i < _stops.length - 1)
                  _buildConnectorLine(trackColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 원과 원 사이의 연결선 박스
  Widget _buildConnectorLine(Color trackColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 42), // 카테고리(30) + 마진(12) = 42
      child: Container(
        width: 60,
        height: 68, // 원의 높이와 동일
        alignment: Alignment.center,
        child: Container(
          width: 60,
          height: 4,
          color: trackColor,
        ),
      ),
    );
  }

  Widget _buildTimelineStop(
    BuildContext context,
    _TimelineStop stop,
    bool isFirst,
    bool isLast,
    Color trackColor,
    Color accentColor,
    TextTheme textTheme,
  ) {
    final bool isClickable =
        stop.placeId != null && stop.placeId!.isNotEmpty;

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 240),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: isClickable ? () => _handleStopTap(stop) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 카테고리 영역 (고정 높이 30px + 마진 12px = 42px)
              SizedBox(
                height: 42,
                child: stop.category != null && stop.category!.trim().isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          stop.category!,
                          style: textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  stop.icon,
                  size: 30,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      stop.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4E4A4A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (stop.subtitle != null && stop.subtitle!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          stop.subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStopTap(_TimelineStop stop) {
    final restaurant = _buildRestaurantFromStop(stop);
    if (restaurant == null) {
      CommonDialogs.showError(
        context: context,
        message: '매장 정보를 불러올 수 없습니다.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
      ),
    );
  }

  Restaurant? _buildRestaurantFromStop(_TimelineStop stop) {
    final placeId = stop.placeId;
    if (placeId == null || placeId.isEmpty) {
      return null;
    }

    final Map<String, dynamic>? data = stop.placeData;
    final Map<String, dynamic>? nestedData =
        data?['data'] is Map<String, dynamic> ? (data!['data'] as Map<String, dynamic>) : null;

    String? detailAddress = stop.subtitle;
    detailAddress ??= _stringFromDynamic(data?['detail_address']) ??
        _stringFromDynamic(data?['address']) ??
        _stringFromDynamic(nestedData?['detail_address']) ??
        _stringFromDynamic(nestedData?['address']);

    final String? subCategory = _stringFromDynamic(data?['category']) ??
        _stringFromDynamic(data?['sub_category']) ??
        (stop.category?.trim().isNotEmpty == true ? stop.category : null);

    final String? image = _stringFromDynamic(data?['image_url']) ??
        _stringFromDynamic(data?['image']) ??
        _stringFromDynamic(nestedData?['image_url']) ??
        _stringFromDynamic(nestedData?['image']);

    final String? latitude = _stringFromDynamic(
          data?['latitude'] ?? data?['lat'],
        ) ??
        _stringFromDynamic(nestedData?['latitude'] ?? nestedData?['lat']);
    final String? longitude = _stringFromDynamic(
          data?['longitude'] ?? data?['lng'],
        ) ??
        _stringFromDynamic(nestedData?['longitude'] ?? nestedData?['lng']);

    final String? phone = _stringFromDynamic(data?['phone']) ??
        _stringFromDynamic(nestedData?['phone']);
    final String? businessHour = _stringFromDynamic(data?['business_hour']) ??
        _stringFromDynamic(nestedData?['business_hour']);
    final String? type = _stringFromDynamic(data?['type']) ??
        _stringFromDynamic(nestedData?['type']);

    final double? rating =
        _doubleFromDynamic(data?['rating']) ?? _doubleFromDynamic(nestedData?['rating']);

    return Restaurant(
      id: placeId,
      name: stop.title,
      detailAddress: detailAddress,
      subCategory: subCategory,
      businessHour: businessHour,
      phone: phone,
      type: type,
      image: image,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
    );
  }

  String? _stringFromDynamic(dynamic value) {
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

  double? _doubleFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Widget _buildTransportSelector(
    int index,
    Color accentColor,
    TextTheme textTheme,
  ) {
    final fromStop = _stops[index];
    final toStop = _stops[index + 1];
    final selectedKey = _selectedTransportKeys[index];
    final routeResult = _calculatedRoutes[index]; // 🔥 계산된 경로 정보
    
    // 선택된 key를 int로 변환 (walk: 0, public: 1, car: 2)
    int selectedTransportType = 0;
    if (selectedKey == 'public') {
      selectedTransportType = 1;
    } else if (selectedKey == 'car') {
      selectedTransportType = 2;
    }

    // 좌표 가져오기
    final originCoords = index == 0
        ? _getOriginCoordinates()
        : _getPlaceCoordinates(_stops[index]);
    final destCoords = _getPlaceCoordinates(_stops[index + 1]);

    return TransportationSelectorWidget(
      segmentIndex: index,
      selectedTransportType: selectedTransportType,
      onTransportTypeChanged: widget.isReadOnly
          ? null
          : (type) {
              // int를 다시 key로 변환
              String newKey = 'walk';
              if (type == 1) {
                newKey = 'public';
              } else if (type == 2) {
                newKey = 'car';
              }
              
              setState(() {
                _selectedTransportKeys[index] = newKey;
              });
              // 교통수단 변경 시 해당 구간 재계산
              _recalculateRoute(index);
            },
      isReadOnly: widget.isReadOnly,
      originCoordinates: originCoords,
      destinationCoordinates: destCoords,
      initialRouteResult: routeResult,
      originName: fromStop.title,
      destinationName: toStop.title,
      style: TransportationSelectorStyle.dropdown,
    );
  }

  Widget _buildEmptyTransportPlaceholder(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFB7C9E).withOpacity(0.18),
        ),
      ),
      child: Text(
        '일정을 추가하면 이동수단을 선택할 수 있어요.',
        style: textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _showGoHomeDialog() async {
    await TemplateUtils.showGoHomeDialog(
      context: context,
      accentColor: const Color(0xFFFB7C9E),
    );
  }

  /// 🔥 저장하기 기능
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 경로 정보 확인 및 누락된 구간 계산
      final Map<int, RouteResult> routeResults = Map<int, RouteResult>.from(_calculatedRoutes);

      for (int i = 0; i < _stops.length - 1; i++) {
        if (!routeResults.containsKey(i)) {
          final originCoords = i == 0
              ? _getOriginCoordinates()
              : _getPlaceCoordinates(_stops[i]);
          final destCoords = _getPlaceCoordinates(_stops[i + 1]);

          if (originCoords != null && destCoords != null) {
            try {
              // 선택된 이동수단을 int로 변환
              int transportType = 0;
              final selectedKey = _selectedTransportKeys[i];
              if (selectedKey == 'public') {
                transportType = 1;
              } else if (selectedKey == 'car') {
                transportType = 2;
              }

              final route = await RouteService.calculateRoute(
                origin: originCoords,
                destination: destCoords,
                transportType: transportType,
              );
              routeResults[i] = route;
            } catch (e) {
              print('❌ 구간 $i 경로 계산 실패: $e');
            }
          }
        }
      }

      // 교통수단 타입을 int로 변환
      final Map<int, int> transportTypes = {};
      for (int i = 0; i < _selectedTransportKeys.length; i++) {
        final key = _selectedTransportKeys[i];
        if (key == 'public') {
          transportTypes[i] = 1;
        } else if (key == 'car') {
          transportTypes[i] = 2;
        } else {
          transportTypes[i] = 0; // walk
        }
      }

      // 🔥 templateType: 3으로 저장
      await HistoryService.saveTemplate3Schedule(
        selectedPlaces: widget.selected,
        selectedPlacesWithData: widget.selectedPlacesWithData,
        orderedPlaces: widget.orderedPlaces,
        categoryIdByName: widget.categoryIdByName,
        originAddress: widget.originAddress,
        originDetailAddress: widget.originDetailAddress,
        transportTypes: transportTypes,
        routeResults: routeResults,
        firstDurationMinutes: widget.firstDurationMinutes,
        otherDurationMinutes: widget.otherDurationMinutes,
      );

      if (!mounted) return;

      CommonDialogs.showSuccess(
        context: context,
        message: '일정표 히스토리에 저장되었습니다.',
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

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

  /// 🔥 공유하기 기능
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

      final scheduleText = _buildScheduleText();
      await ServiceApi.shareToCommunity(scheduleText, userId);

      if (!mounted) return;

      CommonDialogs.showSuccess(
        context: context,
        message: '커뮤니티에 공유되었습니다.',
      );
    } catch (e) {
      if (!mounted) return;

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
    final buffer = StringBuffer();

    // 출발지
    if (widget.originAddress != null && widget.originAddress!.isNotEmpty) {
      buffer.writeln('출발지: ${widget.originAddress}');
      if (widget.originDetailAddress != null && widget.originDetailAddress!.isNotEmpty) {
        buffer.writeln('상세 주소: ${widget.originDetailAddress}');
      }
    } else {
      buffer.writeln('출발지: 집');
    }

    buffer.writeln('');
    buffer.writeln('일정:');

    // 장소 목록
    int order = 1;
    for (int i = 1; i < _stops.length; i++) {
      final stop = _stops[i];
      buffer.writeln('$order. ${stop.title}');
      if (stop.category != null && stop.category!.isNotEmpty) {
        buffer.writeln('   카테고리: ${stop.category}');
      }
      order++;
    }

    return buffer.toString();
  }

  List<_TimelineStop> _buildStops() {
    List<_TimelineStop> stops;

    if (widget.orderedPlaces != null && widget.orderedPlaces!.isNotEmpty) {
      stops = widget.orderedPlaces!
          .map((place) {
            final placeMap = Map<String, dynamic>.from(place as Map);
            final title = (placeMap['name'] as String?)?.trim();
            return _TimelineStop(
              title: title != null && title.isNotEmpty ? title : '알 수 없는 장소',
              subtitle: _extractSubtitle(placeMap),
              category: (placeMap['category'] as String?)?.trim(),
              icon: _resolveIcon(
                placeMap['name'] as String? ?? '',
                placeMap['category'] as String?,
              ),
              placeId: _stringFromDynamic(placeMap['id']),
              placeData: placeMap,
            );
          })
          .toList();
    } else if (widget.selectedPlacesWithData != null &&
        widget.selectedPlacesWithData!.isNotEmpty) {
      final visited = <String>{};
      stops = [];
      widget.selectedPlacesWithData!.forEach((category, placeList) {
        for (final place in placeList) {
          final placeMap = Map<String, dynamic>.from(place as Map);
          final title = (placeMap['name'] as String?)?.trim() ?? '';
          if (title.isEmpty || visited.contains(title)) continue;
          visited.add(title);
          stops.add(
            _TimelineStop(
              title: title,
              subtitle: _extractSubtitle(placeMap),
              category: category,
              icon: _resolveIcon(title, category),
              placeId: _stringFromDynamic(placeMap['id']),
              placeData: placeMap,
            ),
          );
        }
      });
    } else {
      final visited = <String>{};
      stops = [];
      widget.selected.forEach((category, names) {
        for (final name in names) {
          final trimmed = name.trim();
          if (trimmed.isEmpty || visited.contains(trimmed)) continue;
          visited.add(trimmed);
          stops.add(
            _TimelineStop(
              title: trimmed,
              subtitle: null,
              category: category.trim().isEmpty ? null : category,
              icon: _resolveIcon(trimmed, category),
            ),
          );
        }
      });
    }

    final originAddress = widget.originAddress?.trim();
    final displayOriginAddress = (originAddress != null &&
            originAddress.isNotEmpty &&
            !originAddress.contains('위도:'))
        ? originAddress
        : null;
    final originDetail = widget.originDetailAddress?.trim();
    final hasOriginInfo = (originAddress != null && originAddress.isNotEmpty) ||
        (originDetail != null && originDetail.isNotEmpty);

    if (hasOriginInfo && !stops.any((stop) => stop.category == '출발지')) {
      stops.insert(
        0,
        _TimelineStop(
          title: '출발지',
          subtitle: displayOriginAddress,
          category: '출발지',
          icon: Icons.home_outlined,
        ),
      );
    }

    if (stops.isEmpty) {
      stops = [
        const _TimelineStop(
          title: '일정을 추가해 주세요',
          subtitle: '여행지를 선택하면 일정이 구성됩니다.',
          category: null,
          icon: Icons.add_location_alt_outlined,
        ),
      ];
    }

    return stops;
  }

  _TransportOption _transportOptionByKey(String key) {
    return _transportOptions.firstWhere(
      (option) => option.key == key,
      orElse: () => _transportOptions.first,
    );
  }

  String? _extractSubtitle(Map<String, dynamic> placeData) {
    final candidates = <String?>[
      placeData['highlight'] as String?,
      placeData['keyword'] as String?,
      placeData['description'] as String?,
      placeData['summary'] as String?,
      placeData['address'] as String?,
      placeData['detail_address'] as String?,
    ];

    final nested = placeData['data'];
    if (nested is Map<String, dynamic>) {
      candidates.add(nested['highlight'] as String?);
      candidates.add(nested['description'] as String?);
      candidates.add(nested['address'] as String?);
      candidates.add(nested['detail_address'] as String?);
    }

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return _ellipsis(candidate.trim(), 32);
      }
    }
    return null;
  }

  IconData _resolveIcon(String title, String? category) {
    final source = '${category ?? ''} $title'.toLowerCase();

    if (source.contains('공항') || source.contains('비행')) {
      return Icons.flight_takeoff_outlined;
    }
    if (source.contains('호텔') ||
        source.contains('리조트') ||
        source.contains('숙소')) {
      return Icons.hotel_outlined;
    }
    if (source.contains('해수욕장') ||
        source.contains('해변') ||
        source.contains('비치')) {
      return Icons.beach_access_outlined;
    }
    if (source.contains('카페')) {
      return Icons.local_cafe_outlined;
    }
    if (source.contains('맛집') ||
        source.contains('식당') ||
        source.contains('음식') ||
        source.contains('고기')) {
      return Icons.restaurant_outlined;
    }
    if (source.contains('폭포')) {
      return Icons.waterfall_chart_outlined;
    }
    if (source.contains('쇼핑')) {
      return Icons.local_mall_outlined;
    }
    if (source.contains('박물관') ||
        source.contains('전시') ||
        source.contains('문화')) {
      return Icons.museum_outlined;
    }
    if (source.contains('공원') || source.contains('정원')) {
      return Icons.park_outlined;
    }
    if (source.contains('항구') || source.contains('선착장') || source.contains('입도')) {
      return Icons.directions_boat_filled_outlined;
    }

    return Icons.place_outlined;
  }

  String _ellipsis(String text, [int maxLength = 30]) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 1)}…';
  }

  /// 🔥 장소의 위경도를 가져오는 헬퍼 메서드
  ({double lat, double lng})? _getPlaceCoordinates(_TimelineStop stop) {
    return TemplateUtils.getPlaceCoordinates(
      placeTitle: stop.title,
      orderedPlaces: widget.orderedPlaces,
      selectedPlacesWithData: widget.selectedPlacesWithData,
    );
  }

  /// 🔥 출발지 좌표를 가져오는 헬퍼 메서드
  ({double lat, double lng})? _getOriginCoordinates() {
    return TemplateUtils.getOriginCoordinates(widget.originAddress);
  }
}

class _TimelineStop {
  final String title;
  final String? subtitle;
  final String? category;
  final IconData icon;
  final String? placeId;
  final Map<String, dynamic>? placeData;

  const _TimelineStop({
    required this.title,
    this.subtitle,
    this.category,
    required this.icon,
    this.placeId,
    this.placeData,
  });
}

class _TransportOption {
  final String key;
  final String label;
  final IconData icon;

  const _TransportOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}
