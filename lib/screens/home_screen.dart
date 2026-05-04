import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'ipo_detail_screen.dart';
import 'home_search_screen.dart';

class PopularIpo {
  final int rank;
  final String name;
  final String views;
  PopularIpo(this.rank, this.name, this.views);
}

class TrendingIpo {
  final int rank;
  final String name;
  final String rate;
  final String views;
  TrendingIpo(this.rank, this.name, this.rate, this.views);
}

class AttractiveIpo {
  final int score;
  final String name;
  final String date;
  AttractiveIpo(this.score, this.name, this.date);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dummy Data for Preview
  final List<PopularIpo> popularIpos = [
    PopularIpo(1, '바이오메디컬', '3,542 조회'),
    PopularIpo(2, 'AI솔루션즈', '3,125 조회'),
    PopularIpo(3, '그린에너지', '2,800 조회'),
    PopularIpo(4, '스페이스테크', '2,150 조회'),
    PopularIpo(5, '로보틱스', '1,990 조회'),
  ];

  final List<TrendingIpo> trendingIpos = [
    TrendingIpo(1, 'AI솔루션즈', '+125%', '3,125 조회'),
    TrendingIpo(2, '스페이스테크놀로지', '+98%', '2,876 조회'),
    TrendingIpo(3, '바이오메디컬', '+87%', '2,134 조회'),
  ];

  final List<AttractiveIpo> attractiveIpos = [
    AttractiveIpo(92, '스페이스테크놀로지', '4월 8일 상장'),
    AttractiveIpo(88, '바이오메디컬', '4월 10일 상장'),
    AttractiveIpo(85, 'AI솔루션즈', '4월 12일 상장'),
    AttractiveIpo(76, '그린에너지솔루션', '4월 15일 상장'),
  ];

  int _selectedFilterIndex = 0;
  final List<String> _filters = ['최근 상장순', '청약 예정순', '관심 종목순'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Row (Tag & Search Icon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgLightBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '#안정형',
                        style: TextStyle(
                          color: AppColors.primary,
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
                
                // Header
                const Text('오늘의 맞춤 공모주', style: AppTextStyles.h2),
                
                const SizedBox(height: 24),
                
                // Section A: AIPO's Pick
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0FF), // 좀 더 진한 파란 배경
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
                            builder: (_) => const IpoDetailScreen(ipoName: '스페이스테크놀로지'),
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
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '사용자 님의 안정형 성향에 딱 맞는 종목이에요',
                              style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 13, fontWeight: FontWeight.w500),
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
                                  child: const Center(
                                    child: Text('S', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    '스페이스테크놀로지',
                                    style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('92점', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Icon(Icons.business_outlined, size: 18, color: Color(0xFF4A4A4A)),
                                SizedBox(width: 6),
                                Text('주관사: 미래에셋증권', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 13)),
                                SizedBox(width: 16),
                                Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF4A4A4A)),
                                SizedBox(width: 6),
                                Text('청약일: 4.8 ~ 4.9', style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Section B: 실시간 조회 급등
                Text('실시간 조회 급등', style: AppTextStyles.h3.copyWith(fontSize: 18)),
                const SizedBox(height: 20),
                
                Column(
                  children: trendingIpos.map((item) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IpoDetailScreen(ipoName: item.name),
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
                                '${item.rank}',
                                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 65,
                              child: Text(
                                item.views,
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
                Text('공모주 매력지수', style: AppTextStyles.h3.copyWith(fontSize: 18)),
                const SizedBox(height: 16),
                
                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = _selectedFilterIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
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
                
                // Attractive IPOs List (Cards)
                Column(
                  children: attractiveIpos.map((item) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IpoDetailScreen(ipoName: item.name),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: AppColors.borderGray.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: AppColors.primary),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              child: Text(
                                '${item.score}점',
                                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.date,
                                    style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward, size: 18, color: AppColors.borderGray),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Bottom Page Indicators (Dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFF4A4E5A) : AppColors.borderGray.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
