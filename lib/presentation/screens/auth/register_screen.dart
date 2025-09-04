import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/core/utils/logger.dart';
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
  // ========================================
  // Services & Dependencies
  // ========================================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DioRequest _dioRequest = DioRequest();

  // ========================================
  // API Configuration
  // ========================================
  late final String _apiUrl;
  late final String _apiSearchUrl;

  // ========================================
  // Form Controllers
  // ========================================
  late final TextEditingController _idController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _mmsiController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _emailAddrController;

  // ========================================
  // State Variables
  // ========================================
  int? _isIdAvailable;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isDirectInput = false;
  bool _isLoading = false;

  // ========================================
  // Email Domain Configuration
  // ========================================
  String? _selectedEmailDomain;
  static const List<String> _emailDomains = [
    'naver.com',
    'gmail.com',
    'hanmail.net',
    '직접입력'
  ];

  // ========================================
  // Lifecycle Methods
  // ========================================
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

  // ========================================
  // Initialization Methods
  // ========================================
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

    // 디버깅용 로그
    print('===== API URLs 로드 =====');
    print('회원가입 API: $_apiUrl');
    print('중복확인 API: $_apiSearchUrl');
    print('========================');
  }

  void _setDefaultEmailDomain() {
    _selectedEmailDomain = _emailDomains[0];
    _emailAddrController.text = _selectedEmailDomain!;
  }

  // ========================================
  // Validation Methods
  // ========================================
  bool _validateForm() {
    // 아이디 검증
    if (_idController.text.trim().isEmpty) {
      showTopSnackBar(context, '아이디를 입력해주세요.');
      return false;
    }

    if (_isIdAvailable != ValidationConstants.idAvailable) {
      showTopSnackBar(context, '아이디 중복확인을 해주세요.');
      return false;
    }

    // 비밀번호 검증
    if (_passwordController.text.isEmpty) {
      showTopSnackBar(context, '비밀번호를 입력해주세요.');
      return false;
    }

    if (_confirmPasswordController.text.isEmpty) {
      showTopSnackBar(context, '비밀번호 확인을 입력해주세요.');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showTopSnackBar(context, '비밀번호가 일치하지 않습니다.');
      return false;
    }

    if (!ValidationPatterns.isValidPassword(_passwordController.text)) {
      showTopSnackBar(context, '비밀번호는 6-12자리, 영문, 숫자, 특수문자를 포함해야 합니다.');
      return false;
    }

    // MMSI 검증
    if (_mmsiController.text.trim().isEmpty) {
      showTopSnackBar(context, 'MMSI를 입력해주세요.');
      return false;
    }

    if (!ValidationPatterns.isValidMmsi(_mmsiController.text)) {
      showTopSnackBar(context, 'MMSI는 9자리 숫자여야 합니다.');
      return false;
    }

    // 전화번호 검증
    if (_phoneController.text.trim().isEmpty) {
      showTopSnackBar(context, '전화번호를 입력해주세요.');
      return false;
    }

    if (!ValidationPatterns.isValidPhone(_phoneController.text)) {
      showTopSnackBar(context, '올바른 전화번호 형식이 아닙니다.');
      return false;
    }

    // 이메일 검증 (선택사항)
    if (_emailController.text.trim().isNotEmpty || _emailAddrController.text.trim().isNotEmpty) {
      if (_emailController.text.trim().isEmpty || _emailAddrController.text.trim().isEmpty) {
        showTopSnackBar(context, '이메일을 완전히 입력해주세요.');
        return false;
      }
    }

    return true;
  }

  // ========================================
  // API Methods
  // ========================================
  Future<void> _checkIdDuplicate() async {
    final id = _idController.text.trim();

    if (id.isEmpty) {
      showTopSnackBar(context, '아이디를 입력해주세요.');
      return;
    }

    if (!ValidationPatterns.isValidId(id)) {
      showTopSnackBar(context, '아이디는 영문과 숫자만 사용 가능합니다.');
      return;
    }

    try {
      print('중복확인 API 호출: $_apiSearchUrl');
      print('전송 데이터: user_id=$id');

      final response = await _dioRequest.dio.post(
        _apiSearchUrl,
        data: {'user_id': id},
      );

      if (!mounted) return;

      print('응답 데이터: ${response.data}');

      setState(() {
        // API 응답에 따른 처리
        if (response.data is int) {
          _isIdAvailable = response.data;
        } else if (response.data is Map) {
          _isIdAvailable = response.data['result'] ??
              response.data['available'] ??
              response.data['code'] ?? 1;
        } else {
          _isIdAvailable = ValidationConstants.idAvailable;
        }
      });

      final message = _isIdAvailable == ValidationConstants.idAvailable
          ? '사용 가능한 아이디입니다.'
          : '이미 사용 중인 아이디입니다.';
      showTopSnackBar(context, message);
    } catch (e) {
      logger.e('ID 중복 확인 실패: $e');
      showTopSnackBar(context, '아이디 중복 확인에 실패했습니다.');
    }
  }

  Future<void> _register() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase 계정 생성
      final firebaseEmail = '${_idController.text.trim()}@kdn.vms.com';
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: firebaseEmail,
        password: _passwordController.text,
      );

      // API 서버에 회원정보 등록
      final email = _emailController.text.trim().isNotEmpty && _emailAddrController.text.trim().isNotEmpty
          ? '${_emailController.text.trim()}@${_emailAddrController.text.trim()}'
          : '';

      final response = await _dioRequest.dio.post(
        _apiUrl,
        data: {
          'user_id': _idController.text.trim(),
          'user_pwd': _passwordController.text,
          'mmsi': _mmsiController.text.trim(),
          'mphn_no': _phoneController.text.trim(),
          'email_addr': email,
          'firebase_uuid': userCredential.user?.uid,
          'choice_time': widget.nowTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      // API 응답 확인
      if (response.statusCode == 200 || response.data['result'] == 'success') {
        // 회원가입 완료 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterCompleteView(),
          ),
        );
      } else {
        // Firebase 계정 삭제
        await userCredential.user?.delete();
        showTopSnackBar(context, '회원가입에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      logger.e('회원가입 실패: $e');

      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          showTopSnackBar(context, '이미 사용 중인 아이디입니다.');
        } else if (e.code == 'weak-password') {
          showTopSnackBar(context, '비밀번호가 너무 약합니다.');
        } else {
          showTopSnackBar(context, '회원가입에 실패했습니다. ${e.message}');
        }
      } else if (e is DioException) {
        // Firebase 계정이 생성되었다면 삭제
        try {
          await FirebaseAuth.instance.currentUser?.delete();
        } catch (_) {}

        if (e.response?.statusCode == 404) {
          // API 엔드포인트가 없는 경우에도 진행
          logger.i('API 404 - Proceeding with Firebase only');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterCompleteView(),
            ),
          );
        } else {
          showTopSnackBar(context, '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
        }
      } else {
        showTopSnackBar(context, '회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ========================================
  // Event Handlers
  // ========================================
  void _onEmailDomainChanged(String? value) {
    setState(() {
      _selectedEmailDomain = value;
      if (value == '직접입력') {
        _isDirectInput = true;
        _emailAddrController.clear();
      } else {
        _isDirectInput = false;
        _emailAddrController.text = value ?? '';
      }
    });
  }

  void _onIdChanged(String value) {
    setState(() {
      _isIdAvailable = null;
    });
  }

  // ========================================
  // Build Methods
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColorwhite_type1(),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: getColorwhite_type1(),
        title: const AppBarLayerView('회원가입'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildProgressIndicator(),
              const SizedBox(height: 40),
              _buildIdSection(),
              const SizedBox(height: 24),
              _buildPasswordSection(),
              const SizedBox(height: 24),
              _buildConfirmPasswordSection(),
              const SizedBox(height: 24),
              _buildMmsiSection(),
              const SizedBox(height: 24),
              _buildPhoneSection(),
              const SizedBox(height: 24),
              _buildEmailSection(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // UI Builder Methods
  // ========================================
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

  Widget _buildIdSection() {
    return _buildInputSection(
      label: '아이디',
      isRequired: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 7,
                child: _buildTextField(
                  controller: _idController,
                  hintText: '아이디를 입력하세요',
                  onChanged: _onIdChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildIdDuplicateButton(),
              ),
            ],
          ),
          _buildIdStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildIdDuplicateButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: !_isLoading ? _checkIdDuplicate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: getColorsky_Type2(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _isIdAvailable == ValidationConstants.idAvailable ? '재확인' : '중복확인',
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
        message: isAvailable ? '사용 가능한 아이디입니다' : '이미 사용 중인 아이디입니다',
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
        hintText: 'MMSI 번호를 입력하세요',
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildPhoneSection() {
    return _buildInputSection(
      label: '전화번호',
      isRequired: true,
      child: _buildTextField(
        controller: _phoneController,
        hintText: '전화번호를 입력하세요',
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
            flex: 5,
            child: _buildTextField(
              controller: _emailController,
              hintText: '이메일',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '@',
              style: TextStyle(
                fontSize: 16,
                color: getColorgray_Type2(),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: _isDirectInput ? _buildEmailDirectInput() : _buildEmailDomainDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDirectInput() {
    return _buildTextField(
      controller: _emailAddrController,
      hintText: '직접입력',
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildEmailDomainDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: getColorgray_Type3()),
        borderRadius: BorderRadius.circular(8),
        color: getColorwhite_type1(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedEmailDomain,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: getColorgray_Type2()),
          items: _emailDomains.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: value == '직접입력' ? getColorgray_Type2() : getColorblack_type2(),
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

  // ========================================
  // Reusable Widget Builders
  // ========================================
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
        fillColor: enabled ? getColorwhite_type1() : getColorgray_Type3().withOpacity(0.5),
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

// ========================================
// Backward Compatibility
// ========================================
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