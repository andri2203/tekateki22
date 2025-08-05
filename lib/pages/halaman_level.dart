import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tekateki22/models/level.dart';
import 'halaman_permainan.dart';
import '../models/soal.dart';

class HalamanLevel extends StatefulWidget {
  const HalamanLevel({super.key});

  @override
  State<HalamanLevel> createState() => _HalamanLevelState();
}

class _HalamanLevelState extends State<HalamanLevel> {
  final soalRef = FirebaseFirestore.instance.collection('permainan');
  final TextStyle textStyle = TextStyle(color: Colors.white);
  final Icon iconArrowRight = Icon(Icons.arrow_right, color: Colors.white);
  Map<String, dynamic> gameHistory = <String, dynamic>{};
  final User? user = FirebaseAuth.instance.currentUser;
  bool loadingPoin = true;

  @override
  void initState() {
    super.initState();
    historyGamePlay();
  }

  Future<void> historyGamePlay() async {
    final historyUserSnap =
        await FirebaseFirestore.instance.collection(user!.uid).get();

    setState(() {
      gameHistory = {
        for (var doc in historyUserSnap.docs) doc.id: doc.data()['poin'],
      };
      loadingPoin = false;
    });
  }

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

          final firstData = data.docs.first;

          return Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              itemCount: data.docs.length,
              itemBuilder: (context, index) {
                Color boxColor = Colors.blue.shade600;
                bool isEnableToTap = true;
                final datalevel = data.docs[index];

                final List<Soal> dataSoal =
                    datalevel.data().containsKey('soal') == false
                        ? []
                        : (datalevel.data()['soal'] as List)
                            .map<Soal>(
                              (data) => Soal.fromMap({
                                'docID': data['entryID'],
                                ...data,
                              }),
                            )
                            .toList();

                if (dataSoal.isEmpty) {
                  boxColor = Colors.red.shade600;
                }

                final Level level = Level.fromMap({
                  'docID': datalevel.id,
                  'name': datalevel.data()['name'],
                });
                final poin = gameHistory[level.docID];

                final levelBefore = index != 0 ? data.docs[index - 1] : null;

                if (poin == null) {
                  if (firstData.id != level.docID) {
                    if (levelBefore != null) {
                      final int? poinBefore = gameHistory[levelBefore.id];
                      if (poinBefore == null || poinBefore == 0) {
                        isEnableToTap = false;
                        boxColor =
                            dataSoal.isEmpty
                                ? Colors.red.shade900
                                : Colors.blue.shade900;
                      }
                    }
                  }
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    onTap: () {
                      if (isEnableToTap == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Selesaikan Level Sebelumnya"),
                          ),
                        );
                        return;
                      }

                      if (dataSoal.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Soal belum tersedia, mohon tunggu"),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder:
                                  (context) => HalamanPermainan(
                                    level: level,
                                    dataSoal: dataSoal,
                                  ),
                            ),
                          )
                          .then((_) {
                            setState(() {
                              loadingPoin = true;
                            });
                            historyGamePlay();
                          });
                    },
                    title: Text(
                      "${level.name} ${dataSoal.isEmpty ? '(belum ada soal)' : ''}",
                      style: textStyle,
                    ),
                    trailing:
                        loadingPoin
                            ? CircularProgressIndicator()
                            : Text("${poin ?? 0}/100", style: textStyle),
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
