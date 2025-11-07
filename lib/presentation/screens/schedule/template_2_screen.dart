import 'package:flutter/material.dart';
import '../../../data/services/history_service.dart';
import '../../../data/services/service_api.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../data/services/route_service.dart';
import '../main/main_screen.dart';
import 'dart:async';

class Template2Screen extends StatefulWidget {
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

  const Template2Screen({
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
  State<Template2Screen> createState() => _Template2ScreenState();
}

class _Template2ScreenState extends State<Template2Screen> {
  late List<_ScheduleItem> _items;
  String? _originAddress;
  String? _originDetailAddress;
  Map<int, int> _transportTypes = {};
  Map<int, RouteResult> _calculatedRoutes = {};
  bool _isLoadingRoutes = false;
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();

    if (widget.originAddress != null) {
      _originAddress = widget.originAddress;
    }
    if (widget.originDetailAddress != null) {
      _originDetailAddress = widget.originDetailAddress;
    }

    _items = _buildScheduleItems(widget.selected);

    if (widget.isReadOnly && widget.initialTransportTypes != null) {
      _transportTypes = Map<int, int>.from(widget.initialTransportTypes!);
      if (widget.initialRouteResults != null) {
        _calculatedRoutes = Map<int, RouteResult>.from(
          widget.initialRouteResults!,
        );
      }
    } else {
      for (int i = 0; i < _items.length - 1; i++) {
        _transportTypes[i] = 0;
      }
      _loadAllRoutes();
    }
  }

  Future<void> _loadAllRoutes() async {
    if (_items.length <= 1) return;

    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      final List<Future<MapEntry<int, RouteResult>?>> futures = [];

      for (int i = 0; i < _items.length - 1; i++) {
        final originCoords = i == 0
            ? _getOriginCoordinates()
            : _getPlaceCoordinates(_items[i]);
        final destCoords = _getPlaceCoordinates(_items[i + 1]);

        if (originCoords != null && destCoords != null) {
          futures.add(_calculateRouteForSegment(i, originCoords, destCoords));
        }
      }

      final results = await Future.wait(futures);

      for (final result in results) {
        if (result != null) {
          _calculatedRoutes[result.key] = result.value;
        }
      }
    } catch (e) {
      print('❌ 경로 계산 중 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
    }
  }

  Future<MapEntry<int, RouteResult>?> _calculateRouteForSegment(
    int segmentIndex,
    ({double lat, double lng}) origin,
    ({double lat, double lng}) destination,
  ) async {
    try {
      final route = await RouteService.calculateRoute(
        origin: origin,
        destination: destination,
        transportType: _transportTypes[segmentIndex] ?? 0,
      );
      return MapEntry(segmentIndex, route);
    } catch (e) {
      print('❌ 구간 $segmentIndex 경로 계산 실패: $e');
      return null;
    }
  }

  Future<void> _recalculateRoute(int segmentIndex) async {
    final originCoords = segmentIndex == 0
        ? _getOriginCoordinates()
        : _getPlaceCoordinates(_items[segmentIndex]);
    final destCoords = _getPlaceCoordinates(_items[segmentIndex + 1]);

    if (originCoords == null || destCoords == null) return;

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
      }
    } catch (e) {
      print('❌ 구간 $segmentIndex 재계산 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD97941)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isReadOnly ? '일정표 상세' : '오늘의 일정표',
          style: const TextStyle(
            color: Color(0xFFD97941),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFD97941)),
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
                    Icon(Icons.home, size: 20, color: Color(0xFFD97941)),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFFD97941),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '경로 정보 계산 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_calculatedRoutes.length} / ${_items.length - 1} 구간 완료',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHomeSection(),
                  const SizedBox(height: 30),

                  // 🔥 매장 목록 - originName 전달 (수정됨)
                  ...List.generate(_items.length - 1, (index) {
                    // 출발지 이름 결정
                    String originName;
                    if (index == 0) {
                      // 🔥 첫 번째는 항상 "출발지"로 표시
                      originName = '출발지';
                    } else {
                      // 이전 장소 이름
                      originName = _items[index].title;
                    }

                    return Column(
                      children: [
                        _PlannerItemCard(
                          item: _items[index + 1],
                          segmentIndex: index,
                          transportType: _transportTypes[index] ?? 0,
                          routeResult: _calculatedRoutes[index],
                          isReadOnly: widget.isReadOnly,
                          originName: originName, // 🔥 출발지 이름 전달
                          onTransportTypeChanged: (type) {
                            setState(() {
                              _transportTypes[index] = type;
                            });
                            _recalculateRoute(index);
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  }),
                ],
              ),
            ),
      bottomNavigationBar: widget.isReadOnly
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF5F3ED),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: Color(0xFFD97941),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: const Color(0xFFD97941),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFD97941),
                                  ),
                                ),
                              )
                            : const Text(
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
                        onPressed: _isSharing ? null : _handleShare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97941),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                            : const Text(
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

  // 🔥 _buildHeader 메서드는 더 이상 사용하지 않으므로 삭제하거나 주석 처리 가능
  /*
Widget _buildHeader() {
  return Column(
    children: [
      Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFD97941),
              Colors.transparent,
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        '오늘의 일정표',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFFD97941),
          fontWeight: FontWeight.normal,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 3),
      const Text(
        'Daily Planner',
        style: TextStyle(
          fontSize: 36,
          color: Color(0xFFD97941),
          fontWeight: FontWeight.w300,
          letterSpacing: 2,
          fontFamily: 'sans-serif-light',
        ),
      ),
      const SizedBox(height: 12),
      Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFD97941),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ],
  );
}
*/

  Widget _buildHomeSection() {
    String displayAddress = '집';
    if (_originAddress != null && _originAddress!.isNotEmpty) {
      displayAddress = _originAddress!;
      if (_originDetailAddress != null && _originDetailAddress!.isNotEmpty) {
        displayAddress += '\n$_originDetailAddress';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97941), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏠', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '출발지',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD97941),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayAddress,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoHomeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '홈으로 돌아가기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '저장하지 않은 일정표는 다시 불러올 수 없습니다',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97941),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '홈으로 돌아가기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final Map<int, RouteResult> routeResults = Map<int, RouteResult>.from(
        _calculatedRoutes,
      );

      for (int i = 0; i < _items.length - 1; i++) {
        if (!routeResults.containsKey(i)) {
          final originCoords = i == 0
              ? _getOriginCoordinates()
              : _getPlaceCoordinates(_items[i]);
          final destCoords = _getPlaceCoordinates(_items[i + 1]);

          if (originCoords != null && destCoords != null) {
            try {
              final route = await RouteService.calculateRoute(
                origin: originCoords,
                destination: destCoords,
                transportType: _transportTypes[i] ?? 0,
              );
              routeResults[i] = route;
            } catch (e) {
              print('❌ 구간 $i 경로 계산 실패: $e');
            }
          }
        }
      }

      // 🔥 template_type: 2 추가
      await HistoryService.saveSchedule(
        selectedPlaces: widget.selected,
        selectedPlacesWithData: widget.selectedPlacesWithData,
        orderedPlaces: widget.orderedPlaces,
        categoryIdByName: widget.categoryIdByName,
        originAddress: _originAddress,
        originDetailAddress: _originDetailAddress,
        transportTypes: _transportTypes,
        routeResults: routeResults,
        firstDurationMinutes: widget.firstDurationMinutes,
        otherDurationMinutes: widget.otherDurationMinutes,
        templateType: 2, // 🔥 템플릿 2로 저장
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정표 히스토리에 저장되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleShare() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final userId = TokenManager.userId;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final scheduleText = _buildScheduleText();
      await ServiceApi.shareToCommunity(scheduleText, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('커뮤니티에 공유되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('공유 중 오류가 발생했습니다: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  String _buildScheduleText() {
    final buffer = StringBuffer();

    if (_originAddress != null && _originAddress!.isNotEmpty) {
      buffer.writeln('출발지: $_originAddress');
      if (_originDetailAddress != null && _originDetailAddress!.isNotEmpty) {
        buffer.writeln('상세 주소: $_originDetailAddress');
      }
    } else {
      buffer.writeln('출발지: 집');
    }

    buffer.writeln('');
    buffer.writeln('일정:');

    int order = 1;
    widget.selected.forEach((category, places) {
      for (final place in places) {
        buffer.writeln('$order. $place ($category)');
        order++;
      }
    });

    return buffer.toString();
  }

  List<_ScheduleItem> _buildScheduleItems(Map<String, List<String>> selected) {
    final List<_ScheduleItem> items = [];

    String originTitle = '집';
    if (_originAddress != null && _originAddress!.isNotEmpty) {
      if (_originDetailAddress != null && _originDetailAddress!.isNotEmpty) {
        originTitle = '$_originAddress $_originDetailAddress';
      } else {
        originTitle = _originAddress!;
      }
    }

    items.add(
      _ScheduleItem(
        title: originTitle,
        category: '출발지',
        address: originTitle,
        icon: Icons.home_outlined,
      ),
    );

    if (widget.orderedPlaces != null && widget.orderedPlaces!.isNotEmpty) {
      for (int i = 0; i < widget.orderedPlaces!.length; i++) {
        final placeData = widget.orderedPlaces![i];
        final placeName = placeData['name'] as String? ?? '알 수 없음';
        final category = placeData['category'] as String? ?? '기타';

        String? address;
        address = placeData['address'] as String?;
        if (address == null || address.isEmpty) {
          address = placeData['detail_address'] as String?;
        }
        if (address == null || address.isEmpty) {
          final data = placeData['data'] as Map<String, dynamic>?;
          if (data != null) {
            address = data['address'] as String?;
            if (address == null || address.isEmpty) {
              address = data['detail_address'] as String?;
            }
          }
        }

        // 평점 정보
        double? rating;
        final ratingValue = placeData['rating'] ?? placeData['data']?['rating'];
        if (ratingValue is String) {
          rating = double.tryParse(ratingValue);
        } else if (ratingValue is num) {
          rating = ratingValue.toDouble();
        }

        items.add(
          _ScheduleItem(
            title: placeName,
            category: category,
            address: address,
            icon: _iconFor(category),
            rating: rating,
          ),
        );
      }
    } else {
      selected.forEach((category, places) {
        for (final placeName in places) {
          String? address;
          double? rating;

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

                final ratingValue = placeData['rating'];
                if (ratingValue is String) {
                  rating = double.tryParse(ratingValue);
                } else if (ratingValue is num) {
                  rating = ratingValue.toDouble();
                }
              }
            }
          }

          items.add(
            _ScheduleItem(
              title: placeName,
              category: category,
              address: address,
              icon: _iconFor(category),
              rating: rating,
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

  ({double lat, double lng})? _getPlaceCoordinates(_ScheduleItem item) {
    if (widget.orderedPlaces == null || widget.orderedPlaces!.isEmpty) {
      return null;
    }

    for (final placeData in widget.orderedPlaces!) {
      final placeName = placeData['name'] as String? ?? '';
      if (placeName == item.title) {
        dynamic latValue = placeData['latitude'] ?? placeData['lat'];
        dynamic lngValue = placeData['longitude'] ?? placeData['lng'];

        if (latValue == null || lngValue == null) {
          final data = placeData['data'] as Map<String, dynamic>?;
          if (data != null) {
            latValue ??= data['latitude'] ?? data['lat'];
            lngValue ??= data['longitude'] ?? data['lng'];
          }
        }

        double? lat;
        double? lng;

        if (latValue is String) {
          lat = double.tryParse(latValue);
        } else if (latValue is num) {
          lat = latValue.toDouble();
        }

        if (lngValue is String) {
          lng = double.tryParse(lngValue);
        } else if (lngValue is num) {
          lng = lngValue.toDouble();
        }

        if (lat != null && lng != null) {
          return (lat: lat, lng: lng);
        }
        return null;
      }
    }
    return null;
  }

  ({double lat, double lng})? _getOriginCoordinates() {
    if (_originAddress != null && _originAddress!.contains('위도:')) {
      final latMatch = RegExp(r'위도:\s*([\d.]+)').firstMatch(_originAddress!);
      final lngMatch = RegExp(r'경도:\s*([\d.]+)').firstMatch(_originAddress!);

      if (latMatch != null && lngMatch != null) {
        final lat = double.tryParse(latMatch.group(1)!);
        final lng = double.tryParse(lngMatch.group(1)!);
        if (lat != null && lng != null) {
          return (lat: lat, lng: lng);
        }
      }
    }
    return null;
  }
}

class _ScheduleItem {
  final String title;
  final String category;
  final String? address;
  final IconData icon;
  final double? rating;

  _ScheduleItem({
    required this.title,
    required this.category,
    this.address,
    required this.icon,
    this.rating,
  });
}

// 매장 카드
class _PlannerItemCard extends StatefulWidget {
  final _ScheduleItem item;
  final int segmentIndex;
  final int transportType;
  final RouteResult? routeResult;
  final bool isReadOnly;
  final Function(int)? onTransportTypeChanged;
  final String originName;

  const _PlannerItemCard({
    Key? key,
    required this.item,
    required this.segmentIndex,
    required this.transportType,
    this.routeResult,
    this.isReadOnly = false,
    this.onTransportTypeChanged,
    required this.originName,
  }) : super(key: key);

  @override
  State<_PlannerItemCard> createState() => _PlannerItemCardState();
}

class _PlannerItemCardState extends State<_PlannerItemCard> {
  bool _showTransportOptions = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 섹션
          _buildImageSection(),
          const SizedBox(width: 15),

          // 정보 섹션
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 매장명
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD97941), width: 2),
                    ),
                  ),
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),

                // 주소
                _buildInfoItem('📍 주소', widget.item.address ?? '주소 정보 없음'),
                const SizedBox(height: 12),

                // 이동 시간
                _buildTravelTimeSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    String emoji = _getEmojiForCategory(widget.item.category);

    return Column(
      children: [
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFFEFEFE),
            border: Border.all(color: const Color(0xFFD97941), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 40)),
        ),
        const SizedBox(height: 8),
        _buildStars(widget.item.rating ?? 0.0),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Text(
            '★',
            style: TextStyle(fontSize: 18, color: Color(0xFFD97941)),
          );
        } else {
          return Text(
            '☆',
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFFD97941).withOpacity(0.3),
            ),
          );
        }
      }),
    );
  }

  Widget _buildInfoItem(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFD97941),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555555),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTravelTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 출발지 → 도착지 형식으로 변경
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Color(0xFFD97941)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.originName} → ${widget.item.title}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD97941),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 교통수단 아이콘 가로 배치
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTransportIconButton(0, Icons.directions_walk, '도보'),
            _buildTransportIconButton(1, Icons.train, '대중교통'),
            _buildTransportIconButton(2, Icons.directions_car, '차량'),
          ],
        ),

        // 선택된 교통수단의 상세 정보
        if (widget.routeResult != null) ...[
          const SizedBox(height: 16),
          _buildTransportDetailInfo(),
        ],
      ],
    );
  }

  // 🔥 교통수단 아이콘 버튼 (template_1 스타일 유지)
  Widget _buildTransportIconButton(int type, IconData icon, String label) {
    final isSelected = widget.transportType == type;

    return GestureDetector(
      onTap: widget.isReadOnly
          ? null
          : () {
              widget.onTransportTypeChanged?.call(type);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97941) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 선택된 교통수단의 상세 정보
  Widget _buildTransportDetailInfo() {
    final durationMinutes = widget.routeResult!.durationMinutes;
    final distanceMeters = widget.routeResult!.distanceMeters;
    final distanceKm = distanceMeters / 1000.0;

    String transportLabel;
    IconData icon;

    switch (widget.transportType) {
      case 0:
        transportLabel = '도보';
        icon = Icons.directions_walk;
        break;
      case 1:
        transportLabel = '대중교통';
        icon = Icons.train;
        break;
      case 2:
        transportLabel = '차량';
        icon = Icons.directions_car;
        break;
      default:
        transportLabel = '도보';
        icon = Icons.directions_walk;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD97941).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (요약 정보)
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD97941), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$transportLabel 약 ${durationMinutes}분',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97941),
                      ),
                    ),
                    if (distanceKm > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        distanceKm >= 1
                            ? '거리 약 ${distanceKm.toStringAsFixed(1)}km'
                            : '거리 약 ${distanceMeters}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // 🔥 대중교통 상세 경로 (steps가 있는 경우만)
          if (widget.transportType == 1 &&
              widget.routeResult!.steps != null &&
              widget.routeResult!.steps!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '상세 경로',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.routeResult!.steps!.map(
                    (step) => _buildRouteStep(step),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🔥 경로 단계 (template_1 스타일 유지)
  Widget _buildRouteStep(RouteStep step) {
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
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
                        : '1분',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
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

  Widget _buildTransportButton(int type, String emoji, String label) {
    final isSelected = widget.transportType == type;
    final routeResult = isSelected ? widget.routeResult : null;

    String timeText = '계산 중...';
    if (routeResult != null) {
      timeText = '${label} ${routeResult.durationMinutes}분';
    }

    return GestureDetector(
      onTap: () {
        widget.onTransportTypeChanged?.call(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97941) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD97941), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              isSelected ? timeText : label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTransportInfo() {
    String emoji;
    String label;

    switch (widget.transportType) {
      case 0:
        emoji = '🚶';
        label = '도보';
        break;
      case 1:
        emoji = '🚌';
        label = '대중교통';
        break;
      case 2:
        emoji = '🚗';
        label = '차량';
        break;
      default:
        emoji = '🚶';
        label = '도보';
    }

    String timeText = '계산 중...';
    if (widget.routeResult != null) {
      timeText = '${label} ${widget.routeResult!.durationMinutes}분';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD97941),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD97941), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmojiForCategory(String category) {
    switch (category) {
      case '음식점':
        return '🍴';
      case '카페':
        return '☕';
      case '콘텐츠':
        return '🎬';
      default:
        return '📍';
    }
  }
}
