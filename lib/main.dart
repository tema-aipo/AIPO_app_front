import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'models/auth_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
