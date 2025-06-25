enum Arah { mendatar, menurun }

class Soal {
  final String docID;
  final String pertanyaan;
  final String jawaban;
  final Arah arah; // tambah arah
  final int x; // posisi horizontal awal di grid
  final int y; // posisi vertikal awal di grid

  Soal({
    required this.docID,
    required this.pertanyaan,
    required this.jawaban,
    required this.arah,
    required this.x,
    required this.y,
  });

  factory Soal.fromMap(Map<String, dynamic> data) {
    return Soal(
      docID: data['docID'],
      pertanyaan: data['pertanyaan'],
      jawaban: data['jawaban'],
      arah: data['menurun'] ? Arah.menurun : Arah.mendatar,
      x: data['x'],
      y: data['y'],
    );
  }
}
