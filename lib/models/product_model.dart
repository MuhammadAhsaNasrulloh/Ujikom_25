class Product {
  final String produk;
  final int unitId; // Foreign key to unit(id)
  final int categoryId;
  final String? fotoProduk; // Nullable karena foto_produk bersifat opsional
  final double harga;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.produk,
    required this.unitId,
    required this.categoryId,
    this.fotoProduk,
    required this.harga,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method untuk membuat objek dari JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      categoryId: json['kategori_id'],
      produk: json['produk'],
      fotoProduk: json['foto_produk'], // Bisa null
      harga: json['harga'],
      unitId: json['unit_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Method untuk mengonversi objek ke JSON
  Map<String, dynamic> toJson() {
    return {
      'kategori_id': categoryId,
      'produk': produk,
      'foto_produk': fotoProduk, // Bisa null
      'harga': harga,
      'unit_id': unitId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
