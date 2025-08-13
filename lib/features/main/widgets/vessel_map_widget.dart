// lib/features/main/widgets/vessel_map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../vessel/cubit/vessel_cubit.dart';
import '../../vessel/models/vessel_model.dart';

/// 선박 지도 위젯
class VesselMapWidget extends StatefulWidget {
  const VesselMapWidget({super.key});

  @override
  State<VesselMapWidget> createState() => _VesselMapWidgetState();
}

class _VesselMapWidgetState extends State<VesselMapWidget> {
  VesselModel? _selectedVessel;
  bool _showVesselList = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VesselCubit, VesselState>(
      builder: (context, state) {
        return Stack(
          children: [
            // 메인 지도 영역
            _buildMapArea(state),

            // 상단 컨트롤 패널
            _buildTopControls(state),

            // 선박 목록 패널 (슬라이딩)
            if (_showVesselList) _buildVesselListPanel(state),

            // 선택된 선박 정보 패널
            if (_selectedVessel != null) _buildVesselInfoPanel(),

            // 로딩 인디케이터
            if (state.isLoading) _buildLoadingOverlay(),
          ],
        );
      },
    );
  }

  /// 메인 지도 영역 빌드
  Widget _buildMapArea(VesselState state) {
    if (state.errorMessage.isNotEmpty) {
      return _buildErrorWidget(state.errorMessage, () {
        context.read<VesselCubit>().loadVesselList();
      });
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sky1,
            Color(0xFFE3F2FD),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 지도 배경 (격자 패턴)
          _buildMapBackground(),

          // 선박 아이콘들
          ...state.vessels.map((vessel) => _buildVesselMarker(vessel)),

          // 중앙 십자선
          _buildCenterCrosshair(),
        ],
      ),
    );
  }

  /// 지도 배경 (격자 패턴) 빌드
  Widget _buildMapBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: MapGridPainter(),
    );
  }

  /// 선박 마커 빌드
  Widget _buildVesselMarker(VesselModel vessel) {
    if (vessel.latitude == null || vessel.longitude == null) return const SizedBox.shrink();

    // 화면 좌표로 변환 (임시 계산)
    final screenX = (vessel.longitude! + 180) / 360 * MediaQuery.of(context).size.width;
    final screenY = (90 - vessel.latitude!) / 180 * MediaQuery.of(context).size.height;

    return Positioned(
      left: screenX - 15,
      top: screenY - 15,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedVessel = vessel;
          });
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: vessel.isMoving ? AppColors.green1 : AppColors.gray2,
            shape: BoxShape.circle,
            border: Border.all(
              color: _selectedVessel?.mmsi == vessel.mmsi
                  ? AppColors.yellow1
                  : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.sailing,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 중앙 십자선 빌드
  Widget _buildCenterCrosshair() {
    return const Center(
      child: Icon(
        Icons.add,
        size: 20,
        color: AppColors.gray6,
      ),
    );
  }

  /// 상단 컨트롤 패널 빌드
  Widget _buildTopControls(VesselState state) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // 선박 목록 토글 버튼
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showVesselList = !_showVesselList;
                });
              },
              icon: Icon(
                _showVesselList ? Icons.close : Icons.list,
                color: AppColors.sky3,
              ),
              tooltip: '선박 목록',
            ),
          ),

          const SizedBox(width: 8),

          // 선박 수 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '선박 ${state.vessels.length}척',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sky3,
              ),
            ),
          ),

          const Spacer(),

          // 새로고침 버튼
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                context.read<VesselCubit>().loadVesselList();
              },
              icon: const Icon(
                Icons.refresh,
                color: AppColors.sky3,
              ),
              tooltip: '새로고침',
            ),
          ),
        ],
      ),
    );
  }

  /// 선박 목록 패널 빌드
  Widget _buildVesselListPanel(VesselState state) {
    return Positioned(
      top: 80,
      left: 16,
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.sky3,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sailing, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    '선박 목록',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showVesselList = false;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            // 선박 목록
            Expanded(
              child: state.vessels.isEmpty
                  ? const Center(
                child: Text(
                  '선박이 없습니다',
                  style: TextStyle(color: AppColors.gray2),
                ),
              )
                  : ListView.builder(
                itemCount: state.vessels.length,
                itemBuilder: (context, index) {
                  final vessel = state.vessels[index];
                  return _buildVesselListItem(vessel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 선박 목록 아이템 빌드
  Widget _buildVesselListItem(VesselModel vessel) {
    final isSelected = _selectedVessel?.mmsi == vessel.mmsi;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.sky1 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: vessel.isMoving ? AppColors.green1 : AppColors.gray2,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          vessel.shipName ?? 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MMSI: ${vessel.mmsi}',
              style: const TextStyle(fontSize: 12),
            ),
            if (vessel.speedOverGround != null)
              Text(
                '속도: ${vessel.speedOverGround!.toStringAsFixed(1)} knots',
                style: const TextStyle(fontSize: 11, color: AppColors.gray2),
              ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedVessel = vessel;
            _showVesselList = false;
          });
        },
        dense: true,
      ),
    );
  }

  /// 선택된 선박 정보 패널 빌드
  Widget _buildVesselInfoPanel() {
    if (_selectedVessel == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _selectedVessel!.isMoving ? AppColors.green1 : AppColors.gray2,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedVessel!.shipName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedVessel = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'MMSI',
                    _selectedVessel!.mmsi?.toString() ?? '--',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '속도',
                    _selectedVessel!.speedOverGround != null
                        ? '${_selectedVessel!.speedOverGround!.toStringAsFixed(1)} knots'
                        : '--',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '방향',
                    _selectedVessel!.courseOverGround != null
                        ? '${_selectedVessel!.courseOverGround!.toStringAsFixed(0)}°'
                        : '--',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '목적지',
                    _selectedVessel!.destination ?? '--',
                  ),
                ),
              ],
            ),

            if (_selectedVessel!.latitude != null && _selectedVessel!.longitude != null) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                '위치',
                '${_selectedVessel!.latitude!.toStringAsFixed(4)}, ${_selectedVessel!.longitude!.toStringAsFixed(4)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 정보 아이템 빌드
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 로딩 오버레이 빌드
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('선박 정보를 불러오는 중...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 에러 위젯 빌드
  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.red1,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.red1),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sky3,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 지도 격자 패턴을 그리는 커스텀 페인터
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray4.withOpacity(0.3)
      ..strokeWidth = 1;

    const gridSize = 40.0;

    // 수직선 그리기
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 수평선 그리기
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}