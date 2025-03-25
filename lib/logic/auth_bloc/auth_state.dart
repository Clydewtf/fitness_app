import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Начальное состояние (ничего не загружено)
class AuthInitial extends AuthState {}

// Состояние загрузки (при входе, регистрации)
class AuthLoading extends AuthState {}

// Состояние: пользователь загружен
class AuthLoaded extends AuthState {
  final User user;

  AuthLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

// Состояние: ошибка (например, при загрузке данных)
class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Пользователь вошел
class Authenticated extends AuthState {
  final User user;

  Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

// Пользователь не вошел
class Unauthenticated extends AuthState {}

// Ошибка входа
class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}