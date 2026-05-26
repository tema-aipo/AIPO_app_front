import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../theme/app_colors.dart';
import '../services/ipo_service.dart';
import '../models/auth_manager.dart';

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
    final bool newState = !_isFavorite;
    setState(() => _isFavorite = newState);

    // 알림 메시지 정의
    final String companyName =
        _detailData?['summary']?['companyName'] ?? widget.ipoName;
    final String snackMessage = newState
        ? '$companyName가 관심 공모주에 등록되었습니다.'
        : '$companyName가 관심 공모주에서 해제되었습니다.';

    try {
      await _ipoService.toggleFavorite(widget.ipoId, newState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        setState(() => _isFavorite = true);
        return;
      }
      setState(() => _isFavorite = !newState);
      if (mounted) {
        final statusCode = e.response?.statusCode ?? 'unknown';
        final message = e.response?.data?['message'] ?? '관심 종목 변경에 실패했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$message ($statusCode)')),
        );
      }
    } catch (e) {
      setState(() => _isFavorite = !newState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심 종목 변경에 실패했습니다.')),
        );
      }
    }
  }

  // 헬퍼: 숫자 포맷팅 (예: 1250000 -> 1,250,000)
  String _formatNumber(dynamic val) {
    if (val == null) return '미정';
    final num? number = num.tryParse(val.toString());
    if (number == null) return val.toString();
    return number.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _formatDecimal(dynamic val, {int decimals = 2}) {
    if (val == null) return '미정';
    final num? number = num.tryParse(val.toString());
    if (number == null) return val.toString();
    return number.toStringAsFixed(decimals).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?=\.))'), (m) => '${m[1]},');
  }

  // 헬퍼: 날짜 포맷팅 (예: '2026-04-08' -> '2026.04.08')
  String _formatDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '미정';
    final parts = dateStr.split('-');
    if (parts.length >= 3) {
      final month = int.parse(parts[1]).toString().padLeft(2, '0');
      final day = int.parse(parts[2]).toString().padLeft(2, '0');
      return '${parts[0]}.$month.$day';
    }
    return dateStr;
  }

  // 헬퍼: 날짜 기간 포맷팅 (예: '2026.04.08 ~ 04.09')
  String _formatDateRange(String? startStr, String? endStr) {
    if ((startStr == null || startStr.isEmpty) &&
        (endStr == null || endStr.isEmpty)) return '미정';
    if (startStr == null || startStr.isEmpty) return _formatDateShort(endStr);
    if (endStr == null || endStr.isEmpty) return _formatDateShort(startStr);

    final startParts = startStr.split('-');
    final endParts = endStr.split('-');

    if (startParts.length >= 3 && endParts.length >= 3) {
      final startYear = startParts[0];
      final endYear = endParts[0];
      final startMonth = int.parse(startParts[1]).toString().padLeft(2, '0');
      final startDay = int.parse(startParts[2]).toString().padLeft(2, '0');
      final endMonth = int.parse(endParts[1]).toString().padLeft(2, '0');
      final endDay = int.parse(endParts[2]).toString().padLeft(2, '0');

      if (startYear == endYear) {
        return '$startYear.$startMonth.$startDay ~ $endMonth.$endDay';
      }
    }

    return '${_formatDateShort(startStr)} ~ ${_formatDateShort(endStr)}';
  }

  // 헬퍼: 기관수요예측 데이터가 완전히 비었는지 감지
  bool _isForecastEmpty(Map<String, dynamic> forecast) {
    return forecast.isEmpty ||
        (forecast['institutionalCompetitionRate'] == null &&
            forecast['participatingInstitutionCount'] == null &&
            forecast['lockupRate'] == null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_detailData == null) {
      return const Scaffold(body: Center(child: Text('데이터를 찾을 수 없습니다.')));
    }

    final data = _detailData!;
    final summary = data['summary'] ?? {};
    final attraction = data['attraction'] ?? {};
    final attractiveness = data['attractiveness'] ?? {};
    final forecast = data['demandForecast'] ?? {};
    final schedule = data['schedule'] ?? {};
    final depositInfos = data['depositInfos'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AppColors.primaryRed : AppColors.textGray),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [섹션 1] 헤더 - 로고, 회사명, 설명, 요약 3열카드
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          summary['companyName'] ?? widget.ipoName,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bgLightBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getMarketTypeBadgeLabel(summary['marketType']) ??
                              '미정',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary['oneLineDescription'] ?? '정보 수집 중입니다.',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textGray, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildQuickStatsRow(summary),
            const SizedBox(height: 32),

            // [섹션 2] AIPO 매력지수 (기존 UI 보존)
            _buildScoreCard(attraction, attractiveness),
            const SizedBox(height: 32),

            // [섹션 3] 기관 수요예측 결과
            _buildSectionTitle('기관 수요예측 결과'),
            const SizedBox(height: 16),
            if (_isForecastEmpty(forecast))
              _buildEmptyDataCard()
            else
              _buildInfoCard([
                _buildInfoRow(
                    '단순기관 경쟁률',
                    forecast['institutionalCompetitionRate'] != null
                        ? '${_formatNumber(forecast['institutionalCompetitionRate'])}:1'
                        : '미정'),
                _buildInfoRow(
                    '수요예측 참여기관수',
                    forecast['participatingInstitutionCount'] != null
                        ? '${_formatNumber(forecast['participatingInstitutionCount'])}곳'
                        : '미정'),
                _buildInfoRow(
                    '공모가 상단이상 참여 비율',
                    forecast['aboveUpperPriceCompetitionRate'] != null
                        ? '${_formatDecimal(forecast['aboveUpperPriceCompetitionRate'])}%'
                        : '미정'),
                _buildInfoRow(
                    '공모가 상단이상 참여기관수',
                    forecast['aboveUpperPriceInstitutionCount'] != null
                        ? '${_formatNumber(forecast['aboveUpperPriceInstitutionCount'])}곳'
                        : '미정'),
                _buildInfoRow(
                    '의무보유확약 경쟁률',
                    forecast['lockupCompetitionRate'] != null
                        ? '${_formatNumber(forecast['lockupCompetitionRate'])}:1'
                        : '미정'),
                _buildInfoRow(
                    '의무보유확약 기관수',
                    forecast['lockupInstitutionCount'] != null
                        ? '${_formatNumber(forecast['lockupInstitutionCount'])}곳'
                        : '미정'),
                _buildInfoRow(
                    '의무보유확약 비율',
                    forecast['lockupRate'] != null
                        ? '${forecast['lockupRate']}%'
                        : '미정'),
              ]),
            const SizedBox(height: 32),

            // [섹션 4] 청약 일정 (타임라인)
            _buildTimelineSection(
                schedule, summary['companyName'] ?? widget.ipoName),

            // [섹션 6] 청약증거금
            _buildDepositSection(depositInfos),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark));
  }

  // 요약 3열 위젯
  Widget _buildQuickStatsRow(Map<String, dynamic> summary) {
    final String confirmedPrice = summary['confirmedOfferPrice'] != null
        ? '${_formatNumber(summary['confirmedOfferPrice'])}원'
        : '미정';
    final List? leadManagersList = summary['leadManagers'] as List?;
    final String leadManager =
        (leadManagersList != null && leadManagersList.isNotEmpty)
            ? leadManagersList.first.toString()
            : '미정';
    final String dateRange = _formatDateRange(
        summary['subscriptionPeriod']?['startDate'],
        summary['subscriptionPeriod']?['endDate']);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('확정공모가',
                    style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(confirmedPrice,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(height: 32, width: 0.5, color: AppColors.borderGray),
          Expanded(
            child: Column(
              children: [
                const Text('주관사',
                    style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(leadManager,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(height: 32, width: 0.5, color: AppColors.borderGray),
          Expanded(
            child: Column(
              children: [
                const Text('청약일',
                    style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  dateRange,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentTypeBadge(String type) {
    final clean = type.startsWith('#') ? type : '#$type';
    final Color bg;
    final Color text;
    if (clean == '#공격형') {
      bg = const Color(0xFFFFEAEA);
      text = const Color(0xFFD32F2F);
    } else if (clean == '#중립형') {
      bg = const Color(0xFFE2F6EA);
      text = const Color(0xFF107C41);
    } else if (clean.replaceAll(' ', '') == '#분석대기중') {
      bg = const Color(0xFFEEEEEE);
      text = const Color(0xFF9E9E9E);
    } else {
      bg = AppColors.bgLightBlue;
      text = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        clean,
        style: TextStyle(
          fontSize: 12,
          color: text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseTopFactors(List reasons, {int top = 2}) {
    final entries = <Map<String, dynamic>>[];
    for (final r in reasons) {
      final desc = (r['description'] ?? '') as String;
      final title = (r['title'] ?? '') as String;
      final match = RegExp(r'× ([\d.]+)%').firstMatch(desc);
      if (match == null) continue;
      final weight = double.tryParse(match.group(1)!) ?? 0;
      final name = title.replaceAll(RegExp(r'\s*반영점수\s*\d+점'), '').trim();
      entries.add({'name': name, 'weight': weight});
    }
    entries.sort(
        (a, b) => (b['weight'] as double).compareTo(a['weight'] as double));
    return entries.take(top).toList();
  }

  String _generateFactorComment(List reasons) {
    final all = _parseTopFactors(reasons, top: reasons.length);
    if (all.isEmpty) return '';

    final topWeight = all[0]['weight'] as double;
    final secondWeight = all.length > 1 ? all[1]['weight'] as double : 0.0;

    final List<String> mainFactors;
    final String suffix;

    if (topWeight > secondWeight * 1.5) {
      mainFactors = [all[0]['name'] as String];
      suffix = ' 지표를 중심으로 반영한 점수입니다.';
    } else {
      final significant =
          all.where((e) => (e['weight'] as double) >= 20).toList();
      if (significant.length >= 3) {
        mainFactors =
            significant.take(3).map((e) => e['name'] as String).toList();
        suffix = ' 지표를 균형있게 반영한 점수입니다.';
      } else {
        mainFactors = all.take(2).map((e) => e['name'] as String).toList();
        suffix = ' 지표를 중심으로 반영한 점수입니다.';
      }
    }

    return mainFactors.join(', ') + suffix;
  }

  Widget _buildFactorComment(List reasons) {
    final comment = _generateFactorComment(reasons);
    if (comment.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        comment,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textDark.withOpacity(0.65),
          height: 1.5,
        ),
      ),
    );
  }

  // [섹션 2] AIPO 매력지수 (기존 완벽한 카드 그대로 사용)
  Widget _buildScoreCard(
      Map<String, dynamic> attraction, Map<String, dynamic> attractiveness) {
    final selected = attractiveness['selected'] as Map<String, dynamic>?;
    final defaultScore = attractiveness['default'] as Map<String, dynamic>?;
    final scoreData = selected ?? defaultScore;
    final rawScore = scoreData?['score'] ??
        attraction['totalScore'] ??
        _detailData?['score'] ??
        _detailData?['attractionScore'] ??
        0;
    final score = double.tryParse(rawScore.toString())?.round() ?? 0;
    final List reasons = attraction['reasons'] as List? ?? [];
    final rawType = AuthManager.instance.user?.investmentType ?? '';
    final investmentType =
        rawType.startsWith('#') ? rawType.substring(1) : rawType;

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
              const Text('AIPO 매력지수',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              Text('$score점',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          if (investmentType.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  '나의 투자성향 : ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildInvestmentTypeBadge(investmentType),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (investmentType.replaceAll(' ', '') == '분석대기중')
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '투자성향검사를 진행하지 않아 가중치를 반영하지 않은 기본 점수입니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark.withOpacity(0.65),
                  height: 1.5,
                ),
              ),
            )
          else if (reasons.isNotEmpty)
            _buildFactorComment(reasons),
          const SizedBox(height: 8),
          const Divider(color: AppColors.primary, thickness: 0.5),
          const SizedBox(height: 20),
          if (reasons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '산정 근거 데이터가 없습니다.',
                  style: TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
              ),
            )
          else
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
                      child: Icon(Icons.check_circle_outline,
                          size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark)),
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(description,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          AppColors.textDark.withOpacity(0.7),
                                      height: 1.4)),
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

  // [섹션 4] 청약 일정 (타임라인)
  Widget _buildTimelineSection(
      Map<String, dynamic> schedule, String companyName) {
    final demandForecast = schedule['demandForecastPeriod'] ?? {};
    final subPeriod = schedule['subscriptionPeriod'] ?? {};
    final refundDate = schedule['refundDate'];
    final listingDate = schedule['listingDate'];

    final String demandStr = _formatDateRange(
        demandForecast['startDate'], demandForecast['endDate']);
    final String subStr =
        _formatDateRange(subPeriod['startDate'], subPeriod['endDate']);
    final String refundStr = _formatDateShort(refundDate);
    final String listingStr = _formatDateShort(listingDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('$companyName 일정'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              _buildTimelineRow('수요예측일', demandStr),
              const SizedBox(height: 20),
              _buildTimelineRow('청약일', subStr),
              const SizedBox(height: 20),
              _buildTimelineRow('환불일', refundStr),
              const SizedBox(height: 20),
              _buildTimelineRow('상장일', listingStr),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTimelineRow(String label, String dateStr) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          dateStr,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // [섹션 6] 증권사별 배정 수량 목록
  Widget _buildDepositSection(List<dynamic> depositInfos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('청약 증권사'),
        const SizedBox(height: 16),
        if (depositInfos.isEmpty)
          _buildEmptyDataCard()
        else
          ...depositInfos.map((item) {
            final String name = item['securitiesCompanyName'] ?? '미정';
            final allocatedShareCount = item['allocatedShareCount'];
            final subscriptionLimitShareCount =
                item['subscriptionLimitShareCount'];
            final String? note = item['note']?.toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.borderGray.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF9E6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Color(0xFFF2C94C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSubscriptionCompanyMetric('배정 수량', allocatedShareCount),
                  const SizedBox(height: 10),
                  _buildSubscriptionCompanyMetric(
                      '청약 한도', subscriptionLimitShareCount),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildSubscriptionCompanyMetric('비고', note),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 20), // 32 - 12 (last item margin)
      ],
    );
  }

  Widget _buildSubscriptionCompanyMetric(String label, dynamic value) {
    final String valueText = value == null
        ? '미정'
        : value is num
            ? '${_formatNumber(value)}주'
            : value.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valueText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: AppColors.textLightGray, size: 28),
          SizedBox(height: 8),
          Text(
            '미정',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String? _getMarketTypeBadgeLabel(String? marketType) {
    switch (marketType?.toUpperCase()) {
      case 'KOSPI':
        return 'KOSPI';
      case 'KOSDAQ':
        return 'KOSDAQ';
      case 'KONEX':
        return 'KONEX';
      default:
        return null;
    }
  }
}
