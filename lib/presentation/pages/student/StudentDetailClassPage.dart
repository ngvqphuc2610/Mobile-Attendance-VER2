import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/attendance_entity.dart';
import '../../../data/models/entity/class_section_entity.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../../bloc/attendance/attendance_event.dart';
import '../../bloc/attendance/attendance_state.dart';
import '../../bloc/class_section/class_section_bloc.dart';
import '../../bloc/class_section/class_section_event.dart';
import '../../bloc/class_section/class_section_state.dart';
import '../../bloc/session_instance/session_instance_bloc.dart';
import '../../bloc/session_instance/session_instance_event.dart';
import '../../bloc/session_instance/session_instance_state.dart';
import 'StudentDetailCheckinPage.dart';

class StudentDetailClassPage extends StatelessWidget {
  final String classSectionId;
  final String studentId;

  const StudentDetailClassPage({
    super.key,
    required this.classSectionId,
    required this.studentId,
  });

  void _refreshAll(BuildContext context) {
    context.read<ClassSectionBloc>().add(const LoadClassSections());
    context
        .read<SessionInstanceBloc>()
        .add(LoadSessionInstances(sectionId: classSectionId));
    context.read<AttendanceBloc>().add(
          LoadAttendances(
            userId: studentId,
            sectionId: classSectionId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết lớp học phần'),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: () => _refreshAll(context),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Thông báo'),
              Tab(text: 'Điểm danh'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SectionInfoTab(sectionId: classSectionId),
            _AttendanceTab(
              sectionId: classSectionId,
              studentId: studentId,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionInfoTab extends StatelessWidget {
  final String sectionId;

  const _SectionInfoTab({required this.sectionId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassSectionBloc, ClassSectionState>(
      builder: (context, state) {
        if (state is ClassSectionLoading || state is ClassSectionInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ClassSectionError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<ClassSectionBloc>().add(const LoadClassSections()),
          );
        }

        if (state is ClassSectionsLoaded) {
          final section = state.sections.firstWhere(
            (item) => item.id == sectionId,
            orElse: () => const ClassSectionEntity(
              id: '',
              subjectId: '',
              semester: 0,
              year: 0,
              sectionCode: '',
            ),
          );

          if (section.id.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy lớp học phần này.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _SectionSummaryCard(section: section),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin khác',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Mã môn',
                        value: section.subject?.code ?? 'Đang cập nhật',
                      ),
                      _InfoRow(
                        label: 'Tín chỉ',
                        value: section.subject?.credits?.toString() ??
                            'Đang cập nhật',
                      ),
                      _InfoRow(
                        label: 'Năm học',
                        value:
                            section.year != null ? '${section.year}' : 'Chưa rõ',
                      ),
                      _InfoRow(
                        label: 'Học kỳ',
                        value: section.semester != null
                            ? 'HK ${section.semester}'
                            : 'Chưa rõ',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final String sectionId;
  final String studentId;

  const _AttendanceTab({
    required this.sectionId,
    required this.studentId,
  });

  Future<void> _refresh(BuildContext context) async {
    context
        .read<SessionInstanceBloc>()
        .add(LoadSessionInstances(sectionId: sectionId));
    context.read<AttendanceBloc>().add(
          LoadAttendances(
            userId: studentId,
            sectionId: sectionId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionInstanceBloc, SessionInstanceState>(
      builder: (context, sessionState) {
        if (sessionState is SessionInstanceLoading ||
            sessionState is SessionInstanceInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (sessionState is SessionInstanceError) {
          return _ErrorView(
            message: sessionState.message,
            onRetry: () => _refresh(context),
          );
        }

        if (sessionState is! SessionInstancesLoaded) {
          return const SizedBox.shrink();
        }

        final sessions = sessionState.instances
            .where((item) =>
                (item['section_id']?.toString() ?? '') == sectionId)
            .toList(growable: false);

        if (sessions.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: const [
                _EmptyHint(message: 'Chưa có buổi học nào được tạo.'),
              ],
            ),
          );
        }

        sessions.sort((a, b) {
          final aStart = _parseDate(a['starts_at']);
          final bStart = _parseDate(b['starts_at']);
          if (aStart == null && bStart == null) return 0;
          if (aStart == null) return 1;
          if (bStart == null) return -1;
          return aStart.compareTo(bStart);
        });

        return BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, attendanceState) {
            if (attendanceState is AttendanceError) {
              return _ErrorView(
                message: attendanceState.message,
                onRetry: () => _refresh(context),
              );
            }

            final attendances = attendanceState is AttendancesLoaded
                ? attendanceState.attendances
                : <AttendanceEntity>[];

            if (attendanceState is AttendanceLoading &&
                attendances.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final attendanceBySession = <String, AttendanceEntity>{};
            for (final attendance in attendances) {
              final key = attendance.sessionId;
              if (key != null && key.isNotEmpty) {
                attendanceBySession.putIfAbsent(key, () => attendance);
              }
            }

            final now = DateTime.now();
            var presentCount = 0;
            var absentCount = 0;

            final tiles = <Widget>[];

            for (final session in sessions) {
              final sessionId = session['id']?.toString() ?? '';
              final startsAt = _parseDate(session['starts_at']);
              final endsAt = _parseDate(session['ends_at']);
              final attendance = attendanceBySession[sessionId];
              final attended = attendance != null;

              if (attended) {
                presentCount++;
              } else if (startsAt != null && startsAt.isBefore(now)) {
                absentCount++;
              }

              tiles.add(
                _SessionAttendanceTile(
                  session: session,
                  start: startsAt,
                  end: endsAt,
                  attendance: attendance,
                  studentId: studentId,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  BlocBuilder<ClassSectionBloc, ClassSectionState>(
                    builder: (context, state) {
                      if (state is ClassSectionsLoaded) {
                        final section = state.sections.firstWhere(
                          (item) => item.id == sectionId,
                          orElse: () => const ClassSectionEntity(
                            id: '',
                            subjectId: '',
                            semester: 0,
                            year: 0,
                            sectionCode: '',
                          ),
                        );
                        if (section.id.isNotEmpty) {
                          return _SectionSummaryCard(section: section);
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                  _AttendanceStats(
                    totalSessions: sessions.length,
                    presentSessions: presentCount,
                    absentSessions: absentCount,
                  ),
                  const SizedBox(height: 16),
                  ...tiles,
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionSummaryCard extends StatelessWidget {
  final ClassSectionEntity section;

  const _SectionSummaryCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.subject?.name ?? 'Lớp học phần',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (section.sectionCode != null &&
                section.sectionCode!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Mã lớp: ${section.sectionCode}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (section.semester != null || section.year != null) ...[
              const SizedBox(height: 4),
              Text(
                'Học kỳ: ${section.semester ?? '-'} - Năm: ${section.year ?? '-'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceStats extends StatelessWidget {
  final int totalSessions;
  final int presentSessions;
  final int absentSessions;

  const _AttendanceStats({
    required this.totalSessions,
    required this.presentSessions,
    required this.absentSessions,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final highlightColor =
        absentSessions > 0 ? Colors.red.shade600 : Colors.green.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Số buổi vắng: ',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: '$absentSessions',
                style: textTheme.titleMedium?.copyWith(
                  color: highlightColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _StatChip(
              label: 'Tổng buổi',
              value: totalSessions,
              color: Theme.of(context).colorScheme.primary,
            ),
            _StatChip(
              label: 'Có mặt',
              value: presentSessions,
              color: Colors.green.shade600,
            ),
            _StatChip(
              label: 'Vắng',
              value: absentSessions,
              color: Colors.red.shade600,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      backgroundColor: color.withOpacity(0.12),
      label: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SessionAttendanceTile extends StatelessWidget {
  final Map<String, dynamic> session;
  final DateTime? start;
  final DateTime? end;
  final AttendanceEntity? attendance;
  final String studentId;

  const _SessionAttendanceTile({
    required this.session,
    required this.start,
    required this.end,
    required this.attendance,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = start != null
        ? DateFormat('dd/MM/yyyy').format(start!)
        : 'Chưa rõ ngày';
    final timeLabel = (start != null && end != null)
        ? '${DateFormat('HH:mm').format(start!)} - ${DateFormat('HH:mm').format(end!)}'
        : 'Chưa rõ giờ học';

    final roomName = session['room_name']?.toString();
    final roomCode = session['room_code']?.toString();
    final roomLabel = (roomName != null && roomName.isNotEmpty)
        ? roomName
        : (roomCode != null && roomCode.isNotEmpty)
            ? roomCode
            : 'Chưa cập nhật phòng';

    final statusLabel = attendance != null ? 'Có mặt' : 'Chưa điểm danh';
    final statusColor =
        attendance != null ? Colors.green.shade600 : Colors.orange.shade600;
    final statusBackground = statusColor.withOpacity(0.12);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày: $dateLabel',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giờ học: $timeLabel',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phòng: $roomLabel',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentDetailCheckinPage(
                        session: session,
                        attendance: attendance,
                        studentId: studentId,
                      ),
                    ),
                  );
                },
                child: const Text('Xem chi tiết »'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Đã xảy ra lỗi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;

  const _EmptyHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.event_busy, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final raw = value.toString();
  if (raw.isEmpty) return null;
  try {
    return DateTime.parse(raw).toLocal();
  } catch (_) {
    try {
      final format = DateFormat('yyyy-MM-dd HH:mm:ss');
      return format.parse(raw, true).toLocal();
    } catch (_) {
      try {
        final format = DateFormat('yyyy-MM-dd HH:mm');
        return format.parse(raw, true).toLocal();
      } catch (_) {
        return null;
      }
    }
  }
}
