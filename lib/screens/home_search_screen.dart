import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/ipo_service.dart';
import 'ipo_detail_screen.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final IpoService _ipoService = IpoService();

  // 최근 검색어 (SharedPreferences에서 로드)
  List<String> _recentSearches = [];

  // 검색 결과 상태
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // 연관검색어 상태
  List<String> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final text = _searchController.text;

    if (text.isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _hasSearched = false;
        _searchResults = [];
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    // 검색 결과 보는 중에 텍스트를 수정하면 제안 모드로 전환
    if (_hasSearched) {
      setState(() {
        _hasSearched = false;
        _searchResults = [];
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(text);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty || _hasSearched) return;
    setState(() => _isLoadingSuggestions = true);

    try {
      final result = await _ipoService.getIpoList(keyword: query.trim(), size: 7);
      final List items = result['content'] ?? result['items'] ?? [];
      if (mounted && !_hasSearched) {
        setState(() {
          _suggestions = items
              .map<String>((item) =>
                  (item['companyName'] ?? item['name'] ?? '').toString())
              .where((name) => name.isNotEmpty)
              .toList();
          _isLoadingSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  /// SharedPreferences에서 최근 검색어 로드
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentSearchesKey);
    if (saved != null && mounted) {
      setState(() {
        _recentSearches = saved;
      });
    }
  }

  /// 최근 검색어 저장
  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  /// 최근 검색어에 추가 (중복 제거, 최대 10개)
  void _addToRecentSearches(String keyword) {
    _recentSearches.remove(keyword); // 중복 제거
    _recentSearches.insert(0, keyword); // 맨 앞에 추가
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }
    _saveRecentSearches();
  }

  /// 검색 실행
  Future<void> _performSearch(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    _addToRecentSearches(trimmed);

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _suggestions = [];
      _isLoadingSuggestions = false;
    });

    try {
      final result = await _ipoService.getIpoList(keyword: trimmed, size: 50);
      final List items = result['content'] ?? result['items'] ?? [];
      if (mounted) {
        setState(() {
          _searchResults = items;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색에 실패했습니다: $e')),
        );
      }
    }
  }

  /// 날짜 포맷 (2026-04-08 → 04.08)
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final parts = dateStr.split('-');
    if (parts.length < 3) return dateStr;
    return '${parts[1]}.${parts[2]}';
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
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) => _performSearch(value),
                        decoration: InputDecoration(
                          hintText: '종목명, 키워드 검색',
                          hintStyle: const TextStyle(color: AppColors.textLightGray, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: AppColors.textDark),
                            onPressed: () => _performSearch(_searchController.text),
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
              child: _hasSearched
                  ? _buildSearchResults()
                  : (_searchController.text.isNotEmpty
                      ? _buildSuggestionsContent()
                      : _buildInitialContent()),
            ),
          ],
        ),
      ),
    );
  }

  /// 연관검색어 목록
  Widget _buildSuggestionsContent() {
    if (_isLoadingSuggestions) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Text(
          '\'${_searchController.text}\'에 대한 연관검색어가 없습니다.',
          style: const TextStyle(color: AppColors.textLightGray, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderGray),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final query = _searchController.text.toLowerCase();
        final lowerSuggestion = suggestion.toLowerCase();
        final matchStart = lowerSuggestion.indexOf(query);

        return InkWell(
          onTap: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.textLightGray),
                const SizedBox(width: 12),
                Expanded(
                  child: matchStart >= 0
                      ? RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.textDark),
                            children: [
                              if (matchStart > 0)
                                TextSpan(text: suggestion.substring(0, matchStart)),
                              TextSpan(
                                text: suggestion.substring(
                                    matchStart, matchStart + query.length),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                  text: suggestion
                                      .substring(matchStart + query.length)),
                            ],
                          ),
                        )
                      : Text(suggestion,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textDark)),
                ),
                const Icon(Icons.north_west,
                    size: 14, color: AppColors.textLightGray),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 초기 화면: 최근 검색어 + 인기 검색어 (백엔드 미구현 안내)
  Widget _buildInitialContent() {
    return SingleChildScrollView(
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
                  _saveRecentSearches();
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
                return GestureDetector(
                  onTap: () {
                    _searchController.text = text;
                    _performSearch(text);
                  },
                  child: Container(
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
                            _saveRecentSearches();
                          },
                          child: const Icon(Icons.close, color: AppColors.textLightGray, size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// 검색 결과 화면
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: AppColors.textLightGray, size: 48),
            const SizedBox(height: 16),
            Text(
              '\'${_searchController.text}\'에 대한 검색 결과가 없습니다.',
              style: const TextStyle(color: AppColors.textGray, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '다른 키워드로 검색해 보세요.',
              style: TextStyle(color: AppColors.textLightGray, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Text(
            '검색 결과 ${_searchResults.length}건',
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final item = _searchResults[index];
              return _buildSearchResultCard(item);
            },
          ),
        ),
      ],
    );
  }

  /// 검색 결과 카드
  Widget _buildSearchResultCard(Map<String, dynamic> item) {
    final String name = item['companyName'] ?? item['name'] ?? '-';
    final String ipoId = (item['ipoId'] ?? item['id'] ?? '').toString();
    final int score = item['score'] ?? item['attractionScore'] ?? 0;
    final String? leadManager = item['leadManager'];
    final String? startDate = item['subscriptionStartDate'];
    final String? status = item['status'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IpoDetailScreen(ipoId: ipoId, ipoName: name),
          ),
        );
      },
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
            ),
          ],
        ),
        child: Row(
          children: [
            // 좌측: 점수
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• $score점',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (status != null && status.isNotEmpty) ...[
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
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (leadManager != null && leadManager.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      leadManager,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (startDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(startDate)} 청약 시작',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.borderGray),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status) {
      case '수요예측':
      case 'DEMAND_FORECAST':
        bg = const Color(0xFFFFEAEA);
        text = const Color(0xFFD32F2F);
        break;
      case '상장':
      case 'LISTED':
        bg = const Color(0xFFE2F6EA);
        text = const Color(0xFF107C41);
        break;
      case '청약종료':
      case 'SUBSCRIPTION_CLOSED':
        bg = const Color(0xFFF3F3F3);
        text = AppColors.textGray;
        break;
      default: // 청약
        bg = AppColors.bgLightBlue;
        text = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
