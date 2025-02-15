class Unit {
  final int id;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  Unit({
    required this.id,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Unit.fromMap(Map<String, dynamic> data) {
    return Unit(
      id: data['id'],
      unit: data['unit'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}