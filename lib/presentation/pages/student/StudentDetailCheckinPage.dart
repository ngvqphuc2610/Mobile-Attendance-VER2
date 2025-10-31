import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/attendance_entity.dart';
import 'StudentCheckinPage.dart';

class StudentDetailCheckinPage extends StatelessWidget {
  final Map<String, dynamic> session;
  final AttendanceEntity? attendance;
  final String studentId;

  const StudentDetailCheckinPage({
    super.key,
    required this.session,
    required this.studentId,
    this.attendance,
  });

  DateTime? get _startsAt => _parseDate(session['starts_at']);

  DateTime? get _endsAt => _parseDate(session['ends_at']);

  String get _sessionTitle =>
      session['subject_name']?.toString() ?? 'Chi tiết buổi học';

  String get _roomLabel {
    final roomName = session['room_name']?.toString() ?? '';
    final roomCode = session['room_code']?.toString() ?? '';
    if (roomName.isNotEmpty) return roomName;
    if (roomCode.isNotEmpty) return roomCode;
    return 'Đang cập nhật';
  }

  @override
  Widget build(BuildContext context) {
    final start = _startsAt;
    final end = _endsAt;

    final dateText =
        start != null ? DateFormat('dd/MM/yyyy').format(start) : 'Chưa rõ';
    final timeText = (start != null && end != null)
        ? '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}'
        : 'Chưa rõ thời gian';

    final status = session['status']?.toString() ?? 'planned';
    final statusLabel = _statusLabel(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
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
                    'Thông tin buổi học',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Ngày', value: dateText),
                  _InfoRow(label: 'Giờ học', value: timeText),
                  _InfoRow(label: 'Phòng', value: _roomLabel),
                  _InfoRow(
                    label: 'Trạng thái',
                    value: statusLabel,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (attendance != null)
            _AttendanceDetailCard(attendance: attendance!)
          else
            _CheckinEmptyCard(studentId: studentId),
        ],
      ),
    );
  }
}

class _AttendanceDetailCard extends StatelessWidget {
  final AttendanceEntity attendance;

  const _AttendanceDetailCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final checkinTime = DateFormat('dd/MM/yyyy HH:mm').format(
      attendance.atTime.toLocal(),
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đã điểm danh',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Phương thức',
              value: _methodLabel(attendance.method),
            ),
            _InfoRow(label: 'Thời gian', value: checkinTime),
            if (attendance.address != null && attendance.address!.isNotEmpty)
              _InfoRow(label: 'Địa điểm', value: attendance.address!),
            if (attendance.latitude != null && attendance.longitude != null)
              _InfoRow(
                label: 'Toạ độ',
                value:
                    '${attendance.latitude!.toStringAsFixed(6)}, ${attendance.longitude!.toStringAsFixed(6)}',
              ),
            if (attendance.note != null && attendance.note!.isNotEmpty)
              _InfoRow(label: 'Ghi chú', value: attendance.note!),
          ],
        ),
      ),
    );
  }
}

class _CheckinEmptyCard extends StatelessWidget {
  final String studentId;

  const _CheckinEmptyCard({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn chưa điểm danh buổi này',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy thực hiện điểm danh để tránh bị tính vắng.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentCheckinPage(studentId: studentId),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Điểm danh ngay'),
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
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return 'Đã hoàn thành';
    case 'cancelled':
      return 'Đã huỷ';
    case 'planned':
    default:
      return 'Chưa diễn ra';
  }
}

String _methodLabel(AttendanceMethod method) {
  switch (method) {
    case AttendanceMethod.face:
      return 'Nhận diện khuôn mặt';
    case AttendanceMethod.barcode:
      return 'Quét mã / PIN';
    case AttendanceMethod.manual:
    default:
      return 'Thủ công';
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
      return null;
    }
  }
}
