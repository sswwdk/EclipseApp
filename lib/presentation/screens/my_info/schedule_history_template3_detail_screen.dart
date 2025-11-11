import 'package:flutter/material.dart';
import '../../../data/services/history_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../data/services/route_service.dart';
import '../../../data/models/restaurant.dart';
import '../../../shared/helpers/history_parser.dart';
import '../main/restaurant_detail_review_screen.dart';

class ScheduleHistoryTemplate3DetailScreen extends StatefulWidget {
  final String historyId;

  const ScheduleHistoryTemplate3DetailScreen({
    Key? key,
    required this.historyId,
  }) : super(key: key);

  @override
  State<ScheduleHistoryTemplate3DetailScreen> createState() =>
      _ScheduleHistoryTemplate3DetailScreenState();
}

class _ScheduleHistoryTemplate3DetailScreenState
    extends State<ScheduleHistoryTemplate3DetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  late List<_TimelineStop> _stops = [];
  String? _originAddress;
  String? _originDetailAddress;
  Map<int, int> _transportTypes = {};
  Map<int, RouteResult> _routeResults = {};

  @override
  void initState() {
    super.initState();
    _loadHistoryDetail();
  }

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

      final detailResponse = await HistoryService.getHistoryDetail(
        userId,
        widget.historyId,
      );

      if (!mounted) return;

      _parseHistoryDetail(detailResponse);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '일정표를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _parseHistoryDetail(Map<String, dynamic> detailResponse) {
    final data = detailResponse['data'] ?? detailResponse;
    final categories = data['categories'] as List<dynamic>? ?? [];

    _originAddress = (data['origin_address'] as String?)?.trim();
    _originDetailAddress = (data['origin_detail_address'] as String?)?.trim();

    final sortedCategories = List<Map<String, dynamic>>.from(
      categories.map((c) => c as Map<String, dynamic>),
    );
    sortedCategories.sort((a, b) {
      final seqA = a['seq'] as int? ?? 0;
      final seqB = b['seq'] as int? ?? 0;
      return seqA.compareTo(seqB);
    });

    List<_TimelineStop> stops = [];

    // 출발지 추가
    final originAddress = _originAddress?.trim();
    final displayOriginAddress = (originAddress != null &&
            originAddress.isNotEmpty &&
            !_containsCoordinate(originAddress))
        ? originAddress
        : null;
    final originDetail = _originDetailAddress?.trim();
    final hasOriginInfo = (originAddress != null && originAddress.isNotEmpty) ||
        (originDetail != null && originDetail.isNotEmpty);

    if (hasOriginInfo) {
      stops.add(
        _TimelineStop(
          title: '출발지',
          subtitle: displayOriginAddress,
          category: '출발지',
          icon: Icons.home_outlined,
          durationMinutes: null,
        ),
      );
    } else {
      stops.add(
        _TimelineStop(
          title: '출발지',
          subtitle: null,
          category: '출발지',
          icon: Icons.home_outlined,
          durationMinutes: null,
        ),
      );
    }

    for (int i = 0; i < sortedCategories.length; i++) {
      final category = sortedCategories[i];
      final categoryName = category['category_name'] as String? ?? '';
      final address =
          (category['category_detail_address'] as String? ??
                  category['detail_address'] as String? ??
                  category['address'] as String?)
              ?.trim();

      final categoryTypeRaw = category['category_type'];
      int categoryTypeInt = 0;
      if (categoryTypeRaw is int) {
        categoryTypeInt = categoryTypeRaw;
      } else if (categoryTypeRaw is String) {
        categoryTypeInt = int.tryParse(categoryTypeRaw) ?? 0;
      }
      final categoryType = _getCategoryNameFromType(categoryTypeInt);

      int transportation = 0;
      if (category['transportation'] != null) {
        if (category['transportation'] is int) {
          transportation = category['transportation'] as int;
        } else if (category['transportation'] is String) {
          transportation =
              int.tryParse(category['transportation'] as String) ?? 0;
        }
      }

      // duration 정보 추출 (초 단위 → 분 단위 변환)
      final duration = category['duration'] as int? ?? 3600;
      int? durationMinutes;
      if (category['duration'] != null) {
        int durationSeconds = 0;
        if (category['duration'] is int) {
          durationSeconds = category['duration'] as int;
        } else if (category['duration'] is String) {
          durationSeconds = int.tryParse(category['duration'] as String) ?? 0;
        }
        if (durationSeconds > 0) {
          durationMinutes = (durationSeconds / 60).round();
        }
      }

      final placeId =
          _stringFromDynamic(category['category_id']) ??
          _stringFromDynamic(category['categoryId']) ??
          _stringFromDynamic(category['id']);

      stops.add(
        _TimelineStop(
          title: categoryName,
          subtitle: address,
          category: categoryType,
          icon: _iconFor(categoryType),
          durationMinutes: durationMinutes,
          placeId: placeId,
          placeData: category,
        ),
      );

      _transportTypes[i] = transportation;

      // description 파싱하여 경로 정보 추출
      final description = category['description'] as String?;
      if (description != null && description.isNotEmpty) {
        _routeResults[i] = _parseDescriptionToRouteResult(
          description,
          duration ~/ 60,
        );
      } else {
        _routeResults[i] = _parseRouteInfo(category, duration ~/ 60);
      }
    }

    _stops = stops;
  }

  String _getCategoryNameFromType(int categoryType) {
    return HistoryParser.getCategoryNameFromType(categoryType);
  }

  IconData _iconFor(String category) {
    return HistoryParser.getIconForCategory(category);
  }

  RouteResult _parseDescriptionToRouteResult(
    String description,
    int defaultDuration,
  ) {
    return HistoryParser.parseDescriptionToRouteResult(
      description,
      defaultDuration,
    );
  }

  RouteResult _parseRouteInfo(
    Map<String, dynamic> category,
    int defaultDuration,
  ) {
    return HistoryParser.parseRouteInfo(category, defaultDuration);
  }

  bool _containsCoordinate(String value) {
    return value.contains('위도:') || value.contains('경도:');
  }

  String? _stringFromDynamic(dynamic value) {
    return HistoryParser.stringFromDynamic(value);
  }

  double? _doubleFromDynamic(dynamic value) {
    return HistoryParser.doubleFromDynamic(value);
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
        title: const Text('템플릿 3'),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: accentColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFB7C9E)),
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
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadHistoryDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Container(
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
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
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
                            (index) => _buildTransportInfo(
                              index,
                              accentColor,
                              textTheme,
                            ),
                          ),
                        ],
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
                  160.0,
                ),
                if (i < _stops.length - 1) _buildConnectorLine(trackColor),
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
        child: Container(width: 60, height: 4, color: trackColor),
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
    double width,
  ) {
    final bool isClickable = stop.placeId != null && stop.placeId!.isNotEmpty;

    return SizedBox(
      width: width,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
              child: Icon(stop.icon, size: 30, color: accentColor),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withOpacity(0.15)),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStopTap(_TimelineStop stop) {
    final restaurant = _buildRestaurantFromStop(stop);
    if (restaurant == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('매장 정보를 불러올 수 없습니다.')));
      }
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailReviewScreen(
          restaurant: restaurant,
        ),
      ),
    );
  }

  Restaurant? _buildRestaurantFromStop(_TimelineStop stop) {
    final placeId = stop.placeId;
    if (placeId == null || placeId.isEmpty) {
      return null;
    }

    final Map<String, dynamic>? data = stop.placeData is Map<String, dynamic>
        ? stop.placeData
        : null;

    String? detailAddress = stop.subtitle;
    detailAddress ??=
        _stringFromDynamic(data?['category_detail_address']) ??
        _stringFromDynamic(data?['detail_address']) ??
        _stringFromDynamic(data?['address']);

    final String? subCategory =
        _stringFromDynamic(data?['category']) ??
        _stringFromDynamic(data?['sub_category']) ??
        (stop.category?.trim().isNotEmpty == true ? stop.category : null);

    final String? image =
        _stringFromDynamic(data?['image_url']) ??
        _stringFromDynamic(data?['image']);
    final String? phone = _stringFromDynamic(data?['phone']);
    final String? businessHour = _stringFromDynamic(data?['business_hour']);
    final String? type = _stringFromDynamic(data?['type']);
    final double? rating = _doubleFromDynamic(data?['rating']);

    final String? latitude =
        _stringFromDynamic(data?['latitude']) ??
        _stringFromDynamic(data?['lat']);
    final String? longitude =
        _stringFromDynamic(data?['longitude']) ??
        _stringFromDynamic(data?['lng']);

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

  Widget _buildTransportInfo(
    int index,
    Color accentColor,
    TextTheme textTheme,
  ) {
    final fromStop = _stops[index];
    final toStop = _stops[index + 1];
    final transportType = _transportTypes[index] ?? 0;
    final routeResult = _routeResults[index];

    String transportLabel;
    IconData transportIcon;

    switch (transportType) {
      case 0:
        transportLabel = '도보';
        transportIcon = Icons.directions_walk_outlined;
        break;
      case 1:
        transportLabel = '대중교통';
        transportIcon = Icons.directions_transit_outlined;
        break;
      case 2:
        transportLabel = '자동차';
        transportIcon = Icons.directions_car_filled_outlined;
        break;
      default:
        transportLabel = '도보';
        transportIcon = Icons.directions_walk_outlined;
    }

    // 경로 결과에서 duration 정보 우선 사용, 없으면 도착지의 duration 사용
    final durationMinutes =
        routeResult?.durationMinutes ?? toStop.durationMinutes;
    final distanceMeters = routeResult?.distanceMeters ?? 0;
    final distanceKm = distanceMeters / 1000.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(transportIcon, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fromStop.title} → ${toStop.title}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4E4A4A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(transportIcon, size: 16, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          transportLabel,
                          style: textTheme.bodySmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (durationMinutes != null && durationMinutes > 0) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '약 $durationMinutes분',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (distanceKm > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        distanceKm >= 1
                            ? '거리 약 ${distanceKm.toStringAsFixed(1)}km'
                            : '거리 약 ${distanceMeters}m',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // 대중교통인 경우 상세 경로 표시
          if (transportType == 1 &&
              routeResult?.steps != null &&
              routeResult!.steps!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상세 경로',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4E4A4A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...routeResult.steps!.map(
                    (step) => _buildRouteStep(step, accentColor, textTheme),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteStep(
    RouteStep step,
    Color accentColor,
    TextTheme textTheme,
  ) {
    IconData icon;
    Color iconColor;

    switch (step.type) {
      case 'walk':
        icon = Icons.directions_walk;
        iconColor = const Color(0xFF4A90E2);
        break;
      case 'transit':
        icon = Icons.train;
        iconColor = const Color(0xFF5CB85C);
        break;
      case 'drive':
        icon = Icons.directions_car;
        iconColor = const Color(0xFFF0AD4E);
        break;
      default:
        icon = Icons.arrow_forward;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.description != null && step.description!.isNotEmpty)
                  Text(
                    step.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4E4A4A),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (step.type == 'walk' || step.durationMinutes > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.durationMinutes > 0
                        ? '${step.durationMinutes}분'
                        : '환승',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStop {
  final String title;
  final String? subtitle;
  final String? category;
  final IconData icon;
  final int? durationMinutes;
  final String? placeId;
  final Map<String, dynamic>? placeData;

  _TimelineStop({
    required this.title,
    this.subtitle,
    this.category,
    required this.icon,
    this.durationMinutes,
    this.placeId,
    this.placeData,
  });
}
