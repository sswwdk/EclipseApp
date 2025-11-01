import 'package:flutter/material.dart';

class ScheduleBuilderScreen extends StatefulWidget {
  final Map<String, List<String>> selected; // 카테고리별 선택 목록
  final String? originAddress; // 출발지 주소
  final String? originDetailAddress; // 출발지 상세 주소
  final int? firstDurationMinutes; // 템플릿: 첫 이동 또는 첫 체류 시간
  final int? otherDurationMinutes; // 템플릿: 이후 체류 시간

  const ScheduleBuilderScreen({
    Key? key,
    required this.selected,
    this.originAddress,
    this.originDetailAddress,
    this.firstDurationMinutes,
    this.otherDurationMinutes,
  }) : super(key: key);

  @override
  State<ScheduleBuilderScreen> createState() => _ScheduleBuilderScreenState();
}

class _ScheduleBuilderScreenState extends State<ScheduleBuilderScreen> {
  late List<_ScheduleItem> _items;
  String? _originAddress; // 출발지 주소
  String? _originDetailAddress; // 출발지 상세 주소
  Map<int, int> _transportTypes = {}; // 각 구간별 교통수단 (key: segmentIndex, value: transportType)

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
    _items = _buildScheduleItems(widget.selected);
    // 각 구간별로 기본 교통수단 설정 (대중교통)
    for (int i = 0; i < _items.length - 1; i++) {
      _transportTypes[i] = 1;
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
        title: const Text(
          '일정표 만들기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // 메뉴 옵션
            },
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
                onTransportTypeChanged: (type) {
                  setState(() {
                    _transportTypes[itemIndex] = type;
                  });
                },
              );
            }
            return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장하기 기능은 준비 중입니다.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFF8126), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFFFF8126),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text(
                    '저장하기',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공유하기 기능은 준비 중입니다.')),
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

    // 선택된 장소를 순서대로 나열 (카테고리 순서 유지)
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
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
          const SizedBox(width: 8),
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
class _TransportationCard extends StatelessWidget {
  final int segmentIndex;
  final int selectedTransportType;
  final Function(int) onTransportTypeChanged;

  const _TransportationCard({
    Key? key,
    required this.segmentIndex,
    required this.selectedTransportType,
    required this.onTransportTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 교통수단 선택 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TransportButton(
                  icon: Icons.directions_walk,
                  label: '도보',
                  isSelected: selectedTransportType == 0,
                  onTap: () => onTransportTypeChanged(0),
                ),
                _TransportButton(
                  icon: Icons.train,
                  label: '대중교통',
                  isSelected: selectedTransportType == 1,
                  onTap: () => onTransportTypeChanged(1),
                ),
                _TransportButton(
                  icon: Icons.directions_car,
                  label: '자동차',
                  isSelected: selectedTransportType == 2,
                  onTap: () => onTransportTypeChanged(2),
                ),
              ],
            ),
          ),
          
          // 선택된 교통수단의 상세 정보
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: _buildTransportDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportDetails() {
    switch (selectedTransportType) {
      case 0: // 도보
        return Row(
          children: [
            const Icon(Icons.directions_walk, color: Color(0xFFFF8126), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '도보 약 45분',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      case 1: // 대중교통
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.train, color: Color(0xFFFF8126), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '대중교통 약 45분',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.train, color: Colors.green, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('2호선', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '집 근처 역 > 홍대입구역',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.directions_walk, color: Colors.blue, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('도보 5분', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '홍대입구역 1번 출구 > 홍대 CGV',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        );
      case 2: // 자동차
        return Row(
          children: [
            const Icon(Icons.directions_car, color: Color(0xFFFF8126), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '자동차 약 30분',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// 교통수단 버튼
class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TransportButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제 위치 서비스 연동 (geolocator 패키지 등)
      // 현재는 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // 임시로 현재 위치를 주소로 설정
      _addressController.text = '서울시 강남구 테헤란로 123';
      _showSnackBar('현재 위치를 가져왔습니다.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('위를 가져오는 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
                  
                  // 현재 위치 가져오기 버튼
                  OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, color: Color(0xFFFF8126)),
                    label: const Text(
                      '현재 위치 사용',
                      style: TextStyle(
                        color: Color(0xFFFF8126),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFFF8126), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
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


