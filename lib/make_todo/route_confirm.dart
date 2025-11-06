import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'choose_template.dart';

class RouteConfirmScreen extends StatefulWidget {
  final Map<String, List<dynamic>> selected; // 카테고리별 선택 목록 (Map 또는 String)

  const RouteConfirmScreen({Key? key, required this.selected}) : super(key: key);

  @override
  State<RouteConfirmScreen> createState() => _RouteConfirmScreenState();
}

class _RouteConfirmScreenState extends State<RouteConfirmScreen> {
  late List<_ScheduleItem> _items;
  String? _originAddress; // 출발지 주소
  String? _originDetailAddress; // 출발지 상세 주소

  @override
  void initState() {
    super.initState();
    
    // 디버깅: widget.selected의 실제 데이터 구조 확인
    print('🔍 RouteConfirmScreen.initState - widget.selected 데이터:');
    widget.selected.forEach((category, places) {
      print('  [$category] 개수: ${places.length}');
      if (places.isNotEmpty) {
        final firstPlace = places[0];
        print('    첫 번째 항목 타입: ${firstPlace.runtimeType}');
        if (firstPlace is Map) {
          print('    필드 목록: ${(firstPlace as Map).keys.toList()}');
          print('    전체 데이터: $firstPlace');
        } else {
          print('    데이터: $firstPlace');
        }
      }
    });
    
    _items = _buildScheduleItems(widget.selected);
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
        title: const Text(
          '일정표 만들기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return KeyedSubtree(
                key: ValueKey(item.id),
                child: _TimelineRow(
                  item: item,
                  index: index,
                  isLast: index == items.length - 1,
                  showDuration: false, // 미리보기에서는 시간 숨김
                  onDragHandle: item.type == _ItemType.place
                      ? (child) => ReorderableDragStartListener(index: index, child: child)
                      : null,
                  onTap: item.type == _ItemType.origin ? () => _showOriginAddressInput() : null,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // 첫 항목(출발지)은 고정
              if (oldIndex == 0 || newIndex == 0) return;
              if (newIndex > oldIndex) newIndex -= 1;
              setState(() {
                final moved = _items.removeAt(oldIndex);
                _items.insert(newIndex, moved);
              });
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                print('🔍 경로 확정하기 버튼 클릭');
                print('🔍 widget.selected 데이터:');
                widget.selected.forEach((category, places) {
                  print('  [$category]: 총 ${places.length}개 장소');
                  for (int i = 0; i < places.length; i++) {
                    final place = places[i];
                    if (place is Map) {
                      print('    [$i] 장소 이름: ${place['title'] ?? place['name']}');
                      print('       id: ${place['id']}');
                      print('       lat: ${place['lat']}, lng: ${place['lng']}');
                      print('       latitude: ${place['latitude']}, longitude: ${place['longitude']}');
                      print('       category_id: ${place['category_id']}');
                      print('       필드: ${place.keys.toList()}');
                    }
                  }
                });
                
                // 원본 선택 데이터에서 placeName -> categoryName 매핑을 구축
                // 🔥 같은 이름의 가게가 여러 개 있을 수 있으므로, ID를 포함한 고유 키 사용
                final Map<String, String> placeToCategory = {};
                final Map<String, Map<String, dynamic>> placeNameToData = {};
                final List<Map<String, dynamic>> allPlaces = []; // 🔥 모든 선택된 장소를 순서대로 저장
                
                widget.selected.forEach((category, places) {
                  for (final place in places) {
                    String placeName;
                    if (place is Map<String, dynamic>) {
                      placeName = place['title'] as String? ??
                                  place['name'] as String? ??
                                  place['id'] as String? ??
                                  place.toString();
                      
                      // 🔥 ID를 포함한 고유 키 생성 (같은 이름의 가게가 여러 개 있을 수 있음)
                      final String placeId = place['id'] as String? ?? '';
                      final String uniqueKey = placeId.isNotEmpty 
                          ? '$placeName|$placeId' 
                          : '$placeName|${place.hashCode}';
                      
                      placeToCategory[uniqueKey] = category;
                      placeNameToData[uniqueKey] = place;
                      allPlaces.add(place); // 🔥 모든 장소를 순서대로 저장
                      
                      print('🔍 [경로 확정] 장소 추가: $placeName (id: $placeId, uniqueKey: $uniqueKey)');
                      print('   lat: ${place['lat']}, lng: ${place['lng']}');
                      print('   latitude: ${place['latitude']}, longitude: ${place['longitude']}');
                    } else {
                      placeName = place.toString();
                      placeToCategory[placeName] = category;
                    }
                  }
                });

                // 🔥 순서를 유지하는 리스트 생성 (화면 순서 그대로)
                final List<Map<String, dynamic>> orderedPlaces = [];
                
                print('🔍 [경로 확정] _items 순서:');
                for (int i = 0; i < _items.length; i++) {
                  final item = _items[i];
                  print('  [$i] ${item.title} (${item.type})');
                }
                
                // 🔥 _items의 순서대로 orderedPlaces 생성하되, 각 item에 해당하는 실제 데이터 찾기
                // allPlaces를 순회하면서 _items의 순서와 매칭
                int allPlacesIndex = 0;
                for (final item in _items) {
                  if (item.type != _ItemType.place) continue; // 출발지 제외
                  
                  final String placeName = item.title;
                  
                  // 🔥 item.title과 일치하는 place를 allPlaces에서 순서대로 찾기
                  Map<String, dynamic>? matchedPlace;
                  String? matchedCategory;
                  
                  // allPlaces에서 순서대로 검색 (이미 사용한 것은 건너뛰기)
                  for (int i = allPlacesIndex; i < allPlaces.length; i++) {
                    final place = allPlaces[i];
                    final dataPlaceName = place['title'] as String? ?? 
                                        place['name'] as String? ?? '';
                    if (dataPlaceName == placeName) {
                      matchedPlace = place;
                      // category 찾기
                      for (final entry in widget.selected.entries) {
                        if (entry.value.contains(place)) {
                          matchedCategory = entry.key;
                          break;
                        }
                      }
                      allPlacesIndex = i + 1; // 다음 검색은 여기서부터
                      break;
                    }
                  }
                  
                  // 여전히 못 찾았으면 기본값 사용
                  final String categoryName = matchedCategory ?? 
                                             item.categoryName ?? 
                                             item.subtitle;
                  
                  // 위경도 정보 추출 (서버에서 보낼 수 있는 여러 필드명 확인)
                  final String? latitude = matchedPlace?['latitude'] as String? ?? 
                                           matchedPlace?['lat'] as String?;
                  final String? longitude = matchedPlace?['longitude'] as String? ?? 
                                            matchedPlace?['lng'] as String?;
                  
                  orderedPlaces.add({
                    'id': matchedPlace?['id'] as String? ?? '', // 🔥 id를 최상위 레벨로 추가
                    'name': placeName,
                    'category': categoryName,
                    'latitude': latitude, // 🔥 위경도를 최상위 레벨에 명시적으로 추가
                    'longitude': longitude,
                    'data': matchedPlace ?? {},
                  });
                  
                  print('🔍 [경로 확정] orderedPlaces 추가: $placeName');
                  print('   id: ${matchedPlace?['id']}');
                  print('   lat: ${matchedPlace?['lat']}, lng: ${matchedPlace?['lng']}');
                  print('   latitude: ${matchedPlace?['latitude']}, longitude: ${matchedPlace?['longitude']}');
                }
                
                print('🔍 [경로 확정] orderedPlaces 생성 완료:');
                for (int i = 0; i < orderedPlaces.length; i++) {
                  print('  [$i] ${orderedPlaces[i]['name']} (id: ${orderedPlaces[i]['id']})');
                }
                
                // 기존 호환성을 위한 Map 구조도 생성
                final Map<String, List<String>> convertedSelected = {};
                final Map<String, List<Map<String, dynamic>>> selectedPlacesWithData = {};
                
                for (final item in _items) {
                  if (item.type != _ItemType.place) continue;
                  final String placeName = item.title;
                  final String categoryName = placeToCategory[placeName] ?? item.categoryName ?? item.subtitle;
                  convertedSelected.putIfAbsent(categoryName, () => []);
                  convertedSelected[categoryName]!.add(placeName);
                  
                  selectedPlacesWithData.putIfAbsent(categoryName, () => []);
                  final originalPlaces = widget.selected[categoryName];
                  if (originalPlaces != null) {
                    for (final place in originalPlaces) {
                      if (place is Map<String, dynamic>) {
                        final name = place['title'] as String? ?? place['name'] as String? ?? '';
                        if (name == placeName) {
                          selectedPlacesWithData[categoryName]!.add(place);
                          break;
                        }
                      }
                    }
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      // 카테고리명 -> 카테고리ID 매핑 구성 (원본 데이터에서 추출)
                      final Map<String, String> categoryIdByName = {};
                      widget.selected.forEach((categoryName, places) {
                        // 이미 해당 카테고리의 ID를 찾았다면 스킵
                        if (categoryIdByName.containsKey(categoryName)) {
                          return;
                        }
                        
                        for (final place in places) {
                          if (place is Map<String, dynamic>) {
                            final String? catId =
                                place['category_id'] as String? ??
                                place['categoryId'] as String? ??
                                place['categoryID'] as String?;
                            if (catId != null && catId.isNotEmpty) {
                              categoryIdByName[categoryName] = catId;
                              break; // 현재 카테고리의 ID를 찾았으므로 내부 루프만 중단
                            }
                          }
                        }
                      });

                      print('🔍 구축된 categoryIdByName: $categoryIdByName');
                      print('🔍 isEmpty: ${categoryIdByName.isEmpty}');

                      return ChooseTemplateScreen(
                        selected: convertedSelected,
                        selectedPlacesWithData: selectedPlacesWithData,
                        categoryIdByName: categoryIdByName.isEmpty ? null : categoryIdByName,
                        originAddress: _originAddress,
                        originDetailAddress: _originDetailAddress,
                        orderedPlaces: orderedPlaces, // 🔥 순서가 유지되는 리스트 전달
                      );
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8126),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text(
                '경로 확정하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOriginAddressInput() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OriginAddressInputScreen(
          initialAddress: _originAddress,
          initialDetailAddress: _originDetailAddress,
        ),
      ),
    );

    if (result != null && result is Map<String, String?>) {
      setState(() {
        _originAddress = result['address'];
        _originDetailAddress = result['detailAddress'];
        _items = _buildScheduleItems(widget.selected);
      });
    }
  }

  List<_ScheduleItem> _buildScheduleItems(Map<String, List<dynamic>> selected) {
    final List<_ScheduleItem> items = [];
    // 출발지(집)
    String originTitle = '현재 위치';
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
    ));

    // 선택된 장소를 순서대로 나열 (카테고리 순서 유지)
    selected.forEach((category, places) {
      for (final place in places) {
        // place가 Map인지 String인지 확인
        String placeName;
        String subCategory;
        
        if (place is Map<String, dynamic>) {
          // Map 형태인 경우 실제 데이터 추출
          // 서버 응답 형식에 따라 여러 필드명 시도 (title, name 순서로)
          placeName = place['title'] as String? ?? 
                     place['name'] as String? ?? 
                     '알 수 없음';
          subCategory = place['sub_category'] as String? ?? 
                       place['category'] as String? ?? 
                       category;
        } else {
          // String 형태인 경우 (기존 호환성 유지)
          placeName = place.toString();
          subCategory = category;
        }
        
        items.add(_ScheduleItem(
          title: placeName,
          subtitle: subCategory,
          icon: _iconFor(category),
          color: const Color(0xFFFF8126),
          type: _ItemType.place,
          durationMinutes: items.length == 1 ? 45 : 20,
          categoryName: category,
        ));
      }
    });

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
  final String? categoryName; // 원래 카테고리명(그룹핑에 사용)

  _ScheduleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
    this.durationMinutes,
    this.categoryName,
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
    final double leftInfoWidth = 0;
    final double gapBetween = 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: leftInfoWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  showDuration ? _formatDuration(item, index) : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(width: gapBetween),
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
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFE3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: const Color(0xFFFF8126)),
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
                        // 출발지 항목이 아닐 때만 주황색 태그로 표시
                        if (item.type != _ItemType.origin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8126),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '# ${item.subtitle}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          // 출발지 항목은 회색 텍스트로 표시
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.type == _ItemType.place && onDragHandle != null)
                    onDragHandle!(const Icon(Icons.drag_handle, color: Colors.grey, size: 18)),
                  if (item.type == _ItemType.origin && onTap != null)
                    const Icon(Icons.edit, color: Colors.grey, size: 18),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(_ScheduleItem item, int index) {
    if (index == 0) return '';
    final minutes = item.durationMinutes ?? 20;
    return '약 $minutes\n분';
  }
}

// 출발지 주소 입력 화면 (미리보기 단계에서 사용)
class OriginAddressInputScreen extends StatefulWidget {
  final String? initialAddress;
  final String? initialDetailAddress;

  const OriginAddressInputScreen({Key? key, this.initialAddress, this.initialDetailAddress}) : super(key: key);

  @override
  State<OriginAddressInputScreen> createState() => _OriginAddressInputScreenState();
}

class _OriginAddressInputScreenState extends State<OriginAddressInputScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailAddressController = TextEditingController();
  final FocusNode _detailAddressFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isLoadingGPS = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';
    _detailAddressController.text = widget.initialDetailAddress ?? '';
    
    // 화면 진입 시 자동으로 현재 위치 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
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
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pop(
        context,
        {
          'address': _addressController.text.trim(),
          'detailAddress': _detailAddressController.text.trim(),
        },
      );
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('주소 저장 중 오류가 발생했습니다.');
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
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// GPS를 사용하여 현재 위치 가져오기 (위경도만 서버로 전송)
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingGPS = true;
    });

    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showSnackBar('위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.');
        setState(() {
          _isLoadingGPS = false;
        });
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          _showSnackBar('위치 권한이 거부되었습니다.');
          setState(() {
            _isLoadingGPS = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showSnackBar('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
        setState(() {
          _isLoadingGPS = false;
        });
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      // 위경도만 표시 (서버로 전송할 수 있도록)
      setState(() {
        _addressController.text = '위도: ${position.latitude.toStringAsFixed(6)}, 경도: ${position.longitude.toStringAsFixed(6)}';
        _detailAddressController.text = '';
      });
      _showSnackBar('위치 정보를 가져왔습니다. 위경도가 서버로 전송됩니다.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('위치 정보를 가져오는 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGPS = false;
        });
      }
    }
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
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8126)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // GPS 버튼
                  ElevatedButton.icon(
                    onPressed: _isLoadingGPS ? null : _getCurrentLocation,
                    icon: _isLoadingGPS
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 20),
                    label: Text(_isLoadingGPS ? '위치 가져오는 중...' : '현재 위치로 설정'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8126),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_detailAddressFocusNode),
                    decoration: InputDecoration(
                      hintText: '예: 서울시 강남구 테헤란로 123',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _detailAddressController,
                    focusNode: _detailAddressFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveAddress(),
                    decoration: InputDecoration(
                      hintText: '상세 주소 (건물명, 동/호수 등)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8126),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}