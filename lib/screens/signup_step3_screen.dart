import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/signup_stepper.dart';
import '../services/auth_service.dart';

enum InvestmentProfile { stable, aggressive, neutral, pending }

class ProfileData {
  final IconData icon;
  final Color mainColor;
  final String title;
  final String description;
  final List<String> tags;

  ProfileData({
    required this.icon,
    required this.mainColor,
    required this.title,
    required this.description,
    required this.tags,
  });
}

final Map<InvestmentProfile, ProfileData> profileDataMap = {
  InvestmentProfile.stable: ProfileData(
    icon: Icons.security,
    mainColor: AppColors.primary,
    title: '안정형',
    description: '안정적인 수익을 추구하며, 리스크를 최소화하고 우량 공모주 위주의 안전한 투자를 선호합니다.',
    tags: ['#안전제일', '#우량주선호'],
  ),
  InvestmentProfile.aggressive: ProfileData(
    icon: Icons.rocket_launch_outlined,
    mainColor: AppColors.primaryRed,
    title: '공격형',
    description: '다소의 리스크를 감수하더라도 높은 상장일 수익률을 목표로 하며, 적극적인 공모주 투자를 선호합니다.',
    tags: ['#고수익고위험', '#적극투자'],
  ),
  InvestmentProfile.neutral: ProfileData(
    icon: Icons.enhanced_encryption_outlined,
    mainColor: AppColors.primaryGreen,
    title: '중립형',
    description: '손실을 극도로 제한하며, 수익이 적더라도 확실하고 리스크가 없는 매우 보수적인 투자를 선호합니다.',
    tags: ['#원금방어', '#절대안전'],
  ),
  InvestmentProfile.pending: ProfileData(
    icon: Icons.chat_bubble_outline,
    mainColor: AppColors.primary,
    title: '분석 대기중',
    description: '성향 검사를 건너뛰어 기본 설정으로 시작합니다. 마이페이지에서 언제든지 검사를 진행하고 1:1 맞춤형 서비스를 받아보실 수 있습니다.',
    tags: ['#기본설정', '#언제든검사가능'],
  ),
};

class SignupStep3Screen extends StatefulWidget {
  final bool isSkipped;
  final bool isRetest;
  final Map<String, String>? signupData;
  
  const SignupStep3Screen({
    super.key,
    this.isSkipped = false,
    this.isRetest = false,
    this.signupData,
  });

  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleComplete() async {
    if (widget.isRetest) {
      // 재검사의 경우 바로 메인으로
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
      return;
    }

    // 신규 회원가입의 경우 API 호출
    final data = widget.signupData;
    if (data == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);
    try {
      // 1. 회원가입 API 호출
      await _authService.register(
        loginId: data['loginId']!,
        password: data['password']!,
        userName: data['userName']!,
        email: data['email'],
      );

      // 2. 자동 로그인
      await _authService.login(
        loginId: data['loginId']!,
        password: data['password']!,
      );

      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final InvestmentProfile currentProfile = widget.isSkipped ? InvestmentProfile.pending : InvestmentProfile.stable;
    final ProfileData data = profileDataMap[currentProfile]!;
    final bool isPending = currentProfile == InvestmentProfile.pending;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(widget.isRetest ? '검사 결과' : '회원가입', style: AppTextStyles.appBarTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              if (!widget.isRetest) const SignupStepper(currentStep: 3),
              if (!widget.isRetest) const SizedBox(height: 48),
              
              Text(
                widget.isRetest ? '새로운 성향 분석이\n완료되었습니다 🎉' : '환영합니다!\n회원가입이 완료되었습니다 🎉',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 16),
              const Text(
                '분석된 고객님의 공모주 투자 성향은 다음과 같습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.bgLightBlue : data.mainColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data.icon,
                        color: data.mainColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: data.mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyRegular,
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: data.tags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isPending ? AppColors.bgGray : data.mainColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isPending ? AppColors.textBody : data.mainColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
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
                      : Text(widget.isRetest ? '완료' : 'AIPO 시작하기', style: AppTextStyles.buttonText),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
