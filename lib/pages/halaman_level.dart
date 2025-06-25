import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tekateki22/models/level.dart';
import '../components/styles.dart';
import 'halaman_permainan.dart';

class HalamanLevel extends StatefulWidget {
  const HalamanLevel({super.key});

  @override
  State<HalamanLevel> createState() => _HalamanLevelState();
}

class _HalamanLevelState extends State<HalamanLevel> {
  final soalRef = FirebaseFirestore.instance.collection('permainan');
  final TextStyle textStyle = TextStyle(color: Colors.white);
  final Icon iconArrowRight = Icon(Icons.arrow_right, color: Colors.white);

  CollectionReference<Map<String, dynamic>> dataSoal(String docID) {
    return soalRef.doc(docID).collection('soal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("LEVELS", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: soalRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
              child: Center(
                child: Text(
                  'Belum ada data level',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          }

          return Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              itemCount: data.docs.length,
              itemBuilder: (context, index) {
                final datalevel = data.docs[index];
                final Level level = Level.fromMap({
                  'docID': datalevel.id,
                  'name': datalevel.data()['name'],
                });

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HalamanPermainan(level: level),
                        ),
                      );
                    },
                    style: buttonStyle,
                    child: Text(level.name, style: textStyle),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
