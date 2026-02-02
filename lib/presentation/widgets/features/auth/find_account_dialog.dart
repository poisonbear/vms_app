// lib/presentation/widgets/features/auth/find_account_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';

/// 아이디/비밀번호 찾기 다이얼로그
class FindAccountDialog extends StatefulWidget {
  const FindAccountDialog({super.key});

  /// 다이얼로그 표시
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FindAccountDialog(),
    );
  }

  @override
  State<FindAccountDialog> createState() => _FindAccountDialogState();
}

class _FindAccountDialogState extends State<FindAccountDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 컨트롤러
  final TextEditingController _mmsiController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwMmsiController = TextEditingController();

  bool _isLoading = false;
  final dioRequest = DioRequest();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _mmsiController.clear();
        _idController.clear();
        _pwMmsiController.clear();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mmsiController.dispose();
    _idController.dispose();
    _pwMmsiController.dispose();
    super.dispose();
  }

  // 아이디 찾기 API
  Future<void> _findUserId() async {
    if (_mmsiController.text.length != 9) {
      _showResultSnackBar('MMSI 9자리를 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await dioRequest.dio.post(
        ApiConfig.findUserIdByMmsi,
        data: {'mmsi': _mmsiController.text},
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['user_id'] != null) {
        _showResultDialog(
          icon: Icons.person_outline,
          title: '아이디 찾기 결과',
          label: '회원님의 아이디',
          value: response.data['user_id'],
        );
      } else {
        _showResultSnackBar(
          response.data['error'] ?? '등록된 회원 정보를 찾을 수 없습니다.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultSnackBar('서버 연결에 실패했습니다.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 비밀번호 초기화 API
  Future<void> _resetPassword() async {
    if (_idController.text.isEmpty) {
      _showResultSnackBar('아이디를 입력해주세요.', isError: true);
      return;
    }
    if (_pwMmsiController.text.length != 9) {
      _showResultSnackBar('MMSI 9자리를 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await dioRequest.dio.post(
        ApiConfig.resetPassword,
        data: {
          'user_id': _idController.text,
          'mmsi': _pwMmsiController.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['message'] != null) {
        Navigator.pop(context); // 다이얼로그 닫기
        _showResultSnackBar('비밀번호가 000000으로 초기화되었습니다.', isError: false);
      } else {
        _showResultSnackBar(
          response.data['error'] ?? '회원 정보를 찾을 수 없습니다.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultSnackBar('서버 연결에 실패했습니다.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResultSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.redType1 : AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.s8),
        ),
      ),
    );
  }

  void _showResultDialog({
    required IconData icon,
    required String title,
    required String label,
    required String value,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.s16),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.s20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s12),
              decoration: BoxDecoration(
                color: AppColors.blueNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.s12),
              ),
              child: Icon(
                icon,
                color: AppColors.blueNavy,
                size: AppSizes.s32,
              ),
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              title,
              style: const TextStyle(
                fontSize: DesignConstants.fontSizeL,
                fontWeight: FontWeights.w700,
                color: AppColors.blackType2,
              ),
            ),
            const SizedBox(height: AppSizes.s16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.s16),
              decoration: BoxDecoration(
                color: AppColors.grayType15,
                borderRadius: BorderRadius.circular(AppSizes.s12),
                border: Border.all(color: AppColors.grayType16),
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: DesignConstants.fontSizeS,
                      fontWeight: FontWeights.w500,
                      color: AppColors.grayType3,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: DesignConstants.fontSizeXXL,
                      fontWeight: FontWeights.w700,
                      color: AppColors.blueNavy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s20),
            SizedBox(
              width: double.infinity,
              height: AppSizes.s48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 결과 다이얼로그 닫기
                  Navigator.pop(context); // 찾기 다이얼로그 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.s10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: DesignConstants.fontSizeM,
                    fontWeight: FontWeights.w600,
                    color: AppColors.whiteType1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteType1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.s16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '아이디/비밀번호 찾기',
                    style: TextStyle(
                      fontSize: DesignConstants.fontSizeL,
                      fontWeight: FontWeights.w700,
                      color: AppColors.blackType2,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(AppSizes.s8),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSizes.s4),
                      child: Icon(
                        Icons.close,
                        size: AppSizes.s24,
                        color: AppColors.grayType3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.s16),

              // 탭
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grayType15,
                  borderRadius: BorderRadius.circular(AppSizes.s10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.blueNavy,
                    borderRadius: BorderRadius.circular(AppSizes.s8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(AppSizes.s4),
                  labelColor: AppColors.whiteType1,
                  unselectedLabelColor: AppColors.grayType3,
                  labelStyle: const TextStyle(
                    fontSize: DesignConstants.fontSizeS,
                    fontWeight: FontWeights.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '아이디 찾기'),
                    Tab(text: '비밀번호 찾기'),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.s20),

              // 탭 내용
              SizedBox(
                height: _tabController.index == 0 ? 160 : 260,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFindIdTab(),
                    _buildResetPasswordTab(),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // 버튼
              SizedBox(
                width: double.infinity,
                height: AppSizes.s48,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_tabController.index == 0) {
                            _findUserId();
                          } else {
                            _resetPassword();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueNavy,
                    disabledBackgroundColor: AppColors.grayType10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.s10),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: AppSizes.s20,
                          height: AppSizes.s20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.whiteType1,
                          ),
                        )
                      : Text(
                          _tabController.index == 0 ? '아이디 찾기' : '비밀번호 초기화',
                          style: const TextStyle(
                            fontSize: DesignConstants.fontSizeM,
                            fontWeight: FontWeights.w600,
                            color: AppColors.whiteType1,
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

  // 아이디 찾기 탭
  Widget _buildFindIdTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputCard(
          icon: Icons.directions_boat_outlined,
          label: 'MMSI 번호',
          hint: '9자리 숫자 입력',
          controller: _mmsiController,
          keyboardType: TextInputType.number,
          maxLength: 9,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
        ),
        const SizedBox(height: AppSizes.s12),
        Text(
          '회원가입 시 등록한 MMSI 번호를 입력해주세요.',
          style: TextStyle(
            fontSize: DesignConstants.fontSizeXS,
            color: AppColors.grayType6,
          ),
        ),
      ],
    );
  }

  // 비밀번호 찾기 탭
  Widget _buildResetPasswordTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputCard(
          icon: Icons.person_outline,
          label: '아이디',
          hint: '아이디 입력',
          controller: _idController,
        ),
        const SizedBox(height: AppSizes.s12),
        _buildInputCard(
          icon: Icons.directions_boat_outlined,
          label: 'MMSI 번호',
          hint: '9자리 숫자 입력',
          controller: _pwMmsiController,
          keyboardType: TextInputType.number,
          maxLength: 9,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
        ),
        const SizedBox(height: AppSizes.s12),
        Container(
          padding: const EdgeInsets.all(AppSizes.s12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(AppSizes.s8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: AppSizes.s16,
                color: Color(0xFFFF9800),
              ),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  '비밀번호가 000000으로 초기화됩니다.',
                  style: TextStyle(
                    fontSize: DesignConstants.fontSizeXS,
                    color: AppColors.grayType3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // VesselInfoCard 스타일 입력 필드
  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: BoxDecoration(
        color: AppColors.grayType15,
        borderRadius: BorderRadius.circular(AppSizes.s12),
        border: Border.all(color: AppColors.grayType16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.s8),
            decoration: BoxDecoration(
              color: AppColors.blueNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.s8),
            ),
            child: Icon(
              icon,
              color: AppColors.blueNavy,
              size: AppSizes.s18,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: DesignConstants.fontSizeXS,
                    fontWeight: FontWeights.w500,
                    color: AppColors.grayType3,
                  ),
                ),
                SizedBox(
                  height: AppSizes.s28,
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLength: maxLength,
                    inputFormatters: inputFormatters,
                    style: const TextStyle(
                      fontSize: DesignConstants.fontSizeM,
                      fontWeight: FontWeights.w600,
                      color: AppColors.blackType2,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: DesignConstants.fontSizeM,
                        fontWeight: FontWeights.w400,
                        color: AppColors.grayType7,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: () {
                controller.clear();
                setState(() {});
              },
              borderRadius: BorderRadius.circular(AppSizes.s6),
              child: const Padding(
                padding: EdgeInsets.all(AppSizes.s4),
                child: Icon(
                  Icons.clear,
                  size: AppSizes.s18,
                  color: AppColors.grayType6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
