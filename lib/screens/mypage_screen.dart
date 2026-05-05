import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import 'ipo_detail_screen.dart';
import 'login_screen.dart';
import 'signup_step2_screen.dart';
import '../models/auth_manager.dart';
import '../services/user_service.dart';
import '../services/ipo_service.dart';
import '../services/auth_service.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final UserService _userService = UserService();
  final IpoService _ipoService = IpoService();
  final AuthService _authService = AuthService();

  List<dynamic> _favorites = [];
  bool _isLoading = true;

  bool _isSubscriptionAlarmOn = true;
  bool _isListingAlarmOn = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final favs = await _userService.getFavorites();
      setState(() {
        _favorites = favs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(String ipoId, bool currentStatus) async {
    try {
      await _ipoService.toggleFavorite(ipoId, !currentStatus);
      _fetchData();
    } catch (e) {
      if (mounted) {
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
                    _userService.updateNotificationSettings(
                      subscriptionAlarm: _isSubscriptionAlarmOn, 
                      listingAlarm: _isListingAlarmOn
                    ).catchError((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('알림 설정 저장 실패')));
                      }
                    });
                  }),
                  const SizedBox(height: 32),
                  _buildAlarmRow('상장일 알림', '상장 당일 아침에 잊지 않게 알려드려요', _isListingAlarmOn, (val) {
                    setModalState(() => _isListingAlarmOn = val);
                    setState(() => _isListingAlarmOn = val);
                    _userService.updateNotificationSettings(
                      subscriptionAlarm: _isSubscriptionAlarmOn, 
                      listingAlarm: _isListingAlarmOn
                    ).catchError((_) {
                      if (mounted) {
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
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
        final String ipoName = item['name'] ?? '정보 없음';
        final String leadManager = item['leadManager'] ?? '-';

        return GestureDetector(
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => IpoDetailScreen(ipoId: ipoId, ipoName: ipoName))
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ipoName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(leadManager, style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
                ])),
                IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.primaryRed),
                  onPressed: () => _toggleFavorite(ipoId, true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final user = AuthManager.instance.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          _buildSettingsCard([
            Row(children: [
              const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 16),
              Text('${user?.name ?? '사용자'} 님', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.bgLightBlue, borderRadius: BorderRadius.circular(8)), child: Text(user?.investmentType ?? '#안정형', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textGray),
            ]),
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
            _buildSettingsRow(Icons.person_remove_outlined, '회원탈퇴', textColor: AppColors.primaryRed),
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
