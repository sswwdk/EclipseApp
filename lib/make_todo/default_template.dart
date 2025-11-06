import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/service_api.dart';
import '../services/token_manager.dart';
import '../services/route_service.dart';
import '../home/home.dart';
import 'dart:async';

class ScheduleBuilderScreen extends StatefulWidget {
  final Map<String, List<String>> selected; // 카테고리별 선택 목록
  final Map<String, List<Map<String, dynamic>>>? selectedPlacesWithData; // 전체 매장 데이터
  final Map<String, String>? categoryIdByName; // 카테고리명 -> 카테고리ID 매핑
  final String? originAddress; // 출발지 주소
  final String? originDetailAddress; // 출발지 상세 주소
  final int? firstDurationMinutes; // 템플릿: 첫 이동 또는 첫 체류 시간
  final int? otherDurationMinutes; // 템플릿: 이후 체류 시간
  final bool isReadOnly; // 읽기 전용 모드 (편집 불가)
  final Map<int, int>? initialTransportTypes; // 초기 교통수단 정보 (읽기 전용 모드용)
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
    this.orderedPlaces,
  }) : super(key: key);

  @override
  State<ScheduleBuilderScreen> createState() => _ScheduleBuilderScreenState();
}

class _ScheduleBuilderScreenState extends State<ScheduleBuilderScreen> {
  late List<_ScheduleItem> _items;
  String? _originAddress; // 출발지 주소
  String? _originDetailAddress; // 출발지 상세 주소
  Map<int, int> _transportTypes = {}; // 각 구간별 교통수단 (key: segmentIndex, value: transportType)
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
    } else {
      // 각 구간별로 기본 교통수단 설정 (대중교통)
      for (int i = 0; i < _items.length - 1; i++) {
        _transportTypes[i] = 1;
      }
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
        title: Text(
          widget.isReadOnly ? '일정표 상세' : '일정표 만들기',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
      body: ListView.builder(
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
              return _TransportationCard(
                segmentIndex: itemIndex,
                selectedTransportType: _transportTypes[itemIndex] ?? 1,
                onTransportTypeChanged: widget.isReadOnly ? null : (type) {
                  setState(() {
                    _transportTypes[itemIndex] = type;
                  });
                },
                isReadOnly: widget.isReadOnly,
                originCoordinates: itemIndex == 0 
                    ? _getOriginCoordinates() 
                    : _getPlaceCoordinates(items[itemIndex]),
                destinationCoordinates: _getPlaceCoordinates(items[itemIndex + 1]),
                orderedPlaces: widget.orderedPlaces,
              );
            }
            return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: widget.isReadOnly ? null : Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFF8126), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFFFF8126),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
                          ),
                        )
                      : const Text(
                          '저장하기',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: _isSharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '공유하기',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '홈으로 돌아가기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '저장하지 않은 일정표는 다시 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
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
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8126),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '홈으로 돌아가기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      // 모든 이전 화면을 제거하고 홈 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  /// 저장하기 버튼 클릭 시 서버에 일정표 저장
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await HistoryService.saveSchedule(
        selectedPlaces: widget.selected,
        selectedPlacesWithData: widget.selectedPlacesWithData,
        orderedPlaces: widget.orderedPlaces, // 🔥 순서가 유지되는 리스트 전달
        categoryIdByName: widget.categoryIdByName,
        originAddress: _originAddress,
        originDetailAddress: _originDetailAddress,
        transportTypes: _transportTypes,
        firstDurationMinutes: widget.firstDurationMinutes,
        otherDurationMinutes: widget.otherDurationMinutes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정표 히스토리에 저장되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );

      // 홈 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      print('❌ 일정표 저장 실패: $e');
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

  /// 공유하기 버튼 클릭 시 서버에 일정표 공유
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

      // 일정표 정보를 문자열로 변환
      final scheduleText = _buildScheduleText();

      // 커뮤니티에 공유
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

      print('❌ 일정표 공유 실패: $e');
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

  /// 일정표 정보를 텍스트로 변환
  String _buildScheduleText() {
    final buffer = StringBuffer();
    
    // 출발지
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
    
    // 장소 목록
    int order = 1;
    widget.selected.forEach((category, places) {
      for (final place in places) {
        buffer.writeln('$order. $place ($category)');
        order++;
      }
    });
    
    return buffer.toString();
  }

  // 최종 화면에서는 출발지 수정 기능이 없습니다.

  List<_ScheduleItem> _buildScheduleItems(Map<String, List<String>> selected) {
    final List<_ScheduleItem> items = [];
    
    // 출발지(집)
    String originTitle = '집';
    String originSubtitle = '출발지';
    
    if (_originAddress != null && _originAddress!.isNotEmpty) {
      if (_originDetailAddress != null && _originDetailAddress!.isNotEmpty) {
        originTitle = '$_originAddress $_originDetailAddress';
      } else {
        originTitle = _originAddress!;
      }
      originSubtitle = '출발지';
    }
    
    items.add(_ScheduleItem(
      title: originTitle,
      subtitle: originSubtitle,
      icon: Icons.home_outlined,
      color: Colors.grey[700]!,
      type: _ItemType.origin,
      time: null,
    ));

    // 🔥 orderedPlaces가 있으면 순서대로 사용, 없으면 기존 방식
    if (widget.orderedPlaces != null && widget.orderedPlaces!.isNotEmpty) {
      // 순서가 유지되는 리스트 사용
      for (final placeData in widget.orderedPlaces!) {
        final placeName = placeData['name'] as String? ?? '알 수 없음';
        final category = placeData['category'] as String? ?? '기타';
        
        items.add(_ScheduleItem(
          title: placeName,
          subtitle: category,
          icon: _iconFor(category),
          color: const Color(0xFFFF8126),
          type: _ItemType.place,
          durationMinutes: items.length == 1
              ? (widget.firstDurationMinutes ?? 45)
              : (widget.otherDurationMinutes ?? 20),
          time: null,
        ));
      }
    } else {
      // 기존 방식: 카테고리별로 그룹화됨 (하위 호환성)
      selected.forEach((category, places) {
        for (final place in places) {
          items.add(_ScheduleItem(
            title: place,
            subtitle: category,
            icon: _iconFor(category),
            color: const Color(0xFFFF8126),
            type: _ItemType.place,
            durationMinutes: items.length == 1
                ? (widget.firstDurationMinutes ?? 45)
                : (widget.otherDurationMinutes ?? 20),
            time: null,
          ));
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

  /// 장소의 주소를 가져오는 헬퍼 메서드
  String? _getPlaceAddress(_ScheduleItem item) {
    if (widget.orderedPlaces == null || widget.orderedPlaces!.isEmpty) {
      return null;
    }

    // orderedPlaces에서 해당 장소 찾기
    for (final placeData in widget.orderedPlaces!) {
      final placeName = placeData['name'] as String? ?? '';
      if (placeName == item.title) {
        final data = placeData['data'] as Map<String, dynamic>?;
        if (data != null) {
          return data['address'] as String? ?? 
                 data['detail_address'] as String? ??
                 placeData['address'] as String?;
        }
        return placeData['address'] as String?;
      }
    }
    return null;
  }

  /// 장소의 위경도를 가져오는 헬퍼 메서드
  ({double lat, double lng})? _getPlaceCoordinates(_ScheduleItem item) {
    if (widget.orderedPlaces == null || widget.orderedPlaces!.isEmpty) {
      return null;
    }

    // orderedPlaces에서 해당 장소 찾기
    for (final placeData in widget.orderedPlaces!) {
      final placeName = placeData['name'] as String? ?? '';
      if (placeName == item.title) {
        // 위경도를 최상위 레벨에서 먼저 확인
        dynamic latValue = placeData['latitude'] ?? placeData['lat'];
        dynamic lngValue = placeData['longitude'] ?? placeData['lng'];
        
        // 최상위 레벨에 없으면 data 안에서 확인
        if (latValue == null || lngValue == null) {
          final data = placeData['data'] as Map<String, dynamic>?;
          if (data != null) {
            latValue ??= data['latitude'] ?? data['lat'];
            lngValue ??= data['longitude'] ?? data['lng'];
          }
        }
        
        // 문자열이면 파싱, 숫자면 그대로 사용
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

  /// 출발지 좌표를 가져오는 헬퍼 메서드
  ({double lat, double lng})? _getOriginCoordinates() {
    // 출발지 주소가 있으면 좌표 변환이 필요하지만, 
    // 일단 null을 반환하고 서버에서 처리하거나 나중에 주소->좌표 변환 API 추가
    // TODO: 출발지 주소를 좌표로 변환하는 로직 추가 (카카오 API 등)
    // 현재는 출발지가 GPS 위치인 경우를 처리할 수 있도록 주소 형식 확인
    if (_originAddress != null && _originAddress!.contains('위도:')) {
      // GPS 위치 형식: "위도: 37.505147, 경도: 126.943349"
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

enum _ItemType { origin, place }

class _ScheduleItem {
  final String id = UniqueKey().toString();
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final _ItemType type;
  final int? durationMinutes;
  final String? time;

  _ScheduleItem({
    required this.title,
    required this.subtitle,
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

  const _TimelineRow({Key? key, required this.item, required this.index, this.isLast = false, this.onDragHandle, this.showDuration = true, this.onTap}) : super(key: key);

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
                      ? Colors.grey[100] 
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                        size: 20
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
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
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

// 교통수단 선택 카드
class _TransportationCard extends StatefulWidget {
  final int segmentIndex;
  final int selectedTransportType;
  final Function(int)? onTransportTypeChanged;
  final bool isReadOnly;
  final ({double lat, double lng})? originCoordinates;
  final ({double lat, double lng})? destinationCoordinates;
  final List<Map<String, dynamic>>? orderedPlaces;

  const _TransportationCard({
    Key? key,
    required this.segmentIndex,
    required this.selectedTransportType,
    this.onTransportTypeChanged,
    this.isReadOnly = false,
    this.originCoordinates,
    this.destinationCoordinates,
    this.orderedPlaces,
  }) : super(key: key);

  @override
  State<_TransportationCard> createState() => _TransportationCardState();
}

class _TransportationCardState extends State<_TransportationCard> {
  RouteResult? _routeResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRouteInfo();
  }

  @override
  void didUpdateWidget(_TransportationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 교통수단이나 좌표가 변경되면 다시 로드
    if (oldWidget.selectedTransportType != widget.selectedTransportType ||
        oldWidget.originCoordinates != widget.originCoordinates ||
        oldWidget.destinationCoordinates != widget.destinationCoordinates) {
      _loadRouteInfo();
    }
  }

  Future<void> _loadRouteInfo() async {
    // 좌표 정보가 없으면 로드하지 않음
    if (widget.originCoordinates == null || widget.destinationCoordinates == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 [TransportationCard] 이동시간 계산 요청:');
      print('   origin: ${widget.originCoordinates}');
      print('   destination: ${widget.destinationCoordinates}');
      print('   transportType: ${widget.selectedTransportType}');
      
      final result = await RouteService.calculateRoute(
        origin: widget.originCoordinates!,
        destination: widget.destinationCoordinates!,
        transportType: widget.selectedTransportType,
      );

      print('🔍 [TransportationCard] 이동시간 계산 결과:');
      print('   durationMinutes: ${result.durationMinutes}');
      print('   distanceMeters: ${result.distanceMeters}');
      print('   steps: ${result.steps}');
      print('   summary: ${result.summary}');

      if (mounted) {
        setState(() {
          _routeResult = result;
          _isLoading = false;
        });
        print('✅ [TransportationCard] 상태 업데이트 완료');
      }
    } catch (e, stackTrace) {
      print('❌ 이동시간 계산 실패: $e');
      print('   스택 트레이스: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 교통수단 선택 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TransportButton(
                  icon: Icons.directions_walk,
                  label: '도보',
                  isSelected: widget.selectedTransportType == 0,
                  onTap: widget.isReadOnly ? null : () => widget.onTransportTypeChanged?.call(0),
                ),
                _TransportButton(
                  icon: Icons.train,
                  label: '대중교통',
                  isSelected: widget.selectedTransportType == 1,
                  onTap: widget.isReadOnly ? null : () => widget.onTransportTypeChanged?.call(1),
                ),
                _TransportButton(
                  icon: Icons.directions_car,
                  label: '자동차',
                  isSelected: widget.selectedTransportType == 2,
                  onTap: widget.isReadOnly ? null : () => widget.onTransportTypeChanged?.call(2),
                ),
              ],
            ),
            
            // 선택된 교통수단의 상세 정보
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: _buildTransportDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportDetails() {
    // 로딩 중
    if (_isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '이동시간 계산 중...',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    }

    // 에러 발생
    if (_errorMessage != null) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '이동시간 계산 실패',
              style: TextStyle(fontSize: 14, color: Colors.red[600]),
            ),
          ),
        ],
      );
    }

    // 좌표 정보가 없으면 로딩 또는 기본값 표시
    if (widget.originCoordinates == null || widget.destinationCoordinates == null) {
      // 좌표가 없으면 로딩 중 표시 (하드코딩된 기본값 대신)
      if (_isLoading) {
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '좌표 정보 확인 중...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        );
      }
      // 좌표 정보가 없어서 계산할 수 없음
      return Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[300], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '좌표 정보가 없어 이동시간을 계산할 수 없습니다',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    // 실제 계산 결과 표시 (하드코딩된 기본값 대신 실제 서버 응답만 표시)
    if (_routeResult == null) {
      // 서버 응답이 아직 오지 않음
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8126)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '이동시간 계산 중...',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    }

    final durationMinutes = _routeResult!.durationMinutes;
    
    switch (widget.selectedTransportType) {
      case 0: // 도보
        return Row(
          children: [
            const Icon(Icons.directions_walk, color: Color(0xFFFF8126), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '도보 약 ${durationMinutes}분',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      case 1: // 대중교통
        return _buildPublicTransportDetails(durationMinutes);
      case 2: // 자동차
        return Row(
          children: [
            const Icon(Icons.directions_car, color: Color(0xFFFF8126), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '자동차 약 ${durationMinutes}분',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPublicTransportDetails(int durationMinutes) {
    final steps = _routeResult?.steps;
    final distanceMeters = _routeResult?.distanceMeters ?? 0;
    final distanceKm = distanceMeters / 1000.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.train, color: Color(0xFFFF8126), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '대중교통 약 ${durationMinutes}분',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (distanceKm > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      distanceKm >= 1 
                          ? '거리 약 ${distanceKm.toStringAsFixed(1)}km'
                          : '거리 약 ${distanceMeters}m',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (steps != null && steps.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...steps.map((step) => _buildTransportStep(step)),
        ] else if (_routeResult?.summary != null) ...[
          const SizedBox(height: 8),
          Text(
            _routeResult!.summary!,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ],
    );
  }

  Widget _buildTransportStep(RouteStep step) {
    IconData icon;
    Color iconColor;
    
    switch (step.type) {
      case 'walk':
        icon = Icons.directions_walk;
        iconColor = Colors.blue;
        break;
      case 'transit':
        icon = Icons.train;
        iconColor = Colors.green;
        break;
      case 'drive':
        icon = Icons.directions_car;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.arrow_forward;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.description != null && step.description!.isNotEmpty)
                  Text(
                    step.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (step.durationMinutes > 0)
                  Text(
                    '${step.durationMinutes}분',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// 교통수단 버튼
class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TransportButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8126) : Colors.transparent,
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
  State<OriginAddressInputScreen> createState() => _OriginAddressInputScreenState();
}

class _OriginAddressInputScreenState extends State<OriginAddressInputScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailAddressController = TextEditingController();
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
      
      Navigator.pop(
        context,
        {
          'address': _addressController.text.trim(),
          'detailAddress': _detailAddressController.text.trim(),
        },
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
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
        title: const Text(
          '출발지 입력',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF8126),
              ),
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
                      FocusScope.of(context).requestFocus(_detailAddressFocusNode);
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
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

