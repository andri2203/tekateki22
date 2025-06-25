import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_wrapper.dart';
import 'firebase_options.dart'; // file yang tadi dibuat

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ⏳ Tunggu Firebase selesai diinisialisasi
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 💤 Tambahkan delay 3 detik untuk splash (opsional)
  await Future.delayed(Duration(seconds: 3));

  // 🧼 Hapus splash setelah Firebase siap
  FlutterNativeSplash.remove();

  // 🚀 Jalankan aplikasi
  runApp(MyApp());
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
      home: const AuthWrapper(),
    );
  }
}
