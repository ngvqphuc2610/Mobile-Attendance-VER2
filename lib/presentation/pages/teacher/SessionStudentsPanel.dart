import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_attendance/data/repositories/session_instance_repository.dart';
import 'package:mobile_attendance/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:mobile_attendance/presentation/bloc/attendance/attendance_state.dart';
import 'package:mobile_attendance/presentation/bloc/attendance/attendance_event.dart';
import 'package:mobile_attendance/presentation/bloc/enrollment/enrollment_event.dart';
import 'package:mobile_attendance/presentation/bloc/enrollment/enrollment_bloc.dart';
import 'package:mobile_attendance/presentation/bloc/enrollment/enrollment_state.dart';

class SessionStudentsPanel extends StatefulWidget {
  final String sessionId;
  const SessionStudentsPanel({required this.sessionId});

  @override
  State<SessionStudentsPanel> createState() => _SessionStudentsPanelState();
}

class _SessionStudentsPanelState extends State<SessionStudentsPanel> {
  String? _sectionId;
  bool _loadingSection = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSectionIdAndData();
  }

  Future<void> _loadSectionIdAndData() async {
    try {
      // Lấy section_id từ session_instance
      // Giả định repository trả về Map có key 'section_id'
      final sessionRepo = SessionInstanceRepository();

      final session = await sessionRepo.getById(widget.sessionId);
      final sid = (session['section_id'] ?? '').toString();
      if (sid.isEmpty) throw Exception('Không lấy được section_id từ session.');

      setState(() {
        _sectionId = sid;
        _loadingSection = false;
      });

      // Sau khi có sectionId, bắn event load enrollments & attendance
      // ⚠️ Đổi tên event cho khớp code của bạn:
      context.read<EnrollmentBloc>().add(LoadEnrollmentsBySection(sid));
      context.read<AttendanceBloc>().add(LoadAttendances(sectionId: sid));
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingSection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSection) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Lỗi tải dữ liệu buổi học: $_error'),
        ),
      );
    }
    if (_sectionId == null) {
      return const Center(
        child: Text('Không tìm thấy section cho buổi học này.'),
      );
    }

    // Dùng MultiBlocBuilder để lấy cả enrollments và attendance
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, eState) {
        return BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, aState) {
            // loading
            final loading =
                eState is EnrollmentLoading || aState is AttendanceLoading;
            if (loading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // error
            final eErr = (eState is EnrollmentError) ? eState.message : null;
            final aErr = (aState is AttendanceError) ? aState.message : null;
            final err = eErr ?? aErr;
            if (err != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(err),
                ),
              );
            }

            // data
            final enrollments = (eState is EnrollmentsLoaded)
                ? _normalizeList(eState.enrollments)
                : const <Map<String, dynamic>>[];

            final attendances = (aState is AttendancesLoaded)
                ? _normalizeList(aState.attendances)
                : const <Map<String, dynamic>>[];

            // merge
            final attendedIds = attendances
                .map((a) => a['user_id']?.toString())
                .toSet();
            final items =
                enrollments.map<Map<String, dynamic>>((e) {
                  final id =
                      e['student_id']?.toString() ??
                      e['profile_id']?.toString() ??
                      e['id']?.toString();
                  return {
                    'student_id': id,
                    'code': e['code'] ?? e['mssv'] ?? '',
                    'full_name': e['full_name'] ?? '',
                    'present': attendedIds.contains(id),
                  };
                }).toList()..sort((a, b) {
                  final p1 = (b['present'] == true) ? 1 : 0;
                  final p0 = (a['present'] == true) ? 1 : 0;
                  if (p1 != p0) return p1.compareTo(p0);
                  return (a['code'] ?? '').toString().compareTo(
                    (b['code'] ?? '').toString(),
                  );
                });

            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có sinh viên trong lớp này.'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = items[i];
                final present = s['present'] == true;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (s['code'] ?? '?')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                    ),
                  ),
                  title: Text(s['full_name'] ?? '—'),
                  subtitle: Text(s['code'] ?? ''),
                  trailing: present
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.hourglass_bottom),
                );
              },
            );
          },
        );
      },
    );
  }

  // Gom state từ 2 Bloc: Enrollment và Attendance
  Widget _buildList(EnrollmentState? eState, AttendanceState? aState) {
    // Lấy snapshot hiện tại trong _MergedState
    final snap = _MergedState.lastOrNew();

    // Cập nhật theo từng state đến
    if (eState != null) {
      if (eState is EnrollmentLoading) {
        snap.loadingEnrollments = true;
      } else if (eState is EnrollmentError) {
        snap.error = eState.message;
        snap.loadingEnrollments = false;
      } else if (eState is EnrollmentsLoaded) {
        // Giả định eState.enrollments là List<Map> có {student_id, code, full_name}
        snap.enrollments = _normalizeList(eState.enrollments);
        snap.loadingEnrollments = false;
      }
    }

    if (aState != null) {
      if (aState is AttendanceLoading) {
        snap.loadingAttendance = true;
      } else if (aState is AttendanceError) {
        snap.error = aState.message;
        snap.loadingAttendance = false;
      } else if (aState is AttendancesLoaded) {
        // Giả định aState.items là List<Map> có {user_id, at_time}
        snap.attendances = _normalizeList(aState.attendances);
        snap.loadingAttendance = false;
      }
    }

    // Nếu đã có đủ dữ liệu, merge danh sách
    if (!snap.loadingEnrollments &&
        !snap.loadingAttendance &&
        snap.error == null) {
      final attendedIds = snap.attendances
          .map((a) => a['user_id']?.toString())
          .toSet();
      snap.items =
          snap.enrollments.map<Map<String, dynamic>>((e) {
            final id =
                e['student_id']?.toString() ??
                e['profile_id']?.toString() ??
                e['id']?.toString();
            return {
              'student_id': id,
              'code': e['code'] ?? e['mssv'] ?? '',
              'full_name': e['full_name'] ?? '',
              'present': attendedIds.contains(id),
            };
          }).toList()..sort((a, b) {
            // Ưu tiên đã điểm danh lên trước
            final p1 = (b['present'] == true) ? 1 : 0;
            final p0 = (a['present'] == true) ? 1 : 0;
            if (p1 != p0) return p1.compareTo(p0);
            return (a['code'] ?? '').toString().compareTo(
              (b['code'] ?? '').toString(),
            );
          });
    }

    // Lưu snapshot “toàn cục” để MultiBlocBuilder builder đọc được
    _MergedState.last = snap;

    // Trả về SizedBox rỗng – phần render chính ở builder của MultiBlocBuilder
    return const SizedBox.shrink();
  }

  List<Map<String, dynamic>> _normalizeList(dynamic v) {
    if (v is List<Map<String, dynamic>>) return v;
    if (v is List) {
      return v
          .map<Map<String, dynamic>>(
            (e) => (e is Map)
                ? Map<String, dynamic>.from(e)
                : {'raw': e.toString()},
          )
          .toList();
    }
    return const [];
  }
}

// ---------- “snapshot” tạm để gộp 2 state ----------
class _MergedState {
  _MergedState();

  static _MergedState? _last;
  static _MergedState lastOrNew() => _last ??= _MergedState();
  static set last(_MergedState v) => _last = v;
  static _MergedState get last => _last ??= _MergedState();

  // data
  List<Map<String, dynamic>> enrollments = const [];
  List<Map<String, dynamic>> attendances = const [];
  List<Map<String, dynamic>> items = const [];

  // flags
  bool loadingEnrollments = true;
  bool loadingAttendance = true;
  String? error;

  bool get loading => loadingEnrollments || loadingAttendance;
}
