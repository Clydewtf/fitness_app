class UserModel {
  final String id;
  final String name;
  final String email;
  final String password; // Для локальной авторизации
  final int age;
  final double weight;
  final double height;
  final String goal; // "mass", "cut", "strength"

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      age: json['age'],
      weight: json['weight'].toDouble(),
      height: json['height'].toDouble(),
      goal: json['goal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
    };
  }
}