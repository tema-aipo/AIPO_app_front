import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/ipo_service.dart';

class IpoDetailScreen extends StatefulWidget {
  final String ipoId;
  final String ipoName;

  const IpoDetailScreen({
    super.key, 
    required this.ipoId, 
    required this.ipoName,
  });

  @override
  State<IpoDetailScreen> createState() => _IpoDetailScreenState();
}

class _IpoDetailScreenState extends State<IpoDetailScreen> {
  final IpoService _ipoService = IpoService();
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchDetailData();
  }

  Future<void> _fetchDetailData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _ipoService.getIpoDetail(widget.ipoId);
      setState(() {
        _detailData = data;
        _isFavorite = data['isFavorite'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상세 정보를 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final originalState = _isFavorite;
    setState(() => _isFavorite = !originalState);
    
    try {
      await _ipoService.toggleFavorite(widget.ipoId, !originalState);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '관심 종목으로 등록되었습니다.' : '관심 종목에서 해제되었습니다.'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isFavorite = originalState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심 종목 설정에 실패했습니다.')),
        );
      }
    }
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

  Widget _buildInfoRow(String label, String value, {bool isAccent = false, bool isBold = false}) {
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
              color: isAccent ? AppColors.primary : AppColors.textDark,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, String? date, bool isActive) {
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
            date ?? '-',
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
    if (_isLoading && _detailData == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgGray,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final data = _detailData!;
    final score = data['attractionScore'];
    final forecast = data['demandForecast'];
    final schedule = data['schedule'];
    final deposit = data['depositInfo'];
    final offering = data['offeringInfo'];

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        backgroundColor: AppColors.bgGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.primaryRed : AppColors.textGray,
              size: 26,
            ),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // 1. Header Card
              _buildCard(
                child: Column(
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
                      widget.ipoName,
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['businessDescription'] ?? '종목 상세 정보',
                      style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.borderGray, thickness: 0.5),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('확정공모가', style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('${offering?['finalPrice'] ?? '미정'}원', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.borderGray),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('주관사', style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(data['leadManagers']?[0] ?? '-', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.borderGray),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('청약일', style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(schedule?['subscriptionStartDate'] ?? '-', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
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
                    Row(
                      children: [
                        const Text('AIPO 매력지수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        const Spacer(),
                        Text('${score?['score'] ?? '-'}점', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('매력지수 산정 근거', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          if (data['attractionReasons'] != null)
                            for (var reason in data['attractionReasons'] as List)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text('• $reason', style: const TextStyle(color: AppColors.textBody, fontSize: 13, height: 1.6)),
                              )
                          else
                            const Text('산정 근거 데이터가 없습니다.', style: TextStyle(color: AppColors.textBody, fontSize: 13)),
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
                    _buildInfoRow('단순기관 경쟁률', '${forecast?['competitionRate'] ?? '-'} : 1', isAccent: true),
                    _buildInfoRow('수요예측 참여기관수', '${forecast?['participatingInstitutions'] ?? '-'}개', isAccent: true),
                    _buildInfoRow('의무보유확약 비율', '${forecast?['commitmentRatio'] ?? '-'}%', isAccent: true),
                  ],
                ),
              ),

              // 4. Schedule Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('청약 일정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 24),
                    _buildScheduleRow('수요예측일', schedule?['forecastDate'], false),
                    _buildScheduleRow('청약일', '${schedule?['subscriptionStartDate']} ~ ${schedule?['subscriptionEndDate']}', true),
                    _buildScheduleRow('환불일', schedule?['refundDate'], false),
                    _buildScheduleRow('상장일', schedule?['listingDate'], false),
                  ],
                ),
              ),

              // 5. Deposit Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('청약증거금 (최소)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
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
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 12),
                        const Text('최소 청약 증거금', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const Spacer(),
                        Text('${deposit?['minDeposit'] ?? '-'}원', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),

              // 6. General Info Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('공모주 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 24),
                    _buildInfoRow('시가총액', '${offering?['marketCap'] ?? '-'}억원', isAccent: true),
                    _buildInfoRow('유통가능비율', '${offering?['floatingStockRatio'] ?? '-'}%', isAccent: true),
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
