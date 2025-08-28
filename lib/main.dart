import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tekateki22/animation_splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart'; // file yang tadi dibuat

// 🔔 Buat instance notifikasi global
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  // // 🔑 Pastikan binding siap
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 Init Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 🟢 Request izin notifikasi (khusus Android 13+)
  final bool? granted =
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

  debugPrint("Permission granted? $granted");

  // 🚀 Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚀 Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tekacaya',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0A0E2A)),
        primaryColor: Color(0xFF0A0E2A),
        scaffoldBackgroundColor: const Color(0xFF0A0E2A),
        appBarTheme: AppBarTheme(backgroundColor: const Color(0xFF0A0E2A)),
        useMaterial3: true,
      ),
      home: AnimationSplashScreen(),
    );
  }
}
