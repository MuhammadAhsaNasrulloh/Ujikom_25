class Service {
  final String layanan;
  final int? durasi; // Bisa bernilai null
  final String? estimasi; // Bisa bernilai null
  final int? harga; // Tanggal priceService
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.layanan,
    this.durasi, // Bisa bernilai null
    this.estimasi, // Bisa bernilai null
    required this.harga,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromMap(Map<String, dynamic> data) {
    return Service(
      layanan: data['layanan'],
      durasi: data['durasi'],
      estimasi: data['estimasi'],
      harga: data['harga_layanan'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'layanan': layanan,
      'estimasi': estimasi,
      'durasi': durasi?.toString().split('.').last, // Mengembalikan nilai sebagai string
      'harga_layanan': harga,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}