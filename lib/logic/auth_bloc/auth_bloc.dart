import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    // on<LoadUser>(_onLoadUser);
    // on<SaveUser>(_onSaveUser);
    on<LogoutUser>(_onLogoutUser);
    on<CheckLoginStatus>(_onCheckLoginStatus);
    on<LoginUser>(_onLoginUser);
    on<RegisterUser>(_onRegisterUser);
    on<ResetAuthState>((event, emit) {
      emit(AuthInitial());
    });
    on<ForgotPassword>(_onForgotPassword);
  }

  // Выход пользователя
  Future<void> _onLogoutUser(LogoutUser event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    emit(Unauthenticated());
  }

  // Проверка, вошел ли пользователь
  Future<void> _onCheckLoginStatus(CheckLoginStatus event, Emitter<AuthState> emit) async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onRegisterUser(RegisterUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      User? user = await _authService.registerWithEmailPassword(event.email, event.password);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError("Ошибка регистрации"));
      }
    } catch (e) {
      emit(AuthError("Ошибка: $e"));
    }
  }

  // Вход пользователя
  Future<void> _onLoginUser(LoginUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      User? user = await _authService.signInWithEmailPassword(event.email, event.password);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError("Ошибка входа"));
      }
    } catch (e) {
      emit(AuthError("Ошибка: $e"));
    }
  }

  Future<void> _onForgotPassword(ForgotPassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.sendPasswordResetEmail(event.email);
      emit(AuthInitial()); // или можешь сделать отдельное состояние типа PasswordResetSent()
    } catch (e) {
      emit(AuthFailure("Ошибка сброса пароля"));
    }
  }
}