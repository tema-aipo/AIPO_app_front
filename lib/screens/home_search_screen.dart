import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _recentSearches = [
    '스페이스테크놀로지',
    '바이오메디컬 공모가',
    'AI솔루션즈 상장일',
  ];

  final List<String> _popularSearches = [
    '스페이스테크놀로지',
    '그린에너지솔루션',
    '로보틱스 수요예측',
    '바이오메디컬',
    'AI솔루션즈',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back button + Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.bgGray,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '종목명, 키워드 검색',
                          hintStyle: const TextStyle(color: AppColors.textLightGray, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: AppColors.textDark),
                            onPressed: () {
                              // 검색 로직
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderGray, height: 1, thickness: 0.5),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 최근 검색어
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '최근 검색어',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _recentSearches.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '전체삭제',
                            style: TextStyle(color: AppColors.textLightGray, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_recentSearches.isEmpty)
                      const Text('최근 검색어가 없습니다.', style: TextStyle(color: AppColors.textLightGray, fontSize: 14))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: _recentSearches.map((text) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderGray),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  text,
                                  style: const TextStyle(color: AppColors.textGray, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _recentSearches.remove(text);
                                    });
                                  },
                                  child: const Icon(Icons.close, color: AppColors.textLightGray, size: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 48),

                    // 인기 검색어
                    const Text(
                      '실시간 인기 검색어',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(_popularSearches.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: index < 3 ? AppColors.primary : AppColors.textGray,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _popularSearches[index],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // 무작위로 화살표 설정 (목업)
                            Icon(
                              index % 3 == 0 ? Icons.arrow_drop_up : (index % 3 == 1 ? Icons.remove : Icons.arrow_drop_down),
                              color: index % 3 == 0 ? AppColors.primaryRed : (index % 3 == 1 ? AppColors.textLightGray : AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
