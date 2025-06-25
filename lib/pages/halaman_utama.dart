import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/styles.dart';
import 'package:tekateki22/pages/halaman_level.dart';
import 'package:tekateki22/pages/halaman_pengaturan.dart';

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  final User? user = FirebaseAuth.instance.currentUser;
  late final String? displayName;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      displayName = user!.displayName;
    } else {
      displayName = "administrator";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$displayName",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HalamanPengaturan()),
              );
            },
            icon: Icon(Icons.info_outline, color: Colors.white70),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: Icon(Icons.output, color: Colors.red.shade600),
          ),
        ],
      ),
      body: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('images/splash_android12.png'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => HalamanLevel()));
                  },
                  style: buttonStyle,
                  child: Text("Mulai Permainan", style: textStyle),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HalamanPengaturan()),
                    );
                  },
                  style: buttonStyle,
                  child: Text("Pengaturan", style: textStyle),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            child: Text(
              "VERUZ ZABAZI | 2022302034",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
