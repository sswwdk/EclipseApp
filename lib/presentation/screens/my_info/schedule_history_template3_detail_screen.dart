import 'package:flutter/material.dart';
import '../../../data/services/history_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../data/services/route_service.dart';

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
    String originTitle = _originAddress ?? '집';
    if (_originDetailAddress != null && _originDetailAddress!.isNotEmpty) {
      originTitle += '\n$_originDetailAddress';
    }

    stops.add(
      _TimelineStop(
        title: originTitle,
        subtitle: null,
        category: '출발지',
        icon: Icons.home_outlined,
        durationMinutes: null,
      ),
    );

    for (int i = 0; i < sortedCategories.length; i++) {
      final category = sortedCategories[i];
      final categoryName = category['category_name'] as String? ?? '';
      final address = (category['category_detail_address'] as String? ??
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

      stops.add(
        _TimelineStop(
          title: categoryName,
          subtitle: address,
          category: categoryType,
          icon: _iconFor(categoryType),
          durationMinutes: durationMinutes,
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

  IconData _iconFor(String category) {
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
  RouteResult _parseDescriptionToRouteResult(
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
            r'(지선|간선|광역|순환|마을|공항):(\d+[가-힣]*)번',
          ).firstMatch(line);
          final durationMatch = RegExp(r'(\d+)분').firstMatch(line);

          String busInfo = '버스';
          if (busTypeMatch != null) {
            final busType = busTypeMatch.group(1) ?? '';
            final busNumber = busTypeMatch.group(2) ?? '';
            busInfo = '$busType $busNumber번';
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
  RouteResult _parseRouteInfo(
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
        title: const Text('여행 일정표'),
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
                        _buildTimelineSection(
                          trackColor,
                          accentColor,
                          textTheme,
                        ),
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
    const double minCardWidth = 160.0;
    const double spacing = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final count = _stops.length;
        final calculatedWidth = count > 0
            ? (maxWidth - spacing * (count - 1)) / count
            : maxWidth;
        final useScroll = calculatedWidth < minCardWidth;
        final cardWidth = useScroll ? minCardWidth : calculatedWidth;

        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < count; i++) ...[
              _buildTimelineStop(
                _stops[i],
                i == 0,
                i == count - 1,
                trackColor,
                accentColor,
                textTheme,
                cardWidth,
              ),
              if (i != count - 1) const SizedBox(width: spacing),
            ],
          ],
        );

        return useScroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: content,
              )
            : content;
      },
    );
  }

  Widget _buildTimelineStop(
    _TimelineStop stop,
    bool isFirst,
    bool isLast,
    Color trackColor,
    Color accentColor,
    TextTheme textTheme,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          if (stop.category != null && stop.category!.trim().isNotEmpty) ...[
            Container(
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
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    height: 12,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
              if (!isLast)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    height: 12,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
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
    final durationMinutes = routeResult?.durationMinutes ?? toStop.durationMinutes;
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
                child: Icon(
                  transportIcon,
                  color: accentColor,
                ),
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
                        Icon(
                          transportIcon,
                          size: 16,
                          color: accentColor,
                        ),
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
                  ...routeResult.steps!.map((step) => _buildRouteStep(step, accentColor, textTheme)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteStep(RouteStep step, Color accentColor, TextTheme textTheme) {
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

  _TimelineStop({
    required this.title,
    this.subtitle,
    this.category,
    required this.icon,
    this.durationMinutes,
  });
}

