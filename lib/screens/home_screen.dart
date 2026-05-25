import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'ipo_detail_screen.dart';
import 'home_search_screen.dart';
import '../services/ipo_service.dart';
import '../services/user_service.dart';
import '../models/auth_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IpoService _ipoService = IpoService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  Map<String, dynamic>? _homeData;
  
  int _selectedFilterIndex = 0;
  final List<String> _filterKeys = ['recentGrowth', 'subscriptionUpcoming', 'favorite'];
  final List<String> _filters = ['최근 상장순', '청약 예정순', '관심 종목순'];

  static const int _attractInitialCount = 4;
  static const int _attractStep = 4;
  static const int _attractMaxCount = 20;
  int _attractVisibleCount = _attractInitialCount;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
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

  void _onFilterTapped(int index) {
    if (_selectedFilterIndex == index) return;
    setState(() {
      _selectedFilterIndex = index;
      _attractVisibleCount = _attractInitialCount;
    });
    _fetchHomeData();
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // 1. 추천 종목 추출 (조회 로그 없으면 매력지수나 트렌딩 종목으로 대체)
    final featuredIpo = (_homeData?['featuredIpos']?.isNotEmpty == true)
        ? _homeData!['featuredIpos'][0]
        : (_homeData?['attractivenessItems']?.isNotEmpty == true)
            ? _homeData!['attractivenessItems'][0]
            : (_homeData?['trendingIpos']?.isNotEmpty == true)
                ? _homeData!['trendingIpos'][0]
                : null;
    final trendingIpos = _homeData?['trendingIpos'] ?? [];
    final attractivenessItems = _sortedAttractivenessItems(_homeData?['attractiveness']?['items'] ?? []);
    final userType = AuthManager.instance.user?.investmentType ?? '#분석대기중';
    final badgeColors = _getBadgeColors(userType);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        color: AppColors.primary,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: badgeColors['bg'],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          userType,
                          style: TextStyle(
                            color: badgeColors['text'],
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: AppColors.textDark, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeSearchScreen()),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('오늘의 맞춤 공모주', style: AppTextStyles.h2),
                  const SizedBox(height: 24),
                  
                  // Section A: AIPO's Pick
                  if (featuredIpo != null) ...[
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
                                ipoName: featuredIpo['name'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "AIPO's Pick",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '사용자 님의 ${userType.replaceAll('#', '')} 성향에 딱 맞는 종목이에요',
                                style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        (featuredIpo['name'] as String? ?? '').isNotEmpty
                                            ? (featuredIpo['name'] as String).substring(0, 1)
                                            : '?',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      featuredIpo['name'],
                                      style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Row(
                                children: [
                                  Icon(Icons.trending_up, size: 18, color: Color(0xFF4A4A4A)),
                                  SizedBox(width: 6),
                                  Text('매력지수 상위권 종목', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  ],

                  // Section B: 인기 누적 조회 공모주
                  Text('인기 누적 조회 공모주', style: AppTextStyles.h3.copyWith(fontSize: 18)),
                  const SizedBox(height: 20),
                  
                  if (trendingIpos.isEmpty) 
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('아직 조회된 공모주가 없습니다.', style: TextStyle(color: AppColors.textGray)),
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
                                ipoName: item['name'],
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
                                  style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item['name'],
                                  style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 85,
                                child: Text(
                                  '${item['viewCount'] ?? 0} 조회',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section C: 공모주 매력지수
                  // Filters Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filters.length, (index) {
                        final isSelected = _selectedFilterIndex == index;
                        return GestureDetector(
                          onTap: () => _onFilterTapped(index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF383838) : AppColors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF383838) : AppColors.borderGray,
                              ),
                            ),
                            child: Text(
                              _filters[index],
                              style: TextStyle(
                                color: isSelected ? AppColors.white : AppColors.textGray,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Attractive IPOs List
                  if (_isLoading && _homeData != null)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (attractivenessItems.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('해당 조건의 종목이 없습니다.', style: TextStyle(color: AppColors.textGray)),
                    ))
                  else
                    Builder(builder: (context) {
                      final int totalAvailable =
                          attractivenessItems.length < _attractMaxCount
                              ? attractivenessItems.length
                              : _attractMaxCount;
                      final int shownCount = _attractVisibleCount < totalAvailable
                          ? _attractVisibleCount
                          : totalAvailable;
                      final int remaining = totalAvailable - shownCount;
                      final int nextStep = remaining < _attractStep ? remaining : _attractStep;

                      return Column(
                        children: [
                          Column(
                            children: attractivenessItems.take(shownCount).map<Widget>((item) {
                              final isRecentGrowth =
                                  _filterKeys[_selectedFilterIndex] == 'recentGrowth';
                              final String dateLabel;
                              if (isRecentGrowth && item['listingDate'] != null) {
                                dateLabel =
                                    '${_formatDate(item['listingDate']?.toString())} 상장';
                              } else if (item['subscriptionStartDate'] != null) {
                                dateLabel =
                                    '${_formatDate(item['subscriptionStartDate']?.toString())} 청약 시작';
                              } else {
                                dateLabel = (item['dateRange'] ?? '-') as String;
                              }
                              return _buildIpoCard(
                                score: double.tryParse((item['score'] ?? item['attractionScore'] ?? 0).toString())?.round() ?? 0,
                                ipoName: item['name'] ?? item['companyName'] ?? '-',
                                leadManager: item['leadManager'] ?? '-',
                                dateLabel: dateLabel,
                                status: null,   // 홈에서는 상태 배지 미표시
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.borderGray),
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => IpoDetailScreen(
                                    ipoId: item['ipoId'].toString(),
                                    ipoName: item['name'] ?? item['companyName'] ?? '',
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
                                    _attractVisibleCount = (_attractVisibleCount + _attractStep)
                                            .clamp(0, _attractMaxCount);
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: AppColors.borderGray.withOpacity(0.7)),
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
                                    _attractVisibleCount = _attractInitialCount;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: AppColors.borderGray.withOpacity(0.7)),
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
                  
                  const SizedBox(height: 40),
                ],
              ),
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

  List<dynamic> _sortedAttractivenessItems(dynamic rawItems) {
    final items = List<dynamic>.from(rawItems as List? ?? []);
    final filterKey = _filterKeys[_selectedFilterIndex];

    if (filterKey == 'recentGrowth') {
      items.sort((a, b) => _compareDateDesc(
            _parseItemDate(a, 'listingDate'),
            _parseItemDate(b, 'listingDate'),
          ));
    } else if (filterKey == 'subscriptionUpcoming') {
      items.sort((a, b) => _compareDateAsc(
            _parseItemDate(a, 'subscriptionStartDate') ?? _parseItemDate(a, 'subscriptionEndDate'),
            _parseItemDate(b, 'subscriptionStartDate') ?? _parseItemDate(b, 'subscriptionEndDate'),
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
        bg = const Color(0xFFFFEAEA); text = const Color(0xFFD32F2F);
        break;
      case '상장':
        bg = const Color(0xFFE2F6EA); text = const Color(0xFF107C41);
        break;
      case '청약종료':
        bg = const Color(0xFFF3F3F3); text = AppColors.textGray;
        break;
      default: // 청약
        bg = AppColors.bgLightBlue; text = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
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
          boxShadow: [BoxShadow(
            color: AppColors.black.withOpacity(0.015),
            blurRadius: 10, offset: const Offset(0, 4),
          )],
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
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    leadManager,
                    style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13,
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
