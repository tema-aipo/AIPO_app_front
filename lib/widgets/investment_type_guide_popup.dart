import 'package:flutter/material.dart';
import '../models/auth_manager.dart';
import '../theme/app_colors.dart';

class InvestmentTypeGuidePopup extends StatelessWidget {
  final VoidCallback? onGoToMyPage;

  const InvestmentTypeGuidePopup({super.key, this.onGoToMyPage});

  static const _types = [
    _TypeInfo(
      type: '#안정형',
      icon: Icons.shield_outlined,
      bg: Color(0xFFE7F0FF),
      text: AppColors.primary,
      summary: '기관 검증 지표 중심',
      detail: '의무보유확약 비율과 기관 수요예측 경쟁률에\n높은 가중치를 적용합니다. 기관이 검증한\n안정적인 종목을 우선 추천합니다.',
    ),
    _TypeInfo(
      type: '#중립형',
      icon: Icons.balance_outlined,
      bg: Color(0xFFE2F6EA),
      text: Color(0xFF107C41),
      summary: '전 지표 균형 반영',
      detail: '기관 지표와 일반 청약 지표를 균등하게\n반영합니다. 다양한 종목을 고르게 평가해\n폭넓은 투자 기회를 제공합니다.',
    ),
    _TypeInfo(
      type: '#공격형',
      icon: Icons.rocket_launch_outlined,
      bg: Color(0xFFFFEAEA),
      text: Color(0xFFD32F2F),
      summary: '청약 열기 지표 중심',
      detail: '청약 경쟁률과 공모가 상단 참여율에\n높은 가중치를 적용합니다. 시장 기대가\n높은 고수익 가능 종목을 우선 추천합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rawType = AuthManager.instance.user?.investmentType ?? '#분석대기중';
    final userType = rawType.startsWith('#') ? rawType : '#$rawType';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.58,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreExplanation(),
                    const SizedBox(height: 20),
                    _buildTypeCards(userType),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgLightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '투자 성향 가이드',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close, color: AppColors.textGray, size: 22),
        ),
      ],
    );
  }

  Widget _buildScoreExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLightBlue.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 15, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'AIPO 매력지수란?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '기관 수요예측 경쟁률, 의무보유확약 비율, 청약 경쟁률 등의 지표를 종합해 산출하는 공모주 매력 점수입니다.\n\n투자 성향에 따라 각 지표의 반영 비율이 달라져, 같은 종목도 성향마다 점수가 다르게 표시될 수 있습니다.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textDark.withOpacity(0.75),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCards(String currentType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성향별 특징',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ..._types.map((info) => _buildTypeCard(info, currentType)),
      ],
    );
  }

  Widget _buildTypeCard(_TypeInfo info, String currentType) {
    final isCurrent = currentType == info.type;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? info.bg.withOpacity(0.5) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? info.text.withOpacity(0.4) : AppColors.borderGray.withOpacity(0.5),
          width: isCurrent ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: info.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(info.icon, size: 18, color: info.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: info.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        info.type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: info.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      info.summary,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGray,
                      ),
                    ),
                    if (isCurrent) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: info.text.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '내 성향',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: info.text,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  info.detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 0.5, color: AppColors.borderGray),
        const SizedBox(height: 14),
        const Text(
          '마이페이지 > 설정에서 성향을 재검사할 수 있어요.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onGoToMyPage?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              '마이페이지로 이동',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeInfo {
  final String type;
  final IconData icon;
  final Color bg;
  final Color text;
  final String summary;
  final String detail;

  const _TypeInfo({
    required this.type,
    required this.icon,
    required this.bg,
    required this.text,
    required this.summary,
    required this.detail,
  });
}
