import 'package:flutter/material.dart';

class MapControlWidget extends StatelessWidget {
  final VoidCallback onLocationFocus;
  final VoidCallback onOtherVesselsToggle;
  final VoidCallback onTrackingToggle;
  final bool isOtherVesselsVisible;
  final bool isTrackingEnabled;

  const MapControlWidget({
    super.key,
    required this.onLocationFocus,
    required this.onOtherVesselsToggle,
    required this.onTrackingToggle,
    required this.isOtherVesselsVisible,
    required this.isTrackingEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          _buildControlButton(
            context: context,
            icon: Icons.my_location,
            onTap: onLocationFocus,
            isActive: false,
            tooltip: '내 위치',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            context: context,
            icon: Icons.directions_boat,
            onTap: onOtherVesselsToggle,
            isActive: isOtherVesselsVisible,
            tooltip: '다른 선박',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            context: context,
            icon: Icons.timeline,
            onTap: onTrackingToggle,
            isActive: isTrackingEnabled,
            tooltip: '항적 표시',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[700],
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}
