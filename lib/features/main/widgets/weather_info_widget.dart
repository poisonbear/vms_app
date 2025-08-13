import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../navigation/cubit/navigation_cubit.dart';
import '../../weather/models/weather_model.dart';
import 'dart:math' as math;

/// 기상 정보 위젯
class WeatherInfoWidget extends StatefulWidget {
  const WeatherInfoWidget({super.key});

  @override
  State<WeatherInfoWidget> createState() => _WeatherInfoWidgetState();
}

class _WeatherInfoWidgetState extends State<WeatherInfoWidget>
    with TickerProviderStateMixin {
  late AnimationController _refreshAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            _refreshAnimationController.forward().then((_) {
              _refreshAnimationController.reset();
            });
            context.read<NavigationCubit>().loadWeatherInfo();
            context.read<NavigationCubit>().loadWeatherList();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 현재 기상 정보 섹션
                _buildCurrentWeatherSection(state),

                const SizedBox(height: 16),

                // 기상 경보 섹션
                _buildWeatherAlertsSection(state),

                const SizedBox(height: 16),

                // 상세 기상 정보 섹션
                _buildDetailedWeatherSection(state),

                const SizedBox(height: 16),

                // 기상 이력 섹션
                _buildWeatherHistorySection(state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 현재 기상 정보 섹션 빌드
  Widget _buildCurrentWeatherSection(NavigationState state) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.sky3,
              AppColors.sky2,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.cloud_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '현재 해상 기상',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _refreshAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshAnimationController.value * 2 * 3.14159,
                        child: IconButton(
                          onPressed: () {
                            _refreshAnimationController.forward().then((_) {
                              _refreshAnimationController.reset();
                            });
                            context.read<NavigationCubit>().loadWeatherInfo();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildWeatherCard(
                      title: '파고',
                      value: state.weatherInfo?.wave != null
                          ? '${state.weatherInfo!.wave.toStringAsFixed(1)} m'
                          : '--',
                      icon: Icons.waves,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildWeatherCard(
                      title: '시정',
                      value: state.weatherInfo?.visibility != null
                          ? '${state.weatherInfo!.visibility.toStringAsFixed(1)} km'
                          : '--',
                      icon: Icons.visibility,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '마지막 업데이트: ${DateTime.now().toString().substring(0, 16)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 기상 경보 섹션 빌드
  Widget _buildWeatherAlertsSection(NavigationState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: AppColors.yellow2, size: 24),
                SizedBox(width: 12),
                Text(
                  '기상 경보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.weatherInfo != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildAlertCard(
                      '파고 경보',
                      _getWaveAlertLevel(state.weatherInfo!),
                      _getWaveAlertColor(state.weatherInfo!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAlertCard(
                      '시정 경보',
                      _getVisibilityAlertLevel(state.weatherInfo!),
                      _getVisibilityAlertColor(state.weatherInfo!),
                    ),
                  ),
                ],
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    '기상 경보 정보를 불러오는 중...',
                    style: TextStyle(color: AppColors.gray2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 상세 기상 정보 섹션 빌드
  Widget _buildDetailedWeatherSection(NavigationState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.sky3, size: 24),
                SizedBox(width: 12),
                Text(
                  '상세 기상 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.weatherInfo != null) ...[
              _buildDetailInfoGrid(state.weatherInfo!),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 기상 이력 섹션 빌드
  Widget _buildWeatherHistorySection(NavigationState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.sky3, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '기상 이력',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black2,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.sky3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      context.read<NavigationCubit>().loadWeatherList();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                    label: const Text(
                      '새로고침',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.isLoadingWeather)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.weatherList.isEmpty)
              _buildEmptyWeatherWidget()
            else
              _buildWeatherHistoryList(state.weatherList),
          ],
        ),
      ),
    );
  }

  /// 기상 카드 빌드
  Widget _buildWeatherCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 경보 카드 빌드
  Widget _buildAlertCard(String title, String level, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_outlined, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            level,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 상세 정보 그리드 빌드
  Widget _buildDetailInfoGrid(WeatherInfoModel weatherInfo) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildDetailInfoCard(
          '파고 A 경보',
          '${weatherInfo.walm1.toStringAsFixed(1)} m',
          Icons.waves,
          AppColors.green1,
        ),
        _buildDetailInfoCard(
          '파고 B 경보',
          '${weatherInfo.walm2.toStringAsFixed(1)} m',
          Icons.waves,
          AppColors.yellow2,
        ),
        _buildDetailInfoCard(
          '시정 A 경보',
          '${weatherInfo.valm1.toStringAsFixed(1)} km',
          Icons.visibility,
          AppColors.green1,
        ),
        _buildDetailInfoCard(
          '시정 B 경보',
          '${weatherInfo.valm2.toStringAsFixed(1)} km',
          Icons.visibility,
          AppColors.yellow2,
        ),
      ],
    );
  }

  /// 상세 정보 카드 빌드
  Widget _buildDetailInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.gray2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 기상 이력 목록 빌드
  Widget _buildWeatherHistoryList(List<WeatherModel> weatherList) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weatherList.length.clamp(0, 10), // 최대 10개만 표시
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final weather = weatherList[index];
        return _buildWeatherHistoryItem(weather);
      },
    );
  }

  /// 기상 이력 아이템 빌드
  Widget _buildWeatherHistoryItem(WeatherModel weather) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTemperatureColor(weather.currentTemp).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getWeatherIcon(weather.weatherCondition),
          color: _getTemperatureColor(weather.currentTemp),
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            weather.currentTemp != null
                ? '${weather.currentTemp!.toStringAsFixed(1)}°C'
                : '--°C',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              weather.weatherCondition ?? 'Unknown',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (weather.windUSurface != null || weather.windVSurface != null)
            Text(
              '바람: ${_calculateWindSpeed(weather.windUSurface, weather.windVSurface).toStringAsFixed(1)} m/s',
              style: const TextStyle(fontSize: 12),
            ),
          const Spacer(),
          if (weather.waveHeight != null)
            Text(
              '파고: ${weather.waveHeight!.toStringAsFixed(1)}m',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sky3,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatWeatherTime(weather.ts),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray2,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.sky1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '기록',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.sky3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      onTap: () => _showWeatherDetail(weather),
    );
  }

  /// 빈 기상 위젯 빌드
  Widget _buildEmptyWeatherWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Icon(
            Icons.cloud_off,
            size: 48,
            color: AppColors.gray2,
          ),
          SizedBox(height: 12),
          Text(
            '기상 정보가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray2,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '새로고침 버튼을 눌러 다시 시도해보세요',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray6,
            ),
          ),
        ],
      ),
    );
  }

  /// 기상 상세 정보 표시
  void _showWeatherDetail(WeatherModel weather) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기상 상세 정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWeatherDetailRow('기상 상태', weather.weatherCondition ?? 'Unknown'),
              _buildWeatherDetailRow(
                '온도',
                weather.currentTemp != null ? '${weather.currentTemp!.toStringAsFixed(1)}°C' : '--',
              ),
              _buildWeatherDetailRow(
                '바람 속도',
                '${_calculateWindSpeed(weather.windUSurface, weather.windVSurface).toStringAsFixed(1)} m/s',
              ),
              if (weather.gustSurface != null)
                _buildWeatherDetailRow('돌풍', '${weather.gustSurface!.toStringAsFixed(1)} m/s'),
              if (weather.waveHeight != null)
                _buildWeatherDetailRow('파고', '${weather.waveHeight!.toStringAsFixed(1)} m'),
              if (weather.past3hPrecipSurface != null)
                _buildWeatherDetailRow('3시간 강수량', '${weather.past3hPrecipSurface!.toStringAsFixed(1)} mm'),
              _buildWeatherDetailRow('기록 시간', _formatWeatherTime(weather.ts)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 기상 상세 정보 행 빌드
  Widget _buildWeatherDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.gray2,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 파고 경보 레벨 가져오기
  String _getWaveAlertLevel(WeatherInfoModel weatherInfo) {
    final wave = weatherInfo.wave;
    if (wave >= weatherInfo.walm4) return '심각';
    if (wave >= weatherInfo.walm3) return '경고';
    if (wave >= weatherInfo.walm2) return '주의';
    if (wave >= weatherInfo.walm1) return '관심';
    return '정상';
  }

  /// 파고 경보 색상 가져오기
  Color _getWaveAlertColor(WeatherInfoModel weatherInfo) {
    final wave = weatherInfo.wave;
    if (wave >= weatherInfo.walm4) return AppColors.red1;
    if (wave >= weatherInfo.walm3) return AppColors.red2;
    if (wave >= weatherInfo.walm2) return AppColors.yellow2;
    if (wave >= weatherInfo.walm1) return AppColors.yellow1;
    return AppColors.green1;
  }

  /// 시정 경보 레벨 가져오기
  String _getVisibilityAlertLevel(WeatherInfoModel weatherInfo) {
    final visibility = weatherInfo.visibility;
    if (visibility <= weatherInfo.valm4) return '심각';
    if (visibility <= weatherInfo.valm3) return '경고';
    if (visibility <= weatherInfo.valm2) return '주의';
    if (visibility <= weatherInfo.valm1) return '관심';
    return '정상';
  }

  /// 시정 경보 색상 가져오기
  Color _getVisibilityAlertColor(WeatherInfoModel weatherInfo) {
    final visibility = weatherInfo.visibility;
    if (visibility <= weatherInfo.valm4) return AppColors.red1;
    if (visibility <= weatherInfo.valm3) return AppColors.red2;
    if (visibility <= weatherInfo.valm2) return AppColors.yellow2;
    if (visibility <= weatherInfo.valm1) return AppColors.yellow1;
    return AppColors.green1;
  }

  /// 온도 색상 가져오기
  Color _getTemperatureColor(double? temp) {
    if (temp == null) return AppColors.gray2;
    if (temp >= 30) return AppColors.red1;
    if (temp >= 20) return AppColors.yellow2;
    if (temp >= 10) return AppColors.green1;
    if (temp >= 0) return AppColors.sky3;
    return AppColors.sky2;
  }

  /// 기상 아이콘 가져오기
  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.help_outline;
    final lower = condition.toLowerCase();
    if (lower.contains('sun') || lower.contains('clear')) return Icons.wb_sunny;
    if (lower.contains('cloud')) return Icons.cloud;
    if (lower.contains('rain')) return Icons.umbrella;
    if (lower.contains('snow')) return Icons.ac_unit;
    if (lower.contains('storm')) return Icons.thunderstorm;
    if (lower.contains('fog') || lower.contains('mist')) return Icons.foggy;
    return Icons.wb_cloudy;
  }

  /// 바람 속도 계산
  double _calculateWindSpeed(double? u, double? v) {
    if (u == null || v == null) return 0.0;
    return (u * u + v * v).sqrt();
  }

  /// 기상 시간 포맷팅
  String _formatWeatherTime(DateTime? time) {
    if (time == null) return 'Unknown';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

extension NumExtension on num {
  double sqrt() => math.sqrt(this.toDouble());
}