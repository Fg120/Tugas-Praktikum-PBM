class UserModel {
  final String token;
  final String name;
  final String nim;

  const UserModel({required this.token, required this.name, required this.nim});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final user = data['user'] as Map<String, dynamic>? ?? {};

    return UserModel(
      token: data['token'] as String? ?? json['token'] as String? ?? '',
      name: user['name'] as String? ?? '',
      nim: user['username'] as String? ?? user['nim'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'name': name, 'nim': nim};
  }

  @override
  String toString() => 'UserModel(name: $name, nim: $nim)';
}
