import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tekateki22/pages/halaman_tambah_soal.dart';

class HalamanPengaturanSoal extends StatefulWidget {
  const HalamanPengaturanSoal({super.key});

  @override
  State<HalamanPengaturanSoal> createState() => _HalamanPengaturanSoalState();
}

class _HalamanPengaturanSoalState extends State<HalamanPengaturanSoal> {
  final soalRef = FirebaseFirestore.instance.collection('permainan');
  final TextStyle textStyle = TextStyle(color: Colors.white);
  final Icon iconArrowRight = Icon(Icons.arrow_right, color: Colors.white);
  int levelLength = 0;

  @override
  void initState() {
    super.initState();
    soalRef.get().then((snapshot) {
      setState(() {
        levelLength = snapshot.size + 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Pengaturan Soal Level",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => HalamanTambahSoal(
                        data: {"name": "Level $levelLength"},
                        isNewLevel: true,
                      ),
                ),
              );
            },
            label: Text("Tambah Level"),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: soalRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Sedang memuat data, mohon tunggu...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum ada data level',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: data.docs.length,
              itemBuilder: (context, index) {
                final dataLevel = data.docs[index];
                final reference = dataLevel.reference;

                return ListTile(
                  title: Text("Soal ${dataLevel['name']}", style: textStyle),
                  trailing: iconArrowRight,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HalamanTambahSoal(
                              data: dataLevel.data(),
                              reference: reference,
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
