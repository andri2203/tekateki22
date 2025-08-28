import 'package:flutter/material.dart';

class HalamanAboutUs extends StatefulWidget {
  const HalamanAboutUs({super.key});

  @override
  State<HalamanAboutUs> createState() => _HalamanAboutUsState();
}

class _HalamanAboutUsState extends State<HalamanAboutUs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Tentang Aplikasi",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset("images/logo_poltek_aceh.png", width: 180),
              Image.asset("images/splash_android12.png", width: 180),

              // Deskripsi
              Text(
                "Aplikasi ini dibuat oleh saya, VERUZ ZABAZI, "
                "mahasiswa Politeknik Aceh.\n\n"
                "Tujuan aplikasi ini adalah untuk memberikan pengalaman "
                "belajar dan hiburan melalui permainan teka-teki silang.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[300],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Info tambahan
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Politeknik Aceh\n2025",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
