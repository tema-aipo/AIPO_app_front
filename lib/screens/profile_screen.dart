import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/auth_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            _buildTextField('현재 비밀번호'),
            const SizedBox(height: 16),
            _buildTextField('새 비밀번호 (영문, 숫자, 특수문자 조합)'),
            const SizedBox(height: 16),
            _buildTextField('새 비밀번호 확인'),
            const SizedBox(height: 48),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('변경 완료', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
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

  Widget _buildTextField(String hint) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 15, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
