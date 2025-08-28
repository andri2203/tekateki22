import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../services/notification_service.dart';

class HalamanTambahSoal extends StatefulWidget {
  final bool isNewLevel;
  final Map<String, dynamic> data;
  final DocumentReference<Map<String, dynamic>>? reference;
  const HalamanTambahSoal({
    super.key,
    this.isNewLevel = false,
    required this.data,
    this.reference,
  });

  @override
  State<HalamanTambahSoal> createState() => _HalamanTambahSoalState();
}

class _HalamanTambahSoalState extends State<HalamanTambahSoal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<CrosswordEntry> entries = [];
  List<List<GridEntry>> grids = [];
  bool isVertical = false;
  bool isAddingEntry = false;
  bool isLoading = false;
  int gridLength = 10;
  int? selectedX;
  int? selectedY;
  GridEntry defaultGridEntry = GridEntry(char: "", entryID: 0, isFilled: false);
  int randomID = 0;
  int generateEntryID() {
    return DateTime.now().millisecondsSinceEpoch % 100000 +
        Random().nextInt(9000) +
        1000;
  }

  @override
  void initState() {
    super.initState();
    randomID = generateEntryID();
    grids = List.generate(
      gridLength,
      (_) => List.filled(gridLength, defaultGridEntry, growable: true),
      growable: true,
    );
    if (widget.data.containsKey('soal')) {
      entries =
          (widget.data['soal'] as List<dynamic>).map<CrosswordEntry>((soal) {
            return CrosswordEntry(
              entryID: soal['entryID'],
              question: soal['pertanyaan'],
              answer: soal['jawaban'],
              x: soal['x'],
              y: soal['y'],
              isVertical: soal['menurun'],
            );
          }).toList();

      for (var entry in entries) {
        for (int i = 0; i < entry.answer.length; i++) {
          int startX = entry.isVertical ? entry.x : entry.x + i;
          int startY = entry.isVertical ? entry.y + i : entry.y;
          String char = entry.answer[i];
          GridEntry gridEntry = grids[startX][startY];
          if (gridEntry.isFilled &&
              gridEntry.entryID != entry.entryID &&
              gridEntry.char == char) {
            grids[startX][startY] = GridEntry(
              char: gridEntry.char,
              entryID: gridEntry.entryID,
              crossEntryID: entry.entryID,
              isFilled: true,
            );
          } else {
            grids[startX][startY] = GridEntry(
              char: char,
              entryID: entry.entryID,
              isFilled: true,
            );
          }
        }
      }
    }
  }

  Map<String, String> hurufBersilangan = {};

  String? getHuruf(int x, int y) {
    String key = "$x-$y";

    if (hurufBersilangan.containsKey(key)) {
      return hurufBersilangan[key];
    }

    return null;
  }

  void _toggleCell(int x, int y) {
    setState(() {
      isAddingEntry = true;
    });

    GridEntry currentGridEntry = grids[x][y];
    String ans = _answerController.text.replaceAll(" ", "").toUpperCase();
    int? selectedXBefore = selectedX;
    int? selectedYBefore = selectedY;
    int selisihGridX = gridLength - x - ans.length;
    int selisihGridY = gridLength - y - ans.length;

    if (_formKey.currentState!.validate()) {
      if (ans.length > gridLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Text(
              'Jumlah jawaban anda melebihi jumlah batas kotak. Maksimal karakter adalah $gridLength',
            ),
          ),
        );
        return;
      }

      if (isVertical == true && selisihGridY < 0 ||
          isVertical == false && selisihGridX < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Text(
              'Starting Point yang kamu pilih tidak mencukupi kotak (kurang ${isVertical ? selisihGridY : selisihGridX})',
            ),
          ),
        );
        return;
      }

      if (currentGridEntry.isFilled && currentGridEntry.char != ans[0]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Text(
              'Starting Point yang kamu pilih terdapat karakter yang tidak cocok',
            ),
          ),
        );
        return;
      }

      setState(() {
        selectedX = x;
        selectedY = y;
      });

      if (selectedXBefore != null && selectedYBefore != null) {
        for (var clearX = 0; clearX < gridLength; clearX++) {
          for (var clearY = 0; clearY < gridLength; clearY++) {
            GridEntry gridEntry = grids[clearX][clearY];

            if (gridEntry.isFilled && gridEntry.entryID == randomID) {
              setState(() {
                grids[clearX][clearY] = defaultGridEntry;
              });
            }
          }
        }
      }

      for (var i = 0; i < ans.length; i++) {
        int startX = isVertical ? x : x + i;
        int startY = isVertical ? y + i : y;
        String char = ans[i];
        GridEntry gridEntry = grids[startX][startY];

        if (gridEntry.isFilled &&
            gridEntry.entryID != randomID &&
            gridEntry.char != char) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red[700],
              content: Text(
                'Starting Point yang kamu pilih terdapat karakter yang tidak cocok',
              ),
            ),
          );
          return;
        }

        setState(() {
          if (gridEntry.isFilled &&
              gridEntry.entryID != randomID &&
              gridEntry.char == char) {
            grids[startX][startY] = GridEntry(
              char: gridEntry.char,
              entryID: gridEntry.entryID,
              crossEntryID: randomID,
              isFilled: true,
            );
          } else {
            grids[startX][startY] = GridEntry(
              char: char,
              entryID: randomID,
              isFilled: true,
            );
          }
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Mohon isi data form dahulu'),
        ),
      );
      return;
    }
  }

  void _addEntry() {
    if (_formKey.currentState!.validate()) {
      String ans = _answerController.text.replaceAll(" ", "").toUpperCase();

      if (entries.isNotEmpty && selectedX == null ||
          entries.isNotEmpty && selectedY == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a starting position on the grid'),
          ),
        );
        return;
      }

      List<CrosswordEntry> entryData = entries;

      entryData.add(
        CrosswordEntry(
          entryID: randomID,
          question: _questionController.text,
          answer: ans,
          x: selectedX ?? 0,
          y: selectedY ?? 0,
          isVertical: isVertical,
        ),
      );

      setState(() {
        entries = entryData;
        randomID = generateEntryID();
        isAddingEntry = false;

        _clearForm();
      });
    }
  }

  void _deleteEntry(int entryIDSelected) {
    // Cari index berdasarkan ID
    int indexEntrySelected = entries.indexWhere(
      (element) => element.entryID == entryIDSelected,
    );

    if (indexEntrySelected == -1) {
      // Kalau nggak ketemu, langsung return (biar nggak error)
      return;
    }

    // Ambil entry yang akan dihapus
    CrosswordEntry entry = entries[indexEntrySelected];

    setState(() {
      // Hapus entry dari daftar
      entries.removeAt(indexEntrySelected);

      // Loop untuk setiap huruf di entry yang dihapus
      for (int i = 0; i < entry.answer.length; i++) {
        int x = entry.isVertical ? entry.x : entry.x + i;
        int y = entry.isVertical ? entry.y + i : entry.y;

        GridEntry gridEntry = grids[x][y];
        int entryID = gridEntry.entryID;
        int? crossEntryID = gridEntry.crossEntryID;

        if (crossEntryID != null) {
          if (entryID == entryIDSelected) {
            grids[x][y] = GridEntry(
              char: gridEntry.char,
              entryID: crossEntryID,
              isFilled: true,
            );
          } else {
            grids[x][y] = GridEntry(
              char: gridEntry.char,
              entryID: entryID,
              isFilled: true,
            );
          }
        } else {
          grids[x][y] = defaultGridEntry;
        }
      }
    });
  }

  void _clearForm() {
    setState(() {
      _questionController.clear();
      _answerController.clear();
      selectedX = null;
      selectedY = null;
      isVertical = false;
    });
  }

  Future<void> handleUploadQuestions() async {
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Tidak ada yang di unggah, data soal masih kosong'),
        ),
      );
      return;
    }

    if (isAddingEntry) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Masih ada soal yang belum selesai di atur.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      DocumentReference<Map<String, dynamic>>? reference = widget.reference;

      Map<String, dynamic> data = {
        'name': widget.data['name'],
        'soal':
            entries
                .map(
                  (entry) => {
                    'entryID': entry.entryID,
                    'pertanyaan': entry.question,
                    'jawaban': entry.answer,
                    'menurun': entry.isVertical,
                    'x': entry.x,
                    'y': entry.y,
                  },
                )
                .toList(),
      };
      if (widget.isNewLevel == false && reference != null) {
        await reference.update(data);
        await NotificationService.showNotification(
          title: "Sukses",
          body: "Soal berhasil diperbarui!",
        );
      } else {
        await FirebaseFirestore.instance
            .collection('permainan')
            .doc(
              widget.data['name'].toString().toLowerCase().replaceAll(" ", "-"),
            )
            .set(data);
        await NotificationService.showNotification(
          title: "Sukses",
          body: "Level & Soal berhasil diunggah!",
        );
      }
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[700],
            content: Text('Berhasil Unggah Soal untuk ${widget.data['name']}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
      return;
    }
  }

  Future<void> handleDeleteLevel() async {
    final isDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Yakin ingin di hapus?",
            style: TextStyle(fontSize: 18),
          ),
          content: const Text("Level akan di hapus beserta soalnya."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak, Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );

    DocumentReference<Map<String, dynamic>>? reference = widget.reference;

    if (isDelete == true && reference != null) {
      reference.delete();
      await NotificationService.showNotification(
        title: "Sukses",
        body: "Level & Soal berhasil dihapus!",
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final FocusNode? focus = FocusManager.instance.primaryFocus;

        if (focus != null) {
          focus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            "Tambah Soal ${widget.data['name']} ${widget.isNewLevel == true ? '(Baru)' : ''}",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            if (widget.isNewLevel == false)
              IconButton(
                onPressed: handleDeleteLevel,
                icon: Icon(Icons.delete),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.upload),
          backgroundColor: Colors.blue,
          onPressed: handleUploadQuestions,
          label: Text("Unggah Soal", style: TextStyle(color: Colors.black)),
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (widget.isNewLevel == true)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          color: Colors.blue,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Level baru (${widget.data['name']}) akan tertambah setelah unggah soal",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      formSoal(context),
                      const SizedBox(height: 32),
                      const Text(
                        'Puzzle Grid',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      puzzleGrid(context),
                      if (entries.isNotEmpty) ...[
                        const Text(
                          'Current Entries',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: List.generate(entries.length, (index) {
                            final entry = entries[index];

                            return Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  title: Text(
                                    entry.question,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Entry ID: ${entry.entryID}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Answer: ${entry.answer}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Position: (X: ${entry.x}, Y: ${entry.y}) - ${entry.isVertical ? "Vertical" : "Horizontal"}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ElevatedButton(
                                        onPressed:
                                            () => _deleteEntry(entry.entryID),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade400,
                                        ),
                                        child: const Text(
                                          'Hapus',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }

  Widget puzzleGrid(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 32, top: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridLength,
          childAspectRatio: 1,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: gridLength * gridLength,
        itemBuilder: (context, i) {
          final x = i % gridLength;
          final y = i ~/ gridLength;
          GridEntry gridEntry = grids[x][y];

          return GestureDetector(
            onTap: () => _toggleCell(x, y),
            child: Container(
              decoration: BoxDecoration(
                color:
                    selectedX == x && selectedY == y
                        ? Colors.blue
                        : Colors.grey[900],
                border: Border.all(
                  color:
                      gridEntry.crossEntryID != null &&
                              gridEntry.crossEntryID != gridEntry.entryID
                          ? Colors.green[700]!
                          : Colors.grey[700]!,
                ),
              ),
              child: Center(
                child: Text(
                  gridEntry.isFilled ? gridEntry.char : "X: $x, Y: $y",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget formSoal(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Add New Clue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _questionController,
            style: TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Question',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a question';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _answerController,
            style: TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Answer',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an answer';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => isVertical = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isVertical ? Colors.blue : Colors.white,
                  ),
                  child: const Text('Horizontal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => isVertical = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVertical ? Colors.blue : Colors.white,
                  ),
                  child: const Text('Vertical'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addEntry,
            child: const Text('Tambah Soal'),
          ),
        ],
      ),
    );
  }
}

class CrosswordEntry {
  final int entryID;
  final String question;
  final String answer;
  final int x;
  final int y;
  final bool isVertical;

  CrosswordEntry({
    required this.entryID,
    required this.question,
    required this.answer,
    required this.x,
    required this.y,
    required this.isVertical,
  });
}

class GridEntry {
  final String char;
  final int entryID;
  int? crossEntryID;
  final bool isFilled;

  GridEntry({
    required this.char,
    required this.entryID,
    this.crossEntryID,
    required this.isFilled,
  });
}
