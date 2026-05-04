import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'models/auth_manager.dart';
import 'network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 환경 변수 로드
  await dotenv.load(fileName: '.env');
  // Dio HTTP 클라이언트 초기화
  DioClient.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIPO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        primaryColor: const Color(0xFF0066FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
        ),
      ),
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
