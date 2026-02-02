// lib/presentation/screens/auth/force_password_change_screen.dart

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/utils/password_utils.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/presentation/screens/main/main_screen.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class ForcePasswordChangeScreen extends StatefulWidget {
  final String username;

  const ForcePasswordChangeScreen({
    super.key,
    required this.username,
  });

  @override
  State<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String _passwordStrength = '';
  Color _passwordStrengthColor = AppColors.grayType2;
  bool _isPasswordMatching = false;

  final String apiUrl = ApiConfig.updateMember;
  final dioRequest = DioRequest();

  @override
  void initState() {
    super.initState();
    _setupPasswordListeners();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _setupPasswordListeners() {
    _newPasswordController.addListener(() {
      if (mounted) {
        setState(() {
          _checkPasswordStrength();
          _checkPasswordMatching();
        });
      }
    });

    _confirmPasswordController.addListener(() {
      if (mounted) {
        setState(() {
          _checkPasswordMatching();
        });
      }
    });
  }

  void _checkPasswordStrength() {
    final password = _newPasswordController.text;

    if (password.isEmpty) {
      _passwordStrength = '';
      _passwordStrengthColor = AppColors.grayType2;
      return;
    }

    int strength = 0;

    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    if (strength <= 2) {
      _passwordStrength = '약함';
      _passwordStrengthColor = AppColors.redType1;
    } else if (strength <= 4) {
      _passwordStrength = '보통';
      _passwordStrengthColor = Colors.orange;
    } else {
      _passwordStrength = '강함';
      _passwordStrengthColor = Colors.green;
    }
  }

  void _checkPasswordMatching() {
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _isPasswordMatching = false;
      return;
    }
    _isPasswordMatching =
        _newPasswordController.text == _confirmPasswordController.text;
  }

  String? _validatePassword() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      return '새 비밀번호를 입력해주세요.';
    }

    if (newPassword.length < ValidationRules.passwordMinLength ||
        newPassword.length > ValidationRules.passwordMaxLength) {
      return '비밀번호는 ${ValidationRules.passwordMinLength}~${ValidationRules.passwordMaxLength}자여야 합니다.';
    }

    if (newPassword == '0000' || newPassword == '000000') {
      return '임시 비밀번호와 다른 비밀번호를 사용해주세요.';
    }

    if (confirmPassword.isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }

    if (newPassword != confirmPassword) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null;
  }

  Future<void> _changePassword() async {
    final validationError = _validatePassword();
    if (validationError != null) {
      showTopSnackBar(context, validationError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showTopSnackBar(context, '로그인 정보가 없습니다. 다시 로그인해주세요.');
        return;
      }

      final newPassword = _newPasswordController.text;

      // 1. Firebase Auth 비밀번호 변경
      await user.updatePassword(newPassword);
      AppLogger.i('Firebase 비밀번호 변경 성공');

      // 2. 백엔드 API 비밀번호 변경
      final firebaseToken = await user.getIdToken();

      final response = await dioRequest.dio.post(
        apiUrl,
        data: {
          'user_id': widget.username,
          'user_pwd': '000000', // 기존 임시 비밀번호
          'user_npwd': PasswordUtils.hash(newPassword), // 새 비밀번호 (해싱)
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $firebaseToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.i('백엔드 비밀번호 변경 성공');

        if (mounted) {
          showTopSnackBar(context, '비밀번호가 변경되었습니다.');

          // 메인 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                username: widget.username,
                autoFocusLocation: true,
              ),
            ),
          );
        }
      } else {
        throw Exception('백엔드 비밀번호 변경 실패');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase 비밀번호 변경 실패', e);

      String errorMessage = '비밀번호 변경에 실패했습니다.';
      if (e.code == 'requires-recent-login') {
        errorMessage = '보안을 위해 다시 로그인해주세요.';
      }

      if (mounted) {
        showTopSnackBar(context, errorMessage);
      }
    } catch (e) {
      AppLogger.e('비밀번호 변경 오류', e);
      if (mounted) {
        showTopSnackBar(context, '비밀번호 변경에 실패했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteType1,
      appBar: AppBar(
        backgroundColor: AppColors.whiteType1,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(
            fontSize: DesignConstants.fontSizeL,
            fontWeight: FontWeights.w700,
            color: AppColors.grayType3,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 안내 문구
                Container(
                  padding: const EdgeInsets.all(AppSizes.s16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius:
                        BorderRadius.circular(DesignConstants.radiusM),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF9800),
                        size: AppSizes.s24,
                      ),
                      const SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: Text(
                          '임시 비밀번호로 로그인하셨습니다.\n보안을 위해 새 비밀번호를 설정해주세요.',
                          style: TextStyle(
                            fontSize: DesignConstants.fontSizeS,
                            fontWeight: FontWeights.w500,
                            color: AppColors.grayType3,
                            fontFamily: 'Pretendard',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.s32),

                // 새 비밀번호 입력
                _buildPasswordField(
                  label: '새 비밀번호',
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocusNode,
                  hintText:
                      '새 비밀번호 입력 (${ValidationRules.passwordMinLength}~${ValidationRules.passwordMaxLength}자)',
                  isVisible: _isNewPasswordVisible,
                  onToggleVisibility: () {
                    setState(
                        () => _isNewPasswordVisible = !_isNewPasswordVisible);
                  },
                  nextFocusNode: _confirmPasswordFocusNode,
                ),

                // 비밀번호 강도 표시
                if (_passwordStrength.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s8),
                  Row(
                    children: [
                      Text(
                        '비밀번호 강도: ',
                        style: TextStyle(
                          fontSize: DesignConstants.fontSizeXS,
                          fontWeight: FontWeights.w400,
                          color: AppColors.grayType7,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      Text(
                        _passwordStrength,
                        style: TextStyle(
                          fontSize: DesignConstants.fontSizeXS,
                          fontWeight: FontWeights.w600,
                          color: _passwordStrengthColor,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSizes.s20),

                // 비밀번호 확인 입력
                _buildPasswordField(
                  label: '비밀번호 확인',
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  hintText: '비밀번호 다시 입력',
                  isVisible: _isConfirmPasswordVisible,
                  onToggleVisibility: () {
                    setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                  },
                  textInputAction: TextInputAction.done,
                ),

                // 비밀번호 일치 여부
                if (_confirmPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s8),
                  Row(
                    children: [
                      Icon(
                        _isPasswordMatching ? Icons.check_circle : Icons.cancel,
                        size: AppSizes.s16,
                        color: _isPasswordMatching
                            ? Colors.green
                            : AppColors.redType1,
                      ),
                      const SizedBox(width: AppSizes.s4),
                      Text(
                        _isPasswordMatching
                            ? '비밀번호가 일치합니다.'
                            : '비밀번호가 일치하지 않습니다.',
                        style: TextStyle(
                          fontSize: DesignConstants.fontSizeXS,
                          fontWeight: FontWeights.w400,
                          color: _isPasswordMatching
                              ? Colors.green
                              : AppColors.redType1,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSizes.s40),

                // 변경하기 버튼
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    FocusNode? nextFocusNode,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: DesignConstants.fontSizeS,
                fontWeight: FontWeights.w600,
                color: AppColors.grayType3,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(width: AppSizes.s4),
            Container(
              width: AppSizes.s4,
              height: AppSizes.s4,
              decoration: const BoxDecoration(
                color: AppColors.redType1,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.whiteType1,
            borderRadius: BorderRadius.circular(DesignConstants.radiusM),
            border: Border.all(color: AppColors.grayType10),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !isVisible,
            textInputAction: textInputAction,
            onSubmitted: (_) {
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              }
            },
            style: const TextStyle(
              fontSize: DesignConstants.fontSizeS,
              color: AppColors.grayType8,
              fontFamily: 'Pretendard',
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s16,
                vertical: AppSizes.s14,
              ),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: DesignConstants.fontSizeS,
                color: AppColors.grayType7,
                fontFamily: 'Pretendard',
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.grayType7,
                        size: AppSizes.s20,
                      ),
                      onPressed: () {
                        setState(() {
                          controller.clear();
                        });
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.grayType7,
                      size: AppSizes.s20,
                    ),
                    onPressed: onToggleVisibility,
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: AppSizes.s56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(DesignConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: AppSizes.s12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _changePassword,
          borderRadius: BorderRadius.circular(DesignConstants.radiusL),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: AppSizes.s24,
                    height: AppSizes.s24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.whiteType1),
                    ),
                  )
                : const Text(
                    '비밀번호 변경',
                    style: TextStyle(
                      fontSize: DesignConstants.fontSizeM,
                      fontWeight: FontWeights.w700,
                      color: AppColors.whiteType1,
                      fontFamily: 'Pretendard',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
