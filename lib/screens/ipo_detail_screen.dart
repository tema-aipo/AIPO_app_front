import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final data = await _ipoService.getIpoDetail(widget.ipoId);
      setState(() {
        _detailData = data;
        // 백엔드 매핑: summary 내부에 isFavorite 존재
        _isFavorite = data['summary']?['isFavorite'] ?? false;
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
    try {
      await _ipoService.toggleFavorite(widget.ipoId, !_isFavorite);
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심 종목 변경에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_detailData == null) {
      return const Scaffold(body: Center(child: Text('데이터를 찾을 수 없습니다.')));
    }

    final data = _detailData!;
    final summary = data['summary'] ?? {};
    final attraction = data['attraction'] ?? {};
    final forecast = data['demandForecast'] ?? {};
    final schedule = data['schedule'] ?? {};
    final subscriptionPeriod = schedule['subscriptionPeriod'] ?? {};
    final depositInfos = data['depositInfos'] as List? ?? [];
    final offeringInfo = data['offeringInfo'] ?? {};

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? AppColors.primaryRed : AppColors.textGray),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(summary['companyName'] ?? widget.ipoName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(summary['oneLineDescription'] ?? '정보 수집 중입니다.', style: const TextStyle(fontSize: 15, color: AppColors.textGray, height: 1.4)),
            const SizedBox(height: 24),

            // Score Card
            _buildScoreCard(attraction),
            const SizedBox(height: 32),

            // Demand Forecast
            _buildSectionTitle('수요예측 결과'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoRow('기관 경쟁률', '${forecast['institutionalCompetitionRate'] ?? '-'} : 1'),
              _buildInfoRow('의무보유 확약', '${forecast['lockupRate'] ?? '-'} %'),
              _buildInfoRow('공모가', '${summary['confirmedOfferPrice'] ?? '-'} 원'),
            ]),
            const SizedBox(height: 32),

            // Schedule
            _buildSectionTitle('공모 일정'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoRow('청약일', '${subscriptionPeriod['startDate'] ?? '-'} ~ ${subscriptionPeriod['endDate'] ?? '-'}'),
              _buildInfoRow('환불일', schedule['refundDate'] ?? '-'),
              _buildInfoRow('상장일', schedule['listingDate'] ?? '-'),
            ]),
            const SizedBox(height: 32),

            // Deposit
            _buildSectionTitle('청약 정보'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoRow('주관사', (summary['leadManagers'] as List?)?.join(', ') ?? '-'),
              _buildInfoRow('최소 청약 증거금', '${depositInfos.isNotEmpty ? depositInfos[0]['amountForTenShares'] : '-'} 원'),
              _buildInfoRow('유통 가능 물량', '${offeringInfo['circulatingRatio'] ?? '-'} %'),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark));
  }

  Widget _buildScoreCard(Map<String, dynamic> attraction) {
    final score = attraction['totalScore'] ?? 0;
    final List reasons = attraction['reasons'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgLightBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AIPO 매력지수', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Text('$score점', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.primary, thickness: 0.5),
          const SizedBox(height: 20),
          ...reasons.map((reason) {
            final String title = reason['title'] ?? '';
            final String description = reason['description'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        if (description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(description, style: TextStyle(fontSize: 13, color: AppColors.textDark.withOpacity(0.7), height: 1.4)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textGray, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
