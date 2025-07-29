import 'package:flutter/material.dart';
import 'package:tekateki22/pages/halaman_akun_user.dart';
import 'package:tekateki22/pages/halaman_pengaturan_soal.dart';

class HalamanPengaturan extends StatefulWidget {
  final bool isAdmin;
  const HalamanPengaturan({super.key, required this.isAdmin});

  @override
  State<HalamanPengaturan> createState() => _HalamanPengaturanState();
}

class _HalamanPengaturanState extends State<HalamanPengaturan> {
  final TextStyle textStyle = TextStyle(color: Colors.white);
  final Icon iconArrowRight = Icon(Icons.arrow_right, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Pengaturan", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Akun Anda", style: textStyle),
            trailing: iconArrowRight,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => HalamanAkunUser(),
                ),
              );
            },
          ),
          if (widget.isAdmin == true)
            ListTile(
              title: Text("Pengaturan Soal", style: textStyle),
              trailing: iconArrowRight,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => HalamanPengaturanSoal(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
