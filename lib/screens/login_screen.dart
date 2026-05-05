import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    const SizedBox(height: 60),
                    // Header Texts
                    const Text(
                      '환영합니다!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AIPO의 개인화된 맞춤형 서비스를 경험해 보세요.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // ID Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _idCtrl,
                        decoration: const InputDecoration(
                          hintText: '아이디',
                          hintStyle: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _pwCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFFB0B0B0),
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
                    
                    const SizedBox(height: 24),
                    // Signup Text
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: '아직 계정이 없으신가요? ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF757575),
                              fontFamily: 'Pretendard',
                            ),
                            children: [
                              TextSpan(
                                text: '회원가입',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Spacer to push login button to bottom
                    const Expanded(
                      child: SizedBox(height: 32),
                    ),
                    
                    // Bottom Actions
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          if (_idCtrl.text.isEmpty || _pwCtrl.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('아이디와 비밀번호를 입력해 주세요.')),
                            );
                            return;
                          }
                          setState(() => _isLoading = true);
                          try {
                            await _authService.login(
                              loginId: _idCtrl.text,
                              password: _pwCtrl.text,
                            );
                            if (!mounted) return;
                            navigator.pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                              (Route<dynamic> route) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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
}
