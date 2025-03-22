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

// Событие: выход пользователя
class Logout extends AuthEvent {}