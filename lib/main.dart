import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'models/auth_manager.dart';
import 'network/dio_client.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 환경 변수 로드 (웹 배포 환경을 고려하여 assets/env 사용)
  try {
    await dotenv.load(fileName: 'assets/env');
  } catch (e) {
    debugPrint('환경 변수 파일을 로드할 수 없습니다: $e');
  }
  // Dio HTTP 클라이언트 초기화
  DioClient.instance.initialize();
  
  // 앱 시작 시 자동 로그인(세션 복구) 시도
  await AuthService().restoreSession();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIPO',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        primaryColor: const Color(0xFF0066FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFFF5F6F8), // 브라우저 배경색
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 412),
              child: child,
            ),
          ),
        );
      },
      home: ValueListenableBuilder(
        valueListenable: AuthManager.instance.currentUser,
        builder: (context, user, _) {
          if (user != null) {
            return const MainScreen();
          } else {
            return const OnboardingScreen();
          }
        },
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
