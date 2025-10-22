import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/core/di/dependency_injection.dart';
import 'package:mobile_attendance/data/models/entity/session_checkin_token.dart';
import 'package:mobile_attendance/presentation/bloc/session_checkin_token/session_checkin_token_bloc.dart';
import 'package:mobile_attendance/presentation/bloc/session_checkin_token/session_checkin_token_event.dart';
import 'package:mobile_attendance/presentation/bloc/session_checkin_token/session_checkin_token_state.dart';
import 'package:mobile_attendance/presentation/widgets/loading_widget.dart';

import 'SessionStudentsPanel.dart';

class TeacherSessionDetailPage extends StatelessWidget {
  final String sessionId;
  final String sectionId;
  final String? sectionCode;
  final String? subjectName;
  final String? roomName;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const TeacherSessionDetailPage({
    super.key,
    required this.sessionId,
    required this.sectionId,
    this.sectionCode,
    this.subjectName,
    this.roomName,
    this.startsAt,
    this.endsAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName ?? 'Session detail'),
        backgroundColor: AppTheme.adminPrimaryColor,
      ),
      body: BlocProvider<SessionCheckinTokenBloc>(
        create: (_) =>
            sl<SessionCheckinTokenBloc>()
              ..add(LoadSessionCheckinTokens(sessionId: sessionId)),
        child: _TeacherSessionDetailBody(
          sessionId: sessionId,
          sectionId: sectionId,
          sectionCode: sectionCode,
          subjectName: subjectName,
          roomName: roomName,
          startsAt: startsAt,
          endsAt: endsAt,
        ),
      ),
      floatingActionButton: _FabActions(sessionId: sessionId),
    );
  }
}

class _TeacherSessionDetailBody extends StatelessWidget {
  final String sessionId;
  final String sectionId;
  final String? sectionCode;
  final String? subjectName;
  final String? roomName;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const _TeacherSessionDetailBody({
    required this.sessionId,
    required this.sectionId,
    this.sectionCode,
    this.subjectName,
    this.roomName,
    this.startsAt,
    this.endsAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SessionInfoHeader(
          sectionCode: sectionCode,
          subjectName: subjectName,
          roomName: roomName,
          startsAt: startsAt,
          endsAt: endsAt,
        ),
        const SizedBox(height: 12),
        BlocConsumer<SessionCheckinTokenBloc, SessionCheckinTokenState>(
          listener: (context, state) {
            if (state is SessionCheckinTokenOperationSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is SessionCheckinTokenError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SessionCheckinTokenLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _TokenCard(
                  child: SizedBox(
                    height: 160,
                    child: Center(child: LoadingWidget()),
                  ),
                ),
              );
            }

            if (state is SessionCheckinTokenError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TokenCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 36,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<SessionCheckinTokenBloc>().add(
                              LoadSessionCheckinTokens(sessionId: sessionId),
                            ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is SessionCheckinTokenOpened) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TokenCard(child: _ActiveTokenPanel(token: state.token)),
              );
            }

            if (state is SessionCheckinTokensLoaded) {
              final active = state.tokens.where((e) => e.isActive).toList();
              if (active.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TokenCard(
                    child: _ActiveTokenPanel(token: active.first),
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _TokenCard(child: _EmptyState()),
              );
            }

            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TokenCard(child: _EmptyState()),
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(child: SessionStudentsPanel(sessionId: sessionId)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.qr_code_2, size: 56, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Tap Open to generate QR and PIN for this session.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ActiveTokenPanel extends StatefulWidget {
  final SessionCheckinToken token;
  const _ActiveTokenPanel({required this.token});

  @override
  State<_ActiveTokenPanel> createState() => _ActiveTokenPanelState();
}

class _ActiveTokenPanelState extends State<_ActiveTokenPanel> {
  late Duration _remain;

  @override
  void initState() {
    super.initState();
    _remain = _safeRemain(widget.token.expiresAt);
    _ticker.start();
  }

  Duration _safeRemain(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  late final Ticker _ticker = Ticker((_) {
    final remain = _safeRemain(widget.token.expiresAt);
    if (!mounted) return;
    setState(() => _remain = remain);
    if (remain == Duration.zero) {
      _ticker.stop();
    }
  });

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payload = jsonEncode({
      'session_id': widget.token.sessionId,
      'token_id': widget.token.id,
      'nonce': widget.token.nonce,
      'version': 1,
    });

    return Column(
      children: [
        Text('PIN CODE', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        SelectableText(
          widget.token.pin4,
          style: const TextStyle(
            fontSize: 40,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        QrImageView(data: payload, size: 220, backgroundColor: Colors.white),
        const SizedBox(height: 16),
        Text(
          'Time left: ${_formatRemain(_remain)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Expires at ${_formatDate(widget.token.expiresAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }

  String _formatRemain(Duration value) {
    final mm = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = '${_two(local.day)}/${_two(local.month)}/${local.year}';
    final time = '${_two(local.hour)}:${_two(local.minute)}';
    return '$day $time';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _FabActions extends StatelessWidget {
  final String sessionId;
  const _FabActions({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      spacing: 10,
      children: [
        FloatingActionButton.extended(
          heroTag: 'open',
          onPressed: () {
            context.read<SessionCheckinTokenBloc>().add(
              OpenSessionCheckinToken(
                sessionId: sessionId,
                durationSeconds: 180,
              ),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Open'),
        ),
        FloatingActionButton.extended(
          heroTag: 'extend',
          onPressed: () {
            context.read<SessionCheckinTokenBloc>().add(
              ExtendSessionCheckinToken(sessionId: sessionId, addSeconds: 120),
            );
          },
          icon: const Icon(Icons.more_time),
          label: const Text('Extend'),
          backgroundColor: Colors.orange,
        ),
        FloatingActionButton.extended(
          heroTag: 'close',
          onPressed: () {
            context.read<SessionCheckinTokenBloc>().add(
              CloseSessionCheckinToken(sessionId),
            );
          },
          icon: const Icon(Icons.stop),
          label: const Text('Close'),
          backgroundColor: Colors.red,
        ),
      ],
    );
  }
}

class _SessionInfoHeader extends StatelessWidget {
  final String? sectionCode;
  final String? subjectName;
  final String? roomName;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const _SessionInfoHeader({
    required this.sectionCode,
    required this.subjectName,
    required this.roomName,
    required this.startsAt,
    required this.endsAt,
  });

  @override
  Widget build(BuildContext context) {
    final timeRange = _formatRange(startsAt, endsAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectName ?? 'Session',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (sectionCode != null && sectionCode!.isNotEmpty)
                'Section $sectionCode',
              if (roomName != null && roomName!.isNotEmpty) 'Room ${roomName!}',
            ].join(' • '),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          if (timeRange.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  timeRange,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final localStart = start.toLocal();
    final day =
        '${_two(localStart.day)}/${_two(localStart.month)}/${localStart.year}';
    final startTime = '${_two(localStart.hour)}:${_two(localStart.minute)}';
    if (end == null) {
      return '$day $startTime';
    }
    final localEnd = end.toLocal();
    final endTime = '${_two(localEnd.hour)}:${_two(localEnd.minute)}';
    return '$day $startTime - $endTime';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _TokenCard extends StatelessWidget {
  final Widget child;
  const _TokenCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
