// lib/features/main/widgets/navigation_info_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../navigation/cubit/navigation_cubit.dart';
import '../../navigation/models/navigation_history_model.dart';

/// 항행 정보 위젯
class NavigationInfoWidget extends StatefulWidget {
  const NavigationInfoWidget({super.key});

  @override
  State<NavigationInfoWidget> createState() => _NavigationInfoWidgetState();
}

class _NavigationInfoWidgetState extends State<NavigationInfoWidget>
    with TickerProviderStateMixin {
  late AnimationController _warningAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _warningAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _warningAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<NavigationCubit>().loadNavigationWarnings();
            context.read<NavigationCubit>().loadNavigationHistory();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 항행경보 섹션
                _buildNavigationWarningsSection(state),

                const SizedBox(height: 16),

                // 항행 이력 섹션
                _buildNavigationHistorySection(state),

                const SizedBox(height: 16),

                // 통계 섹션
                _buildStatisticsSection(state),

                const SizedBox(height: 16),

                // 빠른 액션 섹션
                _buildQuickActionsSection(state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 항행경보 섹션 빌드
  Widget _buildNavigationWarningsSection(NavigationState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.yellow1.withOpacity(0.1),
              AppColors.yellow2.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _warningAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_warningAnimationController.value * 0.1),
                        child: const Icon(
                          Icons.warning_amber_outlined,
                          color: AppColors.yellow2,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '항행경보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.navigationWarnings?.hasWarnings == true
                          ? AppColors.red1.withOpacity(0.2)
                          : AppColors.green1.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.navigationWarnings?.hasWarnings == true ? '경보' : '정상',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: state.navigationWarnings?.hasWarnings == true
                            ? AppColors.red1
                            : AppColors.green1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gray4),
                ),
                child: Text(
                  state.navigationWarnings?.combinedWarnings ?? '항행경보를 불러오는 중...',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '마지막 업데이트: ${DateTime.now().toString().substring(0, 16)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 항행 이력 섹션 빌드
  Widget _buildNavigationHistorySection(NavigationState state) {
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
                  '항행 이력',
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
                      _showHistorySearchDialog();
                    },
                    icon: const Icon(Icons.search, color: Colors.white, size: 16),
                    label: const Text(
                      '조회',
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
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.navigationHistory.isEmpty && state.isInitialized)
              _buildEmptyHistoryWidget()
            else if (state.navigationHistory.isEmpty)
                _buildInitialStateWidget()
              else
                _buildHistoryList(state.navigationHistory),
          ],
        ),
      ),
    );
  }

  /// 통계 섹션 빌드
  Widget _buildStatisticsSection(NavigationState state) {
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
                const Icon(Icons.analytics, color: AppColors.sky3, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '항행 통계',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '총 항행 기록',
                    '${state.navigationHistory.length}',
                    Icons.sailing,
                    AppColors.sky3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '고유 선박',
                    '${state.navigationHistory.map((h) => h.mmsi).toSet().length}',
                    Icons.directions_boat,
                    AppColors.green1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '최근 업데이트',
                    _getLastUpdateTime(state),
                    Icons.update,
                    AppColors.yellow2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '활성 경보',
                    state.navigationWarnings?.warnings.length.toString() ?? '0',
                    Icons.warning,
                    AppColors.red1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 빠른 액션 섹션 빌드
  Widget _buildQuickActionsSection(NavigationState state) {
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
                Icon(Icons.flash_on, color: AppColors.sky3, size: 24),
                SizedBox(width: 12),
                Text(
                  '빠른 작업',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionButton(
                  '실시간 추적',
                  Icons.gps_fixed,
                      () => _showFeatureNotReady('실시간 추적'),
                ),
                _buildQuickActionButton(
                  '항로 계획',
                  Icons.route,
                      () => _showFeatureNotReady('항로 계획'),
                ),
                _buildQuickActionButton(
                  '보고서 생성',
                  Icons.description,
                      () => _showFeatureNotReady('보고서 생성'),
                ),
                _buildQuickActionButton(
                  '경보 설정',
                  Icons.alarm,
                      () => _showFeatureNotReady('경보 설정'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 통계 카드 빌드
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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

  /// 빠른 액션 버튼 빌드
  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sky1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.sky3.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.sky3, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sky3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이력 목록 빌드
  Widget _buildHistoryList(List<NavigationHistoryModel> history) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length.clamp(0, 5), // 최대 5개만 표시
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryItem(item);
      },
    );
  }

  /// 이력 아이템 빌드
  Widget _buildHistoryItem(NavigationHistoryModel item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.sky1,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.directions_boat,
          color: AppColors.sky3,
          size: 20,
        ),
      ),
      title: Text(
        item.shipName ?? 'Unknown Ship',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MMSI: ${item.mmsi ?? 'Unknown'}',
            style: const TextStyle(fontSize: 12),
          ),
          if (item.psngAuth != null)
            Text(
              '승인: ${item.psngAuth}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.gray2,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(item.regDt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray2,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.green1.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '완료',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.green1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      onTap: () => _showHistoryDetail(item),
    );
  }

  /// 빈 이력 위젯 빌드
  Widget _buildEmptyHistoryWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.gray2,
          ),
          SizedBox(height: 12),
          Text(
            '항행 이력이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray2,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '조회 버튼을 눌러 검색해보세요',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray6,
            ),
          ),
        ],
      ),
    );
  }

  /// 초기 상태 위젯 빌드
  Widget _buildInitialStateWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: AppColors.sky3,
          ),
          SizedBox(height: 12),
          Text(
            '항행 이력 조회',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.sky3,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '조회 버튼을 눌러 항행 이력을 검색하세요',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 이력 검색 다이얼로그 표시
  void _showHistorySearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항행 이력 조회'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '선박명 (선택사항)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'MMSI (선택사항)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NavigationCubit>().loadNavigationHistory();
            },
            child: const Text('조회'),
          ),
        ],
      ),
    );
  }

  /// 이력 상세 표시
  void _showHistoryDetail(NavigationHistoryModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.shipName ?? 'Unknown Ship'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('MMSI', item.mmsi?.toString() ?? 'Unknown'),
            _buildDetailRow('선박 코드', item.shipKdn ?? 'Unknown'),
            _buildDetailRow('승인 상태', item.psngAuth ?? 'Unknown'),
            _buildDetailRow('등록일', _formatDate(item.regDt)),
          ],
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

  /// 상세 정보 행 빌드
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  /// 날짜 포맷팅
  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid';
    }
  }

  /// 마지막 업데이트 시간 가져오기
  String _getLastUpdateTime(NavigationState state) {
    if (state.navigationHistory.isEmpty) return '--';
    return DateTime.now().toString().substring(11, 16);
  }

  /// 기능 준비중 메시지 표시
  void _showFeatureNotReady(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능 준비중입니다.'),
        backgroundColor: AppColors.yellow2,
      ),
    );
  }
}