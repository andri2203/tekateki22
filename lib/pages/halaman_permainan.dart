import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  int gridCount = 10;
  Timer? timer;
  List<String?> grid = [];
  List<String> kunciJawaban = [];
  List<Soal> soalTerpilih = [];
  Map<int, List<int>> nomorSoal = {};
  bool loading = true;
  int soalIndex = 0;
  late Soal soalActive;
  Map<int, String?> isiJawaban = <int, String?>{};
  List<int> indexSoalSelesai = <int>[];
  int waktuPermainan = 0;
  int remainingSeconds = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  DocumentReference<Map<String, dynamic>>? userPoinHistory;
  final GlobalKey _globalKey = GlobalKey();

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
    waktuPermainan = soalTerpilih.length * 60;
    remainingSeconds = soalTerpilih.length * 60;
    soalActive = soalTerpilih[soalIndex];

    final panjangGrid = gridCount;

    grid = List.generate(panjangGrid * panjangGrid, (_) => null);

    List<String> kata = [];

    for (var i = 0; i < dataSoal.length; i++) {
      Soal soal = dataSoal[i];
      int startIndex = soal.x + (soal.y * panjangGrid);
      // kalau belum ada key-nya, buat list kosong
      nomorSoal[startIndex] ??= [];
      // tambahkan nomor ke list
      nomorSoal[startIndex]!.add(i + 1);
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

  Future<void> shareCard() async {
    try {
      // Ambil RenderRepaintBoundary dari global key
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Convert ke image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // biar HD
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Simpan ke file temporary
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/share_tts_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      // Share file
      await SharePlus.instance.share(
        ShareParams(
          title: 'Ayo adu skor TTS sama aku!',
          text: 'Ayo adu skor TTS sama aku!',
          files: [XFile(file.path)],
          previewThumbnail: XFile(file.path),
          sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Terjadi Kesalahan ${e.toString()}'),
            );
          },
        );
      }
      return;
    }
  }

  int calculatePoints({
    required int totalQuestions,
    required int answeredQuestions,
    required int elapsedSeconds,
    required int maxTimeSeconds,
  }) {
    return ((100 - (elapsedSeconds / maxTimeSeconds * 100) * 0.5) *
            (answeredQuestions / totalQuestions))
        .clamp(0, 100)
        .round();
  }

  Future<void> handlePoinPermainan({isTimeOut = false}) async {
    try {
      int timeLimit = waktuPermainan;
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

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(
                  isTimeOut
                      ? "Waktu Anda Telah Habis. "
                      : "Permainan telah selesai. ",
                ),
                actions: [
                  ElevatedButton.icon(
                    onPressed: shareCard, // panggil fungsi share
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text(
                      "Bagikan",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
                content: RepaintBoundary(
                  key: _globalKey,
                  child: cardSharePoint(context, poin),
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
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Terjadi Kesalahan ${e.toString()}'),
            );
          },
        );
      }
      return;
    }
  }

  Widget cardSharePoint(BuildContext context, int poin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pesan Utama
          Text(
            "Terimakasih telah memainkan TTS kami.\nAnda mendapatkan poin $poin di ${widget.level.name}.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Ajakan Share
          Text(
            "Bagikan ke teman-teman anda,\nadu pengetahuan dan skor bersama!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),

          // Footer Terimakasih
          Text(
            "Terimakasih",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
              List<int> nomorList = nomorSoal[index] ?? [];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (char != isiJawaban[index]) {
                      isiJawaban[index] = null;
                    }
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
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
                    if (nomorList.isNotEmpty)
                      Positioned(
                        top: nomorList.length == 1 ? -5 : -10,
                        right: nomorList.length == 1 ? -5 : 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            nomorList.length == 1
                                ? nomorList.first.toString()
                                : nomorList.join(', '),
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
          const SizedBox(height: 12),
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
        persistentFooterButtons: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children:
                List<int>.generate(
                  soalTerpilih.length,
                  (int index) => index,
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
                      minimumSize: const Size(40, 40),
                    ),
                    child: Text(
                      "${nomor + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
