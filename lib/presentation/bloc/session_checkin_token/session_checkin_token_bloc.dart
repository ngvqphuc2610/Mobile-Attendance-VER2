import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/session_checkin_token_repository.dart';
import 'session_checkin_token_event.dart';
import 'session_checkin_token_state.dart';

class SessionCheckinTokenBloc
    extends Bloc<SessionCheckinTokenEvent, SessionCheckinTokenState> {
  final SessionCheckinTokenRepository _repository;

  SessionCheckinTokenBloc({required SessionCheckinTokenRepository repository})
      : _repository = repository,
        super(SessionCheckinTokenInitial()) {
    on<LoadSessionCheckinTokens>(_onLoadSessionCheckinTokens);
    on<OpenSessionCheckinToken>(_onOpenSessionCheckinToken);
    on<CloseSessionCheckinToken>(_onCloseSessionCheckinToken);
    on<ExtendSessionCheckinToken>(_onExtendSessionCheckinToken);
  }

  Future<void> _onLoadSessionCheckinTokens(
    LoadSessionCheckinTokens event,
    Emitter<SessionCheckinTokenState> emit,
  ) async {
    emit(SessionCheckinTokenLoading());
    try {
      final tokens =
          await _repository.getSessionCheckinTokens(sessionId: event.sessionId);
      emit(SessionCheckinTokensLoaded(tokens));
    } catch (e) {
      emit(SessionCheckinTokenError(e.toString()));
    }
  }

  Future<void> _onOpenSessionCheckinToken(
    OpenSessionCheckinToken event,
    Emitter<SessionCheckinTokenState> emit,
  ) async {
    emit(SessionCheckinTokenLoading());
    try {
      final token = await _repository.openSessionCheckinToken(
        sessionId: event.sessionId,
        durationSeconds: event.durationSeconds,
      );
      // 1) Cho UI hiện ngay QR/PIN
      emit(SessionCheckinTokenOpened(token));
      // 2) (tuỳ) load list token để panel bên cạnh cập nhật
      add(LoadSessionCheckinTokens(sessionId: event.sessionId));
    } catch (e) {
      emit(SessionCheckinTokenError(e.toString()));
    }
  }

  Future<void> _onCloseSessionCheckinToken(
    CloseSessionCheckinToken event,
    Emitter<SessionCheckinTokenState> emit,
  ) async {
    emit(SessionCheckinTokenLoading());
    try {
      await _repository.closeSessionCheckinToken(sessionId: event.sessionId);
      emit(const SessionCheckinTokenOperationSuccess('Đóng check-in thành công'));
      add(LoadSessionCheckinTokens(sessionId: event.sessionId));
    } catch (e) {
      emit(SessionCheckinTokenError(e.toString()));
    }
  }

  Future<void> _onExtendSessionCheckinToken(
    ExtendSessionCheckinToken event,
    Emitter<SessionCheckinTokenState> emit,
  ) async {
    emit(SessionCheckinTokenLoading());
    try {
      await _repository.extendSessionCheckinToken(
        sessionId: event.sessionId,
        addSeconds: event.addSeconds,
      );
      emit(const SessionCheckinTokenOperationSuccess('Gia hạn check-in thành công'));
      add(LoadSessionCheckinTokens(sessionId: event.sessionId));
    } catch (e) {
      emit(SessionCheckinTokenError(e.toString()));
    }
  }
}
