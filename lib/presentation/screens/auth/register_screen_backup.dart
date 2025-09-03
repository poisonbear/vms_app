import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/presentation/screens/auth/register_complete_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/widgets/common/custom_app_bar.dart';
// showTopSnackBar는 common_widgets.dart에 정의되어 있음

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  // DioRequest 인스턴스 생성
  final DioRequest dioRequest = DioRequest();
  
  // API URLs from dotenv
  late final String apiUrl;
  late final String apisearchUrl;

  // 컨트롤러
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController mmsiController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailAddrController = TextEditingController();

  // 상태 변수
  int? isIdAvailable;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // .env에서 API URL 로드
    apiUrl = dotenv.env['kdn_insertMobileMembership_key'] ?? '';
    apisearchUrl = dotenv.env['kdn_usm_select_uuid_key'] ?? '';
    
    if (apiUrl.isEmpty || apisearchUrl.isEmpty) {
      AppLogger.e('API URLs not configured in .env');
    }
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    mmsiController.dispose();
    phoneController.dispose();
    emailController.dispose();
    emailAddrController.dispose();
    super.dispose();
  }

  /// 아이디 중복확인
  Future<void> searchForm() async {
    String id = idController.text;

    if (id.isEmpty) {
      showTopSnackBar(context, '아이디를 입력해주세요.');
      return;
    }

    if (!ValidationPatterns.isValidId(id)) {
      showTopSnackBar(context, '아이디 형식이 올바르지 않습니다.\n문자, 숫자 8~12자리로 입력해주세요.');
      return;
    }

    try {
      AppLogger.d('아이디 중복확인 시작: $id');
      
      Response response = await dioRequest.dio.post(
        apisearchUrl,
        data: {'user_id': id},
      );

      setState(() {
        // API 응답에 따른 처리 (0: 사용가능, 1: 사용중)
        if (response.data?['result'] == 0) {
          isIdAvailable = ValidationConstants.idAvailable;
          showTopSnackBar(context, '사용 가능한 아이디입니다.');
        } else {
          isIdAvailable = ValidationConstants.idNotAvailable;
          showTopSnackBar(context, '이미 사용 중인 아이디입니다.');
        }
      });
    } on DioException catch (e) {
      AppLogger.e('아이디 중복확인 오류: ${e.message}');
      if (e.response?.statusCode == 404) {
        showTopSnackBar(context, 'API 서버를 찾을 수 없습니다.\n관리자에게 문의하세요.');
      } else {
        showTopSnackBar(context, '중복확인 중 오류가 발생했습니다.');
      }
    } catch (e) {
      AppLogger.e('예상치 못한 오류: $e');
      showTopSnackBar(context, '중복확인 중 오류가 발생했습니다.');
    }
  }

  /// 회원가입 처리
  Future<void> onRegister() async {
    String id = idController.text;
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailAddrController.text;

    // 유효성 검증
    if (isIdAvailable != ValidationConstants.idAvailable) {
      showTopSnackBar(context, '아이디 중복확인을 해주세요.');
      return;
    }

    if (!ValidationPatterns.isValidPassword(password)) {
      showTopSnackBar(context, '비밀번호 형식이 올바르지 않습니다.');
      return;
    }

    if (!ValidationPatterns.isValidMmsi(mmsi)) {
      showTopSnackBar(context, 'MMSI 형식이 올바르지 않습니다.');
      return;
    }

    if (phone.isNotEmpty && !ValidationPatterns.isValidPhone(phone)) {
      showTopSnackBar(context, '휴대폰 번호 형식이 올바르지 않습니다.');
      return;
    }

    if (password != confirmPassword) {
      showTopSnackBar(context, '비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      // Firebase 사용자 생성
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: '$id@kdn.vms.com',  // 도메인 형식 유지
        password: password,
      );

      String uuid = userCredential.user!.uid;

      // 백엔드 API 호출
      Response response = await dioRequest.dio.post(
        apiUrl,
        data: {
          'user_id': id,
          'password': password,
          'mmsi': mmsi,
          'mphn_no': phone,
          'email_id': email,
          'email_addr': emailaddr,
          'uuid': uuid,
        },
      );

      if (response.data['result'] == 'success') {
        // 회원가입 완료 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterCompleteView(),
          ),
        );
      } else {
        // API 실패 시 Firebase 사용자 삭제
        await userCredential.user?.delete();
        showTopSnackBar(context, '회원가입에 실패했습니다. 다시 시도해주세요.');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase 오류: ${e.code}');
      switch (e.code) {
        case 'weak-password':
          showTopSnackBar(context, '비밀번호가 너무 약합니다.');
          break;
        case 'email-already-in-use':
          showTopSnackBar(context, '이미 사용 중인 계정입니다.');
          break;
        default:
          showTopSnackBar(context, '회원가입 중 오류가 발생했습니다.');
      }
    } on DioException catch (e) {
      // API 오류 시 Firebase 사용자 삭제
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      
      AppLogger.e('API 오류: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        showTopSnackBar(context, 'API 서버를 찾을 수 없습니다.\n관리자에게 문의하세요.');
      } else {
        showTopSnackBar(context, '회원가입 처리 중 오류가 발생했습니다.');
      }
    } catch (e) {
      AppLogger.e('회원가입 오류: $e');
      showTopSnackBar(context, '회원가입 중 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColorwhite_type1(),
      appBar: AppBar(
        title: const AppBarLayerView('회원가입'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 진행 단계 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(1, '약관동의', false),
                  _buildStepConnector(),
                  _buildStepIndicator(2, '정보입력', true),
                  _buildStepConnector(),
                  _buildStepIndicator(3, '가입완료', false),
                ],
              ),
              const SizedBox(height: 30),

              // 타이틀
              TextWidgetString(
                'K-VMS',
                getTextcenter(),
                24,
                getText700(),
                getColorblack_type2(),
              ),
              const SizedBox(height: 8),
              TextWidgetString(
                '회원정보를 입력해주세요',
                getTextcenter(),
                14,
                getText400(),
                getColorgray_Type2(),
              ),
              const SizedBox(height: 30),

              // 아이디 입력
              _buildInputSection(
                label: '아이디',
                isRequired: true,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: idController,
                        hintText: '아이디를 입력하세요',
                        enabled: isIdAvailable != ValidationConstants.idAvailable,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isIdAvailable != ValidationConstants.idAvailable
                            ? searchForm
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColorsky_Type2(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '중복확인',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: getText600(),
                            color: getColorwhite_type1(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isIdAvailable != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        isIdAvailable == ValidationConstants.idAvailable
                            ? Icons.check_circle
                            : Icons.error,
                        size: 16,
                        color: isIdAvailable == ValidationConstants.idAvailable
                            ? Colors.green
                            : getColorred_type1(),
                      ),
                      const SizedBox(width: 4),
                      TextWidgetString(
                        isIdAvailable == ValidationConstants.idAvailable
                            ? '사용 가능한 아이디입니다'
                            : '이미 사용 중인 아이디입니다',
                        getTextleft(),
                        12,
                        getText400(),
                        isIdAvailable == ValidationConstants.idAvailable
                            ? Colors.green
                            : getColorred_type1(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // 비밀번호 입력
              _buildInputSection(
                label: '비밀번호',
                isRequired: true,
                child: _buildTextField(
                  controller: passwordController,
                  hintText: '비밀번호를 입력하세요',
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: getColorgray_Type2(),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 비밀번호 확인
              _buildInputSection(
                label: '비밀번호 확인',
                isRequired: true,
                child: _buildTextField(
                  controller: confirmPasswordController,
                  hintText: '비밀번호를 다시 입력하세요',
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: getColorgray_Type2(),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // MMSI 입력
              _buildInputSection(
                label: 'MMSI',
                isRequired: true,
                child: _buildTextField(
                  controller: mmsiController,
                  hintText: 'MMSI를 입력하세요',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 20),

              // 휴대폰 번호
              _buildInputSection(
                label: '휴대폰 번호',
                isRequired: false,
                child: _buildTextField(
                  controller: phoneController,
                  hintText: '휴대폰 번호를 입력하세요',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 20),

              // 이메일
              _buildInputSection(
                label: '이메일',
                isRequired: false,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: emailController,
                        hintText: '이메일',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextWidgetString(
                        '@',
                        getTextcenter(),
                        16,
                        getText400(),
                        getColorblack_type2(),
                      ),
                    ),
                    Expanded(
                      child: _buildTextField(
                        controller: emailAddrController,
                        hintText: 'naver.com',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColorsky_Type2(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: getText700(),
                      color: getColorwhite_type1(),
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

  // 단계 표시기
  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? getColorsky_Type2() : getColorgray_Type3(),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 16,
                fontWeight: getText600(),
                color: getColorwhite_type1(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextWidgetString(
          label,
          getTextcenter(),
          12,
          getText400(),
          isActive ? getColorblack_type2() : getColorgray_Type2(),
        ),
      ],
    );
  }

  // 단계 연결선
  Widget _buildStepConnector() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: getColorgray_Type3(),
    );
  }

  // 입력 섹션
  Widget _buildInputSection({
    required String label,
    required bool isRequired,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextWidgetString(
              label,
              getTextleft(),
              14,
              getText700(),
              getColorblack_type2(),
            ),
            const SizedBox(width: 4),
            TextWidgetString(
              isRequired ? '(필수)' : '(선택)',
              getTextleft(),
              12,
              getText400(),
              isRequired ? getColorred_type1() : getColorgray_Type2(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // 텍스트 필드
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        fontSize: 14,
        color: getColorblack_type2(),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: getColorgray_Type2(),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? getColorwhite_type1() : getColorgray_Type3().withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: getColorgray_Type3()),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: getColorgray_Type3()),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: getColorsky_Type2(), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: getColorgray_Type3()),
        ),
      ),
    );
  }
}

// 임시 해결책: 클래스 별칭 생성 (IDE 인식 문제 해결용)
class RegisterScreen extends Membershipview {
  const RegisterScreen({super.key, required DateTime nowTime}) 
    : super(nowTime: nowTime);
}
