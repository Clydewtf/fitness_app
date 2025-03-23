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
    on<LogoutUser>(_onLogoutUser);
    on<CheckLoginStatus>(_onCheckLoginStatus);
    on<LoginUser>(_onLoginUser);
    on<ResetAuthState>((event, emit) {
      emit(AuthInitial());
    });
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
  Future<void> _onLogoutUser(LogoutUser event, Emitter<AuthState> emit) async {
    await userRepository.clearUser();
    emit(Unauthenticated());
  }

  // Проверка, вошел ли пользователь
  Future<void> _onCheckLoginStatus(CheckLoginStatus event, Emitter<AuthState> emit) async {
    final isLoggedIn = await userRepository.isLoggedIn();
    final user = await userRepository.loadUser();

    if (isLoggedIn && user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  // Вход пользователя
  Future<void> _onLoginUser(LoginUser event, Emitter<AuthState> emit) async {
    final success = await userRepository.login(event.email, event.password);
    if (success) {
      final user = await userRepository.loadUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthFailure("Ошибка загрузки пользователя"));
      }
    } else {
      emit(AuthFailure("Неверный email или пароль"));
    }
  }
}