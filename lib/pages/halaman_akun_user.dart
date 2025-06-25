import 'package:flutter/material.dart';

class HalamanAkunUser extends StatefulWidget {
  const HalamanAkunUser({super.key});

  @override
  State<HalamanAkunUser> createState() => _HalamanAkunUserState();
}

class _HalamanAkunUserState extends State<HalamanAkunUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Akun Anda", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
    );
  }
}
