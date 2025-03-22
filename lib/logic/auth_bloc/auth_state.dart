import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Начальное состояние (ничего не загружено)
class AuthInitial extends AuthState {}

// Состояние: пользователь загружен
class AuthLoaded extends AuthState {
  final UserModel user;

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