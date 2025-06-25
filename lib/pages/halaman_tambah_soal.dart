import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/styles.dart';

class HalamanTambahSoal extends StatefulWidget {
  final String? docID;
  const HalamanTambahSoal({super.key, this.docID});

  @override
  State<HalamanTambahSoal> createState() => _HalamanTambahSoalState();
}

class _HalamanTambahSoalState extends State<HalamanTambahSoal> {
  final soalRef = FirebaseFirestore.instance.collection('permainan');
  final TextEditingController pertanyaan = TextEditingController();
  final TextEditingController jawaban = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final int gridCount = 10;
  List<List<String?>> grid = [];

  List<Map<String, dynamic>> soal = <Map<String, dynamic>>[];

  InputDecoration inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color.from(
        alpha: 1,
        red: 0.039,
        green: 0.055,
        blue: 0.5,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void handleTambahSoal() {
    if (pertanyaan.text.isNotEmpty && jawaban.text.isNotEmpty) {
      soal.add({
        'pertanyaan': pertanyaan.text.trim(),
        'jawaban': jawaban.text.trim().toUpperCase().replaceAll(" ", ""),
        'menurun': false,
        'x': 0,
        'y': 0,
      });
      pertanyaan.clear();
      jawaban.clear();

      int startX = (gridCount - soal.length) ~/ 2;
      int startY = gridCount ~/ 2;

      for (var i = 0; i < soal.length; i++) {}

      setState(() {});
    }
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
          title: Text("Tambah Soal", style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: pertanyaan,
                  style: TextStyle(color: Colors.white),
                  decoration: inputDecoration(hintText: "Pertanyaan"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jawaban,
                  style: TextStyle(color: Colors.white),
                  decoration: inputDecoration(hintText: "Jawaban"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: handleTambahSoal,
                  style: buttonStyle,
                  child: Text(
                    "Tambah Soal",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 12),
                  child: Divider(color: Colors.white38),
                ),
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
                    int x = index % gridCount;
                    int y = index ~/ gridCount;

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.black,
                      ),
                      child: Center(child: Text("")),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 12),
                  child: Divider(color: Colors.white38),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: buttonStyle,
                  child: Text(
                    "Input Soal",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
