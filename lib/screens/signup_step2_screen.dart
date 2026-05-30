import 'package:flutter/material.dart';
import 'signup_step3_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/signup_stepper.dart';
import '../services/investment_profile_service.dart';

class SignupStep2Screen extends StatefulWidget {
  final bool isRetest;
  final Map<String, String>? signupData;
  const SignupStep2Screen({super.key, this.isRetest = false, this.signupData});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final InvestmentProfileService _profileService = InvestmentProfileService.instance;

  int _currentIndex = 0;
  List<int?> _selectedAnswers = [];

  // 백엔드에서 가져온 데이터
  bool _isLoadingQuestions = true;
  int? _version;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final data = await _profileService.getQuestions();
      final int version = data['version'] ?? 1;
      final List<dynamic> rawQuestions = data['questions'] ?? [];

      setState(() {
        _version = version;
        _questions = rawQuestions.cast<Map<String, dynamic>>();
        _selectedAnswers = List.filled(_questions.length, null);
        _isLoadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingQuestions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('질문을 불러오지 못했습니다: $e')),
      );
    }
  }

  void _handleNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // 모든 질문에 대한 답변을 수집하여 Step3으로 전달
      final List<Map<String, dynamic>> answers = [];
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final selectedIdx = _selectedAnswers[i];
        if (selectedIdx != null) {
          final List<dynamic> options = question['options'] ?? [];
          if (selectedIdx < options.length) {
            final option = options[selectedIdx] as Map<String, dynamic>;
            answers.add({
              'questionId': question['questionId'],
              'optionId': option['optionId'],
            });
          }
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SignupStep3Screen(
            isSkipped: false,
            isRetest: widget.isRetest,
            signupData: widget.signupData,
            version: _version,
            answers: answers,
          ),
        ),
      );
    }
  }

  void _handleSkip() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('안내',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: const Text(
            '정말 스킵하시겠습니까?\n(스킵할 시 매력지수 점수가 기본형으로 나타납니다)',
            style:
                TextStyle(fontSize: 15, height: 1.5, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소',
                  style: TextStyle(
                      color: AppColors.textLightGray,
                      fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupStep3Screen(
                      isSkipped: true,
                      signupData: widget.signupData,
                      version: _version,
                    ),
                  ),
                );
              },
              child: const Text('스킵하기',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이면 스피너 표시
    if (_isLoadingQuestions) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.isRetest ? '투자 성향 재검사' : '회원가입',
              style: AppTextStyles.appBarTitle),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('질문을 불러오는 중입니다...', style: TextStyle(color: AppColors.textGray)),
            ],
          ),
        ),
      );
    }

    // 질문이 없으면 에러 표시
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.isRetest ? '투자 성향 재검사' : '회원가입',
              style: AppTextStyles.appBarTitle),
        ),
        body: const Center(child: Text('질문을 불러올 수 없습니다.')),
      );
    }

    final currentQ = _questions[_currentIndex];
    final String questionText = currentQ['questionText'] ?? '';
    final List<dynamic> options = currentQ['options'] ?? [];
    final bool hasSelection = _selectedAnswers[_currentIndex] != null;

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
        title: Text(widget.isRetest ? '투자 성향 재검사' : '회원가입',
            style: AppTextStyles.appBarTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              if (!widget.isRetest) const SignupStepper(currentStep: 2),
              if (!widget.isRetest) const SizedBox(height: 40),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${_questions.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _questions.length,
                      backgroundColor: AppColors.borderGray,
                      color: AppColors.primary,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Question Text (백엔드 데이터 사용)
              Text(
                'Q${_currentIndex + 1}. $questionText',
                style: AppTextStyles.h3,
              ),

              const SizedBox(height: 32),

              // Options List (백엔드 데이터 사용)
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bool isSelected =
                        _selectedAnswers[_currentIndex] == index;
                    final option = options[index] as Map<String, dynamic>;
                    final String optionText = option['optionText'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAnswers[_currentIndex] = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.bgLightBlue
                              : AppColors.bgGray,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 1)
                              : Border.all(color: Colors.transparent, width: 1),
                        ),
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textBody,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Actions area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentIndex > 0
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.primary, size: 28),
                          onPressed: _handlePrevious,
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        )
                      : const SizedBox(width: 28), // padding to match structure

                  if (!widget.isRetest)
                    TextButton(
                      onPressed: _handleSkip,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '스킵하기',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textGray,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: hasSelection ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelection
                        ? AppColors.primary
                        : AppColors.disabledGray,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.disabledGray,
                    disabledForegroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex == _questions.length - 1 ? '결과 확인하기' : '다음',
                    style: AppTextStyles.buttonText,
                  ),
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
