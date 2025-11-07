import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/token_manager.dart';
import '../services/route_service.dart';
import '../home/restaurant_detail_screen.dart';
import '../services/api_service.dart';

/// 일정표 히스토리 상세 화면
class ScheduleHistoryDetailScreen extends StatefulWidget {
  final String historyId;

  const ScheduleHistoryDetailScreen({Key? key, required this.historyId})
    : super(key: key);

  @override
  State<ScheduleHistoryDetailScreen> createState() =>
      _ScheduleHistoryDetailScreenState();
}

class _ScheduleHistoryDetailScreenState
    extends State<ScheduleHistoryDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // 파싱된 데이터
  late List<_ScheduleItem> _items = [];
  String? _originAddress;
  String? _originDetailAddress;
  Map<int, int> _transportTypes = {};
  Map<int, RouteResult> _routeResults = {};

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
      final detailResponse = await HistoryService.getHistoryDetail(
        userId,
        widget.historyId,
      );

      if (!mounted) return;

      // 상세 정보 파싱하여 일정표 데이터로 변환
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

  /// 히스토리 상세 데이터 파싱
  void _parseHistoryDetail(Map<String, dynamic> detailResponse) {
    final data = detailResponse['data'] ?? detailResponse;
    final categories = data['categories'] as List<dynamic>? ?? [];

    // 출발지 정보
    _originAddress = data['origin_address'] as String?;
    _originDetailAddress = data['origin_detail_address'] as String?;

    print('🔍 서버에서 받은 categories: $categories');

    // seq 필드로 정렬
    final sortedCategories = List<Map<String, dynamic>>.from(
      categories.map((c) => c as Map<String, dynamic>),
    );
    sortedCategories.sort((a, b) {
      final seqA = a['seq'] as int? ?? 0;
      final seqB = b['seq'] as int? ?? 0;
      return seqA.compareTo(seqB);
    });

    // 출발지 추가
    List<_ScheduleItem> items = [];
    String originTitle = '집';
    if (_originAddress != null && _originAddress!.isNotEmpty) {
      originTitle =
          _originDetailAddress != null && _originDetailAddress!.isNotEmpty
          ? '$_originAddress $_originDetailAddress'
          : _originAddress!;
    }

    items.add(
      _ScheduleItem(
        title: originTitle,
        subtitle: '출발지',
        address: null,
        icon: Icons.home_outlined,
        color: Colors.grey[700]!,
        type: _ItemType.origin,
      ),
    );

    // 각 장소 추가
    for (int i = 0; i < sortedCategories.length; i++) {
      final category = sortedCategories[i];
      final categoryName = category['category_name'] as String? ?? '';
      final duration = category['duration'] as int? ?? 3600; // 초 단위

      int transportation = 1;
      if (category['transportation'] != null) {
        if (category['transportation'] is int) {
          transportation = category['transportation'] as int;
        } else if (category['transportation'] is String) {
          transportation =
              int.tryParse(category['transportation'] as String) ?? 1;
        }
      }

      final address =
          category['category_detail_address'] as String? ??
          category['detail_address'] as String? ??
          category['address'] as String?;

      final categoryTypeRaw = category['category_type'];
      int categoryTypeInt = 0;
      if (categoryTypeRaw is int) {
        categoryTypeInt = categoryTypeRaw;
      } else if (categoryTypeRaw is String) {
        categoryTypeInt = int.tryParse(categoryTypeRaw) ?? 0;
      }
      final categoryType = _getCategoryNameFromType(categoryTypeInt);
      final categoryId = category['category_id'] as String? ?? '';

      items.add(
        _ScheduleItem(
          title: categoryName,
          subtitle: categoryType,
          address: address,
          icon: _iconFor(categoryType),
          color: const Color(0xFFFF8126),
          type: _ItemType.place,
          categoryId: categoryId,
        ),
      );

      // 교통수단 정보 저장
      _transportTypes[i] = transportation;

      // 경로 정보 파싱
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

    _items = items;
  }

  /// category_type을 카테고리 이름으로 변환
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

        // "대중교통 약 15분" 파싱
        if (line.contains('약') && line.contains('분')) {
          final match = RegExp(r'약\s*(\d+)분').firstMatch(line);
          if (match != null) {
            durationMinutes = int.tryParse(match.group(1)!) ?? durationMinutes;
          }
          continue;
        }

        // "거리 약 2.5km" 파싱
        if (line.contains('거리')) {
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

        // 이동 단계 파싱
        final timeMatch = RegExp(r'(\d+)분').firstMatch(line);
        int stepDuration = 0;
        if (timeMatch != null) {
          stepDuration = int.tryParse(timeMatch.group(1)!) ?? 0;
        }

        String type = 'walk';
        if (line.contains('도보')) {
          type = 'walk';
        } else if (line.contains('탑승') ||
            line.contains('호선') ||
            line.contains('버스') ||
            line.contains('지하철')) {
          type = 'transit';
        } else if (line.contains('자동차')) {
          type = 'drive';
        } else if (timeMatch == null) {
          continue;
        }

        String desc = line.replaceAll(RegExp(r'\s*\d+분\s*'), '').trim();

        if (desc.isNotEmpty || stepDuration > 0) {
          steps.add(
            RouteStep(
              type: type,
              description: desc.isEmpty ? '이동' : desc,
              durationMinutes: stepDuration,
            ),
          );
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
      print('❌ description 파싱 실패: $e');
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
      print('❌ 경로 정보 파싱 실패: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '일정표 상세',
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
              child: CircularProgressIndicator(color: Color(0xFFFF8126)),
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
                        backgroundColor: const Color(0xFFFF8126),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _items.length * 2 - 1,
              itemBuilder: (context, index) {
                if (index % 2 == 0) {
                  int itemIndex = index ~/ 2;
                  final item = _items[itemIndex];
                  return _TimelineRow(
                    item: item,
                    index: itemIndex,
                    isLast: itemIndex == _items.length - 1,
                  );
                } else {
                  int itemIndex = index ~/ 2;
                  if (itemIndex < _items.length - 1) {
                    return _TransportationCard(
                      segmentIndex: itemIndex,
                      selectedTransportType: _transportTypes[itemIndex] ?? 0,
                      routeResult: _routeResults[itemIndex],
                    );
                  }
                  return const SizedBox.shrink();
                }
              },
            ),
    );
  }
}

// 아이템 타입
enum _ItemType { origin, place }

// 일정 아이템
class _ScheduleItem {
  final String title;
  final String subtitle;
  final String? address;
  final IconData icon;
  final Color color;
  final _ItemType type;
  final String? categoryId; // 가게 ID (가게 상세 화면 이동용)

  _ScheduleItem({
    required this.title,
    required this.subtitle,
    this.address,
    required this.icon,
    required this.color,
    required this.type,
    this.categoryId,
  });
}

// 타임라인 행 (default_template.dart와 동일)
class _TimelineRow extends StatelessWidget {
  final _ScheduleItem item;
  final int index;
  final bool isLast;

  const _TimelineRow({
    Key? key,
    required this.item,
    required this.index,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 가게 정보 카드인 경우 탭 가능하게 만들기
    final isPlace = item.type == _ItemType.place;
    final hasCategoryId = item.categoryId != null && item.categoryId!.isNotEmpty;

    Widget cardContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        const SizedBox(height: 4),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // 가게 정보 카드이고 categoryId가 있으면 탭 가능하게 만들기
    if (isPlace && hasCategoryId) {
      return InkWell(
        onTap: () => _navigateToRestaurantDetail(context, item.categoryId!, item.title, item.address),
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return cardContent;
  }

  /// 가게 상세 화면으로 이동
  void _navigateToRestaurantDetail(BuildContext context, String categoryId, String restaurantName, String? address) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 [Schedule History] 가게 상세 화면 이동 시작');
    print('  → Category ID: $categoryId');
    print('  → Restaurant Name (전달): $restaurantName');
    print('  → Address (전달): $address');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      // 가게 정보 가져오기 (태그, 리뷰 등)
      final restaurantData = await ApiService.getRestaurant(categoryId);
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 [Schedule History] 서버에서 받은 데이터');
      print('  → Rating: ${restaurantData.rating}');
      print('  → Reviews 개수: ${restaurantData.reviews.length}');
      print('  → Tags 개수: ${restaurantData.tags.length}');
      print('  → Is Favorite: ${restaurantData.isFavorite}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // 이미 가지고 있는 이름과 주소 정보를 사용하여 Restaurant 객체 생성
      final restaurant = Restaurant(
        id: categoryId,
        name: restaurantName, // 이미 가지고 있는 가게 이름 사용
        detailAddress: address, // 이미 가지고 있는 주소 사용
        rating: restaurantData.rating,
        reviews: restaurantData.reviews,
        tags: restaurantData.tags,
        isFavorite: restaurantData.isFavorite,
        // 나머지 필드는 기본값 또는 null
        do_: null,
        si: null,
        gu: null,
        subCategory: null,
        businessHour: null,
        phone: null,
        type: null,
        image: null,
        latitude: null,
        longitude: null,
        lastCrawl: null,
      );
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ [Schedule History] Restaurant 객체 생성 완료');
      print('  → Restaurant ID: ${restaurant.id}');
      print('  → Restaurant Name (최종): ${restaurant.name}');
      print('  → Restaurant Name (비어있음?): ${restaurant.name.isEmpty}');
      print('  → Detail Address (최종): ${restaurant.detailAddress}');
      print('  → Detail Address (null?): ${restaurant.detailAddress == null}');
      print('  → Address (getter): ${restaurant.address}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (!context.mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
        ),
      );
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ [Schedule History] 가게 상세 화면 이동 실패');
      print('  → Error: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가게 정보를 불러올 수 없습니다: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// 교통수단 카드 (default_template.dart와 동일)
class _TransportationCard extends StatelessWidget {
  final int segmentIndex;
  final int selectedTransportType;
  final RouteResult? routeResult;

  const _TransportationCard({
    Key? key,
    required this.segmentIndex,
    required this.selectedTransportType,
    this.routeResult,
  }) : super(key: key);

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
            // 교통수단 선택 버튼 (읽기 전용이므로 비활성화)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TransportButton(
                  icon: Icons.directions_walk,
                  label: '도보',
                  isSelected: selectedTransportType == 0,
                ),
                _TransportButton(
                  icon: Icons.train,
                  label: '대중교통',
                  isSelected: selectedTransportType == 1,
                ),
                _TransportButton(
                  icon: Icons.directions_car,
                  label: '자동차',
                  isSelected: selectedTransportType == 2,
                ),
              ],
            ),
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
    if (routeResult == null) {
      return Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
          const SizedBox(width: 8),
          Text(
            '경로 정보 없음',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    }

    final durationMinutes = routeResult!.durationMinutes;

    switch (selectedTransportType) {
      case 0: // 도보
        return Row(
          children: [
            const Icon(
              Icons.directions_walk,
              color: Color(0xFFFF8126),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '도보 약 ${durationMinutes}분',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
      case 1: // 대중교통
        return _buildPublicTransportDetails(durationMinutes);
      case 2: // 자동차
        return Row(
          children: [
            const Icon(
              Icons.directions_car,
              color: Color(0xFFFF8126),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '자동차 약 ${durationMinutes}분',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPublicTransportDetails(int durationMinutes) {
    final steps = routeResult?.steps;
    final distanceMeters = routeResult?.distanceMeters ?? 0;
    final distanceKm = distanceMeters / 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.train, color: Color(0xFFFF8126), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '대중교통 약 ${durationMinutes}분',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF8126),
                      ),
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
        ),
        if (steps != null && steps.isNotEmpty) ...[
          const SizedBox(height: 12),
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...steps.map((step) => _buildTransportStep(step)),
              ],
            ),
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
      padding: const EdgeInsets.only(bottom: 8),
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
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (step.type == 'walk' || step.durationMinutes > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.durationMinutes > 0
                        ? '${step.durationMinutes}분'
                        : '이동 없음',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

// 교통수단 버튼 (읽기 전용)
class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _TransportButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
