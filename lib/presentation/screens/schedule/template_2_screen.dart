import 'package:flutter/material.dart';
import '../../../data/services/history_service.dart';
import '../../../data/services/service_api.dart';
import '../../../shared/helpers/token_manager.dart';
import '../../../data/services/route_service.dart';
import '../../../data/services/api_service.dart';
import '../main/main_screen.dart';
import 'dart:async';
import '../../widgets/common_dialogs.dart';
import '../../widgets/transportation_selector_widget.dart';
import 'template_utils.dart';

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
  bool _isLoadingRatings = false; // 🔥 추가

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

    // 🔥 평점 정보 로드
    _loadRatings();
  }

  // 🔥 평점 정보를 API에서 가져오는 메서드
  Future<void> _loadRatings() async {
    if (widget.orderedPlaces == null || widget.orderedPlaces!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingRatings = true;
    });

    try {
      for (int i = 0; i < widget.orderedPlaces!.length; i++) {
        final placeData = widget.orderedPlaces![i];

        // 🔥 id 필드 사용 (category_id 대신)
        final categoryId = placeData['id'] as String?;

        if (categoryId != null && categoryId.isNotEmpty) {
          try {
            print('🔍 매장 정보 조회 중: $categoryId');

            // 🔥 API 호출해서 상세 정보 가져오기
            final restaurant = await ApiService.getRestaurant(categoryId);

            print(
              '✅ 평점 조회 완료: ${restaurant.averageStars ?? restaurant.rating}',
            );

            // 🔥 평점 업데이트 (i+1 인덱스 주의: 0번은 출발지)
            if (mounted && i + 1 < _items.length) {
              setState(() {
                _items[i + 1] = _ScheduleItem(
                  title: _items[i + 1].title,
                  category: _items[i + 1].category,
                  address: _items[i + 1].address,
                  icon: _items[i + 1].icon,
                  rating:
                      restaurant.averageStars ??
                      restaurant.rating, // 🔥 평점 업데이트
                  imageUrl:
                      _items[i + 1].imageUrl ??
                      restaurant.image, // 🔥 이미지도 업데이트
                );
              });
            }
          } catch (e) {
            print('❌ 매장 $categoryId 평점 로드 실패: $e');
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRatings = false;
        });
      }
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
    return TemplateUtils.calculateRouteForSegment(
      segmentIndex: segmentIndex,
      origin: origin,
      destination: destination,
      transportType: _transportTypes[segmentIndex] ?? 0,
      originTitle: segmentIndex == 0 ? '출발지' : _items[segmentIndex].title,
      destinationTitle: _items[segmentIndex + 1].title,
    );
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isReadOnly ? '일정표 상세' : '템플릿 2',
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
                    Icon(Icons.home, size: 20, color: Colors.black),
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
              accentColor: const Color(0xFFD97941),
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

  Future<void> _showGoHomeDialog() async {
    await TemplateUtils.showGoHomeDialog(
      context: context,
      accentColor: const Color(0xFFD97941),
    );
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

  Future<void> _handleShare() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final userId = TokenManager.userId;
      if (userId == null) {
        if (!mounted) return;
        CommonDialogs.showError(context: context, message: '로그인이 필요합니다.');
        return;
      }

      final scheduleText = _buildScheduleText();
      await ServiceApi.shareToCommunity(scheduleText, userId);

      if (!mounted) return;

      CommonDialogs.showSuccess(context: context, message: '커뮤니티에 공유되었습니다.');
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

  String _buildScheduleText() {
    return TemplateUtils.buildScheduleText(
      selected: widget.selected,
      originAddress: _originAddress,
      originDetailAddress: _originDetailAddress,
    );
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
        imageUrl: null,
        rating: null,
      ),
    );

    if (widget.orderedPlaces != null && widget.orderedPlaces!.isNotEmpty) {
      for (int i = 0; i < widget.orderedPlaces!.length; i++) {
        final placeData = widget.orderedPlaces![i];
        final placeName = placeData['name'] as String? ?? '알 수 없음';
        final category = placeData['category'] as String? ?? '기타';

        print('🔍 placeData 전체: $placeData');
        print('🔍 category_id: ${placeData['category_id']}');

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

        // 🔥 평점 정보 - average_stars 우선, 없으면 rating
        double? rating;
        final averageStarsValue =
            placeData['average_stars'] ?? placeData['data']?['average_stars'];
        if (averageStarsValue != null) {
          if (averageStarsValue is String) {
            rating = double.tryParse(averageStarsValue);
          } else if (averageStarsValue is num) {
            rating = averageStarsValue.toDouble();
          }
        }

        // average_stars가 없으면 rating 시도
        if (rating == null) {
          final ratingValue =
              placeData['rating'] ?? placeData['data']?['rating'];
          if (ratingValue != null) {
            if (ratingValue is String) {
              rating = double.tryParse(ratingValue);
            } else if (ratingValue is num) {
              rating = ratingValue.toDouble();
            }
          }
        }

        // 이미지 URL 추출
        String? imageUrl;
        imageUrl = placeData['image_url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) {
          final data = placeData['data'] as Map<String, dynamic>?;
          if (data != null) {
            imageUrl = data['image_url'] as String?;
          }
        }

        print('🔍 매장명: $placeName, 평점: $rating');

        items.add(
          _ScheduleItem(
            title: placeName,
            category: category,
            address: address,
            icon: _iconFor(category),
            rating: rating,
            imageUrl: imageUrl,
          ),
        );
      }
    } else {
      selected.forEach((category, places) {
        for (final placeName in places) {
          String? address;
          double? rating;
          String? imageUrl;

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

                // 🔥 평점 정보 - average_stars 우선
                final averageStarsValue = placeData['average_stars'];
                if (averageStarsValue != null) {
                  if (averageStarsValue is String) {
                    rating = double.tryParse(averageStarsValue);
                  } else if (averageStarsValue is num) {
                    rating = averageStarsValue.toDouble();
                  }
                }

                // average_stars가 없으면 rating 사용
                if (rating == null) {
                  final ratingValue = placeData['rating'];
                  if (ratingValue != null) {
                    if (ratingValue is String) {
                      rating = double.tryParse(ratingValue);
                    } else if (ratingValue is num) {
                      rating = ratingValue.toDouble();
                    }
                  }
                }

                imageUrl = placeData['image_url'] as String?;
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
              imageUrl: imageUrl,
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
    return TemplateUtils.getPlaceCoordinates(
      placeTitle: item.title,
      orderedPlaces: widget.orderedPlaces,
      selectedPlacesWithData: widget.selectedPlacesWithData,
    );
  }

  ({double lat, double lng})? _getOriginCoordinates() {
    return TemplateUtils.getOriginCoordinates(_originAddress);
  }
}

class _ScheduleItem {
  final String title;
  final String category;
  final String? address;
  final IconData icon;
  final double? rating;
  final String? imageUrl;

  _ScheduleItem({
    required this.title,
    required this.category,
    this.address,
    required this.icon,
    this.rating,
    this.imageUrl,
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
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97941), width: 2),
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
          clipBehavior: Clip.antiAlias, // 🔥 이미지 모서리 처리
          child:
              widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
              ? Image.network(
                  widget.item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 🔥 이미지 로딩 실패 시 이모지 표시
                    return Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 40)),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    // 🔥 로딩 중 표시
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFFD97941),
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : Center(
                  // 🔥 이미지 URL이 없으면 이모지 표시
                  child: Text(emoji, style: const TextStyle(fontSize: 40)),
                ),
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
        return _buildStar(index, rating);
      }),
    );
  }

  Widget _buildStar(int index, double rating) {
    double fillPercentage = 0.0;

    if (index < rating.floor()) {
      // 완전히 채워진 별
      fillPercentage = 1.0;
    } else if (index < rating) {
      // 부분적으로 채워진 별
      fillPercentage = rating - index;
    } else {
      // 빈 별
      fillPercentage = 0.0;
    }

    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          // 배경 (빈 별)
          Icon(
            Icons.star_border,
            size: 18,
            color: const Color(0xFFD97941).withOpacity(0.3),
          ),
          // 채워진 부분
          ClipRect(
            clipper: _StarClipper(fillPercentage),
            child: const Icon(Icons.star, size: 18, color: Color(0xFFD97941)),
          ),
        ],
      ),
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

        // 🔥 새로운 TransportationSelectorWidget 사용 (inline 스타일)
        TransportationSelectorWidget(
          segmentIndex: widget.segmentIndex,
          selectedTransportType: widget.transportType,
          onTransportTypeChanged: widget.isReadOnly ? null : widget.onTransportTypeChanged,
          isReadOnly: widget.isReadOnly,
          originCoordinates: null, // 좌표는 이미 계산된 routeResult에 포함
          destinationCoordinates: null, // 좌표는 이미 계산된 routeResult에 포함
          initialRouteResult: widget.routeResult,
          originName: widget.originName,
          destinationName: widget.item.title,
          style: TransportationSelectorStyle.inline,
        ),
      ],
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

class _StarClipper extends CustomClipper<Rect> {
  final double percentage;

  _StarClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * percentage, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
  }
}
