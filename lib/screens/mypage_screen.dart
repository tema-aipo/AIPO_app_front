import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import '../theme/app_colors.dart';
import 'ipo_detail_screen.dart';
import 'login_screen.dart';
import 'signup_step2_screen.dart';
import 'profile_screen.dart';
import '../models/auth_manager.dart';
import '../services/user_service.dart';
import '../services/ipo_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => MyPageScreenState();
}

class MyPageScreenState extends State<MyPageScreen> {
  final UserService _userService = UserService();
  final IpoService _ipoService = IpoService();
  final AuthService _authService = AuthService();

  List<dynamic> _favorites = [];
  bool _isLoading = true;

  bool _isSubscriptionAlarmOn = true;
  bool _isListingAlarmOn = false;
  final Map<String, bool> _activeNotifications = {};

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
  void initState() {
    super.initState();
    _fetchData();
  }

  void refresh() {
    _fetchData(showLoading: false);
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        _userService.getFavorites(),
        _userService.getNotificationSettings(),
      ]);
      final favs = results[0] as List<dynamic>;
      final notiSettings = results[1] as Map<String, dynamic>;

      final subAlarm = notiSettings['subscriptionScheduleNotificationEnabled'] ?? true;
      final lstAlarm = notiSettings['listingDateNotificationEnabled'] ?? false;

      // 백엔드 전역 알림 설정을 NotificationService에 미러링
      // → 팝업/알림 목록 필터링에 즉시 반영됨
      NotificationService.instance.updateGlobalSettings(
        subscription: subAlarm as bool,
        listing: lstAlarm as bool,
      );

      setState(() {
        _favorites = favs;
        for (var item in favs) {
          final id = item['ipoId']?.toString() ?? '';
          if (id.isNotEmpty) {
            // NotificationService의 로컬 캐시에서 종목별 알림 설정 읽기
            // (백엔드 API 준비 전까지는 SharedPreferences 기반)
            _activeNotifications[id] =
                NotificationService.instance.isIpoNotificationEnabled(id);
          }
        }
        _isSubscriptionAlarmOn = subAlarm;
        _isListingAlarmOn = lstAlarm;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite(String ipoId, bool currentStatus) async {
    final originalFavorites = List<dynamic>.from(_favorites);
    
    final stockItem = originalFavorites.firstWhere(
      (item) => (item['ipoId']?.toString() ?? '') == ipoId,
      orElse: () => null,
    );
    final String companyName = stockItem != null 
        ? (stockItem['companyName'] ?? stockItem['name'] ?? '해당 공모주')
        : '해당 공모주';

    if (currentStatus && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$companyName가 관심 공모주에서 해제되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // 즉각적인 로컬 삭제 (Optimistic Update)
    setState(() {
      _favorites.removeWhere((item) => (item['ipoId']?.toString() ?? '') == ipoId);
    });

    try {
      await _ipoService.toggleFavorite(ipoId, !currentStatus);
      
      // 백그라운드 데이터 갱신 (로딩 스피너 없는 조용한 갱신)
      final results = await Future.wait([
        _userService.getFavorites(),
        _userService.getNotificationSettings(),
      ]);
      final favs = results[0] as List<dynamic>;
      final notiSettings = results[1] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _favorites = favs;
          _isSubscriptionAlarmOn = notiSettings['subscriptionScheduleNotificationEnabled'] ?? true;
          _isListingAlarmOn = notiSettings['listingDateNotificationEnabled'] ?? false;
        });
      }
    } catch (e) {
      // API 실패 시 복구
      if (mounted) {
        setState(() {
          _favorites = originalFavorites;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('관심 종목 변경에 실패했습니다.')));
      }
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      const Text('알림 설정', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                      GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: AppColors.textGray)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildAlarmRow('청약 일정 알림', '청약 시작일과 마감일에 알려드려요', _isSubscriptionAlarmOn, (val) {
                    setModalState(() => _isSubscriptionAlarmOn = val);
                    setState(() => _isSubscriptionAlarmOn = val);
                    // NotificationService에 즉시 반영 → 팝업 필터링에 적용
                    NotificationService.instance.updateGlobalSettings(
                      subscription: _isSubscriptionAlarmOn,
                      listing: _isListingAlarmOn,
                    );
                    // 백엔드 저장 (이미 연동 완료)
                    _userService.updateNotificationSettings(
                      subscriptionAlarm: _isSubscriptionAlarmOn,
                      listingAlarm: _isListingAlarmOn,
                    ).catchError((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('알림 설정 저장 실패')));
                      }
                    });
                  }),
                  const SizedBox(height: 32),
                  _buildAlarmRow('상장일 알림', '상장 당일 아침에 잊지 않게 알려드려요', _isListingAlarmOn, (val) {
                    setModalState(() => _isListingAlarmOn = val);
                    setState(() => _isListingAlarmOn = val);
                    // NotificationService에 즉시 반영 → 팝업 필터링에 적용
                    NotificationService.instance.updateGlobalSettings(
                      subscription: _isSubscriptionAlarmOn,
                      listing: _isListingAlarmOn,
                    );
                    // 백엔드 저장 (이미 연동 완료)
                    _userService.updateNotificationSettings(
                      subscriptionAlarm: _isSubscriptionAlarmOn,
                      listingAlarm: _isListingAlarmOn,
                    ).catchError((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('알림 설정 저장 실패')));
                      }
                    });
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlarmRow(String title, String desc, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: AppColors.textGray.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
        CupertinoSwitch(activeColor: AppColors.primary, value: value, onChanged: onChanged),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('정말 로그아웃 하시습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: AppColors.textGray))),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawBottomSheet() {
    final TextEditingController passwordController = TextEditingController();
    bool isWithdrawing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppColors.borderGray,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.primaryRed, size: 28),
                        SizedBox(width: 12),
                        Text(
                          '회원 탈퇴 안내',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '탈퇴 시 유의사항',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• 탈퇴 시 현재 계정 정보 및 관심 공모주 목록이 모두 삭제됩니다.\n• AI 챗봇 대화 기록은 복구할 수 없도록 영구 폐기됩니다.\n• 해당 아이디로 재가입하는 것은 불가능할 수 있습니다.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '안전한 탈퇴를 위해 비밀번호를 입력해 주세요.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '비밀번호 입력',
                        hintStyle: const TextStyle(color: AppColors.textLightGray, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: AppColors.bgGray.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderGray.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryRed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isWithdrawing
                            ? null
                            : () async {
                                final password = passwordController.text.trim();
                                if (password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('비밀번호를 입력해 주세요.')),
                                  );
                                  return;
                                }

                                setModalState(() => isWithdrawing = true);
                                try {
                                  await _userService.withdraw(password);
                                  await _authService.logout();
                                  
                                  if (!context.mounted) return;
                                  final navigator = Navigator.of(context);
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                                  navigator.pop(); // Close bottom sheet
                                  navigator.pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                  
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(content: Text('회원 탈퇴가 완료되었습니다. 이용해 주셔서 감사합니다.')),
                                  );
                                } catch (e) {
                                  setModalState(() => isWithdrawing = false);
                                  String errMsg = '회원 탈퇴에 실패했습니다. 비밀번호를 확인해 주세요.';
                                  bool isPasswordError = false;

                                  if (e is DioException) {
                                    if (e.response?.statusCode == 401) {
                                      errMsg = '비밀번호가 일치하지 않습니다.';
                                      isPasswordError = true;
                                    } else if (e.response?.data != null && e.response?.data is Map) {
                                      errMsg = e.response?.data['message'] ?? errMsg;
                                    }
                                  }

                                  if (isPasswordError) {
                                    if (!context.mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded, color: AppColors.primaryRed, size: 28),
                                            SizedBox(width: 8),
                                            Text('비밀번호 불일치', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          ],
                                        ),
                                        content: const Text(
                                          '입력하신 비밀번호가 일치하지 않습니다. 다시 확인 후 입력해 주세요.',
                                          style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.textDark),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errMsg)),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isWithdrawing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '회원 탈퇴하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text('마이 페이지', style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGray,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: '관심 공모주'), Tab(text: '설정')],
          ),
        ),
        body: TabBarView(children: [_buildFavoritesTab(), _buildSettingsTab()]),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_favorites.isEmpty) return const Center(child: Text('관심 등록한 종목이 없습니다.'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final item = _favorites[index];
        final String ipoId = item['ipoId']?.toString() ?? '';
        final String ipoName = item['companyName'] ?? item['name'] ?? '정보 없음';
        final String leadManager = item['leadManager'] ?? '-';
        final String? status = item['status'];
        final String dateRange = item['dateRange'] ?? '-';
        final int score = item['attractionScore'] ?? item['score'] ?? item['recentGrowthScore'] ?? 0;

        final bool isNotificationOn = _activeNotifications[ipoId] ?? true;

        return _buildIpoCard(
          score: score,
          ipoName: ipoName,
          leadManager: leadManager,
          dateLabel: dateRange,
          status: status,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isNotificationOn ? Icons.notifications_active : Icons.notifications_none, 
                  color: isNotificationOn ? const Color(0xFFF2C94C) : AppColors.textGray.withOpacity(0.5), 
                  size: 22
                ),
                onPressed: () async {
                  final newValue = !isNotificationOn;
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _activeNotifications[ipoId] = newValue);

                  // NotificationService에 즉시 반영 (SharedPreferences 영속화)
                  await NotificationService.instance
                      .setIpoNotificationEnabled(ipoId, newValue);

                  // [백엔드 연동 시] 아래 줄 추가:
                  // await _userService.updateIpoNotificationSetting(
                  //   ipoId: ipoId, enabled: newValue);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(newValue
                          ? '$ipoName의 청약 및 상장 알림이 활성화되었습니다.'
                          : '$ipoName의 청약 및 상장 알림이 비활성화되었습니다.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.primaryRed, size: 22),
                onPressed: () => _toggleFavorite(ipoId, true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => IpoDetailScreen(ipoId: ipoId, ipoName: ipoName))
          ).then((_) => _fetchData()),
        );
      },
    );
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
      case '환불':
        bg = const Color(0xFFFFF4E8); text = const Color(0xFFFF5E00);
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

  Widget _buildSettingsTab() {
    final user = AuthManager.instance.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          _buildSettingsCard([
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Row(children: [
                const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 16),
                Text('${user?.name ?? '사용자'} 님', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                (() {
                  final rawType = user?.investmentType ?? '#분석대기중';
                  final colors = _getBadgeColors(rawType);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors['bg'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rawType,
                      style: TextStyle(
                        color: colors['text'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                })(),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textGray),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSettingsCard([
            InkWell(onTap: _showNotificationSettings, child: _buildSettingsRow(Icons.notifications_none, '알림 설정')),
            const Divider(height: 32),
            InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupStep2Screen(isRetest: true))), child: _buildSettingsRow(Icons.description_outlined, '투자 성향 재검사')),
          ]),
          const SizedBox(height: 24),
          _buildSettingsCard([
            InkWell(onTap: _showLogoutDialog, child: _buildSettingsRow(Icons.logout, '로그아웃')),
            const Divider(height: 32),
            InkWell(
              onTap: _showWithdrawBottomSheet,
              child: _buildSettingsRow(Icons.person_remove_outlined, '회원탈퇴', textColor: AppColors.primaryRed),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderGray.withOpacity(0.5)), boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsRow(IconData icon, String title, {Color textColor = AppColors.textDark}) {
    return Row(children: [
      Icon(icon, color: AppColors.textGray, size: 24),
      const SizedBox(width: 16),
      Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
      const Spacer(),
      const Icon(Icons.chevron_right, color: AppColors.textGray),
    ]);
  }
}
