import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Событие: загрузка пользователя
class LoadUser extends AuthEvent {}

// Событие: сохранение данных пользователя
class SaveUser extends AuthEvent {
  final UserModel user;

  SaveUser(this.user);

  @override
  List<Object?> get props => [user];
}

// Событие: проверка входа
class CheckLoginStatus extends AuthEvent {}

// Событие: вход пользователя
class LoginUser extends AuthEvent {
  final String email;
  final String password;

  LoginUser(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

// Событие: выход пользователя
class LogoutUser extends AuthEvent {}

// Сброс ошибки после отображения
class ResetAuthState extends AuthEvent {}