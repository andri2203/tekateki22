class Level {
  final String docID;
  final String name;

  Level(this.docID, {required this.name});

  factory Level.fromMap(Map<String, dynamic> level) {
    return Level(level['docID'], name: level['name']);
  }
}
