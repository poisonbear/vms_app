import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
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
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController mmsiController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailaddrController = TextEditingController();

  // Focus nodes
  final FocusNode emailDomainFocusNode = FocusNode();

  // Validation states
  bool isIdValid = true;
  bool isValpw = true;
  bool isValnpw = true;
  bool isValcnpw = true;
  bool isValms = true;
  bool isValphone = true;
  bool isValemail = true;
  bool isValemailaddr = true;

  // UI states
  bool isLoading = false;
  bool isSubmitting = false;
  bool isDropdownOpened = false;

  // API URLs
  final String apiUrl = dotenv.env['kdn_usm_update_membership_key'] ?? '';
  final String userInfoUrl = dotenv.env['kdn_usm_select_member_info_data'] ?? '';
  final dioRequest = DioRequest();

  // Dropdown data
  List<String> items = ['naver.com', 'gmail.com', 'hanmail.net'];
  String? selectedValue;
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _setupListeners();
    loadUserInfo();
  }

  @override
  void dispose() {
    _removeListeners();
    _disposeControllers();
    super.dispose();
  }

  // ========================================
  // 초기화 및 정리 메서드 (구조적 개선)
  // ========================================

  void _initializeUserData() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final id = email.split('@')[0];
      idController.text = id;
    }
  }

  void _setupListeners() {
    idController.addListener(validateId);
    passwordController.addListener(_validatePasswords);
    newPasswordController.addListener(_validatePasswords);
    confirmPasswordController.addListener(_validatePasswords);
    mmsiController.addListener(validatems);
    phoneController.addListener(validatephone);
    emailController.addListener(validateemail);
    emailaddrController.addListener(validateemail);
  }

  void _removeListeners() {
    idController.removeListener(validateId);
    passwordController.removeListener(_validatePasswords);
    newPasswordController.removeListener(_validatePasswords);
    confirmPasswordController.removeListener(_validatePasswords);
    mmsiController.removeListener(validatems);
    phoneController.removeListener(validatephone);
    emailController.removeListener(validateemail);
    emailaddrController.removeListener(validateemail);
  }

  void _disposeControllers() {
    idController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    mmsiController.dispose();
    phoneController.dispose();
    emailController.dispose();
    emailaddrController.dispose();
    controller.dispose();
    emailDomainFocusNode.dispose();
  }

  // ========================================
  // 검증 로직 통합 (중복 제거)
  // ========================================

  bool _validatePassword(String password) {
    if (password.isEmpty) return true; // 빈 문자열은 입력 없음으로 처리

    bool hasMinLength = password.length >= 6 && password.length <= 12;
    bool hasLetter = ValidationRules.letterRegExp.hasMatch(password);
    bool hasNumber = ValidationRules.numberRegExp.hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasMinLength && hasLetter && hasNumber && hasSpecial;
  }

  void validateId() {
    if (!mounted) return;
    setState(() {
      isIdValid = ValidationRules.isValidId(idController.text);
    });
  }

  void _validatePasswords() {
    if (!mounted) return;
    setState(() {
      String pw = passwordController.text;
      String npw = newPasswordController.text;
      String cnpw = confirmPasswordController.text;

      isValpw = _validatePassword(pw);
      isValnpw = _validatePassword(npw);
      isValcnpw = _validatePassword(cnpw);
    });
  }

  void validatems() {
    if (!mounted) return;
    setState(() {
      isValms = ValidationRules.isValidMmsi(mmsiController.text);
    });
  }

  void validatephone() {
    if (!mounted) return;
    setState(() {
      isValphone = ValidationRules.isValidPhone(phoneController.text);
    });
  }

  void validateemail() {
    if (!mounted) return;
    setState(() {
      String email = emailController.text;
      String emailaddr = emailaddrController.text;
      isValemail = email.isNotEmpty;
      isValemailaddr = emailaddr.isNotEmpty;
    });
  }

  // ========================================
  // 데이터 로딩 (API 호출 방식 수정)
  // ========================================

  // 기존 회원정보 불러오기 (원본 API 호출 방식 복원)
  Future<void> loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.d('사용자가 로그인되어 있지 않습니다.');
        return;
      }

      final uuid = user.uid; // uuid 사용 (원본 방식)
      final firebaseToken = await user.getIdToken(); // firebaseToken 선언 추가

      if (userInfoUrl.isEmpty) {
        AppLogger.d('회원정보 조회 API URL이 설정되지 않았습니다.');
        return;
      }

      AppLogger.d('=== 회원정보 조회 시도 ===');
      AppLogger.d('API URL: $userInfoUrl');
      AppLogger.d('UUID: $uuid');

      // 원본 API 호출 방식 복원
      final response = await dioRequest.dio.post(
        userInfoUrl,
        data: {'uuid': uuid}, // 원본처럼 uuid만 전송
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken', // 이제 firebaseToken 사용 가능
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
      // 회원가입 시 입력한 핵심 정보만 처리
      AppLogger.d('서버에서 받은 회원정보: $data');

      // MMSI 정보
      if (data.containsKey('mmsi') && data['mmsi'] != null) {
        mmsiController.text = data['mmsi'].toString();
        AppLogger.d('MMSI 설정: ${data['mmsi']}');
      }

      // 휴대폰 번호
      if (data.containsKey('mphn_no') && data['mphn_no'] != null) {
        phoneController.text = data['mphn_no'].toString();
        AppLogger.d('휴대폰번호 설정: ${data['mphn_no']}');
      }

      // 이메일 정보 처리
      String emailId = '';
      String emailDomain = '';

      // 전체 이메일 주소 형태
      if (data.containsKey('email_addr') && data['email_addr'] != null && data['email_addr'].isNotEmpty) {
        final emailParts = data['email_addr'].toString().split('@');
        if (emailParts.length == 2) {
          emailId = emailParts[0];
          emailDomain = emailParts[1];
          AppLogger.d('이메일: $emailId@$emailDomain');
        }
      }

      // 분리된 이메일 ID
      if (data.containsKey('email_id') && data['email_id'] != null && data['email_id'].isNotEmpty) {
        emailId = data['email_id'].toString();
        AppLogger.d('이메일 ID: $emailId');
      }

      // 분리된 도메인
      if (data.containsKey('email_domain') && data['email_domain'] != null && data['email_domain'].isNotEmpty) {
        emailDomain = data['email_domain'].toString();
        AppLogger.d('이메일 도메인: $emailDomain');
      }

      emailController.text = emailId;
      emailaddrController.text = emailDomain;

      // 사용자 ID 동기화
      if (data.containsKey('user_id') && data['user_id'] != null) {
        final serverUserId = data['user_id'].toString();
        if (idController.text != serverUserId) {
          idController.text = serverUserId;
          AppLogger.d('사용자 ID 동기화: $serverUserId');
        }
      }

      AppLogger.d('폼 데이터 업데이트 완료');
    });
  }

  // ========================================
  // 폼 검증 로직 분리 (가독성 개선)
  // ========================================

  String? _validateFormData() {
    //// String id = idController.text; // unused - use directly
    String password = passwordController.text;
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    // 비밀번호 관련 검증
    final isChangingPassword = newPassword.isNotEmpty;
    final hasOldPassword = password.isNotEmpty;

    if (hasOldPassword && !isChangingPassword) {
      return '변경하실 새로운 비밀번호를 입력해주세요.';
    }

    if (isChangingPassword) {
      if (password.isEmpty) {
        return '기존 비밀번호를 입력해주세요.';
      }
      if (confirmPassword.isEmpty) {
        return '새로운 비밀번호 확인란을 입력해주세요.';
      }
      if (!isValpw) {
        return '기존 비밀번호 형식이 올바르지 않습니다.';
      }
      if (!isValnpw) {
        return '새로운 비밀번호 형식이 올바르지 않습니다.';
      }
      if (!isValcnpw) {
        return '새로운 비밀번호 확인 형식이 올바르지 않습니다.';
      }
      if (password == newPassword) {
        return '새로운 비밀번호가 기존 비밀번호와 동일합니다.';
      }
      if (newPassword != confirmPassword) {
        return '새로운 비밀번호가 일치하지 않습니다.';
      }
    }

    // MMSI 형식 검증
    if (mmsi.isNotEmpty && !isValms) {
      return '선박 MMSI 번호 형식이 올바르지 않거나\n 9자리에 벗어납니다.';
    }

    // 휴대폰 형식 검증
    if (phone.isNotEmpty && !isValphone) {
      return '휴대폰 번호 형식이 올바르지 않거나\n 11자리에 벗어납니다.';
    }

    // 수정할 데이터 확인
    bool isValidMmsi = mmsi.isNotEmpty && isValms;
    bool isValidPhone = phone.isNotEmpty && isValphone;
    bool isValidEmail = email.isNotEmpty && emailaddr.isNotEmpty;
    bool hasDataToUpdate = isChangingPassword || isValidMmsi || isValidPhone || isValidEmail;

    if (!hasDataToUpdate) {
      return '수정할 정보를 하나 이상 올바르게 입력해주세요.';
    }

    return null; // 검증 통과
  }

  // ========================================
  // API 호출 로직 분리 (Firebase 처리)
  // ========================================

  Future<void> _handleFirebasePasswordChange(User user, String currentPassword, String newPassword) async {
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    await user.reload();
  }

  Future<void> _updateServerProfile(User user, Map<String, dynamic> dataToSend, String? firebaseToken) async {
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

  // ========================================
  // 메인 제출 로직 (구조적 개선)
  // ========================================

  Future<void> submitForm() async {
    setState(() {
      isSubmitting = true;
    });

    // 폼 검증
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
      // 로딩 다이얼로그 표시
      if (mounted) {
        showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      }

      await _processProfileUpdate();

      // 성공 처리
      if (mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기
      showTopSnackBar(context, '회원정보가 성공적으로 수정되었습니다.');

      // 키보드와 포커스 완전 제거
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      FocusScope.of(context).unfocus();
      await Future.delayed(AppDurations.milliseconds100);

      if (mounted) Navigator.pop(context); // 회원정보수정 화면 닫기
    } catch (e) {
      if (mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기
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
    if (user == null || user.email == null) {
      throw Exception('로그인이 만료되었습니다. 다시 로그인해주세요.');
    }

    // 데이터 준비
    String password = passwordController.text;
    String newPassword = newPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    final isChangingPassword = newPassword.isNotEmpty;
    final firebaseToken = await user.getIdToken();
    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    // 서버 전송 데이터 구성
    final dataToSend = {
      'user_id': idController.text,
      if (isChangingPassword) 'user_pwd': password,
      if (isChangingPassword) 'user_npwd': newPassword,
      'mmsi': mmsi,
      'mphn_no': phone,
      'choice_time': widget.nowTime.toIso8601String(),
      if (email.isNotEmpty && emailaddr.isNotEmpty) 'email_addr': '${email.trim()}@${emailaddr.trim()}',
      'uuid': user.uid,
      'fcm_tkn': fcmToken,
    };

    // 서버 업데이트 먼저 시도 (firebaseToken 파라미터 추가)
    await _updateServerProfile(user, dataToSend, firebaseToken);

    // Firebase 비밀번호 변경 (서버 성공 후)
    if (isChangingPassword) {
      await _handleFirebasePasswordChange(user, password, newPassword);
    }
  }

  void _handleSubmitError(dynamic e) {
    String errorMessage;

    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 401) {
        errorMessage =
        responseData is Map && responseData['message'] != null ? responseData['message'] : '기존 비밀번호가 일치하지 않습니다.';
      } else {
        errorMessage = responseData is Map && responseData['message'] != null
            ? responseData['message']
            : statusCode == null
            ? '서버에 연결할 수 없습니다. 다시 시도해주세요.'
            : '처리 중 오류가 발생했습니다.';
      }
    } else {
      errorMessage = '에러 발생: $e';
    }

    showTopSnackBar(context, errorMessage);
  }

  // ========================================
  // UI 빌드 (기존 UI 완전 유지)
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const AppBarLayerView('회원정보수정'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSizes.s20,
            right: AppSizes.s20,
            top: AppSizes.s20,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: AppSizes.s40, bottom: AppSizes.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('아이디', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.s20),
                  child: inputWidget_deactivate(AppSizes.i266, AppSizes.i48, idController, '', AppColors.grayType7,
                      isReadOnly: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('기존 비밀번호', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.s13),
                  child: inputWidget(AppSizes.i266, AppSizes.i48, passwordController, '비밀번호', AppColors.grayType7,
                      obscureText: true),
                ),
              ),
              if (!isValpw && !isSubmitting)
                Padding(
                  padding: EdgeInsets.only(top: AppSizes.s0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidgetString('비밀번호는 문자, 숫자 및 특수문자를 포함한 6자리 이상 12자리 이하로 입력하여야 합니다.', TextAligns.left,
                          AppSizes.i12, FontWeights.w700, AppColors.redType3),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('새로운 비밀번호', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.s20),
                  child: inputWidget(AppSizes.i266, AppSizes.i48, newPasswordController, '비밀번호', AppColors.grayType7,
                      obscureText: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('새로운 비밀번호 확인', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.s20),
                  child: inputWidget(
                      AppSizes.i266, AppSizes.i48, confirmPasswordController, '비밀번호 확인', AppColors.grayType7,
                      obscureText: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.s8),
                child: TextWidgetString('선박 MMSI 번호', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.s20),
                  child: inputWidget(
                      AppSizes.i266, AppSizes.i48, mmsiController, 'MMSI 번호(숫자 9자리)를 입력해주세요', AppColors.grayType7),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.s8),
                child: TextWidgetString('휴대폰 번호', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.s20),
                  child:
                      inputWidget(AppSizes.i266, AppSizes.i48, phoneController, "'-' 구분없이 숫자만 입력", AppColors.grayType7),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('이메일', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.s20),
                child: Row(
                  children: [
                    Expanded(
                      child: inputWidget(
                        AppSizes.i133,
                        AppSizes.i48,
                        emailController,
                        '이메일 아이디 입력',
                        AppColors.grayType7,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.s4),
                      child: TextWidgetString('@', TextAligns.center, AppSizes.i16, FontWeights.w700, AppColors.grayType8),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            controller: emailaddrController,
                            focusNode: emailDomainFocusNode,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.whiteType1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                                borderSide: BorderSide(color: AppColors.grayType7, width: AppSizes.s1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                                borderSide: BorderSide(color: AppColors.grayType7, width: AppSizes.s1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                                borderSide: BorderSide(color: AppColors.grayType7, width: AppSizes.s1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: DesignConstants.spacing20, vertical: DesignConstants.spacing12),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: SvgPicture.asset(
                              'assets/kdn/usm/img/down_select_img.svg',
                              width: AppSizes.s24,
                              height: AppSizes.s24,
                            ),
                            color: Colors.white,
                            onSelected: (String value) {
                              setState(() {
                                selectedValue = value;
                                emailaddrController.text = value;
                                emailDomainFocusNode.unfocus();
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              return items.map((String value) {
                                return PopupMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: AppSizes.s20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyType2,
                      shape: Borders.rounded10,
                      elevation: 0,
                      padding: EdgeInsets.all(AppSizes.s18),
                    ),
                    child: TextWidgetString(
                      '회원정보수정 완료하기',
                      TextAligns.center,
                      AppSizes.i16,
                      FontWeights.w700,
                      AppColors.whiteType1,
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
}
