// lib/presentation/screens/profile/edit_profile_screen.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';

class MemberInformationChange extends StatefulWidget {
  final DateTime nowTime;

  const MemberInformationChange({super.key, required this.nowTime});

  @override
  State<MemberInformationChange> createState() => _MembershipviewState();
}

class _MembershipviewState extends State<MemberInformationChange> {
  // Controllers
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();
  final TextEditingController mmsiController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailaddrController = TextEditingController();

  // Focus nodes
  final FocusNode emailDomainFocusNode = FocusNode();

  // UI states
  bool isLoading = false;
  bool isSubmitting = false;

  // 비밀번호 표시 상태
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // API URLs
  final String apiUrl = ApiConfig.updateMember;
  final String userInfoUrl = ApiConfig.memberInfo;
  final dioRequest = DioRequest();

  // Dropdown data
  List<String> items = [
    'gmail.com',
    'naver.com',
    'hanmail.net',
    'daum.net',
    'nate.com'
  ];
  String selectedValue = 'gmail.com';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
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
    emailDomainFocusNode.dispose();
    super.dispose();
  }

  // ========================================
  // 사용자 정보 불러오기 (원본 방식)
  // ========================================
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
          AppLogger.d('⚠️ 잘못된 요청 (400): ${e.response?.data}');
        } else if (statusCode == 401) {
          AppLogger.d('⚠️ 인증 오류 (401): JWT 토큰 문제일 수 있습니다.');
        } else if (statusCode == 404) {
          AppLogger.d('⚠️ API 엔드포인트 404 오류: $userInfoUrl');
        }
      } else {
        AppLogger.d('일반 오류: $e');
      }

      AppLogger.d('빈 폼으로 계속 진행합니다.');
    }
  }

  void _updateFormWithUserData(Map<String, dynamic> data) {
    if (!mounted) return;
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
        final serverUserId =
        data['user_id'].toString().replaceAll('@kdn.vms.com', '');
        idController.text = serverUserId;
        AppLogger.d('사용자 ID 동기화: $serverUserId');
      }

      AppLogger.d('폼 데이터 업데이트 완료');
    });
  }

  // ========================================
  // 폼 검증 로직
  // ========================================
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
    if (phone.isEmpty) {
      return '휴대폰 번호를 입력해주세요.';
    }
    if (email.isEmpty || emailaddr.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    return null;
  }

  // ========================================
  // 제출 로직
  // ========================================
  Future<void> submitForm() async {
    setState(() {
      isSubmitting = true;
    });

    final validationError = _validateFormData();
    if (validationError != null) {
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

      if (mounted) Navigator.pop(context);
      showTopSnackBar(context, SuccessMessages.profileUpdated);

      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      FocusScope.of(context).unfocus();
      await Future.delayed(AppDurations.milliseconds100);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
    if (user == null) throw Exception('로그인이 만료되었습니다.');

    String password = passwordController.text;
    String newPassword = newPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    final isChangingPassword = newPassword.isNotEmpty;
    final firebaseToken = await user.getIdToken();
    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    final dataToSend = {
      'user_id': user.email,
      'mmsi': mmsi,
      'mphn_no': phone,
      'email_id': email,
      'email_domain': emailaddr,
      'fcm_token': fcmToken,
      if (isChangingPassword) ...{
        'old_password': password,
        'new_password': newPassword,
      }
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

    showTopSnackBar(context, errorMessage);
  }

  // ========================================
  // UI 빌드
  // ========================================
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
              // 헤더 카드
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
                      color: AppColors.primary.withOpacity(0.3),
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

              // 메인 폼
              Padding(
                padding: const EdgeInsets.all(AppSizes.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // 수정 1: 아이디 섹션 - 한줄 표시 (도메인 제거)
                    // ============================================
                    Container(
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSizes.s8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(DesignConstants.opacity10),
                                borderRadius: BorderRadius.circular(AppSizes.s8),
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
                                  borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                                  border: Border.all(color: AppColors.grayType10, width: 1.5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.s16, vertical: AppSizes.s14),
                                  child: Text(
                                    // Firebase의 email에서 도메인 제거하여 표시
                                    FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
                                        (idController.text.isNotEmpty ? idController.text : ''),
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

                    // 비밀번호 변경 섹션
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
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: AppSizes.s12),
                          _buildPasswordInput(
                            controller: newPasswordController,
                            label: '새 비밀번호',
                            hint: '새 비밀번호를 입력하세요',
                            isVisible: _isNewPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: AppSizes.s12),
                          _buildPasswordInput(
                            controller: confirmPasswordController,
                            label: '비밀번호 확인',
                            hint: '새 비밀번호를 다시 입력하세요',
                            isVisible: _isConfirmPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // 선박 정보 섹션
                    _buildSectionCard(
                      icon: Icons.directions_boat_outlined,
                      title: '선박 정보',
                      child: _buildInput(
                        controller: mmsiController,
                        label: 'MMSI',
                        hint: 'MMSI를 입력하세요',
                        keyboardType: TextInputType.number,
                      ),
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // 연락처 섹션
                    _buildSectionCard(
                      icon: Icons.phone_outlined,
                      title: '연락처',
                      child: _buildInput(
                        controller: phoneController,
                        label: '휴대폰 번호',
                        hint: '휴대폰 번호를 입력하세요',
                        keyboardType: TextInputType.phone,
                      ),
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // ============================================
                    // 수정 2: 이메일 섹션 - 도메인 라벨 길이 증가 (flex: 2 → 3)
                    // ============================================
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
                            flex: 3,  // 수정: 2에서 3으로 변경하여 도메인 라벨 길이 증가
                            child: _buildEmailDomainSelector(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.s32),

                    // 제출 버튼
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
                        .withOpacity(DesignConstants.opacity10),
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
            keyboardType: keyboardType,
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
            ),
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
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.grayType7,
                  size: AppSizes.s20,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
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
                  style: const TextStyle(
                    fontSize: DesignConstants.fontSizeS,
                    color: AppColors.grayType8,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.s16, vertical: AppSizes.s14),
                    border: InputBorder.none,
                    hintText: '직접 입력 또는 선택',
                    hintStyle: TextStyle(
                      fontSize: DesignConstants.fontSizeS,
                      color: AppColors.grayType7,
                    ),
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
                                ? AppColors.primary.withOpacity(0.1)
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
            color: AppColors.primary.withOpacity(0.4),
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