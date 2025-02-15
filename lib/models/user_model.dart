class UserModel {
  final String id;
  final String name;
  final String role;
  final String fotoProfile;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.fotoProfile,
    required this.isActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'],
      name: data['name'],
      role: data['role'],
      fotoProfile: data['foto_profile'],
      isActive: data['is_active'],
    );
  }
}
