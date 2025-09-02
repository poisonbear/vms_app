import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/presentation/screens/auth/register_complete_screen.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

class Membershipview extends StatefulWidget {
  final DateTime nowTime;

  const Membershipview({super.key, required this.nowTime});

  @override
  State<Membershipview> createState() => _MembershipviewState();
}

class _MembershipviewState extends State<Membershipview> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController mmsiController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailaddrController = TextEditingController();

  bool isIdValid = true;
  bool isValpw = true;
  bool isValms = true;
  bool isValphone = true;
  bool isValemail = true;
  bool isValemailaddr = true;

  int? isIdAvailable;

  List<String> items = ['naver.com', 'gmail.com', 'hanmail.net'];
  String? selectedValue;
  TextEditingController controller = TextEditingController();

  final String apiUrl = dotenv.env['kdn_usm_insert_membership_key'] ?? '';
  final String apisearchUrl = dotenv.env['kdn_usm_select_membership_search_key'] ?? '';
  final dioRequest = DioRequest();

  @override
  void initState() {
    super.initState();
    idController.addListener(validateId);
    passwordController.addListener(validatepw);
    mmsiController.addListener(validatems);
    phoneController.addListener(validatephone);
    emailController.addListener(validateemail);
    emailaddrController.addListener(validateemail);
  }

  @override
  void dispose() {
    idController.removeListener(validateId);
    idController.dispose();
    passwordController.removeListener(validatepw);
    passwordController.dispose();
    confirmPasswordController.dispose();
    mmsiController.dispose();
    mmsiController.removeListener(validatems);
    phoneController.dispose();
    phoneController.removeListener(validatephone);
    emailController.removeListener(validateemail);
    emailController.dispose();
    emailaddrController.removeListener(validateemail);
    emailaddrController.dispose();
    super.dispose();
  }

  /// ✅ ValidationPatterns를 사용한 아이디 검증
  void validateId() {
    setState(() {
      isIdValid = ValidationPatterns.isValidId(idController.text);
      if (isIdAvailable != null) {
        isIdAvailable = null;
      }
    });
  }

  /// ✅ ValidationPatterns를 사용한 비밀번호 검증
  void validatepw() {
    setState(() {
      String password = passwordController.text;
      isValpw = ValidationPatterns.isValidPassword(password);
    });
  }

  /// ✅ ValidationPatterns를 사용한 MMSI 검증
  void validatems() {
    setState(() {
      String mmsi = mmsiController.text;
      if (mmsi.isEmpty) {
        isValms = true;
      } else {
        isValms = ValidationPatterns.isValidMmsi(mmsi);
      }
    });
  }

  /// ✅ ValidationPatterns를 사용한 전화번호 검증
  void validatephone() {
    setState(() {
      String phone = phoneController.text;
      if (phone.isEmpty) {
        isValphone = true;
      } else {
        isValphone = ValidationPatterns.isValidPhone(phone);
      }
    });
  }

  void validateemail() {
    setState(() {
      String email = emailController.text;
      String emailaddr = emailaddrController.text;
      isValemail = email.isNotEmpty;
      isValemailaddr = emailaddr.isNotEmpty;
    });
  }

  /// 아이디 중복 조회
  Future<void> searchForm() async {
    String id = idController.text.trim();

    if (id.isEmpty) {
      showTopSnackBar(context, '아이디를 입력해주세요.');
      return;
    }

    if (!ValidationPatterns.isValidId(id)) {
      showTopSnackBar(context, '아이디 형식이 올바르지 않습니다.\n문자, 숫자 8~12자리로 입력해주세요.');
      return;
    }

    try {
      Response response = await dioRequest.dio.post(
        apisearchUrl,
        data: {'user_id': id},
      );

      setState(() {
        if (response.data is int) {
          isIdAvailable = response.data;
        } else {
          isIdAvailable = null;
        }
      });

      if (isIdAvailable == ValidationConstants.idAvailable) {
        showTopSnackBar(context, '사용 가능한 아이디입니다.');
      } else if (isIdAvailable == ValidationConstants.idNotAvailable) {
        showTopSnackBar(context, '이미 사용 중인 아이디입니다.');
      }
    } catch (e) {
      AppLogger.e('아이디 중복 확인 오류: $e');
      setState(() {
        isIdAvailable = null;
      });
      showTopSnackBar(context, '서버 오류 발생. 다시 시도해주세요.');
    }
  }

  /// 회원가입 처리
  Future<void> submitForm() async {
    String id = idController.text;
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    String mmsi = mmsiController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String emailaddr = emailaddrController.text;

    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 필수 항목 체크
    if (id.isEmpty || password.isEmpty || confirmPassword.isEmpty || mmsi.isEmpty) {
      showTopSnackBar(context, '회원가입을 위해 필수 항목을 입력해주세요.');
      return;
    }

    // 아이디 중복 확인 체크
    if (isIdAvailable == null) {
      showTopSnackBar(context, '아이디 중복 확인을 해주세요.');
      return;
    }

    if (isIdAvailable == ValidationConstants.idNotAvailable) {
      showTopSnackBar(context, '이미 사용 중인 아이디입니다.');
      return;
    }

    // ValidationPatterns를 사용한 최종 검증
    if (!ValidationPatterns.isValidId(id)) {
      showTopSnackBar(context, '아이디 형식이 올바르지 않습니다.');
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
        email: '$id@vms.com',
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
        // ✅ 올바른 클래스명으로 네비게이션
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterCompleteView(),
          ),
        );
      } else {
        showTopSnackBar(context, '회원가입에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      AppLogger.e('회원가입 오류: $e');
      
      if (e is FirebaseAuthException) {
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
      } else {
        showTopSnackBar(context, '회원가입 중 오류가 발생했습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 아이디 입력
            TextFormField(
              controller: idController,
              decoration: InputDecoration(
                labelText: '아이디',
                hintText: '영문+숫자 8~12자리',
                errorText: !isIdValid ? '아이디 형식이 올바르지 않습니다.' : null,
                suffixIcon: IconButton(
                  onPressed: searchForm,
                  icon: const Icon(Icons.check),
                ),
              ),
            ),
            
            // 아이디 중복확인 결과 표시
            if (isIdAvailable == ValidationConstants.idAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  '사용 가능한 아이디입니다.',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            
            if (isIdAvailable == ValidationConstants.idNotAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  '이미 사용 중인 아이디입니다.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),

            // 비밀번호 입력
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호',
                hintText: '영문+숫자+특수문자 6~12자리',
                errorText: !isValpw ? '비밀번호 형식이 올바르지 않습니다.' : null,
              ),
            ),

            const SizedBox(height: 16),

            // 비밀번호 확인
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                hintText: '비밀번호를 다시 입력하세요',
              ),
            ),

            const SizedBox(height: 16),

            // MMSI 입력
            TextFormField(
              controller: mmsiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'MMSI',
                hintText: '9자리 숫자',
                errorText: !isValms ? 'MMSI는 9자리 숫자여야 합니다.' : null,
              ),
            ),

            const SizedBox(height: 16),

            // 전화번호 입력
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '휴대폰 번호 (선택)',
                hintText: '11자리 숫자',
                errorText: !isValphone ? '전화번호는 11자리 숫자여야 합니다.' : null,
              ),
            ),

            const SizedBox(height: 16),

            // 이메일 입력
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일 ID',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('@'),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: const InputDecoration(
                      labelText: '도메인',
                    ),
                    items: items.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedValue = newValue;
                        emailaddrController.text = newValue ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 회원가입 버튼
            ElevatedButton(
              onPressed: submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '회원가입',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
