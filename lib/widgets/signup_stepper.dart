import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SignupStepper extends StatelessWidget {
  final int currentStep;

  const SignupStepper({super.key, required this.currentStep});

  Widget _buildStepIndicator(String number, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.white,
            shape: BoxShape.circle,
            border: isActive ? null : Border.all(color: AppColors.borderGray, width: 1.5),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.textGray, // Step 3 pending used E0E0E0 but textGray is consistent
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textGray,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 50,
      height: 1.5,
      color: AppColors.borderGray,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStepIndicator('1', '정보입력', currentStep == 1),
        _buildStepLine(),
        _buildStepIndicator('2', '투자성향검사', currentStep == 2),
        _buildStepLine(),
        _buildStepIndicator('3', '완료', currentStep == 3),
      ],
    );
  }
}
