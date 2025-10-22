import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/core/di/dependency_injection.dart';
import 'package:mobile_attendance/core/helpers/location_helper.dart';
import 'package:mobile_attendance/presentation/widgets/loading_widget.dart';
import 'package:mobile_attendance/data/models/entity/attendance_entity.dart';

import '../../bloc/enrollment/enrollment_bloc.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../../bloc/attendance/attendance_event.dart';
import '../../bloc/attendance/attendance_state.dart';
import '../../bloc/auth/auth_bloc.dart';

import '../../bloc/session_checkin_token/session_checkin_token_bloc.dart';
import '../../bloc/session_checkin_token/session_checkin_token_event.dart';
import '../../bloc/session_checkin_token/session_checkin_token_state.dart';

import 'SessionStudentsPanel.dart';
import 'TeacherQrDisplayPage.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionCheckinTokenBloc>(
          create: (_) =>
              sl<SessionCheckinTokenBloc>()
                ..add(LoadSessionCheckinTokens(sessionId: sessionId)),
        ),
        BlocProvider<EnrollmentBloc>(create: (_) => sl<EnrollmentBloc>()),
        BlocProvider<AttendanceBloc>(create: (_) => sl<AttendanceBloc>()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(subjectName ?? 'Session detail'),
          backgroundColor: AppTheme.adminPrimaryColor,
        ),
        body: _TeacherSessionDetailBody(
          sessionId: sessionId,
          sectionId: sectionId,
          sectionCode: sectionCode,
          subjectName: subjectName,
          roomName: roomName,
          startsAt: startsAt,
          endsAt: endsAt,
        ),
        floatingActionButton: _FabActions(sessionId: sessionId),
      ),
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
    final teacherProfileId = context.select<AuthBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is AuthAuthenticated) {
        return state.user.id;
      }
      return null;
    });

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
        if (teacherProfileId != null) ...[
          _TeacherSelfAttendanceCard(
            teacherProfileId: teacherProfileId,
            sessionId: sessionId,
            sectionId: sectionId,
          ),
          const SizedBox(height: 12),
        ],

        /// Hiển thị trạng thái token + điều hướng khi mở token thành công
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

            // ✅ Khi Open thành công → chuyển sang trang QR
            if (state is SessionCheckinTokenOpened) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeacherQrDisplayPage(token: state.token),
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

            // Nếu có token active (trở lại trang khi token còn hiệu lực) → cho nút mở trang QR
            if (state is SessionCheckinTokensLoaded) {
              final active = state.tokens.where((e) => e.isActive).toList();
              if (active.isNotEmpty) {
                final token = active.first;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TokenCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_2, size: 40),
                        const SizedBox(height: 8),
                        const Text('A QR token is active for this session.'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TeacherQrDisplayPage(token: token),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open QR'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            // Mặc định: chưa có token
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TokenCard(child: _EmptyState()),
            );
          },
        ),

        const SizedBox(height: 16),

        // Danh sách sinh viên + trạng thái điểm danh
        Expanded(
          child: SessionStudentsPanel(
            sessionId: sessionId,
            sectionId: sectionId,
          ),
        ),
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
              //cho giới hạn 3p
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

class _TeacherSelfAttendanceCard extends StatefulWidget {
  final String teacherProfileId;
  final String sessionId;
  final String sectionId;

  const _TeacherSelfAttendanceCard({
    required this.teacherProfileId,
    required this.sessionId,
    required this.sectionId,
  });

  @override
  State<_TeacherSelfAttendanceCard> createState() =>
      _TeacherSelfAttendanceCardState();
}

class _TeacherSelfAttendanceCardState
    extends State<_TeacherSelfAttendanceCard> {
  AttendanceEntity? _lastRecord;
  bool _submitInProgress = false;

  AttendanceEntity? _findRecord(List<AttendanceEntity> items) {
    for (final entry in items) {
      if (entry.userId == widget.teacherProfileId) {
        return entry;
      }
    }
    return null;
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = '${_two(local.day)}/${_two(local.month)}/${local.year}';
    final time = '${_two(local.hour)}:${_two(local.minute)}';
    return '$time $day';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  Future<void> _handleCheckIn(BuildContext context) async {
    setState(() => _submitInProgress = true);
    try {
      final location = await LocationHelper.getCurrentLocation();
      context.read<AttendanceBloc>().add(
        CreateAttendance(
          userId: widget.teacherProfileId,
          method: AttendanceMethod.manual,
          sectionId: widget.sectionId,
          sessionId: widget.sessionId,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracyMeters: location.accuracyMeters,
          address: location.address,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to access current location. Please try again.'),
        ),
      );
      setState(() => _submitInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) =>
          current is AttendanceOperationSuccess || current is AttendanceError,
      listener: (_, __) {
        if (!_submitInProgress || !mounted) return;
        setState(() => _submitInProgress = false);
      },
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        buildWhen: (previous, current) =>
            current is AttendanceLoading ||
            current is AttendancesLoaded ||
            current is AttendanceInitial,
        builder: (context, state) {
          if (state is AttendancesLoaded) {
            _lastRecord = _findRecord(state.attendances);
          } else if (state is AttendanceInitial) {
            _lastRecord = null;
          }

          final loading = state is AttendanceLoading && _lastRecord == null;
          final checkedIn = _lastRecord != null;
          final theme = Theme.of(context);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Điểm danh giảng viên',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (loading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          checkedIn ? Icons.verified_user : Icons.schedule,
                          color: checkedIn ? Colors.green : Colors.orangeAccent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checkedIn
                        ? 'Đã điểm danh lúc ${_formatDateTime(_lastRecord!.atTime)}'
                        : 'Chưa điểm danh buổi này.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (checkedIn &&
                      (_lastRecord?.address?.isNotEmpty == true)) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Địa điểm: ${_lastRecord!.address}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: checkedIn || _submitInProgress
                        ? null
                        : () => _handleCheckIn(context),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(checkedIn ? 'Đã điểm danh' : 'Điểm danh ngay'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
            ].join(' | '),
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
