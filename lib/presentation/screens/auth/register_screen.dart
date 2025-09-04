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

class RegisterScreen extends StatefulWidget {
  final DateTime? nowTime;

  const RegisterScreen({super.key, this.nowTime});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ===== Services & Dependencies =====
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DioRequest _dioRequest = DioRequest();

  // ===== API Configuration =====
  late final String _apiUrl;
  late final String _apiSearchUrl;

  // ===== Form Controllers =====
  late final TextEditingController _idController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _mmsiController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _emailAddrController;

  // ===== State Variables =====
  int? _isIdAvailable;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isDirectInput = false;
  bool _isLoading = false;

  // ===== Email Domain Configuration =====
  String? _selectedEmailDomain;
  static const List<String> _emailDomains = [
    'naver.com',
    'gmail.com',
    'hanmail.net',
    '직접입력'
  ];

  // ===== Lifecycle Methods =====
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadApiConfiguration();
    _setDefaultEmailDomain();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // ===== Initialization Methods =====
  void _initializeControllers() {
    _idController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _mmsiController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _emailAddrController = TextEditingController();
  }

  void _disposeControllers() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mmsiController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emailAddrController.dispose();
  }

  void _loadApiConfiguration() {
    _apiUrl = dotenv.env['kdn_usm_insert_membership_key'] ?? '';
    _apiSearchUrl = dotenv.env['kdn_usm_select_membership_search_key'] ?? '';

    if (_apiUrl.isEmpty || _apiSearchUrl.isEmpty) {
      AppLogger.e('API URLs not configured in .env');
    }
  }

  void _setDefaultEmailDomain() {
    _selectedEmailDomain = _emailDomains.first;
    _emailAddrController.text = _selectedEmailDomain!;
  }

  // ===== Business Logic Methods =====

  /// 아이디 중복확인
  Future<void> _checkIdDuplicate() async {
    final id = _idController.text.trim();

    if (!_validateIdFormat(id)) return;

    setState(() => _isLoading = true);

    try {
      final response = await _dioRequest.dio.post(
        _apiSearchUrl,
        data: {'user_id': id},
      );

      _processIdCheckResponse(response);
    } on DioException catch (e) {
      _handleIdCheckError(e);
    } catch (e) {
      _showSnackBar('서버 오류가 발생했습니다.');
      setState(() => _isIdAvailable = null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateIdFormat(String id) {
    if (id.isEmpty) {
      _showSnackBar('아이디를 입력해주세요.');
      return false;
    }

    if (!ValidationPatterns.isValidId(id)) {
      _showSnackBar('아이디 형식이 올바르지 않습니다.\n문자, 숫자 8~12자리로 입력해주세요.');
      return false;
    }

    return true;
  }

  void _processIdCheckResponse(Response response) {
    setState(() {
      if (response.data is int) {
        _isIdAvailable = response.data;
      } else if (response.data is Map) {
        _isIdAvailable = response.data['result'] ?? response.data['code'] ?? 1;
      } else {
        _isIdAvailable = null;
      }
    });

    final message = _isIdAvailable == ValidationConstants.idAvailable
        ? '사용 가능한 아이디입니다.'
        : '이미 사용 중인 아이디입니다.';
    _showSnackBar(message);
  }

  void _handleIdCheckError(DioException e) {
    String message;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      message = '서버에 연결할 수 없습니다.';
    } else if (e.response?.statusCode == 404) {
      message = 'API 엔드포인트를 찾을 수 없습니다.';
    } else {
      message = '중복확인 중 오류가 발생했습니다.';
    }

    _showSnackBar(message);
    setState(() => _isIdAvailable = null);
  }

  /// 회원가입 처리
  Future<void> _register() async {
    print('\n========== 회원가입 프로세스 시작 ==========');

    if (!_validateAllFields()) return;

    setState(() => _isLoading = true);

    try {
      final formData = _getFormData();
      final id = formData['id'] ?? '';
      final password = formData['password'] ?? '';

      print('[회원가입] 입력 정보:');
      print('  ID: $id');
      print('  Firebase Email: $id@kdn.vms.com');

      // Firebase 계정 생성 직접 시도
      final firebaseEmail = '$id@kdn.vms.com';
      print('[회원가입] createUserWithEmailAndPassword 호출...');

      UserCredential? userCredential;

      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: firebaseEmail,
          password: password,
        );

        print('✅ Firebase 계정 생성 성공!');
        print('  UID: ${userCredential.user?.uid}');

      } on FirebaseAuthException catch (e) {
        print('❌ Firebase 계정 생성 실패: ${e.code}');

        if (e.code == 'email-already-in-use') {
          // 기존 계정 발견 - 사용자에게 선택권 제공
          final shouldDelete = await _showExistingAccountDialog();

          if (!shouldDelete) {
            setState(() => _isLoading = false);
            print('========== 회원가입 프로세스 종료 (사용자 취소) ==========\n');
            return;
          }

          // 기존 계정 삭제 시도
          final deleted = await _deleteExistingAccount(firebaseEmail, password);

          if (!deleted) {
            setState(() => _isLoading = false);
            return;
          }

          // 계정 삭제 성공 - 다시 생성
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: firebaseEmail,
              password: password,
            );
            print('✅ 계정 재생성 성공!');
          } catch (retryError) {
            print('❌ 계정 재생성 실패: $retryError');
            _showSnackBar('계정 생성에 실패했습니다. 잠시 후 다시 시도해주세요.');
            setState(() => _isLoading = false);
            return;
          }
        } else {
          // 다른 Firebase 에러 처리
          _handleFirebaseAuthError(e);
          setState(() => _isLoading = false);
          return;
        }
      }

      // 백엔드 API 호출
      print('[회원가입] 백엔드 API 호출...');
      await _registerToBackend(userCredential, formData);
    
      print('========== 회원가입 프로세스 완료 ==========\n');

    } on DioException catch (e) {
      print('❌ 백엔드 API 에러: $e');
      await _handleBackendError(e);
    } catch (e) {
      print('❌ 예상치 못한 에러: $e');
      AppLogger.e('Registration error: $e');
      _showSnackBar('회원가입 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showExistingAccountDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('기존 계정 발견'),
        content: const Text(
          '이전에 사용했던 계정 정보가 시스템에 남아있습니다.\n'
              '기존 계정을 삭제하고 새로 가입하시겠습니까?\n\n'
              '※ 동일한 비밀번호를 입력하셔야 처리 가능합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('기존 계정 삭제 후 재가입'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _deleteExistingAccount(String email, String password) async {
    print('[삭제 프로세스] 시작...');
    print('  이메일: $email');

    _showLoadingDialog();

    try {
      print('Firebase 로그인 시도...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ 로그인 성공!');
      print('  UID: ${credential.user?.uid}');

      print('계정 삭제 시도...');
      await credential.user?.delete();

      print('✅ 계정 삭제 완료!');

      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      _showSnackBar('기존 계정이 삭제되었습니다. 회원가입을 진행합니다.');

      await Future.delayed(const Duration(seconds: 1));
      print('[삭제 프로세스] 성공적으로 완료');
      return true;

    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      print('❌ Firebase 인증 오류 발생:');
      print('  에러 코드: ${e.code}');
      print('  에러 메시지: ${e.message}');

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        await _showPasswordMismatchDialog();
        return false;
      } else if (e.code == 'user-not-found') {
        _showSnackBar('계정을 찾을 수 없습니다.');
        return true; // 이미 없으므로 진행 가능
      } else {
        _showSnackBar('기존 계정 처리 중 오류: ${e.code}');
        return false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      print('❌ 예상치 못한 오류: $e');
      _showSnackBar('계정 삭제 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<void> _showPasswordMismatchDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 불일치'),
        content: const Text(
          '기존 계정의 비밀번호와 일치하지 않습니다.\n'
              '다른 아이디를 사용하시거나, 관리자에게 문의해주세요.\n\n'
              '고객센터: 1234-5678',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  bool _validateAllFields() {
    final formData = _getFormData();

    final id = formData['id'] ?? '';
    final password = formData['password'] ?? '';
    final confirmPassword = formData['confirmPassword'] ?? '';
    final mmsi = formData['mmsi'] ?? '';
    final phone = formData['phone'] ?? '';
    final emailaddr = formData['emailaddr'] ?? '';

    // 필수 항목 체크
    if (id.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        mmsi.isEmpty) {
      _showSnackBar('회원가입을 위해 필수 항목을 입력해주세요.');
      return false;
    }

    // 중복확인 체크
    if (_isIdAvailable == null) {
      _showSnackBar('아이디 중복 확인을 해주세요.');
      return false;
    }

    if (_isIdAvailable != ValidationConstants.idAvailable) {
      _showSnackBar('이미 사용 중인 아이디입니다.');
      return false;
    }

    // 유효성 검사
    if (!ValidationPatterns.isValidPassword(password)) {
      _showSnackBar('비밀번호 형식이 올바르지 않습니다.');
      return false;
    }

    if (!ValidationPatterns.isValidMmsi(mmsi)) {
      _showSnackBar('MMSI 형식이 올바르지 않습니다.');
      return false;
    }

    if (phone.isNotEmpty &&
        !ValidationPatterns.isValidPhone(phone)) {
      _showSnackBar('휴대폰 번호 형식이 올바르지 않습니다.');
      return false;
    }

    if (password != confirmPassword) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return false;
    }

    if (_isDirectInput && emailaddr.isEmpty) {
      _showSnackBar('이메일 도메인을 입력해주세요.');
      return false;
    }

    return true;
  }

  Map<String, String> _getFormData() {
    return {
      'id': _idController.text.trim(),
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'mmsi': _mmsiController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'emailaddr': _isDirectInput
          ? _emailAddrController.text
          : _selectedEmailDomain ?? '',
    };
  }

  Future<void> _registerToBackend(
      UserCredential userCredential,
      Map<String, String> formData,
      ) async {
    final id = formData['id'] ?? '';
    final password = formData['password'] ?? '';
    final mmsi = formData['mmsi'] ?? '';
    final phone = formData['phone'] ?? '';
    final email = formData['email'] ?? '';
    final emailaddr = formData['emailaddr'] ?? '';

    print('[백엔드 API] 전송 데이터:');
    print('  user_id: $id');
    print('  mmsi: $mmsi');
    print('  mphn_no: $phone');
    print('  firebase_uuid: ${userCredential.user!.uid}');
    print('  email_addr: ${(email.isNotEmpty && emailaddr.isNotEmpty) ? '$email@$emailaddr' : '(빈값)'}');
    print('  choice_time: ${widget.nowTime?.toIso8601String() ?? DateTime.now().toIso8601String()}');

    final response = await _dioRequest.dio.post(
      _apiUrl,
      data: {
        'user_id': id,
        'user_pwd': password,
        'mmsi': mmsi,
        'mphn_no': phone,
        'firebase_uuid': userCredential.user!.uid,
        'email_addr': (email.isNotEmpty && emailaddr.isNotEmpty)
            ? '$email@$emailaddr'
            : '',
        'choice_time': widget.nowTime?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      },
    );

    print('[백엔드 API] 응답:');
    print('  Status: ${response.statusCode}');
    print('  Data: ${response.data}');

    if (response.data['result'] == 'success' || response.statusCode == 200) {
      _navigateToCompleteScreen();
    } else {
      await userCredential.user?.delete();
      _showSnackBar('회원가입에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    final message = switch (e.code) {
      'weak-password' => '비밀번호가 너무 약합니다.',
      'email-already-in-use' => '계정이 이미 존재합니다.',
      _ => '회원가입 중 오류가 발생했습니다.',
    };
    _showSnackBar(message);
  }

  Future<void> _handleBackendError(DioException e) async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {}

    if (e.response?.statusCode == 404) {
      AppLogger.i('API 404 - Proceeding with Firebase only');
      _navigateToCompleteScreen();
    } else {
      _showSnackBar('회원가입 처리 중 오류가 발생했습니다.');
    }
  }

  // ===== UI Helper Methods =====
  void _showSnackBar(String message) {
    showTopSnackBar(context, message);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _navigateToCompleteScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterCompleteView(),
      ),
    );
  }

  void _onIdChanged(String value) {
    setState(() {
      if (_isIdAvailable != null) {
        _isIdAvailable = null;
      }
    });
  }

  void _onEmailDomainChanged(String? newValue) {
    setState(() {
      _selectedEmailDomain = newValue;
      if (newValue == '직접입력') {
        _isDirectInput = true;
        _emailAddrController.clear();
      } else {
        _isDirectInput = false;
        _emailAddrController.text = newValue ?? '';
      }
    });
  }

  // ===== Build Methods =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColorwhite_type1(),
      appBar: AppBar(
        title: const AppBarLayerView('회원가입'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 30),
          _buildHeader(),
          const SizedBox(height: 30),
          _buildForm(),
          const SizedBox(height: 40),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIndicator(1, '약관동의', false),
        _buildStepConnector(),
        _buildStepIndicator(2, '정보입력', true),
        _buildStepConnector(),
        _buildStepIndicator(3, '가입완료', false),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildIdSection(),
        const SizedBox(height: 20),
        _buildPasswordSection(),
        const SizedBox(height: 20),
        _buildConfirmPasswordSection(),
        const SizedBox(height: 20),
        _buildMmsiSection(),
        const SizedBox(height: 20),
        _buildPhoneSection(),
        const SizedBox(height: 20),
        _buildEmailSection(),
      ],
    );
  }

  Widget _buildIdSection() {
    return Column(
      children: [
        _buildInputSection(
          label: '아이디',
          isRequired: true,
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _idController,
                  hintText: '아이디를 입력하세요',
                  onChanged: _onIdChanged,
                ),
              ),
              const SizedBox(width: 8),
              _buildIdCheckButton(),
            ],
          ),
        ),
        _buildIdStatusIndicator(),
      ],
    );
  }

  Widget _buildIdCheckButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _idController.text.trim().isNotEmpty && !_isLoading
            ? _checkIdDuplicate
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: getColorsky_Type2(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _isIdAvailable == ValidationConstants.idAvailable
              ? '재확인'
              : '중복확인',
          style: TextStyle(
            fontSize: 14,
            fontWeight: getText600(),
            color: getColorwhite_type1(),
          ),
        ),
      ),
    );
  }

  Widget _buildIdStatusIndicator() {
    if (_idController.text.trim().isNotEmpty && _isIdAvailable == null) {
      return _buildStatusRow(
        icon: Icons.info_outline,
        color: Colors.orange,
        message: '아이디 중복확인이 필요합니다',
      );
    }

    if (_isIdAvailable != null) {
      final isAvailable = _isIdAvailable == ValidationConstants.idAvailable;
      return _buildStatusRow(
        icon: isAvailable ? Icons.check_circle : Icons.error,
        color: isAvailable ? Colors.green : getColorred_type1(),
        message: isAvailable
            ? '사용 가능한 아이디입니다'
            : '이미 사용 중인 아이디입니다',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          TextWidgetString(
            message,
            getTextleft(),
            12,
            getText400(),
            color,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return _buildInputSection(
      label: '비밀번호',
      isRequired: true,
      child: _buildTextField(
        controller: _passwordController,
        hintText: '비밀번호를 입력하세요',
        obscureText: !_isPasswordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: getColorgray_Type2(),
          ),
          onPressed: () => setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          }),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordSection() {
    return _buildInputSection(
      label: '비밀번호 확인',
      isRequired: true,
      child: _buildTextField(
        controller: _confirmPasswordController,
        hintText: '비밀번호를 다시 입력하세요',
        obscureText: !_isConfirmPasswordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: getColorgray_Type2(),
          ),
          onPressed: () => setState(() {
            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
          }),
        ),
      ),
    );
  }

  Widget _buildMmsiSection() {
    return _buildInputSection(
      label: 'MMSI',
      isRequired: true,
      child: _buildTextField(
        controller: _mmsiController,
        hintText: 'MMSI를 입력하세요',
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildPhoneSection() {
    return _buildInputSection(
      label: '휴대폰 번호',
      isRequired: false,
      child: _buildTextField(
        controller: _phoneController,
        hintText: '휴대폰 번호를 입력하세요',
        keyboardType: TextInputType.phone,
      ),
    );
  }

  Widget _buildEmailSection() {
    return _buildInputSection(
      label: '이메일',
      isRequired: false,
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _emailController,
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
            child: _isDirectInput
                ? _buildTextField(
              controller: _emailAddrController,
              hintText: '도메인 입력',
            )
                : _buildEmailDomainDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDomainDropdown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: getColorgray_Type3()),
        borderRadius: BorderRadius.circular(8),
        color: getColorwhite_type1(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedEmailDomain,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: Icon(
            Icons.arrow_drop_down,
            color: getColorblack_type2(),
          ),
          style: TextStyle(
            fontSize: 14,
            color: getColorblack_type2(),
          ),
          items: _emailDomains.map((domain) {
            return DropdownMenuItem<String>(
              value: domain,
              child: Text(
                domain,
                style: TextStyle(
                  fontSize: 14,
                  color: domain == '직접입력'
                      ? getColorgray_Type2()
                      : getColorblack_type2(),
                ),
              ),
            );
          }).toList(),
          onChanged: _onEmailDomainChanged,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: !_isLoading ? _register : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: getColorsky_Type2(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          '회원가입',
          style: TextStyle(
            fontSize: 16,
            fontWeight: getText700(),
            color: getColorwhite_type1(),
          ),
        ),
      ),
    );
  }

  // ===== Reusable Widget Builders =====
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

  Widget _buildStepConnector() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: getColorgray_Type3(),
    );
  }

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
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
        fillColor: enabled
            ? getColorwhite_type1()
            : getColorgray_Type3().withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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

// ===== Backward Compatibility =====
class Membershipview extends StatefulWidget {
  final DateTime nowTime;

  const Membershipview({super.key, required this.nowTime});

  @override
  State<Membershipview> createState() => _MembershipviewState();
}

class _MembershipviewState extends State<Membershipview> {
  @override
  Widget build(BuildContext context) {
    return RegisterScreen(nowTime: widget.nowTime);
  }
}