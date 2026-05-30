import 'package:flutter/material.dart';
import 'signup_step2_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/signup_stepper.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService.instance;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();

  bool _isCheckingId = false;
  bool? _isIdAvailable;
  String _lastCheckedId = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkIdAvailability() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      _showError('아이디를 입력해 주세요.');
      return;
    }
    
    setState(() => _isCheckingId = true);
    try {
      final available = await _authService.checkLoginIdAvailability(id);
      setState(() {
        _isIdAvailable = available;
        _lastCheckedId = id;
        _isCheckingId = false;
      });
      if (available) {
        _showSuccess('사용 가능한 아이디입니다.');
      } else {
        _showError('이미 사용 중이거나 사용할 수 없는 아이디입니다.');
      }
    } catch (e) {
      setState(() => _isCheckingId = false);
      _showError('중복 확인 실패: $e');
    }
  }

  bool _validate() {
    if (_nameCtrl.text.isEmpty) {
      _showError('이름을 입력해 주세요.');
      return false;
    }
    if (_idCtrl.text.isEmpty) {
      _showError('아이디를 입력해 주세요.');
      return false;
    }
    if (_isIdAvailable != true || _lastCheckedId != _idCtrl.text.trim()) {
      _showError('아이디 중복확인을 진행해 주세요.');
      return false;
    }
    if (_pwCtrl.text.isEmpty) {
      _showError('비밀번호를 입력해 주세요.');
      return false;
    }
    if (_pwCtrl.text != _pwConfirmCtrl.text) {
      _showError('비밀번호가 일치하지 않습니다.');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('회원가입', style: AppTextStyles.appBarTitle),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    
                    const SignupStepper(currentStep: 1),
                    
                    const SizedBox(height: 48),
                    
                    // 이름
                    _buildTextField('이름', _nameCtrl),
                    
                    // 이메일
                    _buildTextField('이메일', _emailCtrl),
                    
                    // 아이디 + 중복확인
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.bgGray,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _idCtrl,
                                decoration: const InputDecoration(
                                  hintText: '아이디',
                                  hintStyle: TextStyle(
                                    color: AppColors.textGray,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isCheckingId ? null : _checkIdAvailability,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              child: _isCheckingId
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      '중복확인', 
                                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.white)
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 비밀번호
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bgGray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _pwCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          hintStyle: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textGray,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    // 비밀번호 확인
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bgGray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _pwConfirmCtrl,
                        obscureText: _obscurePasswordConfirm,
                        decoration: InputDecoration(
                          hintText: '비밀번호 확인',
                          hintStyle: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textGray,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePasswordConfirm = !_obscurePasswordConfirm;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const Expanded(
                      child: SizedBox(height: 32),
                    ),
                    
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_validate()) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignupStep2Screen(
                                signupData: {
                                  'loginId': _idCtrl.text,
                                  'password': _pwCtrl.text,
                                  'userName': _nameCtrl.text,
                                  'email': _emailCtrl.text,
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('다음', style: AppTextStyles.buttonText),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textGray,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
