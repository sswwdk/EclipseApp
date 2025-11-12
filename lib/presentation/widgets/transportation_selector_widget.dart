import 'package:flutter/material.dart';
import '../../data/services/route_service.dart';

/// 교통수단 선택 및 경로 정보 표시 위젯
///
/// 템플릿 화면에서 공통으로 사용되는 교통수단 계산 기능을 제공합니다.
/// - 교통수단 선택 (도보, 대중교통, 자동차)
/// - 경로 정보 자동 계산
/// - 소요시간 및 거리 표시
/// - 대중교통 상세 경로 표시
class TransportationSelectorWidget extends StatefulWidget {
  /// 구간 인덱스 (로깅 및 식별용)
  final int segmentIndex;

  /// 선택된 교통수단 타입 (0: 도보, 1: 대중교통, 2: 자동차)
  final int selectedTransportType;

  /// 교통수단 변경 시 콜백 (null이면 읽기 전용)
  final Function(int)? onTransportTypeChanged;

  /// 읽기 전용 모드 여부
  final bool isReadOnly;

  /// 출발지 좌표
  final ({double lat, double lng})? originCoordinates;

  /// 도착지 좌표
  final ({double lat, double lng})? destinationCoordinates;

  /// 초기 경로 정보 (읽기 전용 모드나 미리 계산된 경우)
  final RouteResult? initialRouteResult;

  /// 출발지 이름 (UI 표시용)
  final String? originName;

  /// 도착지 이름 (UI 표시용)
  final String? destinationName;

  /// UI 스타일 타입
  final TransportationSelectorStyle style;

  const TransportationSelectorWidget({
    Key? key,
    required this.segmentIndex,
    required this.selectedTransportType,
    this.onTransportTypeChanged,
    this.isReadOnly = false,
    this.originCoordinates,
    this.destinationCoordinates,
    this.initialRouteResult,
    this.originName,
    this.destinationName,
    this.style = TransportationSelectorStyle.card,
  }) : super(key: key);

  @override
  State<TransportationSelectorWidget> createState() =>
      _TransportationSelectorWidgetState();
}

class _TransportationSelectorWidgetState
    extends State<TransportationSelectorWidget> {
  RouteResult? _routeResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 이미 경로 정보가 있으면 API 호출 없이 바로 사용
    if (widget.initialRouteResult != null) {
      _routeResult = widget.initialRouteResult;
      print(
        '✅ [TransportationSelector-${widget.segmentIndex}] 이미 계산된 경로 정보 사용',
      );
    } else {
      // 경로 정보가 없으면 계산
      print(
        '⚠️ [TransportationSelector-${widget.segmentIndex}] 경로 정보 없음, 직접 계산 시도',
      );
      _loadRouteInfo();
    }
  }

  @override
  void didUpdateWidget(TransportationSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 경로 정보가 변경되면 업데이트
    if (oldWidget.initialRouteResult != widget.initialRouteResult) {
      setState(() {
        _routeResult = widget.initialRouteResult;
      });
      print('✅ [TransportationSelector-${widget.segmentIndex}] 경로 정보 업데이트됨');
    }

    // 이미 경로 정보가 있으면 재계산하지 않음
    if (widget.initialRouteResult != null) {
      return;
    }

    // 교통수단이나 좌표가 변경되면 다시 로드 (경로 정보가 없는 경우만)
    if (oldWidget.selectedTransportType != widget.selectedTransportType ||
        oldWidget.originCoordinates != widget.originCoordinates ||
        oldWidget.destinationCoordinates != widget.destinationCoordinates) {
      print(
        '⚠️ [TransportationSelector-${widget.segmentIndex}] 교통수단/좌표 변경, 재계산 시도',
      );
      _loadRouteInfo();
    }
  }

  Future<void> _loadRouteInfo() async {
    // 좌표 정보가 없으면 로드하지 않음
    if (widget.originCoordinates == null ||
        widget.destinationCoordinates == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 [TransportationSelector] 이동시간 계산 요청:');
      print('   origin: ${widget.originCoordinates}');
      print('   destination: ${widget.destinationCoordinates}');
      print('   transportType: ${widget.selectedTransportType}');

      final result = await RouteService.calculateRoute(
        origin: widget.originCoordinates!,
        destination: widget.destinationCoordinates!,
        transportType: widget.selectedTransportType,
      );

      print('🔍 [TransportationSelector] 이동시간 계산 결과:');
      print('   durationMinutes: ${result.durationMinutes}');
      print('   distanceMeters: ${result.distanceMeters}');

      if (mounted) {
        setState(() {
          _routeResult = result;
          _isLoading = false;
        });
        print('✅ [TransportationSelector] 상태 업데이트 완료');
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
    switch (widget.style) {
      case TransportationSelectorStyle.card:
        return _buildCardStyle();
      case TransportationSelectorStyle.inline:
        return _buildInlineStyle();
      case TransportationSelectorStyle.dropdown:
        return _buildDropdownStyle();
    }
  }

  /// 카드 스타일 (템플릿 1 스타일)
  Widget _buildCardStyle() {
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
                _buildTransportButton(
                  type: 0,
                  icon: Icons.directions_walk,
                  label: '도보',
                  color: const Color(0xFFFF8126),
                ),
                _buildTransportButton(
                  type: 1,
                  icon: Icons.train,
                  label: '대중교통',
                  color: const Color(0xFFFF8126),
                ),
                _buildTransportButton(
                  type: 2,
                  icon: Icons.directions_car,
                  label: '자동차',
                  color: const Color(0xFFFF8126),
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

  /// 인라인 스타일 (템플릿 2 스타일)
  Widget _buildInlineStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 교통수단 아이콘 가로 배치
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTransportIconButton(
              type: 0,
              icon: Icons.directions_walk,
              label: '도보',
              color: const Color(0xFFD97941),
            ),
            _buildTransportIconButton(
              type: 1,
              icon: Icons.train,
              label: '대중교통',
              color: const Color(0xFFD97941),
            ),
            _buildTransportIconButton(
              type: 2,
              icon: Icons.directions_car,
              label: '차량',
              color: const Color(0xFFD97941),
            ),
          ],
        ),

        // 선택된 교통수단의 상세 정보
        if (_routeResult != null) ...[
          const SizedBox(height: 16),
          _buildInlineTransportDetailInfo(),
        ],
      ],
    );
  }

  /// 드롭다운 스타일 (템플릿 3 스타일)
  Widget _buildDropdownStyle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFB7C9E).withOpacity(0.18)),
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
                      color: const Color(0xFFFB7C9E).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconForTransportType(widget.selectedTransportType),
                  color: const Color(0xFFFB7C9E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.originName != null &&
                        widget.destinationName != null)
                      Text(
                        '${widget.originName} → ${widget.destinationName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E4A4A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    _buildRouteInfoText(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!widget.isReadOnly) _buildDropdownButton(),
            ],
          ),
          // 대중교통 상세 경로
          if (widget.selectedTransportType == 1 &&
              _routeResult?.steps != null &&
              _routeResult!.steps!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailedSteps(),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportButton({
    required int type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = widget.selectedTransportType == type;

    return GestureDetector(
      onTap: widget.isReadOnly
          ? null
          : () => widget.onTransportTypeChanged?.call(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
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

  Widget _buildTransportIconButton({
    required int type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = widget.selectedTransportType == type;

    return GestureDetector(
      onTap: widget.isReadOnly
          ? null
          : () => widget.onTransportTypeChanged?.call(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
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

  Widget _buildDropdownButton() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: widget.selectedTransportType,
        icon: const Icon(Icons.expand_more, color: Color(0xFFFB7C9E)),
        borderRadius: BorderRadius.circular(16),
        items: const [
          DropdownMenuItem<int>(
            value: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_walk_outlined,
                  size: 20,
                  color: Color(0xFFFB7C9E),
                ),
                SizedBox(width: 8),
                Text('도보'),
              ],
            ),
          ),
          DropdownMenuItem<int>(
            value: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_transit_outlined,
                  size: 20,
                  color: Color(0xFFFB7C9E),
                ),
                SizedBox(width: 8),
                Text('대중교통'),
              ],
            ),
          ),
          DropdownMenuItem<int>(
            value: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car_filled_outlined,
                  size: 20,
                  color: Color(0xFFFB7C9E),
                ),
                SizedBox(width: 8),
                Text('자동차'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;
          widget.onTransportTypeChanged?.call(value);
        },
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

    // 읽기 전용 모드이고 서버에서 받은 경로 정보가 있으면 바로 표시
    if (widget.isReadOnly && _routeResult != null) {
      return _buildTransportDetailsByType();
    }

    // 좌표 정보가 없으면 안내 메시지
    if (widget.originCoordinates == null ||
        widget.destinationCoordinates == null) {
      if (!widget.isReadOnly) {
        return Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[300],
              size: 20,
            ),
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
    }

    // 실제 계산 결과 표시
    if (_routeResult == null) {
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

    return _buildTransportDetailsByType();
  }

  Widget _buildTransportDetailsByType() {
    if (_routeResult == null) {
      return const SizedBox.shrink();
    }

    final durationMinutes = _routeResult!.durationMinutes;

    switch (widget.selectedTransportType) {
      case 0: // 도보
        return Row(
          children: [
            const Icon(
              Icons.directions_walk,
              color: Color(0xFFFF8126),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '도보 약 ${durationMinutes}분',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            Expanded(
              child: Text(
                '자동차 약 ${durationMinutes}분',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
        // 헤더: 요약 정보
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

        // 상세 경로
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

  Widget _buildInlineTransportDetailInfo() {
    final durationMinutes = _routeResult!.durationMinutes;
    final distanceMeters = _routeResult!.distanceMeters;
    final distanceKm = distanceMeters / 1000.0;

    String transportLabel;
    IconData icon;

    switch (widget.selectedTransportType) {
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

          // 대중교통 상세 경로
          if (widget.selectedTransportType == 1 &&
              _routeResult!.steps != null &&
              _routeResult!.steps!.isNotEmpty) ...[
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
                  ..._routeResult!.steps!.map(
                    (step) => _buildTransportStep(step),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteInfoText() {
    if (_routeResult != null) {
      final durationMinutes = _routeResult!.durationMinutes;
      final distanceMeters = _routeResult!.distanceMeters;

      return Row(
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '약 ${durationMinutes}분',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFB7C9E),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (distanceMeters > 0) ...[
            const SizedBox(width: 12),
            Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              distanceMeters >= 1000
                  ? '약 ${(distanceMeters / 1000).toStringAsFixed(1)}km'
                  : '약 ${distanceMeters}m',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      );
    } else {
      return Text(
        '이동수단을 선택해 주세요',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }
  }

  Widget _buildDetailedSteps() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상세 경로',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4E4A4A),
            ),
          ),
          const SizedBox(height: 12),
          ..._routeResult!.steps!.map((step) => _buildTransportStep(step)),
        ],
      ),
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
                        : '1분',
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

  IconData _getIconForTransportType(int type) {
    switch (type) {
      case 0:
        return Icons.directions_walk_outlined;
      case 1:
        return Icons.directions_transit_outlined;
      case 2:
        return Icons.directions_car_filled_outlined;
      default:
        return Icons.directions_walk_outlined;
    }
  }
}

/// 교통수단 선택 위젯의 UI 스타일
enum TransportationSelectorStyle {
  /// 카드 스타일 (템플릿 1)
  card,

  /// 인라인 스타일 (템플릿 2)
  inline,

  /// 드롭다운 스타일 (템플릿 3)
  dropdown,
}
