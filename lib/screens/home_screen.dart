import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'ipo_detail_screen.dart';
import 'home_search_screen.dart';
import 'notification_screen.dart';
import '../services/notification_service.dart';
import '../models/auth_manager.dart';
import '../widgets/investment_type_guide_popup.dart';
import '../widgets/ipo_card.dart';
import '../providers/home_provider.dart';
import '../utils/investment_type.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onGoToMyPage;

  const HomeScreen({super.key, this.onGoToMyPage});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _attractInitialCount = 4;
  static const int _attractStep = 4;
  static const int _attractMaxCount = 20;
  int _attractVisibleCount = _attractInitialCount;

  final GlobalKey _attractSectionKey = GlobalKey();

  final List<String> _filters = ['최근 상장순', '청약 진행/예정순', '관심 종목순'];

  void _onFilterTapped(int index) {
    final current = ref.read(homeFilterProvider);
    if (current == index) return;
    setState(() => _attractVisibleCount = _attractInitialCount);
    ref.read(homeFilterProvider.notifier).state = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _attractSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeDataProvider);
    final selectedFilterIndex = ref.watch(homeFilterProvider);
    final userType = AuthManager.instance.user?.investmentType ?? '#분석대기중';
    final badgeColors = getBadgeColors(userType);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeDataProvider.notifier).refresh(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section A: Top Action Row + AIPO's Pick
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text(
                            'AIPO',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => InvestmentTypeGuidePopup(
                                    onGoToMyPage: widget.onGoToMyPage,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: badgeColors['bg'],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        userType,
                                        style: TextStyle(
                                          color: badgeColors['text'],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.info_outline,
                                          size: 13, color: badgeColors['text']),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  ListenableBuilder(
                                    listenable: NotificationService.instance,
                                    builder: (context, _) {
                                      final unreadCount =
                                          NotificationService.instance.unreadCount;
                                      return GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const NotificationScreen()),
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            const Icon(Icons.campaign_outlined,
                                                color: AppColors.textDark, size: 28),
                                            if (unreadCount > 0)
                                              Positioned(
                                                top: -2,
                                                right: -2,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primaryRed,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.search,
                                        color: AppColors.textDark, size: 28),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const HomeSearchScreen()),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('오늘의 맞춤 공모주', style: AppTextStyles.h2),
                      const SizedBox(height: 24),
                      // AIPO's Pick 카드
                      homeAsync.when(
                        loading: () => const SizedBox(
                          height: 120,
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (home) {
                          final featuredIpo =
                              home.featuredIpos.isNotEmpty
                                  ? home.featuredIpos[0]
                                  : home.attractivenessItems.isNotEmpty
                                      ? home.attractivenessItems[0]
                                      : (home.raw['trendingIpos']
                                                  ?.isNotEmpty ==
                                              true
                                          ? home.raw['trendingIpos'][0]
                                          : null);
                          if (featuredIpo == null) return const SizedBox.shrink();
                          return _buildFeaturedCard(
                              featuredIpo, userType, badgeColors);
                        },
                      ),
                    ],
                  ),
                ),

                // Section B: 인기 누적 조회 공모주
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('인기 누적 조회 공모주',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 20),
                      homeAsync.when(
                        loading: () => const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const Text('데이터를 불러오지 못했습니다.',
                            style: TextStyle(color: AppColors.textGray)),
                        data: (home) {
                          if (home.trendingIpos.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('아직 조회된 공모주가 없습니다.',
                                  style:
                                      TextStyle(color: AppColors.textGray)),
                            );
                          }
                          return Column(
                            children: home.trendingIpos.asMap().entries.map<Widget>((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isLast = index == home.trendingIpos.length - 1;
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IpoDetailScreen(
                                      ipoId: item['ipoId'].toString(),
                                      ipoName: item['name'] ??
                                          item['companyName'] ??
                                          '',
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '${item['rank']}',
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item['name'] ??
                                              item['companyName'] ??
                                              '',
                                          style: const TextStyle(
                                              color: AppColors.textDark,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 85,
                                        child: Text(
                                          '${item['viewCount'] ?? 0} 조회',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              color: AppColors.textGray,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Section C: 필터 + 종목 리스트
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        key: _attractSectionKey,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_filters.length, (index) {
                            final isSelected = selectedFilterIndex == index;
                            return GestureDetector(
                              onTap: () => _onFilterTapped(index),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF383838)
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF383838)
                                        : AppColors.borderGray,
                                  ),
                                ),
                                child: Text(
                                  _filters[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textGray,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      homeAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text('데이터를 불러오지 못했습니다: $e',
                                style: const TextStyle(
                                    color: AppColors.textGray)),
                          ),
                        ),
                        data: (home) {
                          final filterKey =
                              homeFilterKeys[selectedFilterIndex];
                          final attractivenessItems =
                              _sortedAttractivenessItems(
                                  home.attractivenessItems, filterKey);
                          if (attractivenessItems.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Text('해당 조건의 종목이 없습니다.',
                                    style: TextStyle(
                                        color: AppColors.textGray)),
                              ),
                            );
                          }
                          final int totalAvailable =
                              attractivenessItems.length < _attractMaxCount
                                  ? attractivenessItems.length
                                  : _attractMaxCount;
                          final int shownCount =
                              _attractVisibleCount < totalAvailable
                                  ? _attractVisibleCount
                                  : totalAvailable;
                          final int remaining = totalAvailable - shownCount;
                          final int nextStep = remaining < _attractStep
                              ? remaining
                              : _attractStep;

                          return Column(
                            children: [
                              Column(
                                children: attractivenessItems
                                    .take(shownCount)
                                    .map<Widget>((item) {
                                  final String dateLabel = _buildDateLabel(
                                      item, filterKey);
                                  return IpoCard(
                                    score: double.tryParse(
                                                (item['score'] ??
                                                        item[
                                                            'attractionScore'] ??
                                                        0)
                                                    .toString())
                                            ?.round() ??
                                        0,
                                    ipoName: item['name'] ??
                                        item['companyName'] ??
                                        '-',
                                    leadManager:
                                        item['leadManager'] ?? '-',
                                    dateLabel: dateLabel,
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: AppColors.borderGray),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => IpoDetailScreen(
                                          ipoId:
                                              item['ipoId'].toString(),
                                          ipoName: item['name'] ??
                                              item['companyName'] ??
                                              '',
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (remaining > 0) ...[
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => setState(() {
                                      _attractVisibleCount =
                                          (_attractVisibleCount +
                                                  _attractStep)
                                              .clamp(0, _attractMaxCount);
                                    }),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side: BorderSide(
                                          color: AppColors.borderGray
                                              .withOpacity(0.7)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      foregroundColor: AppColors.textDark,
                                    ),
                                    child: Text(
                                      '더보기 +$nextStep',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (shownCount >
                                  _attractInitialCount) ...[
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => setState(() {
                                      _attractVisibleCount =
                                          _attractInitialCount;
                                    }),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side: BorderSide(
                                          color: AppColors.borderGray
                                              .withOpacity(0.7)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      foregroundColor: AppColors.textDark,
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_arrow_up,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 헬퍼 위젯 ─────────────────────────────────────────

  Widget _buildFeaturedCard(
      dynamic featuredIpo, String userType, Map<String, Color> badgeColors) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateText = _buildFeaturedDateLabel(
        Map<dynamic, dynamic>.from(featuredIpo as Map), today);
    final leadManager = featuredIpo['leadManager'] as String?;
    final hasLead = leadManager != null && leadManager.isNotEmpty;
    final hasDate = dateText != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0FF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IpoDetailScreen(
                ipoId: featuredIpo['ipoId'].toString(),
                ipoName:
                    featuredIpo['name'] ?? featuredIpo['companyName'] ?? '',
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      "AIPO's Pick",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right,
                        size: 24, color: AppColors.textDark),
                  ],
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text:
                              '${AuthManager.instance.user?.name ?? '사용자'} 님의 '),
                      TextSpan(
                        text: userType.replaceAll('#', ''),
                        style: TextStyle(
                          color: badgeColors['text'] ?? AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: ' 성향에 딱 맞는 종목이에요'),
                    ],
                  ),
                  style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        featuredIpo['name'] ??
                            featuredIpo['companyName'] ??
                            '',
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    () {
                      final raw = featuredIpo['score'] ??
                          featuredIpo['attractionScore'];
                      final score =
                          double.tryParse(raw?.toString() ?? '')?.round();
                      if (score == null) return const SizedBox.shrink();
                      return Text(
                        '$score점',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }(),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasLead || hasDate)
                  Row(
                    children: [
                      if (hasLead) ...[
                        const Icon(Icons.business_outlined,
                            size: 13, color: Color(0xFF4A4A4A)),
                        const SizedBox(width: 4),
                        Text(
                          '주관사: $leadManager',
                          style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                      if (hasLead && hasDate) const SizedBox(width: 12),
                      if (hasDate) ...[
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Color(0xFF4A4A4A)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateText,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 날짜/정렬 헬퍼 ───────────────────────────────────

  String _buildDateLabel(dynamic item, String filterKey) {
    if (filterKey == 'recentGrowth' && item['listingDate'] != null) {
      return '${_formatDate(item['listingDate']?.toString())} 상장';
    } else if (filterKey == 'favorite') {
      final String range = (item['dateRange'] ?? '-') as String;
      final String? status = item['status']?.toString();
      switch (status) {
        case '수요예측':
          return '$range 수요예측';
        case '청약':
          return '$range 청약';
        case '청약종료':
          return '$range 청약';
        case '상장':
          return '$range 상장';
        default:
          return range;
      }
    } else if (item['subscriptionStartDate'] != null) {
      return '${_formatDate(item['subscriptionStartDate']?.toString())} 청약 시작';
    } else {
      return (item['dateRange'] ?? '-') as String;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final parts = dateStr.split('-');
    if (parts.length < 3) return dateStr;
    return '${parts[1]}.${parts[2]}';
  }

  String? _buildFeaturedDateLabel(
      Map<dynamic, dynamic> ipo, DateTime today) {
    final startRaw = ipo['subscriptionStartDate']?.toString();
    final endRaw = ipo['subscriptionEndDate']?.toString();
    final refundRaw = ipo['refundDate']?.toString();
    final listingRaw = ipo['listingDate']?.toString();

    final subStart = startRaw != null ? DateTime.tryParse(startRaw) : null;
    final subEnd = endRaw != null ? DateTime.tryParse(endRaw) : null;
    final refund = refundRaw != null ? DateTime.tryParse(refundRaw) : null;
    final listing = listingRaw != null ? DateTime.tryParse(listingRaw) : null;

    DateTime d(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    if (subStart != null) {
      final normalizedStart = d(subStart);
      final dateStr = subEnd != null
          ? '${_formatDate(startRaw)} ~ ${_formatDate(endRaw)}'
          : _formatDate(startRaw);

      if (today.isBefore(normalizedStart)) {
        final diff = normalizedStart.difference(today).inDays;
        return '청약 D-$diff ($dateStr)';
      }
      if (subEnd != null) {
        if (!today.isAfter(d(subEnd))) return '청약 진행중 ($dateStr)';
      } else {
        if (today.isAtSameMomentAs(normalizedStart)) {
          return '청약 진행중 ($dateStr)';
        }
      }
    }

    if (refund != null && !today.isAfter(d(refund))) {
      final diff = d(refund).difference(today).inDays;
      return diff == 0
          ? '오늘 환불일 (${_formatDate(refundRaw)})'
          : '환불 D-$diff (${_formatDate(refundRaw)})';
    }

    if (listing != null) {
      final diff = d(listing).difference(today).inDays;
      if (diff > 0) return '상장 D-$diff (${_formatDate(listingRaw)})';
      if (diff == 0) return '오늘 상장! (${_formatDate(listingRaw)})';
      return '상장일: ${_formatDate(listingRaw)}';
    }

    return null;
  }

  List<dynamic> _sortedAttractivenessItems(
      List<dynamic> items, String filterKey) {
    final sorted = List<dynamic>.from(items);
    if (filterKey == 'recentGrowth') {
      final today = DateTime.now();
      sorted.removeWhere((item) {
        final date = _parseItemDate(item, 'listingDate');
        return date == null || date.isAfter(today);
      });
      sorted.sort((a, b) => _compareDateDesc(
            _parseItemDate(a, 'listingDate'),
            _parseItemDate(b, 'listingDate'),
          ));
    } else if (filterKey == 'subscriptionUpcoming') {
      sorted.sort((a, b) => _compareDateAsc(
            _parseItemDate(a, 'subscriptionStartDate') ??
                _parseItemDate(a, 'subscriptionEndDate'),
            _parseItemDate(b, 'subscriptionStartDate') ??
                _parseItemDate(b, 'subscriptionEndDate'),
          ));
    }
    return sorted;
  }

  DateTime? _parseItemDate(dynamic item, String key) {
    if (item is! Map || item[key] == null) return null;
    return DateTime.tryParse(item[key].toString());
  }

  int _compareDateAsc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  int _compareDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
