import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // for cupertino switch if needed, but flutter Switch is fine
import '../theme/app_colors.dart';
import 'ipo_detail_screen.dart';
import 'calendar_screen.dart'; // EventType 열거형 재활용
import 'profile_screen.dart';
import 'login_screen.dart';
import 'signup_step2_screen.dart';
import '../models/favorite_manager.dart';
import '../models/auth_manager.dart';

class MyPageTask {
  final int score;
  final String name;
  final String broker;
  final String period;
  final EventType type;
  bool isBellOn;
  bool isHeartOn;

  MyPageTask({
    required this.score,
    required this.name,
    required this.broker,
    required this.period,
    required this.type,
    this.isBellOn = true,
    this.isHeartOn = true,
  });
}

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late List<MyPageTask> _localTasks;

  // Settings states
  bool _isSubscriptionAlarmOn = true;
  bool _isListingAlarmOn = false;

  @override
  void initState() {
    super.initState();
    // 화면에 들어올 때 스냅샷 복사 (빈 하트 유지 기능)
    _localTasks = List.from(FavoriteManager.instance.favoritesNotifier.value);
    // 복사된 시점에서는 모두 찜이 눌려 있는 상태
    for (var t in _localTasks) {
      t.isHeartOn = true;
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
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24), // balance
                      const Text('알림 설정', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: AppColors.textGray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Option 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('청약 일정 알림', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('청약 시작일과 마감일에 알려드려요', style: TextStyle(color: AppColors.textGray.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      CupertinoSwitch(
                        activeColor: AppColors.primary,
                        value: _isSubscriptionAlarmOn,
                        onChanged: (val) {
                          setModalState(() => _isSubscriptionAlarmOn = val);
                          setState(() => _isSubscriptionAlarmOn = val); // update parent
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Option 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('상장일 알림', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('상장 당일 아침에 잊지 않게 알려드려요', style: TextStyle(color: AppColors.textGray.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      CupertinoSwitch(
                        activeColor: AppColors.primary,
                        value: _isListingAlarmOn,
                        onChanged: (val) {
                          setModalState(() => _isListingAlarmOn = val);
                          setState(() => _isListingAlarmOn = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // required for keyboard adjustment
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pull indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    const Text('회원탈퇴', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: AppColors.textGray),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('정말 탈퇴하시겠어요?', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  '탈퇴 시 맞춤형 투자 성향 및 챗봇 대화 내역이 모두 삭제되며 복구할 수 없습니다.\n본인 확인을 위해 비밀번호를 입력해 주세요.',
                  style: TextStyle(color: AppColors.textGray.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                ),
                const SizedBox(height: 24),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '비밀번호 입력',
                    hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 15, fontWeight: FontWeight.w500),
                    suffixIcon: const Icon(Icons.visibility_outlined, color: AppColors.textGray),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.borderGray.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryRed), // focus color red
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthManager.instance.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                         context,
                         MaterialPageRoute(builder: (_) => const LoginScreen()),
                         (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('탈퇴하기', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: const Text(
            '정말 로그아웃 하시겠습니까?',
            style: TextStyle(color: AppColors.textGray, height: 1.5, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () async {
                await AuthManager.instance.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          ],
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
          toolbarHeight: 60,
          centerTitle: true,
          title: const Text('마이 페이지',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGray,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: '관심 공모주'),
              Tab(text: '설정'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavoritesTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      itemCount: _localTasks.length,
      itemBuilder: (context, index) {
        final task = _localTasks[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => IpoDetailScreen(ipoName: task.name)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                    color: AppColors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Left Part
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 8, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${task.score}점',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: task.type.bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        task.type.label,
                        style: TextStyle(
                            color: task.type.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Middle Part
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.broker,
                        style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.period,
                        style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right Part
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          task.isBellOn = !task.isBellOn;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(task.isBellOn ? '알림이 설정되었습니다.' : '알림이 해제되었습니다.'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Icon(
                        task.isBellOn
                            ? Icons.notifications
                            : Icons.notifications_none,
                        color: task.isBellOn
                            ? const Color(0xFFFFD600)
                            : AppColors.textGray,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          task.isHeartOn = !task.isHeartOn;
                        });
                        FavoriteManager.instance.toggleFavorite(task.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(task.isHeartOn ? '관심 종목으로 등록되었습니다.' : '관심 종목에서 해제되었습니다.'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Icon(
                        task.isHeartOn ? Icons.favorite : Icons.favorite_border,
                        color: task.isHeartOn
                            ? AppColors.primaryRed
                            : AppColors.textGray,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final user = AuthManager.instance.currentUser.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          // Profile Card
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: _buildSettingsCard(
              [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          color: AppColors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Text('${user?.name ?? '사용자'} 님',
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgLightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(user?.investmentType ?? '#안정형',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.textGray),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Group 1
          _buildSettingsCard(
            [
              InkWell(
                onTap: _showNotificationSettings,
                child: _buildSettingsRow(Icons.notifications_none, '알림 설정'),
              ),
              const Divider(
                  color: AppColors.borderGray, height: 32, thickness: 0.5),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupStep2Screen(isRetest: true)),
                  );
                },
                child: _buildSettingsRow(Icons.description_outlined, '투자 성향 재검사'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Group 2
          _buildSettingsCard(
            [
              _buildSettingsRow(Icons.headset_mic_outlined, '문의하기'),
              const Divider(
                  color: AppColors.borderGray, height: 32, thickness: 0.5),
              _buildSettingsRow(Icons.info_outline, '앱 버전 정보',
                  trailingText: '최신 버전 (v1.0.0)'),
            ],
          ),
          const SizedBox(height: 24),
          // Group 3
          _buildSettingsCard(
            [
              InkWell(
                onTap: _showLogoutDialog,
                child: _buildSettingsRow(Icons.logout, '로그아웃'),
              ),
              const Divider(
                  color: AppColors.borderGray, height: 32, thickness: 0.5),
              InkWell(
                onTap: _showDeleteAccountSheet,
                child: _buildSettingsRow(Icons.person_remove_outlined, '회원탈퇴',
                    textColor: AppColors.primaryRed),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsRow(IconData icon, String title,
      {String? trailingText, Color textColor = AppColors.textDark}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textGray, size: 24),
        const SizedBox(width: 16),
        Text(title,
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (trailingText != null)
          Text(trailingText,
              style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
        if (trailingText == null && textColor != AppColors.primaryRed)
          const Icon(Icons.chevron_right, color: AppColors.textGray),
      ],
    );
  }
}
