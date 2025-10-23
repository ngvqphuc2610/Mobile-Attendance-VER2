import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/entity/student_schedule_entity.dart';
import '../../bloc/studentschedule/student_schedule_bloc.dart';
import '../../bloc/studentschedule/student_schedule_state.dart';

class StudentDetailSchedulePage extends StatelessWidget {
  final String scheduleId;

  const StudentDetailSchedulePage({
    super.key,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiet lich hoc'),
      ),
      body: BlocBuilder<StudentScheduleBloc, StudentScheduleState>(
        builder: (context, state) {
          if (state is StudentScheduleLoading ||
              state is StudentScheduleInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentScheduleError) {
            return _ErrorView(message: state.message);
          }

          if (state is StudentSchedulesLoaded) {
            final schedule = state.schedules.firstWhere(
              (item) => item.id == scheduleId,
              orElse: () => const StudentScheduleEntity(
                id: '',
                sectionId: '',
                dayOfWeek: DateTime.monday,
                startTime: '',
                endTime: '',
              ),
            );

            if (schedule.id.isEmpty) {
              return const _ErrorView(
                message: 'Khong tim thay lich hoc.',
              );
            }

            return _ScheduleDetailView(schedule: schedule);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ScheduleDetailView extends StatelessWidget {
  final StudentScheduleEntity schedule;

  const _ScheduleDetailView({required this.schedule});

  static const _weekdayLabels = <int, String>{
    DateTime.monday: 'Thu 2',
    DateTime.tuesday: 'Thu 3',
    DateTime.wednesday: 'Thu 4',
    DateTime.thursday: 'Thu 5',
    DateTime.friday: 'Thu 6',
    DateTime.saturday: 'Thu 7',
    DateTime.sunday: 'Chu nhat',
  };

  @override
  Widget build(BuildContext context) {
    final subjectLine = [
      schedule.subjectCode,
      schedule.subjectName,
    ].where((e) => e != null && e!.isNotEmpty).join(', ');

    final weekdayText = _weekdayLabels[schedule.dayOfWeek] ?? 'Chua ro ngay';
    final date = schedule.startsAt ?? _fallbackDate(schedule.dayOfWeek);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final displayDate =
        date != null ? '$weekdayText, ${dateFormat.format(date)}' : weekdayText;

    final timeRange = _buildSlot(schedule);
    final room = schedule.roomName ?? schedule.roomCode ?? 'Dang cap nhat';
    final credits = schedule.subjectCredits?.toString() ?? 'Dang cap nhat';
    final group = _extractGroup(schedule.sectionCode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.sectionCode ?? 'Lich hoc',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subjectLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subjectLine,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 16),
                _InfoRow(label: 'Mon hoc', value: subjectLine),
                _InfoRow(label: 'Vao luc', value: displayDate),
                _InfoRow(label: 'Gio hoc', value: timeRange),
                _InfoRow(label: 'Phong', value: room),
                _InfoRow(label: 'So tin chi', value: credits),
                _InfoRow(label: 'Nhom', value: group),
                if (schedule.semester != null || schedule.year != null) ...[
                  _InfoRow(
                    label: 'Hoc ky',
                    value:
                        'HK ${schedule.semester ?? '-'} nam ${schedule.year ?? '-'}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _fallbackDate(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) return null;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - DateTime.monday));
    return monday.add(Duration(days: weekday - DateTime.monday));
  }

  String _buildSlot(StudentScheduleEntity schedule) {
    if (schedule.startsAt != null && schedule.endsAt != null) {
      final start = DateFormat('HH:mm').format(schedule.startsAt!);
      final end = DateFormat('HH:mm').format(schedule.endsAt!);
      return '$start - $end';
    }
    return '${_trimTime(schedule.startTime)} - ${_trimTime(schedule.endTime)}';
  }

  String _trimTime(String raw) {
    if (raw.isEmpty) return 'Dang cap nhat';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hh = parts[0].padLeft(2, '0');
    final mm = parts[1].padLeft(2, '0');
    return '$hh:$mm';
  }

  String _extractGroup(String? sectionCode) {
    if (sectionCode == null || sectionCode.isEmpty) return 'Dang cap nhat';
    final match = RegExp(r'(\d+)$').firstMatch(sectionCode);
    return match?.group(1) ?? sectionCode;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              value.isEmpty ? 'Dang cap nhat' : value,
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

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Khong the tai chi tiet lich hoc',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
