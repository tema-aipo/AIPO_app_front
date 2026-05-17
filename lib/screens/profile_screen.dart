import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../theme/app_colors.dart';
import '../models/auth_manager.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 비밀번호 필드를 입력해 주세요.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 비밀번호와 비밀번호 확인이 일치하지 않습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _userService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      await _authService.logout();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 안전하게 변경되었습니다. 보안을 위해 다시 로그인해 주세요.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      String errMsg = '비밀번호 변경에 실패했습니다.';
      if (e is DioException) {
        if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
          if (e.response?.data != null && e.response?.data is Map) {
            final code = e.response?.data['code'];
            if (code == 'INVALID_PASSWORD') {
              errMsg = '현재 비밀번호가 올바르지 않습니다.';
            } else {
              errMsg = e.response?.data['message'] ?? errMsg;
            }
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthManager.instance.currentUser.value;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textDark, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('내 정보', style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: AppColors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildDisabledRow('이름', user?.name ?? '사용자'),
                  const Divider(color: AppColors.borderGray, height: 1, thickness: 0.5),
                  _buildDisabledRow('아이디', user?.id ?? 'guest'),
                  const Divider(color: AppColors.borderGray, height: 1, thickness: 0.5),
                  _buildDisabledRow('이메일', user?.email ?? 'guest@hello.com'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Password Section
            const Text('비밀번호 변경', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildTextField('현재 비밀번호', _currentPasswordController, _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 16),
            _buildTextField('새 비밀번호 (영문, 숫자, 특수문자 조합)', _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 16),
            _buildTextField('새 비밀번호 확인', _confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 48),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('변경 완료', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline, color: AppColors.textGray, size: 16),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 15, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textGray,
            size: 22,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderGray.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
