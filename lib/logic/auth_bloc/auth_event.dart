import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Событие: загрузка пользователя
class LoadUser extends AuthEvent {}

// Событие: проверка входа
class CheckLoginStatus extends AuthEvent {}

// Событие: Регистрация
class RegisterUser extends AuthEvent {
  final String email;
  final String password;

  RegisterUser(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

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

class ForgotPassword extends AuthEvent {
  final String email;

  ForgotPassword(this.email);

  @override
  List<Object?> get props => [email];
}