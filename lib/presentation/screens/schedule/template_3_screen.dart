import 'package:flutter/material.dart';

import '../../../data/services/route_service.dart';

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
      body: SingleChildScrollView(
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
                          '이동수단 선택',
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
      bottomNavigationBar: Container(
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
                  onPressed: () => _showSnackBar('저장하기 기능은 준비 중입니다.'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFB7C9E), width: 2),
                    foregroundColor: const Color(0xFFFB7C9E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '저장하기',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showSnackBar('공유하기 기능은 준비 중입니다.'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB7C9E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '공유하기',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
    const minCardWidth = 150.0;
    const spacing = 16.0;

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

        final children = <Widget>[];
        for (int i = 0; i < count; i++) {
          children.add(
            _buildTimelineStop(
              _stops[i],
              i == 0,
              i == count - 1,
              trackColor,
              accentColor,
              textTheme,
              cardWidth,
            ),
          );
          if (i != count - 1) {
            children.add(const SizedBox(width: spacing));
          }
        }

        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );

        if (useScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }

        return content;
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
    );
  }

  Widget _buildTransportSelector(
    int index,
    Color accentColor,
    TextTheme textTheme,
  ) {
    final fromStop = _stops[index];
    final toStop = _stops[index + 1];
    final selectedKey = _selectedTransportKeys[index];
    final currentOption = _transportOptionByKey(selectedKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Row(
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
              currentOption.icon,
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
                const SizedBox(height: 4),
                Text(
                  '이동수단을 선택해 주세요',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedKey,
              icon: Icon(
                Icons.expand_more,
                color: accentColor,
              ),
              borderRadius: BorderRadius.circular(16),
              items: _transportOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option.key,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option.icon,
                            size: 20,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(option.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedTransportKeys[index] = value;
                });
              },
            ),
          ),
        ],
      ),
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

  void _showGoHomeDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '홈으로 돌아가기',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '저장하지 않은 내용이 사라질 수 있습니다.\n그래도 이동할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB7C9E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('홈으로'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFB7C9E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<_TimelineStop> _buildStops() {
    List<_TimelineStop> stops;

    if (widget.orderedPlaces != null && widget.orderedPlaces!.isNotEmpty) {
      stops = widget.orderedPlaces!
          .map(
            (place) => _TimelineStop(
              title: (place['name'] as String?)?.trim().isNotEmpty == true
                  ? (place['name'] as String).trim()
                  : '알 수 없는 장소',
              subtitle: _extractSubtitle(place),
              category: (place['category'] as String?)?.trim(),
              icon: _resolveIcon(
                place['name'] as String? ?? '',
                place['category'] as String?,
              ),
            ),
          )
          .toList();
    } else if (widget.selectedPlacesWithData != null &&
        widget.selectedPlacesWithData!.isNotEmpty) {
      final visited = <String>{};
      stops = [];
      widget.selectedPlacesWithData!.forEach((category, placeList) {
        for (final place in placeList) {
          final title = (place['name'] as String?)?.trim() ?? '';
          if (title.isEmpty || visited.contains(title)) continue;
          visited.add(title);
          stops.add(
            _TimelineStop(
              title: title,
              subtitle: _extractSubtitle(place),
              category: category,
              icon: _resolveIcon(title, category),
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

    final originTitle = widget.originAddress?.trim();
    if (originTitle != null &&
        originTitle.isNotEmpty &&
        !stops.any((stop) => stop.title == originTitle)) {
      final originSubtitle = widget.originDetailAddress?.trim();
      stops.insert(
        0,
        _TimelineStop(
          title: originTitle,
          subtitle: originSubtitle != null && originSubtitle.isNotEmpty
              ? originSubtitle
              : '출발',
          category: '출발지',
          icon: _resolveIcon(originTitle, '출발'),
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
}

class _TimelineStop {
  final String title;
  final String? subtitle;
  final String? category;
  final IconData icon;

  const _TimelineStop({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
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
