import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'onboarding_screen.dart';


const String BACKEND_BASE = 'http://10.0.2.2:4000';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const TrustSyncApp());
}

class TrustSyncApp extends StatelessWidget {
  const TrustSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustSync Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E3A8A), 
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      
      home: const OnboardingScreen(),
    );
  }
}