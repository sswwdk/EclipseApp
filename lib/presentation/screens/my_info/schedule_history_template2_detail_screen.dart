import 'package:flutter/material.dart';
import '../../../data/services/history_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../data/services/route_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/restaurant.dart';
import '../../../shared/helpers/history_parser.dart';
import '../main/restaurant_detail_review_screen.dart';

class ScheduleHistoryTemplate2DetailScreen extends StatefulWidget {
  final String historyId;

  const ScheduleHistoryTemplate2DetailScreen({
    Key? key,
    required this.historyId,
  }) : super(key: key);

  @override
  State<ScheduleHistoryTemplate2DetailScreen> createState() =>
      _ScheduleHistoryTemplate2DetailScreenState();
}

class _ScheduleHistoryTemplate2DetailScreenState
    extends State<ScheduleHistoryTemplate2DetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;

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
        category: '출발지',
        address: null,
        icon: Icons.home_outlined,
        categoryId: null,
        rating: null,
        imageUrl: null,
      ),
    );

    for (int i = 0; i < sortedCategories.length; i++) {
      final category = sortedCategories[i];
      final categoryName = category['category_name'] as String? ?? '';
      final categoryId = category['category_id'] as String? ?? '';
      final duration = category['duration'] as int? ?? 3600;

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

      double? rating;
      final ratingValue = category['rating'];
      if (ratingValue is String) {
        rating = double.tryParse(ratingValue);
      } else if (ratingValue is num) {
        rating = ratingValue.toDouble();
      }

      // 🔥 이미지 URL 추출
      String? imageUrl =
          category['image'] as String? ??
          category['image_url'] as String? ??
          category['category_image'] as String?;

      items.add(
        _ScheduleItem(
          title: categoryName,
          category: categoryType,
          address: address,
          icon: _iconFor(categoryType),
          categoryId: categoryId,
          rating: rating,
          imageUrl: imageUrl, // 🔥 추가
        ),
      );

      _transportTypes[i] = transportation;

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
        title: const Text(
          '오늘의 일정표',
          style: TextStyle(
            color: Color(0xFFD97941),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD97941)),
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
                        backgroundColor: const Color(0xFFD97941),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHomeSection(),
                  const SizedBox(height: 30),

                  // 🔥 originName 전달
                  ...List.generate(_items.length - 1, (index) {
                    String originName;
                    if (index == 0) {
                      originName = '출발지';
                      if (_originAddress != null &&
                          _originAddress!.isNotEmpty) {
                        final parts = _originAddress!.split(' ');
                        if (parts.length >= 2) {
                          originName = '${parts[0]} ${parts[1]}';
                        } else {
                          originName = parts[0];
                        }
                      }
                    } else {
                      originName = _items[index].title;
                    }

                    return Column(
                      children: [
                        _PlannerItemCard(
                          item: _items[index + 1],
                          segmentIndex: index,
                          transportType: _transportTypes[index] ?? 0,
                          routeResult: _routeResults[index],
                          originName: originName,
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildHomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97941), width: 2),
      ),
      child: const Row(
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
    );
  }
}

class _ScheduleItem {
  final String title;
  final String category;
  final String? address;
  final IconData icon;
  final String? categoryId;
  final double? rating;
  final String? imageUrl;

  _ScheduleItem({
    required this.title,
    required this.category,
    this.address,
    required this.icon,
    this.categoryId,
    this.rating,
    this.imageUrl,
  });
}

// 🔥 수정된 _PlannerItemCard
class _PlannerItemCard extends StatelessWidget {
  final _ScheduleItem item;
  final int segmentIndex;
  final int transportType;
  final RouteResult? routeResult;
  final String originName;

  const _PlannerItemCard({
    Key? key,
    required this.item,
    required this.segmentIndex,
    required this.transportType,
    this.routeResult,
    required this.originName,
  }) : super(key: key);

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
          _buildImageSection(context),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD97941), width: 2),
                    ),
                  ),
                  child: Text(
                    item.title,
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
                _buildInfoItem('📍 주소', item.address ?? '주소 정보 없음'),
                const SizedBox(height: 12),
                _buildTravelTimeSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return InkWell(
      onTap: item.categoryId != null && item.categoryId!.isNotEmpty
          ? () => _navigateToDetail(context)
          : null,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFFEFEFE),
              border: Border.all(color: const Color(0xFFD97941), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // 🔥 이미지 로딩 실패 시 이모지 표시
                      String emoji = _getEmojiForCategory(item.category);
                      return Container(
                        color: const Color(0xFFFFF5E8),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      // 🔥 로딩 중 표시
                      return Container(
                        color: const Color(0xFFFFF5E8),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFFD97941),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    // 🔥 이미지 URL이 없으면 이모지와 배경색 표시
                    color: const Color(0xFFFFF5E8),
                    child: Center(
                      child: Text(
                        _getEmojiForCategory(item.category),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          _buildStars(item.rating ?? 0.0),
        ],
      ),
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
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Color(0xFFD97941)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$originName → ${item.title}',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTransportIconButton(0, Icons.directions_walk, '도보'),
            _buildTransportIconButton(1, Icons.train, '대중교통'),
            _buildTransportIconButton(2, Icons.directions_car, '차량'),
          ],
        ),
        if (routeResult != null) ...[
          const SizedBox(height: 16),
          _buildTransportDetailInfo(),
        ],
      ],
    );
  }

  Widget _buildTransportIconButton(int type, IconData icon, String label) {
    final isSelected = transportType == type;

    return Container(
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
    );
  }

  Widget _buildTransportDetailInfo() {
    final durationMinutes = routeResult!.durationMinutes;
    final distanceMeters = routeResult!.distanceMeters;
    final distanceKm = distanceMeters / 1000.0;

    String transportLabel;
    IconData icon;

    switch (transportType) {
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
          if (transportType == 1 &&
              routeResult!.steps != null &&
              routeResult!.steps!.isNotEmpty) ...[
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
                  ...routeResult!.steps!.map((step) => _buildRouteStep(step)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  Future<void> _navigateToDetail(BuildContext context) async {
    if (item.categoryId == null || item.categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매장 정보를 불러올 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97941)),
          ),
        ),
      );

      // 🔥 매장 상세 정보 API 호출 (이미지 포함)
      print('🔍 매장 상세 정보 조회 시작: ${item.categoryId}');
      final detailedRestaurant = await ApiService.getRestaurant(
        item.categoryId!,
      );
      print('✅ 매장 상세 정보 조회 완료: ${detailedRestaurant.image}');

      if (!context.mounted) return;
      Navigator.pop(context); // 로딩 닫기

      // 🔥 API에서 받은 전체 정보로 Restaurant 객체 생성
      final restaurant = Restaurant(
        id: item.categoryId!,
        name: detailedRestaurant.name.isNotEmpty
            ? detailedRestaurant.name
            : item.title,
        subCategory: detailedRestaurant.subCategory ?? item.category,
        detailAddress: detailedRestaurant.detailAddress ?? item.address,
        image: detailedRestaurant.image, // 🔥 API에서 받은 이미지 사용
        phone: detailedRestaurant.phone,
        rating: detailedRestaurant.rating ?? item.rating,
        businessHour: detailedRestaurant.businessHour,
      );

      print('🏪 Restaurant 객체 생성 완료: image = ${restaurant.image}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailReviewScreen(
            restaurant: restaurant,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);

      print('❌ 매장 상세 화면 이동 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('매장 정보를 불러오는 데 실패했습니다: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
