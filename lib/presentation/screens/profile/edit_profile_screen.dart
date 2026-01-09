// lib/presentation/screens/profile/edit_profile_screen.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/utils/password_utils.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class MemberInformationChange extends StatefulWidget {
  final DateTime nowTime;

  const MemberInformationChange({super.key, required this.nowTime});

  @override
  State<MemberInformationChange> createState() => _MembershipviewState();
}

class _MembershipviewState extends State<MemberInformationChange> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController mmsiController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailaddrController = TextEditingController();

  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode newPasswordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  final FocusNode mmsiFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode emailDomainFocusNode = FocusNode();

  bool isLoading = false;
  bool isSubmitting = false;

  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isPasswordMatching = false;
  String _passwordStrength = '';
  Color _passwordStrengthColor = AppColors.grayType2;

  final String apiUrl = ApiConfig.updateMember;
  final String userInfoUrl = ApiConfig.memberInfo;
  final dioRequest = DioRequest();

  List<String> items = ['gmail.com', 'naver.com', 'hanmail.net', 'nate.com'];
  String selectedValue = 'gmail.com';

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    loadUserInfo();
    _setupPasswordListeners();
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    mmsiController.dispose();
    phoneController.dispose();
    emailController.dispose();
    emailaddrController.dispose();

    passwordFocusNode.dispose();
    newPasswordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    mmsiFocusNode.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    emailDomainFocusNode.dispose();

    super.dispose();
  }

  void _initializeUserData() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final id = email.split('@')[0];
      idController.text = id;
    }
  }

  void _setupPasswordListeners() {
    newPasswordController.addListener(() {
      if (mounted) {
        setState(() {
          _checkPasswordStrength();
          _checkPasswordMatching();
        });
      }
    });

    confirmPasswordController.addListener(() {
      if (mounted) {
        setState(() {
          _checkPasswordMatching();
        });
      }
    });
  }

  void _checkPasswordStrength() {
    final password = newPasswordController.text;

    if (password.isEmpty) {
      _passwordStrength = '';
      _passwordStrengthColor = AppColors.grayType2;
      return;
    }

    int strength = 0;

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
    if (newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _isPasswordMatching = false;
      return;
    }

    _isPasswordMatching =
        newPasswordController.text == confirmPasswordController.text;
  }

  Future<void> loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.d('사용자가 로그인되어 있지 않습니다.');
        return;
      }

      final uuid = user.uid;
      final firebaseToken = await user.getIdToken();

      if (userInfoUrl.isEmpty) {
        AppLogger.d('회원정보 조회 API URL이 설정되지 않았습니다.');
        return;
      }

      AppLogger.d('=== 회원정보 조회 시도 ===');
      AppLogger.d('API URL: $userInfoUrl');
      AppLogger.d('UUID: $uuid');

      final response = await dioRequest.dio.post(
        userInfoUrl,
        data: {'uuid': uuid},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        }),
      );

      AppLogger.d('응답 상태코드: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          AppLogger.d('응답 필드: ${data.keys.join(', ')}');
          _updateFormWithUserData(data);
          AppLogger.d('=== 회원정보 로딩 성공 ===');
        } else if (data is List && data.isNotEmpty) {
          AppLogger.d('리스트 형태 응답, 첫 번째 항목 사용');
          _updateFormWithUserData(data[0]);
        }
      }
    } catch (e) {
      AppLogger.d('=== 회원정보 조회 실패 ===');

      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        AppLogger.d('Status Code: $statusCode');
        AppLogger.d('Request URL: ${e.requestOptions.uri}');
        AppLogger.d('Request Data: ${e.requestOptions.data}');

        if (e.response?.data != null) {
          AppLogger.d('서버 응답: ${e.response?.data}');
        }

        if (statusCode == 400) {
          AppLogger.d('잘못된 요청 (400): ${e.response?.data}');
        } else if (statusCode == 401) {
          AppLogger.d('인증 오류 (401): JWT 토큰 문제일 수 있습니다.');
        } else if (statusCode == 404) {
          AppLogger.d('API 엔드포인트 404 오류: $userInfoUrl');
        }
      } else {
        AppLogger.d('일반 오류: $e');
      }

      AppLogger.d('빈 폼으로 계속 진행합니다.');
    }
  }

  void _updateFormWithUserData(Map<String, dynamic> data) {
    if (!mounted) return;
    if (!context.mounted) return;
    setState(() {
      AppLogger.d('서버에서 받은 회원정보: $data');

      if (data.containsKey('mmsi') && data['mmsi'] != null) {
        mmsiController.text = data['mmsi'].toString();
        AppLogger.d('MMSI 설정: ${data['mmsi']}');
      }

      if (data.containsKey('mphn_no') && data['mphn_no'] != null) {
        phoneController.text = data['mphn_no'].toString();
        AppLogger.d('휴대폰번호 설정: ${data['mphn_no']}');
      }

      String emailId = '';
      String emailDomain = '';

      if (data.containsKey('email_addr') &&
          data['email_addr'] != null &&
          data['email_addr'].isNotEmpty) {
        final emailParts = data['email_addr'].toString().split('@');
        if (emailParts.length == 2) {
          emailId = emailParts[0];
          emailDomain = emailParts[1];
          AppLogger.d('이메일: $emailId@$emailDomain');
        }
      }

      if (data.containsKey('email_id') &&
          data['email_id'] != null &&
          data['email_id'].isNotEmpty) {
        emailId = data['email_id'].toString();
        AppLogger.d('이메일 ID: $emailId');
      }

      if (data.containsKey('email_domain') &&
          data['email_domain'] != null &&
          data['email_domain'].isNotEmpty) {
        emailDomain = data['email_domain'].toString();
        AppLogger.d('이메일 도메인: $emailDomain');
      }

      emailController.text = emailId;
      emailaddrController.text = emailDomain;
      if (emailDomain.isNotEmpty && items.contains(emailDomain)) {
        selectedValue = emailDomain;
      }

      if (data.containsKey('user_id') && data['user_id'] != null) {
        final serverUserId = data['user_id']
            .toString()
            .replaceAll(StringConstants.emailDomain, '');
        idController.text = serverUserId;
        AppLogger.d('사용자 ID 동기화: $serverUserId');
      }

      AppLogger.d('폼 데이터 업데이트 완료');
    });
  }

  String? _validateFormData() {
    String password = passwordController.text;
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    final isChangingPassword = newPassword.isNotEmpty;
    final hasOldPassword = password.isNotEmpty;

    if (hasOldPassword && !isChangingPassword) {
      return '변경하실 새로운 비밀번호를 입력해주세요.';
    }

    if (isChangingPassword) {
      if (!hasOldPassword) {
        return '현재 비밀번호를 입력해주세요.';
      }
      if (newPassword != confirmPassword) {
        return '새 비밀번호와 확인 비밀번호가 일치하지 않습니다.';
      }
      if (newPassword.length < 8) {
        return '비밀번호는 8자 이상이어야 합니다.';
      }
    }

    if (mmsi.isEmpty) {
      return 'MMSI를 입력해주세요.';
    }

    if (mmsi.length != ValidationRules.mmsiLength) {
      return 'MMSI는 ${ValidationRules.mmsiLength}자리 숫자여야 합니다.';
    }

    if (phone.isEmpty) {
      return '휴대폰 번호를 입력해주세요.';
    }

    if (phone.length != ValidationRules.phoneLength) {
      return '휴대폰 번호는 ${ValidationRules.phoneLength}자리 숫자여야 합니다.';
    }

    if (email.isEmpty || emailaddr.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    return null;
  }

  Future<void> submitForm() async {
    setState(() {
      isSubmitting = true;
    });

    final validationError = _validateFormData();

    if (validationError != null) {
      if (!mounted) {
        setState(() => isSubmitting = false);
        return;
      }
      if (!context.mounted) {
        setState(() => isSubmitting = false);
        return;
      }

      showTopSnackBar(context, validationError);
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      await _processProfileUpdate();

      if (!mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }
      if (!context.mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }

      if (mounted) Navigator.pop(context);

      if (!mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }
      if (!context.mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }

      showTopSnackBar(context, SuccessMessages.profileUpdated);

      await SystemChannels.textInput.invokeMethod('TextInput.hide');

      if (!mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }
      if (!context.mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }

      FocusScope.of(context).unfocus();
      await Future.delayed(AppDurations.milliseconds100);

      if (!mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }
      if (!context.mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }
      if (!context.mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }

      if (mounted) Navigator.pop(context);

      if (!mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }
      if (!context.mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
        return;
      }

      _handleSubmitError(e);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _processProfileUpdate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 만료되었습니다.');
    }

    String password = passwordController.text;
    String newPassword = newPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    final isChangingPassword = newPassword.isNotEmpty;
    final firebaseToken = await user.getIdToken();
    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    // 비밀번호 해싱 적용
    final dataToSend = {
      'user_id': idController.text,
      if (isChangingPassword)
        'user_pwd': PasswordUtils.hash(password), // 현재 비밀번호 해싱
      if (isChangingPassword)
        'user_npwd': PasswordUtils.hash(newPassword), // 새 비밀번호 해싱
      'mmsi': mmsi,
      'mphn_no': phone,
      'choice_time': widget.nowTime.toIso8601String(),
      if (email.isNotEmpty && emailaddr.isNotEmpty)
        'email_addr': '${email.trim()}@${emailaddr.trim()}',
      'uuid': user.uid,
      'fcm_tkn': fcmToken,
    };

    await _sendUpdateRequest(dataToSend, firebaseToken);
  }

  Future<void> _sendUpdateRequest(
      Map<String, dynamic> dataToSend, String? firebaseToken) async {
    if (firebaseToken == null) {
      throw Exception('인증 토큰을 가져올 수 없습니다.');
    }

    final response = await dioRequest.dio.post(
      apiUrl,
      data: dataToSend,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $firebaseToken',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('서버 처리 중 오류가 발생했습니다.');
    }
  }

  void _handleSubmitError(dynamic e) {
    String errorMessage;

    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 400) {
        errorMessage = responseData is Map && responseData['message'] != null
            ? responseData['message']
            : ErrorMessages.oldPasswordIncorrect;
      } else {
        errorMessage = responseData is Map && responseData['message'] != null
            ? responseData['message']
            : statusCode == null
                ? ErrorMessages.serverConnection
                : ErrorMessages.processingError;
      }
    } else {
      errorMessage = '${ErrorMessages.generalError}: $e';
    }

    if (!mounted) return;
    if (!context.mounted) return;

    showTopSnackBar(context, errorMessage);
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.s8),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.s16, color: color),
          const SizedBox(width: AppSizes.s8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: DesignConstants.fontSizeXS,
                color: color,
                fontWeight: FontWeights.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayType14,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.whiteType1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.grayType8, size: AppSizes.s20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '회원정보 수정',
          style: TextStyle(
            fontSize: DesignConstants.fontSizeL,
            fontWeight: FontWeights.w700,
            color: AppColors.grayType8,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: AppSizes.s20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s20, vertical: AppSizes.s10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.s8),
                        decoration: BoxDecoration(
                          color: AppColors.whiteOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: AppSizes.s20,
                          color: AppColors.whiteType1,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),
                      const Expanded(
                        child: Text(
                          '계정 정보를 안전하게 관리하세요',
                          style: TextStyle(
                            fontSize: DesignConstants.fontSizeXS,
                            fontWeight: FontWeights.w600,
                            color: AppColors.whiteType1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.whiteType1,
                        borderRadius:
                            BorderRadius.circular(DesignConstants.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blackOpacity(0.05),
                            blurRadius: DesignConstants.radiusM,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.s20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSizes.s8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                    alpha: DesignConstants.opacity10),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.s8),
                              ),
                              child: const Icon(
                                Icons.account_circle_outlined,
                                size: AppSizes.s20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSizes.s12),
                            const Text(
                              '아이디',
                              style: TextStyle(
                                fontSize: DesignConstants.fontSizeM,
                                fontWeight: FontWeights.w700,
                                color: AppColors.grayType8,
                              ),
                            ),
                            const SizedBox(width: AppSizes.s16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      DesignConstants.radiusM),
                                  border: Border.all(
                                      color: AppColors.grayType10, width: 1.5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.s16,
                                      vertical: AppSizes.s14),
                                  child: Text(
                                    FirebaseAuth.instance.currentUser?.email
                                            ?.split('@')[0] ??
                                        (idController.text.isNotEmpty
                                            ? idController.text
                                            : ''),
                                    style: const TextStyle(
                                      fontSize: DesignConstants.fontSizeS,
                                      color: Colors.black,
                                      fontWeight: FontWeights.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.s16),
                    _buildSectionCard(
                      icon: Icons.lock_outline,
                      title: '비밀번호 변경',
                      child: Column(
                        children: [
                          _buildPasswordInput(
                            controller: passwordController,
                            label: '현재 비밀번호',
                            hint: '현재 비밀번호를 입력하세요',
                            isVisible: _isPasswordVisible,
                            focusNode: passwordFocusNode,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            onSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(newPasswordFocusNode);
                            },
                          ),
                          const SizedBox(height: AppSizes.s12),
                          _buildPasswordInput(
                            controller: newPasswordController,
                            label: '새 비밀번호',
                            hint: '새 비밀번호를 입력하세요',
                            isVisible: _isNewPasswordVisible,
                            focusNode: newPasswordFocusNode,
                            onToggleVisibility: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                            onSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(confirmPasswordFocusNode);
                            },
                          ),
                          if (newPasswordController.text.isNotEmpty)
                            _buildStatusRow(
                              icon: Icons.security,
                              color: _passwordStrengthColor,
                              message: '비밀번호 강도: $_passwordStrength',
                            ),
                          const SizedBox(height: AppSizes.s12),
                          _buildPasswordInput(
                            controller: confirmPasswordController,
                            label: '비밀번호 확인',
                            hint: '새 비밀번호를 다시 입력하세요',
                            isVisible: _isConfirmPasswordVisible,
                            focusNode: confirmPasswordFocusNode,
                            onToggleVisibility: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                            onSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(mmsiFocusNode);
                            },
                          ),
                          if (confirmPasswordController.text.isNotEmpty)
                            _buildStatusRow(
                              icon: _isPasswordMatching
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _isPasswordMatching
                                  ? Colors.green
                                  : AppColors.redType1,
                              message: _isPasswordMatching
                                  ? '비밀번호가 일치합니다'
                                  : '비밀번호가 일치하지 않습니다',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s16),
                    _buildSectionCard(
                      icon: Icons.directions_boat_outlined,
                      title: '선박 정보',
                      child: Column(
                        children: [
                          _buildInput(
                            controller: mmsiController,
                            label: 'MMSI',
                            hint: 'MMSI를 입력하세요 (9자리 숫자)',
                            keyboardType: TextInputType.number,
                            focusNode: mmsiFocusNode,
                            maxLength: ValidationRules.mmsiLength,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            enabled: false,
                            onSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(phoneFocusNode);
                            },
                          ),
                          const SizedBox(height: AppSizes.s8),
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: AppSizes.s16,
                                color: AppColors.grayType7,
                              ),
                              SizedBox(width: AppSizes.s4),
                              Expanded(
                                child: Text(
                                  'MMSI는 변경할 수 없습니다.',
                                  style: TextStyle(
                                    fontSize: DesignConstants.fontSizeXS,
                                    color: AppColors.grayType7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s16),
                    _buildSectionCard(
                      icon: Icons.phone_outlined,
                      title: '연락처',
                      child: _buildInput(
                        controller: phoneController,
                        label: '휴대폰 번호',
                        hint: '휴대폰 번호를 입력하세요 (11자리 숫자)',
                        keyboardType: TextInputType.phone,
                        focusNode: phoneFocusNode,
                        maxLength: ValidationRules.phoneLength,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(emailFocusNode);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.s16),
                    _buildSectionCard(
                      icon: Icons.email_outlined,
                      title: '이메일',
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildInput(
                              controller: emailController,
                              label: '이메일',
                              hint: '이메일 입력',
                              keyboardType: TextInputType.emailAddress,
                              focusNode: emailFocusNode,
                              onSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(emailDomainFocusNode);
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.s8,
                                vertical: AppSizes.s24),
                            child: Text(
                              '@',
                              style: TextStyle(
                                fontSize: DesignConstants.fontSizeL,
                                fontWeight: FontWeights.w500,
                                color: AppColors.grayType3,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildEmailDomainSelector(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s32),
                    _buildSubmitButton(),
                    const SizedBox(height: AppSizes.s32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteType1,
        borderRadius: BorderRadius.circular(DesignConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity(0.05),
            blurRadius: DesignConstants.radiusM,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s8),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: DesignConstants.opacity10),
                    borderRadius: BorderRadius.circular(AppSizes.s8),
                  ),
                  child: Icon(
                    icon,
                    size: AppSizes.s20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: DesignConstants.fontSizeM,
                    fontWeight: FontWeights.w700,
                    color: AppColors.grayType8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignConstants.fontSizeS,
            fontWeight: FontWeights.w600,
            color: AppColors.grayType3,
          ),
        ),
        const SizedBox(height: AppSizes.s8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.whiteType1 : AppColors.grayType14,
            borderRadius: BorderRadius.circular(DesignConstants.radiusM),
            border: Border.all(
              color: enabled ? AppColors.grayType10 : AppColors.grayType12,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            focusNode: focusNode,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onSubmitted: onSubmitted,
            enabled: enabled,
            textInputAction: onSubmitted != null
                ? TextInputAction.next
                : TextInputAction.done,
            style: TextStyle(
              fontSize: DesignConstants.fontSizeS,
              color: enabled ? AppColors.grayType8 : AppColors.grayType7,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16, vertical: AppSizes.s14),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: DesignConstants.fontSizeS,
                color: AppColors.grayType7,
              ),
              counterText: '',
              suffixIcon: enabled && controller.text.isNotEmpty
                  ? IconButton(
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
                    )
                  : null,
            ),
            onChanged: (value) {
              if (enabled) {
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignConstants.fontSizeS,
            fontWeight: FontWeights.w600,
            color: AppColors.grayType3,
          ),
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
            obscureText: !isVisible,
            focusNode: focusNode,
            onSubmitted: onSubmitted,
            textInputAction: onSubmitted != null
                ? TextInputAction.next
                : TextInputAction.done,
            style: const TextStyle(
              fontSize: DesignConstants.fontSizeS,
              color: AppColors.grayType8,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16, vertical: AppSizes.s14),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: DesignConstants.fontSizeS,
                color: AppColors.grayType7,
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

  Widget _buildEmailDomainSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '도메인',
          style: TextStyle(
            fontSize: DesignConstants.fontSizeS,
            fontWeight: FontWeights.w600,
            color: AppColors.grayType3,
          ),
        ),
        const SizedBox(height: AppSizes.s8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.whiteType1,
            borderRadius: BorderRadius.circular(DesignConstants.radiusM),
            border: Border.all(color: AppColors.grayType10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: emailaddrController,
                  focusNode: emailDomainFocusNode,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: DesignConstants.fontSizeS,
                    color: AppColors.grayType8,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16, vertical: AppSizes.s14),
                    border: InputBorder.none,
                    hintText: '직접 입력 또는 선택',
                    hintStyle: const TextStyle(
                      fontSize: DesignConstants.fontSizeS,
                      color: AppColors.grayType7,
                    ),
                    suffixIcon: emailaddrController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.grayType7,
                              size: AppSizes.s20,
                            ),
                            onPressed: () {
                              setState(() {
                                emailaddrController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (items.contains(value)) {
                        selectedValue = value;
                      } else {
                        selectedValue = 'gmail.com';
                      }
                    });
                  },
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    color: AppColors.whiteType1,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignConstants.radiusM),
                      side: const BorderSide(color: AppColors.grayType10),
                    ),
                    elevation: 8,
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.grayType2,
                    size: AppSizes.s20,
                  ),
                  onSelected: (String value) {
                    setState(() {
                      selectedValue = value;
                      emailaddrController.text = value;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return items.map((String value) {
                      final isSelected = value == selectedValue;
                      return PopupMenuItem<String>(
                        value: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.transparent,
                            borderRadius: BorderRadius.circular(AppSizes.s6),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s12, vertical: AppSizes.s8),
                          child: Row(
                            children: [
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(right: AppSizes.s8),
                                  child: Icon(
                                    Icons.check,
                                    size: AppSizes.s16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: DesignConstants.fontSizeS,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.grayType8,
                                  fontWeight: isSelected
                                      ? FontWeights.w600
                                      : FontWeights.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
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
          onTap: isSubmitting ? null : submitForm,
          borderRadius: BorderRadius.circular(DesignConstants.radiusL),
          child: Center(
            child: isSubmitting
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
                    '수정 완료',
                    style: TextStyle(
                      fontSize: DesignConstants.fontSizeM,
                      fontWeight: FontWeights.w700,
                      color: AppColors.whiteType1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
