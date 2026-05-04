import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/favorite_manager.dart';

class IpoDetailScreen extends StatefulWidget {
  final String ipoName;

  const IpoDetailScreen({super.key, required this.ipoName});

  @override
  State<IpoDetailScreen> createState() => _IpoDetailScreenState();
}

class _IpoDetailScreenState extends State<IpoDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = FavoriteManager.instance.isFavorite(widget.ipoName);
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPlaceholder = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textGray, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: isPlaceholder ? AppColors.primary : AppColors.textDark,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, String date, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.borderGray,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.textDark : AppColors.textGray,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            date,
            style: TextStyle(
              color: isActive ? AppColors.textDark : AppColors.textGray,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder string for convenience
    const String placeholder = '[데이터 연동 대기]';

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        backgroundColor: AppColors.bgGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // 1. Header Card
              _buildCard(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -18,
                      right: -18,
                      child: IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? AppColors.primaryRed : AppColors.textGray,
                          size: 26,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          FavoriteManager.instance.toggleFavorite(widget.ipoName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isFavorite ? '관심 종목으로 등록되었습니다.' : '관심 종목에서 해제되었습니다.'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.layers, color: AppColors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.ipoName, // dynamic from listing
                          style: AppTextStyles.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '차세대 우주항공 혁신 선도기업',
                          style: TextStyle(color: AppColors.textGray, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.borderGray, thickness: 0.5),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            children: [
                              Text('확정공모가', style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                              SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(placeholder, style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.borderGray),
                        const Expanded(
                          child: Column(
                            children: [
                              Text('주관사', style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                              SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(placeholder, style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.borderGray),
                        const Expanded(
                          child: Column(
                            children: [
                              Text('청약일', style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                              SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(placeholder, style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

              // 2. Score Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('AIPO 매력지수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        Spacer(),
                        Text(placeholder, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgLightBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('매력지수 산정 근거 (임시 데이터)', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                          SizedBox(height: 12),
                          Text('• 기관 수요예측 지수: $placeholder', style: TextStyle(color: AppColors.textBody, fontSize: 13, height: 1.6)),
                          Text('• 유통가능물량 지수: $placeholder', style: TextStyle(color: AppColors.textBody, fontSize: 13, height: 1.6)),
                          Text('• 의무보유확약 지수: $placeholder', style: TextStyle(color: AppColors.textBody, fontSize: 13, height: 1.6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Institutional Results Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('기관 수요예측 결과', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 24),
                    _buildInfoRow('단순기관 경쟁률', placeholder, isPlaceholder: true),
                    _buildInfoRow('수요예측 참여기관수', placeholder, isPlaceholder: true),
                    _buildInfoRow('공모가 상단이상 경쟁률', placeholder, isPlaceholder: true),
                    _buildInfoRow('공모가 상단이상 참여기관수', placeholder, isPlaceholder: true),
                    _buildInfoRow('의무보유확약 경쟁률', placeholder, isPlaceholder: true),
                    _buildInfoRow('의무보유확약 기관수', placeholder, isPlaceholder: true),
                    _buildInfoRow('의무보유확약 비율', placeholder, isPlaceholder: true),
                  ],
                ),
              ),

              // 4. Competition Rate Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('청약 경쟁률', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 20),
                    // Toggle Mockup
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF383838),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(child: Text('균등배정', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(color: AppColors.borderGray),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(child: Text('비례배정', style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w700))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('예상 균등 배정 수량', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        Text(placeholder, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.borderGray, thickness: 0.5),
                    const SizedBox(height: 20),
                    _buildInfoRow('통합 경쟁률', placeholder, isPlaceholder: true),
                  ],
                ),
              ),

              // 5. Schedule Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('청약 일정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 24),
                    _buildScheduleRow('수요예측일', placeholder, false),
                    _buildScheduleRow('청약일', placeholder, true), // active
                    _buildScheduleRow('환불일', placeholder, false),
                    _buildScheduleRow('상장일', placeholder, false),
                  ],
                ),
              ),

              // 6. Deposit Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('청약증거금', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.square, color: Colors.white, size: 10),
                        ),
                        const SizedBox(width: 12),
                        const Text(placeholder, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const Spacer(),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(placeholder, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 7. General Info Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('공모주 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 24),
                    _buildInfoRow('시가총액', placeholder, isPlaceholder: true),
                    _buildInfoRow('균등배정비율', placeholder, isPlaceholder: true),
                    _buildInfoRow('유통가능비율', placeholder, isPlaceholder: true),
                    _buildInfoRow('구주매출비율', placeholder, isPlaceholder: true),
                  ],
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
