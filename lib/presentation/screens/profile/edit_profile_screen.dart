import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';
import 'package:vms_app/presentation/widgets/common/custom_app_bar.dart';

class MemberInformationChange extends StatefulWidget {
  final DateTime nowTime;

  const MemberInformationChange({super.key, required this.nowTime});

  @override
  State<MemberInformationChange> createState() => _MembershipviewState();
}

class _MembershipviewState extends State<MemberInformationChange> {
  final TextEditingController idController = TextEditingController(); // 아이디 입력값
  final TextEditingController passwordController = TextEditingController(); // 기존 비밀번호 입력값
  final TextEditingController newPasswordController = TextEditingController(); // 새로운 비밀번호 입력값
  final TextEditingController confirmPasswordController =
      TextEditingController(); // 새로운 비밀번호 확인 입력값
  final TextEditingController mmsiController = TextEditingController(); // mmsi 번호 입력값
  final TextEditingController phoneController = TextEditingController(); // 휴대폰 번호 입력값
  final TextEditingController emailController = TextEditingController(); // 이메일 입력값
  final TextEditingController emailaddrController =
      TextEditingController(); // 이메일 주소 입력값  naver.com , google.com 등등

  final FocusNode emailDomainFocusNode = FocusNode(); //focus 강제 저거

  bool isIdValid = true; // 아이디 상태값
  bool isValpw = true; // 기존 비밀번호 상태값
  bool isValnpw = true; // 새로운 비밀번호 상태값
  bool isValcnpw = true; // 새로운 비밀번호 확인 상태값
  bool isValms = true; // mmsi 상태값
  bool isValphone = true; // 휴대폰 번호 상태값
  bool isValemail = true; // 이메일 상태값
  bool isValemailaddr = true; // 이메일 주소 상태값

  bool isLoading = false; //회원정보 수정 중 로딩 상태 표시용
  bool isSubmitting = false; //버튼을 눌렀을 때만 경고 숨기기

  final String apiUrl = dotenv.env['kdn_usm_update_membership_key'] ?? ''; // 회원정보수정 완료하기 url
  final String userInfoUrl = dotenv.env['kdn_usm_select_member_info_data'] ?? ''; // 회원정보 수정 정보 가져오기
  final dioRequest = DioRequest();
  bool isDropdownOpened = false;

  List<String> items = ['naver.com', 'gmail.com', 'hanmail.net'];
  String? selectedValue;
  TextEditingController controller = TextEditingController(); // 이메일 주소 직접입력 시 이메일 주소 입력값

  // 시작
  // 이벤트 초기화
  @override
  void initState() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final id = email.split('@')[0];
      idController.text = id; // 아이디 입력칸에 자동 설정
    }
    super.initState();
    idController.addListener(validateId); // 기존 비밀번호 이벤트 초기화
    passwordController.addListener(validatepw); // 기존 비밀번호 이벤트 초기화
    newPasswordController.addListener(() => validateOnlyNew()); // 새로운 비밀번호 이벤트 초기화
    confirmPasswordController.addListener(() => validateOnlyNew()); // 새로운 비밀번호 확인 이벤트 초기화
    mmsiController.addListener(validatems); // mmsi 이벤트 초기화
    phoneController.addListener(validatephone); // 휴대폰 번호 이벤트 초기화
    emailController.addListener(validateemail); // 이메일 이벤트 초기화
    emailaddrController.addListener(validateemail); // 이메일 주소 이벤트 초기화

    loadUserInfo();
  }

  // 종료
  // 이벤트 초기화
  @override
  void dispose() {
    idController.removeListener(validateId); //  아이디 리스너 삭제
    idController.dispose(); //  아이디 컨트롤러 삭제
    passwordController.removeListener(validatepw); // 기존 비밀번호 리스너 삭제
    passwordController.dispose(); // 기존 비밀번호 컨트롤러 삭제
    newPasswordController.removeListener(() => validateOnlyNew()); // 새로운 비밀번호 리스너 삭제
    newPasswordController.dispose(); // 새로운 비밀번호 컨트롤러 삭제
    confirmPasswordController.removeListener(() => validateOnlyNew()); // 확인 비밀번호 리스너 삭제
    confirmPasswordController.dispose(); // 확인 비밀번호 컨트롤러 삭제
    mmsiController.dispose(); // mmsi 번호 컨트롤러 삭제
    mmsiController.removeListener(validatems); // mmsi 번호 리스너 삭제
    phoneController.dispose(); // 휴대폰 번호 컨트롤러 삭제
    phoneController.removeListener(validatephone); // 휴대폰 번호 리스너 삭제
    emailController.dispose(); // 이메일 컨트롤러 삭제
    emailaddrController.dispose(); // 이메일 주소 컨트롤러 삭제
    emailDomainFocusNode.dispose(); // focus 삭제
    super.dispose();
  }

  // 아이디 유효성 검사 함수  - 문자 및 숫자로 8~12자리 검사
  void validateId() {
    setState(() {
      RegExp regex = RegExp(r'^[a-zA-Z0-9]{8,12}$');
      isIdValid = ValidationPatterns.isValidId(idController.text);
    });
  }

  // 비밀번호 유효성 검사 - 문자 및 숫자로 6~12자리 검사
  void validatepw() {
    setState(() {
      String pw = passwordController.text;
      String npw = newPasswordController.text;
      String cnpw = confirmPasswordController.text;

      bool validate(String password) {
        // 🔥 빈 문자열은 무효한 것으로 처리 (경고 표시됨)
        bool hasMinLength = password.length >= 6 && password.length <= 12;
        bool hasLetter = ValidationPatterns.letterRegExp.hasMatch(password);
        bool hasNumber = ValidationPatterns.numberRegExp.hasMatch(password);
        bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
        return hasMinLength && hasLetter && hasNumber && hasSpecial;
      }

      isValpw = validate(pw);
      isValnpw = validate(npw);
      isValcnpw = validate(cnpw);
    });
  }

  // 새로운 비밀번호 유효성 검사 (기존 비밀번호 제외)
  void validateOnlyNew() {
    setState(() {
      String npw = newPasswordController.text;
      String cnpw = confirmPasswordController.text;

      bool validate(String password) {
        bool hasMinLength = password.length >= 6 && password.length <= 12;
        bool hasLetter = ValidationPatterns.letterRegExp.hasMatch(password);
        bool hasNumber = ValidationPatterns.numberRegExp.hasMatch(password);
        bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
        return hasMinLength && hasLetter && hasNumber && hasSpecial;
      }

      isValnpw = validate(npw);
      isValcnpw = validate(cnpw);
      // isValpw는 건드리지 않음!
    });
  }

  // mmsi 번호 유효성 검사 - 숫자 9자리만 허용
  void validatems() {
    setState(() {
      RegExp regex = ValidationPatterns.mmsiRegExp;
      isValms = ValidationPatterns.isValidMmsi(mmsiController.text);
    });
  }

  // 휴대폰 번호 유효성 검사 - 숫자 11자리만 허용
  void validatephone() {
    setState(() {
      RegExp regex = ValidationPatterns.phoneRegExp;
      isValphone = ValidationPatterns.isValidPhone(phoneController.text);
    });
  }

  // 이메일 유효성 검사 함수
  void validateemail() {
    setState(() {
      String email = emailController.text;
      String emailaddr = emailaddrController.text;
      isValemail = email.isNotEmpty;
      isValemailaddr = emailaddr.isNotEmpty;
    });
  }

  // 기존 회원정보 불러오기
  Future<void> loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uuid = user.uid;

      final response = await dioRequest.dio.post(
        userInfoUrl,
        data: {'uuid': uuid},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        setState(() {
          // MMSI 정보 채우기
          mmsiController.text = data['mmsi'] ?? '';

          // 전화번호 정보 채우기
          phoneController.text = data['mphn_no'] ?? '';

          // 이메일 정보 분리해서 채우기
          if (data['email_addr'] != null && data['email_addr'].isNotEmpty) {
            final emailParts = data['email_addr'].split('@');
            if (emailParts.length == 2) {
              emailController.text = emailParts[0];
              emailaddrController.text = emailParts[1];
            }
          }
        });
      }
    } catch (e) {}
  }

  //회원정보수정 완료하기 버튼
  Future<void> submitForm() async {
    // 🔥 추가: 버튼을 눌렀을 때 경고 메시지 숨기기
    setState(() {
      isSubmitting = true;
    });

    String id = idController.text;
    String password = passwordController.text;
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    //비밀번호 관련 검증 (기존 비밀번호가 입력된 경우)
    final isChangingPassword = newPassword.isNotEmpty;
    final hasOldPassword = password.isNotEmpty;

    if (hasOldPassword && !isChangingPassword) {
      showTopSnackBar(context, '변경하실 새로운 비밀번호를 입력해주세요.');
      return;
    }

    if (isChangingPassword) {
      if (password.isEmpty) {
        showTopSnackBar(context, '기존 비밀번호를 입력해주세요.');
        return;
      }
      if (confirmPassword.isEmpty) {
        showTopSnackBar(context, '새로운 비밀번호 확인란을 입력해주세요.');
        return;
      }
      // 기존 비밀번호 형식 검증
      if (!isValpw) {
        showTopSnackBar(context, '기존 비밀번호 형식이 올바르지 않습니다.');
        return;
      }

      // 새로운 비밀번호 형식 검증
      if (!isValnpw) {
        showTopSnackBar(context, '새로운 비밀번호 형식이 올바르지 않습니다.');
        return;
      }

      // 새로운 비밀번호 확인 형식 검증
      if (!isValcnpw) {
        showTopSnackBar(context, '새로운 비밀번호 확인 형식이 올바르지 않습니다.');
        return;
      }
      if (password == newPassword) {
        showTopSnackBar(context, '새로운 비밀번호가 기존 비밀번호와 동일합니다.');
        return;
      }
      if (newPassword != confirmPassword) {
        showTopSnackBar(context, '새로운 비밀번호가 일치하지 않습니다.');
        return;
      }
    }

    //MMSI 형식 검증
    bool isValidMmsi = false;
    if (mmsi.isNotEmpty) {
      if (!isValms) {
        showTopSnackBar(context, '선박 MMSI 번호 형식이 올바르지 않거나\n 9자리에 벗어납니다.');
        return;
      } else {
        isValidMmsi = true;
      }
    }

    //휴대폰 형식 검증
    bool isValidPhone = false;
    if (phone.isNotEmpty) {
      if (!isValphone) {
        showTopSnackBar(context, '휴대폰 번호 형식이 올바르지 않거나\n 11자리에 벗어납니다.');
        return;
      } else {
        isValidPhone = true;
      }
    }

    //이메일 유효성
    final isValidEmail = email.isNotEmpty && emailaddr.isNotEmpty;

    //실제로 전송 가능한 항목이 하나라도 있는지 확인
    final hasDataToUpdate = isChangingPassword || isValidMmsi || isValidPhone || isValidEmail;

    if (!hasDataToUpdate) {
      showTopSnackBar(context, '수정할 정보를 하나 이상 올바르게 입력해주세요.');
      return;
    }

    setState(() {
      isLoading = true; // 로딩 시작
    });

    try {
      //회원정보 수정 처리 중 사용자에게 로딩 상태 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 🔥 Firebase 사용자 정보 가져오기
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        showTopSnackBar(context, '로그인이 만료되었습니다. 다시 로그인해주세요.');
        return;
      }

      final firebaseToken = await user.getIdToken(); //JWT 토큰 가져오기
      final uuid = user.uid;

      // FCM 토큰 가져오기
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken() ?? ''; //fcmToken 가져오기

      //서버 전송 데이터 구성
      final dataToSend = {
        'user_id': id,
        if (isChangingPassword) 'user_pwd': password,
        if (isChangingPassword) 'user_npwd': newPassword,
        'mmsi': mmsi,
        'mphn_no': phone,
        'choice_time': widget.nowTime.toIso8601String(),
        if (email.isNotEmpty && emailaddr.isNotEmpty)
          'email_addr': '${email.trim()}@${emailaddr.trim()}',
        'uuid': uuid,
        'fcm_tkn': fcmToken,
      };

      final checkResponse = await dioRequest.dio.post(
        apiUrl,
        data: dataToSend,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        }),
      );

      // 🔥 서버 응답 상태 체크 추가
      if (checkResponse.statusCode != 200) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        showTopSnackBar(context, '서버 처리 중 오류가 발생했습니다.');
        return;
      }

      //비밀번호 변경 요청이 있을 경우만 Firebase 인증 및 업데이트
      if (isChangingPassword) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        await user.reload();
      }

      //모든 처리가 성공적으로 완료된 경우에만 성공 메시지 표시
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      showTopSnackBar(context, '회원정보가 성공적으로 수정되었습니다.');

      // 키보드와 포커스 완전 제거
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      FocusScope.of(context).unfocus();
      await Future.delayed(AnimationConstants.durationInstant);

      Navigator.pop(context); // 회원정보수정 화면 닫고, 마이페이지(MemberInformationView)로 돌아감
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 401) {
          // 다이얼로그 닫기
          Navigator.pop(context);

          // 비밀번호 틀림에 대한 명확한 분기 처리
          final message = responseData is Map && responseData['message'] != null
              ? responseData['message']
              : '기존 비밀번호가 일치하지 않습니다.';
          showTopSnackBar(context, message);
          return;
        }

        final message = responseData is Map && responseData['message'] != null
            ? responseData['message']
            : statusCode == null
                ? '서버에 연결할 수 없습니다. 다시 시도해주세요.'
                : '처리 중 오류가 발생했습니다.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: $message')),
        );
      } else {
        // Firebase 인증 실패 또는 기타 예상 못한 에러
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // 로딩 끝
          isSubmitting = false; //처리 완료 후 경고 다시 표시 가능하게
        });
      }
    }
  }

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
            left: getSize20().toDouble(),
            right: getSize20().toDouble(),
            top: getSize20().toDouble(),
            bottom: MediaQuery.of(context).viewInsets.bottom + getSize20().toDouble(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    EdgeInsets.only(top: getSize40().toDouble(), bottom: getSize8().toDouble()),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString(
                        '아이디', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                  child: inputWidget_deactivate(
                      getSize266(), getSize48(), idController, '', getColorgray_Type7(),
                      isReadOnly: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('기존 비밀번호', getTextcenter(), getSize16(), getText700(),
                        getColorgray_Type8()),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getSize13().toDouble()),
                  child: inputWidget(
                      getSize266(), getSize48(), passwordController, '비밀번호', getColorgray_Type7(),
                      obscureText: true),
                ),
              ),
              if (!isValpw && !isSubmitting)
                Padding(
                  padding: EdgeInsets.only(top: getSize0().toDouble()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidgetString('비밀번호는 문자, 숫자 및 특수문자를 포함한 6자리 이상 12자리 이하로 입력하여야 합니다.',
                          getTextleft(), getSize12(), getText700(), getColorred_type3()),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('새로운 비밀번호', getTextcenter(), getSize16(), getText700(),
                        getColorgray_Type8()),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                  child: inputWidget(getSize266(), getSize48(), newPasswordController, '비밀번호',
                      getColorgray_Type7(),
                      obscureText: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString('새로운 비밀번호 확인', getTextcenter(), getSize16(), getText700(),
                        getColorgray_Type8()),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                  child: inputWidget(getSize266(), getSize48(), confirmPasswordController,
                      '비밀번호 확인', getColorgray_Type7(),
                      obscureText: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                child: TextWidgetString(
                    '선박 MMSI 번호', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                  child: inputWidget(getSize266(), getSize48(), mmsiController,
                      'MMSI 번호(숫자 9자리)를 입력해주세요', getColorgray_Type7()),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                child: TextWidgetString(
                    '휴대폰 번호', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                  child: inputWidget(getSize266(), getSize48(), phoneController, "'-' 구분없이 숫자만 입력",
                      getColorgray_Type7()),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: getSize8().toDouble()),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgetString(
                        '이메일', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                child: Row(
                  children: [
                    Expanded(
                      child: inputWidget(
                        getSize133(),
                        getSize48(),
                        emailController,
                        '이메일 아이디 입력',
                        getColorgray_Type7(),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: getSize4().toDouble()),
                      child: TextWidgetString(
                          '@', getTextcenter(), getSize16(), getText700(), getColorgray_Type8()),
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
                              fillColor: getColorwhite_type1(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                                borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                                borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignConstants.radiusM),
                                borderSide: BorderSide(color: getColorgray_Type7(), width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: DesignConstants.spacing20,
                                  vertical: DesignConstants.spacing12),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: SvgPicture.asset(
                              'assets/kdn/usm/img/down_select_img.svg',
                              width: 24,
                              height: 24,
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
                padding: EdgeInsets.only(top: getSize20().toDouble()),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getColorsky_Type2(),
                      shape: getTextradius6(),
                      elevation: 0,
                      padding: EdgeInsets.all(getSize18().toDouble()),
                    ),
                    child: TextWidgetString(
                      '회원정보수정 완료하기',
                      getTextcenter(),
                      getSize16(),
                      getText700(),
                      getColorwhite_type1(),
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

class RedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), // 원 중심
      size.width / 2, // 반지름
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
