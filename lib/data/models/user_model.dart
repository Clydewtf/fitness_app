class UserModel {
  final String id;
  final String email;
  final String password; // Для локальной авторизации

  final String? name;
  final int? age;
  final double? weight;
  final double? height;
  final String? goal; // "mass", "cut", "strength"

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    this.name,
    this.age,
    this.weight,
    this.height,
    this.goal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      name: json['name'],
      age: json['age'],
      weight: (json['weight'] != null) ? json['weight'].toDouble() : null,
      height: (json['height'] != null) ? json['height'].toDouble() : null,
      goal: json['goal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
    };
  }
}