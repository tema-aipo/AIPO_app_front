import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/signup_stepper.dart';
import '../services/auth_service.dart';
import '../services/investment_profile_service.dart';
import '../models/auth_manager.dart';

class SignupStep3Screen extends StatefulWidget {
  final bool isSkipped;
  final bool isRetest;
  final Map<String, String>? signupData;
  final int? version;
  final List<Map<String, dynamic>>? answers;
  
  const SignupStep3Screen({
    super.key,
    this.isSkipped = false,
    this.isRetest = false,
    this.signupData,
    this.version,
    this.answers,
  });

  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  bool _isSubmittingProfile = false;
  final AuthService _authService = AuthService();
  final InvestmentProfileService _profileService = InvestmentProfileService();

  // 백엔드로부터 받은 투자성향 결과
  Map<String, dynamic>? _profileResult;

  @override
  void initState() {
    super.initState();
    if (widget.isRetest) {
      if (!widget.isSkipped && widget.answers != null) {
        _submitRetestResult();
      }
    } else {
      _registerAndSubmitProfile();
    }
  }

  Future<void> _registerAndSubmitProfile() async {
    final data = widget.signupData;
    if (data == null) return;

    setState(() => _isSubmittingProfile = true);
    try {
      // 1. 회원가입 API 호출 → userId 반환
      final userId = await _authService.register(
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

      // 3. 투자성향 결과 제출 (스킵하지 않은 경우)
      if (!widget.isSkipped && widget.version != null && widget.answers != null) {
        final result = await _profileService.submitResult(
          userId: userId,
          version: widget.version!,
          answers: widget.answers!,
        );
        final profileLabel = result['profileLabel'] ?? '';
        if (profileLabel.isNotEmpty) {
          AuthManager.instance.updateInvestmentType(profileLabel);
        }
        if (mounted) {
          setState(() {
            _profileResult = result;
            _isSubmittingProfile = false;
          });
        }
      } else if (widget.isSkipped && widget.version != null) {
        // 스킵한 경우
        await _profileService.skipProfile(
          userId: userId,
          version: widget.version!,
        );
        AuthManager.instance.updateInvestmentType('분석대기중');
        if (mounted) {
          setState(() {
            _isSubmittingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isSubmittingProfile = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 처리 실패: $e')),
        );
      }
    }
  }

  Future<void> _submitRetestResult() async {
    if (widget.version == null || widget.answers == null) return;
    setState(() => _isSubmittingProfile = true);
    try {
      final result = await _profileService.retestProfile(
        version: widget.version!,
        answers: widget.answers!,
      );
      
      // AuthManager의 투자 성향도 업데이트
      final profileLabel = result['profileLabel'] ?? '';
      if (profileLabel.isNotEmpty) {
        AuthManager.instance.updateInvestmentType(profileLabel);
      }

      if (!mounted) return;
      setState(() {
        _profileResult = result;
        _isSubmittingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('투자성향 결과 처리 실패: $e')),
      );
    }
  }

  Future<void> _handleComplete() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  // 프로필 타입에 따른 UI 데이터 (백엔드 응답 기반)
  _ProfileDisplayData _getDisplayData() {
    // 스킵 또는 API 미호출 시 기본값
    if (widget.isSkipped) {
      return _ProfileDisplayData(
        icon: Icons.chat_bubble_outline,
        mainColor: AppColors.primary,
        title: '분석 대기중',
        description: '성향 검사를 건너뛰어 기본 설정으로 시작합니다. 마이페이지에서 언제든지 검사를 진행하고 1:1 맞춤형 서비스를 받아보실 수 있습니다.',
        tags: ['#기본설정', '#언제든검사가능'],
      );
    }

    // 백엔드 결과가 있는 경우
    if (_profileResult != null) {
      final String profileLabel = _profileResult!['profileLabel'] ?? '안정형';
      final String description = _profileResult!['description'] ?? '';
      final List<dynamic> rawTags = _profileResult!['tags'] ?? [];
      final List<String> tags = rawTags.map((t) => '#$t').toList();

      IconData icon;
      Color mainColor;
      switch (profileLabel) {
        case '공격형':
          icon = Icons.rocket_launch_outlined;
          mainColor = AppColors.primaryRed;
          break;
        case '중립형':
          icon = Icons.balance_outlined;
          mainColor = AppColors.primaryGreen;
          break;
        case '안정형':
        default:
          icon = Icons.security;
          mainColor = AppColors.primary;
          break;
      }

      return _ProfileDisplayData(
        icon: icon,
        mainColor: mainColor,
        title: profileLabel,
        description: description,
        tags: tags,
      );
    }

    // 기본값 (답변 제출 전 or 로딩 중)
    return _ProfileDisplayData(
      icon: Icons.security,
      mainColor: AppColors.primary,
      title: '안정형',
      description: '안정적인 수익을 추구하며, 리스크를 최소화하고 우량 공모주 위주의 안전한 투자를 선호합니다.',
      tags: ['#안전제일', '#우량주선호'],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 재검사 결과 로딩 중
    if (_isSubmittingProfile) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(widget.isRetest ? '검사 결과' : '회원가입', style: AppTextStyles.appBarTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                widget.isRetest ? '투자 성향을 분석하고 있습니다...' : '회원가입 결과를 처리하고 있습니다...', 
                style: const TextStyle(color: AppColors.textGray)
              ),
            ],
          ),
        ),
      );
    }

    final displayData = _getDisplayData();
    final bool isPending = widget.isSkipped;

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
                        color: isPending ? AppColors.bgLightBlue : displayData.mainColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        displayData.icon,
                        color: displayData.mainColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      displayData.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: displayData.mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      displayData.description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyRegular,
                    ),
                    const SizedBox(height: 24),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: displayData.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPending ? AppColors.bgGray : displayData.mainColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isPending ? AppColors.textBody : displayData.mainColor,
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
                  onPressed: _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(widget.isRetest ? '완료' : 'AIPO 시작하기', style: AppTextStyles.buttonText),
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

class _ProfileDisplayData {
  final IconData icon;
  final Color mainColor;
  final String title;
  final String description;
  final List<String> tags;

  _ProfileDisplayData({
    required this.icon,
    required this.mainColor,
    required this.title,
    required this.description,
    required this.tags,
  });
}
