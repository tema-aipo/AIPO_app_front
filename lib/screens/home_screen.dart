import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'ipo_detail_screen.dart';
import 'home_search_screen.dart';
import 'notification_screen.dart';
import '../services/ipo_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../models/auth_manager.dart';
import '../widgets/investment_type_guide_popup.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToMyPage;

  const HomeScreen({super.key, this.onGoToMyPage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IpoService _ipoService = IpoService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  Map<String, dynamic>? _homeData;
  List<dynamic>? _cachedFeaturedIpos;
  List<dynamic>? _cachedAttractivenessItems;

  int _selectedFilterIndex = 0;
  final List<String> _filterKeys = [
    'recentGrowth',
    'subscriptionUpcoming',
    'favorite'
  ];
  final List<String> _filters = ['최근 상장순', '청약 진행/예정순', '관심 종목순'];

  static const int _attractInitialCount = 4;
  static const int _attractStep = 4;
  static const int _attractMaxCount = 20;
  int _attractVisibleCount = _attractInitialCount;

  final GlobalKey _attractSectionKey = GlobalKey();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    _unreadCount = NotificationService.instance.unreadCount;
    NotificationService.instance.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    if (mounted) {
      setState(() {
        _unreadCount = NotificationService.instance.unreadCount;
      });
    }
  }

  Future<void> _fetchHomeData() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> data;
      if (_filterKeys[_selectedFilterIndex] == 'favorite') {
        data = await _ipoService.getHomeData('favorite');
        final favorites = await _userService.getFavorites();
        data['attractivenessItems'] = favorites;
        data['attractiveness'] = {'items': favorites};
      } else {
        data = await _ipoService.getHomeData(
          _filterKeys[_selectedFilterIndex],
        );
      }
      setState(() {
        _homeData = data;
        if (_filterKeys[_selectedFilterIndex] != 'favorite') {
          _cachedFeaturedIpos = data['featuredIpos'] ?? [];
          _cachedAttractivenessItems = data['attractivenessItems'] ??
              data['attractiveness']?['items'] ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _onFilterTapped(int index) async {
    if (_selectedFilterIndex == index) return;
    setState(() {
      _selectedFilterIndex = index;
      _attractVisibleCount = _attractInitialCount;
    });
    await _fetchHomeData();
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

  Map<String, Color> _getBadgeColors(String rawType) {
    final cleanType = rawType.startsWith('#') ? rawType : '#$rawType';
    if (cleanType == '#안정형') {
      return {
        'bg': AppColors.bgLightBlue,
        'text': AppColors.primary,
      };
    } else if (cleanType == '#공격형') {
      return {
        'bg': const Color(0xFFFFEAEA),
        'text': const Color(0xFFD32F2F),
      };
    } else if (cleanType == '#중립형') {
      return {
        'bg': const Color(0xFFE2F6EA),
        'text': const Color(0xFF107C41),
      };
    } else {
      return {
        'bg': const Color(0xFFF3F3F3),
        'text': AppColors.textGray,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _homeData == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final featuredIpo = (_cachedFeaturedIpos?.isNotEmpty == true)
        ? _cachedFeaturedIpos![0]
        : (_cachedAttractivenessItems?.isNotEmpty == true)
            ? _cachedAttractivenessItems![0]
            : (_homeData?['trendingIpos']?.isNotEmpty == true)
                ? _homeData!['trendingIpos'][0]
                : null;
    final trendingIpos = _homeData?['trendingIpos'] ?? [];
    final attractivenessItems = _sortedAttractivenessItems(
        _homeData?['attractiveness']?['items'] ?? []);
    final userType = AuthManager.instance.user?.investmentType ?? '#분석대기중';
    final badgeColors = _getBadgeColors(userType);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHomeData,
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
                              // 확성기 버튼 (알림 목록)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationScreen()),
                                  );
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.campaign_outlined,
                                        color: AppColors.textDark, size: 28),
                                    if (_unreadCount > 0)
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
                              ),
                              const SizedBox(width: 16),
                              // 검색 버튼
                              IconButton(
                                icon: const Icon(Icons.search,
                                    color: AppColors.textDark, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const HomeSearchScreen()),
                                  );
                                },
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
                      if (featuredIpo != null)
                        Container(
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IpoDetailScreen(
                                      ipoId: featuredIpo['ipoId'].toString(),
                                      ipoName: featuredIpo['name'] ?? featuredIpo['companyName'] ?? '',
                                    ),
                                  ),
                                );
                              },
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
                                        Icon(
                                          Icons.chevron_right,
                                          size: 24,
                                          color: AppColors.textDark,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: '${AuthManager.instance.user?.name ?? '사용자'} 님의 '),
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
                                            featuredIpo['name'] ?? featuredIpo['companyName'] ?? '',
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
                                          final raw = featuredIpo['score'] ?? featuredIpo['attractionScore'];
                                          final score = double.tryParse(raw?.toString() ?? '')?.round();
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
                                    () {
                                      final leadManager = featuredIpo['leadManager'] as String?;
                                      final now = DateTime.now();
                                      final today = DateTime(now.year, now.month, now.day);
                                      final dateText = _buildFeaturedDateLabel(
                                          Map<dynamic, dynamic>.from(featuredIpo as Map), today);

                                      final hasLead = leadManager != null && leadManager.isNotEmpty;
                                      final hasDate = dateText != null;
                                      if (!hasLead && !hasDate) return const SizedBox.shrink();

                                      return Row(
                                        children: [
                                          if (hasLead) ...[
                                            const Icon(Icons.business_outlined,
                                                size: 13, color: Color(0xFF4A4A4A)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '주관사: $leadManager',
                                              style: const TextStyle(
                                                  color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                          if (hasLead && hasDate)
                                            const SizedBox(width: 12),
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
                                      );
                                    }(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Section B: 인기 누적 조회 공모주
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('인기 누적 조회 공모주',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 20),
                      if (trendingIpos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('아직 조회된 공모주가 없습니다.',
                              style: TextStyle(color: AppColors.textGray)),
                        )
                      else
                        Column(
                          children: trendingIpos.map<Widget>((item) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IpoDetailScreen(
                                      ipoId: item['ipoId'].toString(),
                                      ipoName: item['name'] ?? item['companyName'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
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
                                        item['name'] ?? item['companyName'] ?? '',
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
                        ),
                    ],
                  ),
                ),

                // Section C: 필터 + 종목 리스트
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        key: _attractSectionKey,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_filters.length, (index) {
                            final isSelected = _selectedFilterIndex == index;
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
                      if (_isLoading && _homeData != null)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (attractivenessItems.isEmpty)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('해당 조건의 종목이 없습니다.',
                              style: TextStyle(color: AppColors.textGray)),
                        ))
                      else
                        Builder(builder: (context) {
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
                                  final filterKey =
                                      _filterKeys[_selectedFilterIndex];
                                  final String dateLabel;
                                  if (filterKey == 'recentGrowth' &&
                                      item['listingDate'] != null) {
                                    dateLabel =
                                        '${_formatDate(item['listingDate']?.toString())} 상장';
                                  } else if (filterKey == 'favorite') {
                                    final String range =
                                        (item['dateRange'] ?? '-') as String;
                                    final String? status =
                                        item['status']?.toString();
                                    switch (status) {
                                      case '수요예측':
                                        dateLabel = '$range 수요예측';
                                        break;
                                      case '청약':
                                        dateLabel = '$range 청약';
                                        break;
                                      case '청약종료':
                                        dateLabel = '$range 청약';
                                        break;
                                      case '상장':
                                        dateLabel = '$range 상장';
                                        break;
                                      default:
                                        dateLabel = range;
                                    }
                                  } else if (item['subscriptionStartDate'] !=
                                      null) {
                                    dateLabel =
                                        '${_formatDate(item['subscriptionStartDate']?.toString())} 청약 시작';
                                  } else {
                                    dateLabel =
                                        (item['dateRange'] ?? '-') as String;
                                  }
                                  return _buildIpoCard(
                                    score: double.tryParse((item['score'] ??
                                                    item['attractionScore'] ??
                                                    0)
                                                .toString())
                                            ?.round() ??
                                        0,
                                    ipoName: item['name'] ??
                                        item['companyName'] ??
                                        '-',
                                    leadManager: item['leadManager'] ?? '-',
                                    dateLabel: dateLabel,
                                    status: null,
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: AppColors.borderGray),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => IpoDetailScreen(
                                            ipoId: item['ipoId'].toString(),
                                            ipoName: item['name'] ??
                                                item['companyName'] ??
                                                '',
                                          ),
                                        )),
                                  );
                                }).toList(),
                              ),
                              if (remaining > 0) ...[
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _attractVisibleCount =
                                            (_attractVisibleCount +
                                                    _attractStep)
                                                .clamp(0, _attractMaxCount);
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side: BorderSide(
                                          color: AppColors.borderGray
                                              .withOpacity(0.7)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
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
                              ] else if (shownCount > _attractInitialCount) ...[
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _attractVisibleCount =
                                            _attractInitialCount;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side: BorderSide(
                                          color: AppColors.borderGray
                                              .withOpacity(0.7)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
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
                        }),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final parts = dateStr.split('-');
    if (parts.length < 3) return dateStr;
    return '${parts[1]}.${parts[2]}';
  }

  String? _buildFeaturedDateLabel(Map<dynamic, dynamic> ipo, DateTime today) {
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
        if (!today.isAfter(d(subEnd))) {
          return '청약 진행중 ($dateStr)';
        }
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

  List<dynamic> _sortedAttractivenessItems(dynamic rawItems) {
    final items = List<dynamic>.from(rawItems as List? ?? []);
    final filterKey = _filterKeys[_selectedFilterIndex];

    if (filterKey == 'recentGrowth') {
      final today = DateTime.now();
      items.removeWhere((item) {
        final date = _parseItemDate(item, 'listingDate');
        return date == null || date.isAfter(today);
      });
      items.sort((a, b) => _compareDateDesc(
            _parseItemDate(a, 'listingDate'),
            _parseItemDate(b, 'listingDate'),
          ));
    } else if (filterKey == 'subscriptionUpcoming') {
      items.sort((a, b) => _compareDateAsc(
            _parseItemDate(a, 'subscriptionStartDate') ??
                _parseItemDate(a, 'subscriptionEndDate'),
            _parseItemDate(b, 'subscriptionStartDate') ??
                _parseItemDate(b, 'subscriptionEndDate'),
          ));
    }

    return items;
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

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status) {
      case '수요예측':
        bg = const Color(0xFFFFEAEA);
        text = const Color(0xFFD32F2F);
        break;
      case '상장':
        bg = const Color(0xFFE2F6EA);
        text = const Color(0xFF107C41);
        break;
      case '청약종료':
        bg = const Color(0xFFF3F3F3);
        text = AppColors.textGray;
        break;
      default: // 청약
        bg = AppColors.bgLightBlue;
        text = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildIpoCard({
    required int score,
    required String ipoName,
    required String leadManager,
    required String dateLabel,
    String? status,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // 좌측: 점수 + 상태뱃지
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• $score점',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 6),
                    _buildStatusBadge(status),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 중앙: 종목명 + 주관사 + 날짜
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ipoName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    leadManager,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 우측: 액션 영역
            trailing,
          ],
        ),
      ),
    );
  }
}
