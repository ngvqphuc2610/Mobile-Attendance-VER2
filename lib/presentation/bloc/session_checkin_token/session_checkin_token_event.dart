
import 'package:equatable/equatable.dart';

abstract class SessionCheckinTokenEvent extends Equatable {
  const SessionCheckinTokenEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessionCheckinTokens extends SessionCheckinTokenEvent {
  final String? sessionId;

  const LoadSessionCheckinTokens({this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class OpenSessionCheckinToken extends SessionCheckinTokenEvent {
  final String sessionId;
  final int durationSeconds;

  const OpenSessionCheckinToken({
    required this.sessionId,
    this.durationSeconds = 180,
  });

  @override
  List<Object> get props => [sessionId, durationSeconds];
}

class CloseSessionCheckinToken extends SessionCheckinTokenEvent {
  final String sessionId;

  const CloseSessionCheckinToken(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}

class ExtendSessionCheckinToken extends SessionCheckinTokenEvent {
  final String sessionId;
  final int addSeconds;

  const ExtendSessionCheckinToken({
    required this.sessionId,
    this.addSeconds = 120,
  });

  @override
  List<Object> get props => [sessionId, addSeconds];
}