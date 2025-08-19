import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  List<String> grid = [];
  final ValueNotifier<List<bool>> gridCharCorrect = ValueNotifier(
    List.generate(10 * 10, (_) => false),
  );
  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];
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
  List<int> indexGridActive = [];
  int currentActiveIndex = 0;

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

  void _moveToNext(int currentIndex) {
    int pos = indexGridActive.indexOf(currentIndex);
    if (pos != -1 && pos < indexGridActive.length - 1) {
      int nextIndex = indexGridActive[pos + 1];

      // Cek apakah sudah ada isi ATAU sudah correct
      if (controllers[nextIndex].text.isNotEmpty ||
          gridCharCorrect.value[nextIndex]) {
        // rekursif, lompat ke berikutnya sampai ketemu yang kosong/salah
        _moveToNext(nextIndex);
      } else {
        FocusScope.of(context).requestFocus(focusNodes[nextIndex]);
        currentActiveIndex = nextIndex;
      }
    }
  }

  void _moveToPrev(int currentIndex) {
    int pos = indexGridActive.indexOf(currentIndex);

    if (pos > 0) {
      int prevIndex = indexGridActive[pos - 1];

      FocusScope.of(context).requestFocus(focusNodes[prevIndex]);
      currentActiveIndex = prevIndex;

      // kalau char sudah correct → kunci dengan cara reset controllernya
      if (gridCharCorrect.value[prevIndex]) {
        FocusScope.of(context).requestFocus(focusNodes[prevIndex - 1]);
        // pastikan teks tetap sama (tidak bisa dihapus)
        final text = controllers[prevIndex].text;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controllers[prevIndex].text = text;
        });
      }
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
        handlePoinPermainan(
          isTimeOut: true,
          correctChar: gridCharCorrect.value,
        );
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
    int startIndexActive = soalActive.x + (soalActive.y * gridCount);

    // auto buka keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNodes[startIndexActive]);
    });

    for (var i = 0; i < soalActive.jawaban.length; i++) {
      int currIdx = i;

      if (soalActive.arah == Arah.menurun) {
        currIdx = startIndexActive + (i * gridCount);
      } else {
        currIdx = startIndexActive + i;
      }

      indexGridActive.add(currIdx);
    }

    final panjangGrid = gridCount;

    grid = List.generate(panjangGrid * panjangGrid, (_) => "");
    controllers = List.generate(
      panjangGrid * panjangGrid,
      (_) => TextEditingController(),
    );
    focusNodes = List.generate(panjangGrid * panjangGrid, (_) => FocusNode());

    for (var i = 0; i < dataSoal.length; i++) {
      Soal soal = dataSoal[i];
      int startIndex = soal.x + (soal.y * panjangGrid);
      // kalau belum ada key-nya, buat list kosong
      nomorSoal[startIndex] ??= [];
      // tambahkan nomor ke list
      nomorSoal[startIndex]!.add(i + 1);

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
    required int totalCells,
    required List<bool> gridCharCorrect,
    required int elapsedSeconds,
    required int maxTimeSeconds,
  }) {
    final answeredCells =
        gridCharCorrect.where((isCorrect) => isCorrect).length;

    return ((100 - (elapsedSeconds / maxTimeSeconds * 100) * 0.5) *
            (answeredCells / totalCells))
        .clamp(0, 100)
        .round();
  }

  Future<void> handlePoinPermainan({
    isTimeOut = false,
    required correctChar,
  }) async {
    try {
      int timeLimit = waktuPermainan;
      int timeTaken = timeLimit - remainingSeconds;
      int poin = calculatePoints(
        totalCells: grid.where((c) => c.isNotEmpty).length,
        gridCharCorrect: correctChar,
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: gridCount * gridCount,
            itemBuilder: (context, index) {
              String char = grid[index];
              TextEditingController controller = controllers[index];
              List<int> nomorList = nomorSoal[index] ?? [];
              bool isActive = indexGridActive.contains(index);

              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(focusNodes[index]);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ✅ hanya cell ini yang listen
                    ValueListenableBuilder<List<bool>>(
                      valueListenable: gridCharCorrect,
                      builder: (context, listCorrect, _) {
                        bool isCorrect = listCorrect[index];

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color:
                                  indexGridActive.isNotEmpty &&
                                          indexGridActive.contains(index)
                                      ? Colors.green.shade600
                                      : char != ""
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                            ),
                            color:
                                char == ""
                                    ? Theme.of(context).primaryColor
                                    : controller.text.isEmpty
                                    ? Colors.white
                                    : isCorrect
                                    ? Colors.green.shade400
                                    : Colors.red.shade400,
                          ),
                          child:
                              char == ""
                                  ? Container()
                                  : KeyboardListener(
                                    focusNode: FocusNode(),
                                    onKeyEvent: (event) {
                                      if (event is KeyDownEvent &&
                                          event.logicalKey ==
                                              LogicalKeyboardKey.backspace) {
                                        if (controller.text.isEmpty &&
                                            isActive) {
                                          _moveToPrev(index);
                                        }
                                      }
                                    },
                                    child: TextField(
                                      inputFormatters: [
                                        LockCorrectCharFormatter(
                                          gridCharCorrect.value[index],
                                        ),
                                      ],
                                      controller: controller,
                                      focusNode: focusNodes[index],
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      decoration: const InputDecoration(
                                        counterText: "",
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      onChanged: (val) {
                                        if (val.isNotEmpty && isActive) {
                                          final correct =
                                              char == val.toUpperCase();

                                          // update flag benar utk sel ini
                                          final temp = List<bool>.from(
                                            gridCharCorrect.value,
                                          );
                                          temp[index] = correct;
                                          gridCharCorrect.value = temp;

                                          // ✅ hitung total sel input (unik) dan berapa yang sudah benar
                                          final int totalInputCells =
                                              grid
                                                  .where((c) => c.isNotEmpty)
                                                  .length;

                                          int correctCount = 0;
                                          for (
                                            int i = 0;
                                            i < grid.length;
                                            i++
                                          ) {
                                            if (grid[i].isNotEmpty && temp[i]) {
                                              correctCount++;
                                            }
                                          }

                                          final bool allCorrect =
                                              correctCount == totalInputCells;

                                          if (allCorrect) {
                                            handlePoinPermainan(
                                              correctChar: temp,
                                            ); // 🎉 semua benar
                                          } else {
                                            _moveToNext(
                                              index,
                                            ); // lanjut ke sel berikutnya
                                          }
                                        }
                                      },
                                    ),
                                  ),
                        );
                      },
                    ),
                    if (nomorList.isNotEmpty)
                      Positioned(
                        top: nomorList.length == 1 ? -5 : -10,
                        right: nomorList.length == 1 ? -5 : 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
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
            padding: EdgeInsets.all(8),
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
                      Soal soal = soalTerpilih[nomor];

                      int startIndex = soal.x + (soal.y * gridCount);

                      FocusScope.of(
                        context,
                      ).requestFocus(focusNodes[startIndex]);
                      SystemChannels.textInput.invokeMethod('TextInput.show');

                      if (soalIndex != nomor) {
                        setState(() {
                          indexGridActive = [];
                          soalIndex = nomor;
                          soalActive = soal;

                          for (var i = 0; i < soalActive.jawaban.length; i++) {
                            if (soalActive.arah == Arah.menurun) {
                              indexGridActive.add(startIndex + (i * gridCount));
                            } else {
                              indexGridActive.add(startIndex + i);
                            }
                          }
                        });
                      }
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
                : SingleChildScrollView(child: papanPermainan(context)),
      ),
    );
  }
}

class LockCorrectCharFormatter extends TextInputFormatter {
  final bool isLocked;
  LockCorrectCharFormatter(this.isLocked);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (isLocked) {
      return oldValue; // cegah perubahan
    }
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
