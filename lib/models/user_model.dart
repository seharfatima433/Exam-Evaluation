class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // 'teacher' | 'student'
  final String? rollNo;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.rollNo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return UserModel(
      id: _parseInt(user['id']),
      name: user['name'] ?? user['full_name'] ?? 'User',
      email: user['email'] ?? '',
      role: json['role'] ?? user['role'] ?? '',
      rollNo: user['rollno']?.toString(),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
