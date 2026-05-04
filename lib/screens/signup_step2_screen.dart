import 'package:flutter/material.dart';
import 'signup_step3_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/signup_stepper.dart';

class SurveyQuestion {
  final String text;
  final List<String> options;
  SurveyQuestion({required this.text, required this.options});
}

class SignupStep2Screen extends StatefulWidget {
  final bool isRetest;
  const SignupStep2Screen({super.key, this.isRetest = false});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  int _currentIndex = 0;
  final List<int?> _selectedAnswers = List.filled(6, null);

  final List<SurveyQuestion> _questions = [
    SurveyQuestion(
      text: 'Q1. 공모주 청약 참여 경험이 얼마나 있으신가요?',
      options: ['전혀 없음', '1~2회 참여', '3~5회 참여', '6회 이상 정기적 참여'],
    ),
    SurveyQuestion(
      text: 'Q2. 상장 첫날 -20% 하락 시 어떻게 대응하시나요?',
      options: ['즉시 매도', '상황 지켜봄', '추가 매수 고려', '장기 보유 전환'],
    ),
    SurveyQuestion(
      text: 'Q3. 투자설명서 검토 수준은 어느 정도이신가요?',
      options: ['거의 보지 않음', '요약본만 확인', '주요 재무·공모 구조 확인', '산업 전망·경쟁사 분석까지'],
    ),
    SurveyQuestion(
      text: 'Q4. IPO 중 고위험·고수익 기대 종목(바이오·테크 등)에 적극 청약한다.',
      options: ['전혀 동의하지 않음', '동의하지 않음', '동의함', '매우 동의함'],
    ),
    SurveyQuestion(
      text: 'Q5. IPO 상장 후 단기 변동성을 감수하며 고수익 추구한다.',
      options: ['전혀 동의하지 않음', '동의하지 않음', '동의함', '매우 동의함'],
    ),
    SurveyQuestion(
      text: 'Q6. 포트폴리오의 20% 이상을 IPO 청약에 배분할 수 있다.',
      options: ['전혀 동의하지 않음', '동의하지 않음', '동의함', '매우 동의함'],
    ),
  ];

  void _handleNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                SignupStep3Screen(isSkipped: false, isRetest: widget.isRetest)),
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
                      builder: (_) => const SignupStep3Screen(isSkipped: true)),
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
    final currentQ = _questions[_currentIndex];
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

              // Question Text
              Text(
                currentQ.text,
                style: AppTextStyles.h3,
              ),

              const SizedBox(height: 32),

              // Options List
              Expanded(
                child: ListView.separated(
                  itemCount: currentQ.options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bool isSelected =
                        _selectedAnswers[_currentIndex] == index;

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
                          currentQ.options[index],
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
