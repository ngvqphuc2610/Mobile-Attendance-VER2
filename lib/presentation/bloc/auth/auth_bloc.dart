import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/dto/register_otp_result.dart';
import '../../../data/models/dto/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String? totp;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.totp,
  });

  @override
  List<Object?> get props => [email, password, totp];
}

class AuthRegisterOtpRequested extends AuthEvent {
  final RegisterRequestData data;

  const AuthRegisterOtpRequested({required this.data});

  @override
  List<Object?> get props => [data];
}

class AuthRegisterOtpSubmitted extends AuthEvent {
  final String transactionId;
  final String otp;

  const AuthRegisterOtpSubmitted({
    required this.transactionId,
    required this.otp,
  });

  @override
  List<Object?> get props => [transactionId, otp];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthRefreshRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final UserModel user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthRegisterOtpSent extends AuthState {
  final RegisterOtpResult result;

  const AuthRegisterOtpSent(this.result);

  @override
  List<Object?> get props => [result];
}

class AuthLoginTotpRequired extends AuthState {
  final String email;
  final String password;
  final String message;

  const AuthLoginTotpRequired({
    required this.email,
    required this.password,
    required this.message,
  });

  @override
  List<Object?> get props => [email, password, message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterOtpRequested>(_onRegisterOtpRequested);
    on<AuthRegisterOtpSubmitted>(_onRegisterOtpSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthRefreshRequested>(_onRefreshRequested);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.login(
        event.email,
        event.password,
        totp: event.totp,
      );
      emit(AuthAuthenticated(user: user));
    } on NeedTotpException catch (e) {
      emit(
        AuthLoginTotpRequired(
          email: event.email,
          password: event.password,
          message: e.message,
        ),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterOtpRequested(
    AuthRegisterOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await _authRepository.requestRegisterOtp(data: event.data);
      emit(AuthRegisterOtpSent(result));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterOtpSubmitted(
    AuthRegisterOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.verifyRegisterOtp(
        transactionId: event.transactionId,
        otp: event.otp,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.refreshCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  void _onUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(AuthAuthenticated(user: event.user));
    }
  }
}
