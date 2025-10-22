import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/core/di/dependency_injection.dart';
import 'package:mobile_attendance/presentation/bloc/session_instance/session_instance_bloc.dart';
import 'package:mobile_attendance/presentation/bloc/session_instance/session_instance_event.dart';
import 'package:mobile_attendance/presentation/bloc/session_instance/session_instance_state.dart';

import 'TeacherSessionDetailPage.dart';

class TeacherSectionSessionsPage extends StatefulWidget {
  final String sectionId;
  final String? sectionCode;

  const TeacherSectionSessionsPage({
    super.key,
    required this.sectionId,
    this.sectionCode,
  });

  @override
  State<TeacherSectionSessionsPage> createState() =>
      _TeacherSectionSessionsPageState();
}

class _TeacherSectionSessionsPageState
    extends State<TeacherSectionSessionsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload(BuildContext context) {
    context.read<SessionInstanceBloc>().add(
      LoadSessionInstances(sectionId: widget.sectionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sectionCode == null
        ? 'Sessions'
        : 'Sessions • ${widget.sectionCode}';

    return BlocProvider<SessionInstanceBloc>(
      create: (_) =>
          sl<SessionInstanceBloc>()
            ..add(LoadSessionInstances(sectionId: widget.sectionId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: AppTheme.adminPrimaryColor,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => _reload(context),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by room, status or time',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SessionInstanceBloc, SessionInstanceState>(
                builder: (context, state) {
                  if (state is SessionInstanceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SessionInstanceError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => _reload(context),
                    );
                  }

                  if (state is SessionInstancesLoaded) {
                    final rows = state.instances
                        .map(_SessionParser.fromMap)
                        .whereType<SessionRowData>()
                        .toList();

                    final filtered = _filter(rows, _query);
                    if (filtered.isEmpty) {
                      return const _EmptyView();
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _reload(context),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final row = filtered[index];
                          return ListTile(
                            leading: _StatusAvatar(status: row.status),
                            title: Text(
                              row.displayDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(row.timeAndRoom),
                            trailing: _StatusChip(status: row.status),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeacherSessionDetailPage(
                                    sessionId: row.sessionId,
                                    sectionId: widget.sectionId,
                                    sectionCode:
                                        widget.sectionCode ?? row.sectionCode,
                                    subjectName: row.subjectName,
                                    roomName: row.roomName,
                                    startsAt: row.startsAt,
                                    endsAt: row.endsAt,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SessionRowData> _filter(List<SessionRowData> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((row) {
      return row.status.toLowerCase().contains(q) ||
          row.roomName.toLowerCase().contains(q) ||
          row.displayDate.toLowerCase().contains(q) ||
          row.timeAndRoom.toLowerCase().contains(q);
    }).toList();
  }
}

class SessionRowData {
  final String sessionId;
  final String status;
  final String roomName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String displayDate;
  final String timeAndRoom;
  final String? sectionCode;
  final String? subjectName;

  SessionRowData({
    required this.sessionId,
    required this.status,
    required this.roomName,
    required this.startsAt,
    required this.endsAt,
    required this.displayDate,
    required this.timeAndRoom,
    this.sectionCode,
    this.subjectName,
  });
}

class _SessionParser {
  static SessionRowData? fromMap(Map<String, dynamic> map) {
    final sessionId = map['id']?.toString();
    if (sessionId == null || sessionId.isEmpty) return null;

    final status = (map['status'] ?? 'planned').toString();
    final roomName =
        (map['room_name'] ?? map['room_code'] ?? map['room_id'] ?? '')
            .toString();

    final startsAt = _parseDate(map['starts_at']);
    final endsAt = _parseDate(map['ends_at']);

    final displayDate = _formatDayDate(startsAt);
    final timeRange = '${_formatTime(startsAt)} - ${_formatTime(endsAt)}';
    final timeAndRoom = roomName.isEmpty
        ? timeRange
        : '$timeRange\nRoom $roomName';

    return SessionRowData(
      sessionId: sessionId,
      status: status,
      roomName: roomName,
      startsAt: startsAt,
      endsAt: endsAt,
      displayDate: displayDate,
      timeAndRoom: timeAndRoom,
      sectionCode: map['section_code']?.toString(),
      subjectName: map['subject_name']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    final text = value.toString();
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso.toLocal();
    if (text.contains(' ')) {
      final fallback = DateTime.tryParse(text.replaceFirst(' ', 'T'));
      if (fallback != null) return fallback.toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static String _formatDayDate(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '--';
    final wd = _weekdays[dt.weekday % 7];
    return '$wd, ${_two(dt.day)}/${_two(dt.month)}/${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '--:--';
    return '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.event_busy, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No sessions for this section.'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status),
      backgroundColor: _bg(status),
      shape: StadiumBorder(side: BorderSide(color: _border(status))),
    );
  }

  Color _border(String value) {
    switch (value) {
      case 'open':
        return Colors.green.shade300;
      case 'closed':
        return Colors.red.shade300;
      case 'cancelled':
        return Colors.grey.shade400;
      default:
        return Colors.blueGrey.shade300;
    }
  }

  Color _bg(String value) {
    switch (value) {
      case 'open':
        return Colors.green.shade50;
      case 'closed':
        return Colors.red.shade50;
      case 'cancelled':
        return Colors.grey.shade100;
      default:
        return Colors.blueGrey.shade50;
    }
  }
}

class _StatusAvatar extends StatelessWidget {
  final String status;

  const _StatusAvatar({required this.status});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: _bg(status),
      foregroundColor: _fg(status),
      child: Icon(_icon(status)),
    );
  }

  Color _bg(String value) {
    switch (value) {
      case 'open':
        return Colors.green.shade50;
      case 'closed':
        return Colors.red.shade50;
      case 'cancelled':
        return Colors.grey.shade100;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _fg(String value) {
    switch (value) {
      case 'open':
        return Colors.green.shade700;
      case 'closed':
        return Colors.red.shade700;
      case 'cancelled':
        return Colors.grey.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _icon(String value) {
    switch (value) {
      case 'open':
        return Icons.play_circle_fill;
      case 'closed':
        return Icons.stop_circle_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.event;
    }
  }
}
