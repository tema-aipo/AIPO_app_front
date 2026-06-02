import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'mypage_screen.dart';
import 'chatbot_screen.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';
import '../widgets/ipo_notification_popup.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey<CalendarScreenState> _calendarKey = GlobalKey();
  final GlobalKey<MyPageScreenState> _myPageKey = GlobalKey();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(onGoToMyPage: () => _onItemTapped(3)),
      CalendarScreen(key: _calendarKey),
      const ChatbotScreen(),
      MyPageScreen(key: _myPageKey),
    ];
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService.instance.initialize();
    if (!mounted) return;
    if (NotificationService.instance.consumeAndCheckPopup()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const IpoNotificationPopup(),
        );
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _calendarKey.currentState?.refresh();
    } else if (index == 3) {
      _myPageKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderGray, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textGray,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          showUnselectedLabels: true,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_outlined)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.calendar_today_outlined)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.calendar_today)),
              label: '일정',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble_outline)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble)),
              label: '챗봇',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_outline)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person)),
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }
}
  

//vercel 깃 테스트