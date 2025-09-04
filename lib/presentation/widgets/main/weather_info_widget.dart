import 'package:flutter/material.dart';

class WeatherInfoWidget extends StatelessWidget {
  final bool isWaveSelected;
  final bool isVisibilitySelected;
  final ValueChanged<bool> onWaveChanged;
  final ValueChanged<bool> onVisibilityChanged;
  
  const WeatherInfoWidget({
    super.key,
    required this.isWaveSelected,
    required this.isVisibilitySelected,
    required this.onWaveChanged,
    required this.onVisibilityChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      top: MediaQuery.of(context).padding.top + 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '날씨 정보',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildWeatherOption(
                  label: '파고',
                  value: isWaveSelected,
                  onChanged: onWaveChanged,
                ),
                const SizedBox(width: 16),
                _buildWeatherOption(
                  label: '시정',
                  value: isVisibilitySelected,
                  onChanged: onVisibilityChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeatherOption({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
