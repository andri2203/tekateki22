import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/styles.dart';
import '../models/level.dart';
import '../models/soal.dart';

class HalamanPermainan extends StatefulWidget {
  final Level level;
  final List<Soal> dataSoal;
  const HalamanPermainan({
    super.key,
    required this.level,
    required this.dataSoal,
  });

  @override
  State<HalamanPermainan> createState() => _HalamanPermainanState();
}

class _HalamanPermainanState extends State<HalamanPermainan> {
  int remainingSeconds = 120;
  int gridCount = 10;
  Timer? timer;
  List<String?> grid = [];
  List<String> kunciJawaban = [];
  List<Soal> soalTerpilih = [];
  Map<int, int?> nomorSoal = {};
  bool loading = true;
  int soalIndex = 0;
  late Soal soalActive;
  Map<int, String?> isiJawaban = <int, String?>{};
  List<int> indexSoalSelesai = <int>[];
  final User? user = FirebaseAuth.instance.currentUser;
  DocumentReference<Map<String, dynamic>>? userPoinHistory;

  @override
  void initState() {
    super.initState();
    generateFixedGrid();

    if (user != null) {
      userPoinHistory = FirebaseFirestore.instance
          .collection(user!.uid)
          .doc(widget.level.docID);
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        handlePoinPermainan(isTimeOut: true);
      }
    });
    setState(() {});
  }

  void generateFixedGrid() {
    final List<Soal> dataSoal = widget.dataSoal;

    soalTerpilih = widget.dataSoal;

    soalActive = soalTerpilih[soalIndex];

    final panjangGrid = gridCount;

    grid = List.generate(panjangGrid * panjangGrid, (_) => null);

    List<String> kata = [];

    for (var i = 0; i < dataSoal.length; i++) {
      Soal soal = dataSoal[i];
      int startIndex = soal.x + (soal.y * panjangGrid);
      nomorSoal[startIndex] = i + 1;
      kata.add(soal.jawaban);

      for (var j = 0; j < soal.jawaban.length; j++) {
        int currentIndex;

        if (soal.arah == Arah.mendatar) {
          currentIndex = startIndex + j; // 👉 geser ke kanan (X axis)
        } else {
          currentIndex =
              startIndex + (j * panjangGrid); // 👉 geser ke bawah (Y axis)
        }

        // Pastikan tidak keluar dari batas grid
        if (currentIndex < grid.length) {
          isiJawaban[currentIndex] = null;
          grid[currentIndex] = soal.jawaban[j];
        }
      }
    }

    List<String> hurufUnik =
        kata.join().toUpperCase().split('').toSet().toList();
    hurufUnik.sort();

    kunciJawaban = hurufUnik;
    loading = false;
    setState(() {});
    startTimer();
  }

  String formatTimer(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String mm = minutes.toString().padLeft(2, '0');
    String ss = remainingSeconds.toString().padLeft(2, '0');
    return "$mm:$ss";
  }

  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ingin meninggalkan permainan?'),
          content: const Text(
            'Skor dan waktu akan direset jika anda meninggalkan permainan',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Tidak, Saya Lanjutkan'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Ya, Saya akan kembali nanti'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  int calculatePoints({
    required int totalQuestions,
    required int answeredQuestions,
    required int elapsedSeconds,
    required int maxTimeSeconds,
  }) {
    // Kalau semua soal dijawab
    if (answeredQuestions >= totalQuestions) {
      if (elapsedSeconds <= 30) return 100;
      if (elapsedSeconds <= 60) return 80;
      if (elapsedSeconds <= 90) return 60;
      if (elapsedSeconds <= maxTimeSeconds) return 50;
    }

    // Kalau belum selesai menjawab saat waktu habis
    if (elapsedSeconds >= maxTimeSeconds &&
        answeredQuestions < totalQuestions) {
      double percent = answeredQuestions / totalQuestions;
      return (50 * percent).round(); // maksimum poin 50 dikalikan progress
    }

    // Kalau waktu belum habis tapi soal belum selesai → belum final
    return 0;
  }

  Future<void> handlePoinPermainan({isTimeOut = false}) async {
    int timeLimit = 120;
    int timeTaken = timeLimit - remainingSeconds;
    int poin = calculatePoints(
      totalQuestions: soalTerpilih.length,
      answeredQuestions: indexSoalSelesai.length,
      elapsedSeconds: timeTaken,
      maxTimeSeconds: timeLimit,
    );

    if (userPoinHistory != null) {
      final docSnapshot = await userPoinHistory!.get();

      if (docSnapshot.exists) {
        // Dokumen sudah ada → update poin
        await userPoinHistory!.update({'poin': poin});
      } else {
        // Dokumen belum ada → buat baru
        await userPoinHistory!.set({'poin': poin});
      }

      String pesan = "Anda mendapatkan poin : $poin";

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                '${isTimeOut ? "Waktu Anda Telah Habis. " : "Permainan telah selesai. "}$pesan',
              ),
            );
          },
        ).then((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  Widget papanPermainan(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: gridCount * gridCount,
            itemBuilder: (context, index) {
              String? char = grid[index];
              int? nomor = nomorSoal[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (char != isiJawaban[index]) {
                      isiJawaban[index] = null;
                    }
                  });
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color:
                            char == null
                                ? Theme.of(context).primaryColor
                                : isiJawaban[index] == null
                                ? Colors.white
                                : char == isiJawaban[index]
                                ? Colors.green.shade400
                                : Colors.red.shade400,
                      ),
                      child: Center(
                        child:
                            char == null
                                ? Text("")
                                : Text(isiJawaban[index] ?? ""),
                      ),
                    ),
                    if (nomor != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            nomor.toString(),
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.green.shade600,
            ),
            child: Text(
              "${soalIndex + 1}. ${soalActive.pertanyaan}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: kunciJawaban.length,
            itemBuilder: (_, index) {
              String kunci = kunciJawaban[index];

              return ElevatedButton(
                onPressed: () {
                  int startIndex = soalActive.x + (soalActive.y * gridCount);

                  for (var j = 0; j < soalActive.jawaban.length; j++) {
                    int currentIndex;

                    if (soalActive.arah == Arah.mendatar) {
                      currentIndex = startIndex + j;
                    } else {
                      currentIndex = startIndex + (j * gridCount);
                    }

                    // Cek apakah posisi saat ini belum diisi
                    if (isiJawaban[currentIndex] == null ||
                        isiJawaban[currentIndex] == "") {
                      isiJawaban[currentIndex] = kunci;
                      break; // 👉 berhenti setelah mengisi satu huruf
                    }
                  }

                  for (var i = 0; i < soalTerpilih.length; i++) {
                    Soal soal = soalTerpilih[i];
                    int indexSoal = soal.x + (soal.y * gridCount);
                    List<int> keysToCombine = <int>[];

                    for (var j = 0; j < soal.jawaban.length; j++) {
                      String jawabanChar = soal.jawaban[j];
                      int indexJawaban;

                      if (soal.arah == Arah.mendatar) {
                        indexJawaban = indexSoal + j;
                      } else {
                        indexJawaban = indexSoal + (j * gridCount);
                      }

                      if (jawabanChar == isiJawaban[indexJawaban]) {
                        keysToCombine.add(indexJawaban);
                      }
                    }

                    if (keysToCombine.isNotEmpty && soalIndex == i) {
                      String jawabanDiIsi =
                          keysToCombine
                              .map((key) => isiJawaban[key] ?? '')
                              .join();

                      if (jawabanDiIsi.contains(soal.jawaban)) {
                        indexSoalSelesai.add(soalIndex);
                      }
                    }
                  }

                  setState(() {});

                  if (indexSoalSelesai.length == soalTerpilih.length) {
                    timer?.cancel();
                    handlePoinPermainan();
                  }
                },
                style: buttonStyle,
                child: Text(
                  kunci,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _showBackDialog() ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              final bool shouldPop = await _showBackDialog() ?? false;
              if (context.mounted && shouldPop) {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.close, color: Colors.red.shade600),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            widget.level.name.toUpperCase(),
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                formatTimer(remainingSeconds),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body:
            loading
                ? Center(child: CircularProgressIndicator())
                : papanPermainan(context),
        persistentFooterAlignment: AlignmentDirectional.center,
        persistentFooterButtons:
            List<int>.generate(
              soalTerpilih.length,
              (int index) => index,
              growable: true,
            ).map((nomor) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (soalIndex != nomor) {
                      soalIndex = nomor;
                      soalActive = soalTerpilih[nomor];
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      soalIndex == nomor
                          ? Colors.green.shade600
                          : Colors.blue.shade600,
                ),
                child: Text(
                  "${nomor + 1}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
