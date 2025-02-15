class Kategori {
  final int id;
  final String kategori;
  final DateTime createdAt;
  final DateTime updatedAt;

  Kategori({
    required this.id,
    required this.kategori,
    required this.createdAt,
    required this.updatedAt,
  });

  // Membuat objek Kategori dari Map
  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'],
      kategori: map['kategori'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Mengubah objek Kategori menjadi Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kategori': kategori,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
