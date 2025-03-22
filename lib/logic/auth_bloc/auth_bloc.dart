import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository userRepository;

  AuthBloc(this.userRepository) : super(AuthInitial()) {
    on<LoadUser>(_onLoadUser);
    on<SaveUser>(_onSaveUser);
    on<Logout>(_onLogout);
  }

  // Загрузка пользователя
  Future<void> _onLoadUser(LoadUser event, Emitter<AuthState> emit) async {
    try {
      final user = await userRepository.loadUser();
      if (user != null) {
        emit(AuthLoaded(user));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthError("Ошибка загрузки данных"));
    }
  }

  // Сохранение пользователя
  Future<void> _onSaveUser(SaveUser event, Emitter<AuthState> emit) async {
    try {
      await userRepository.saveUser(event.user);
      emit(AuthLoaded(event.user));
    } catch (e) {
      emit(AuthError("Ошибка сохранения данных"));
    }
  }

  // Выход пользователя
  Future<void> _onLogout(Logout event, Emitter<AuthState> emit) async {
    await userRepository.clearUser();
    emit(AuthInitial());
  }
}