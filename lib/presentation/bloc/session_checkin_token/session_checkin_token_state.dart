import 'package:equatable/equatable.dart';
import '../../../data/models/entity/session_checkin_token.dart';

abstract class SessionCheckinTokenState extends Equatable {
  const SessionCheckinTokenState();
  @override
  List<Object?> get props => [];
}

class SessionCheckinTokenInitial extends SessionCheckinTokenState {}

class SessionCheckinTokenLoading extends SessionCheckinTokenState {}

class SessionCheckinTokensLoaded extends SessionCheckinTokenState {
  final List<SessionCheckinToken> tokens;
  const SessionCheckinTokensLoaded(this.tokens);
  @override
  List<Object?> get props => [tokens];
}

/// Dùng cho thông điệp ngắn (đóng/gia hạn…)
class SessionCheckinTokenOperationSuccess extends SessionCheckinTokenState {
  final String message;
  const SessionCheckinTokenOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// Dùng ngay sau khi MỞ check-in để UI hiển thị QR/PIN
class SessionCheckinTokenOpened extends SessionCheckinTokenState {
  final SessionCheckinToken token;
  const SessionCheckinTokenOpened(this.token);
  @override
  List<Object?> get props => [token];
}

class SessionCheckinTokenError extends SessionCheckinTokenState {
  final String message;
  const SessionCheckinTokenError(this.message);
  @override
  List<Object?> get props => [message];
}
