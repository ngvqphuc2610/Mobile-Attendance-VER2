import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_attendance/data/models/entity/attendance_entity.dart';
import 'package:mobile_attendance/data/models/entity/enrollment_entity.dart';
import 'package:mobile_attendance/data/repositories/session_instance_repository.dart';
import 'package:mobile_attendance/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:mobile_attendance/presentation/bloc/attendance/attendance_event.dart';
import 'package:mobile_attendance/presentation/bloc/attendance/attendance_state.dart';
import 'package:mobile_attendance/presentation/bloc/enrollment/enrollment_bloc.dart';
import 'package:mobile_attendance/presentation/bloc/enrollment/enrollment_event.dart';
import 'package:mobile_attendance/presentation/bloc/enrollment/enrollment_state.dart';

class SessionStudentsPanel extends StatefulWidget {
  const SessionStudentsPanel({
    super.key,
    required this.sessionId,
    this.sectionId,
  });

  final String sessionId;
  final String? sectionId;

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
    if (widget.sectionId != null && widget.sectionId!.isNotEmpty) {
      _sectionId = widget.sectionId;
      _loadingSection = false;
      _dispatchLoads(widget.sectionId!);
    } else {
      _resolveSectionId();
    }
  }

  Future<void> _resolveSectionId() async {
    try {
      final sessionRepo = SessionInstanceRepository();
      final session = await sessionRepo.getById(widget.sessionId);
      final sid = (session['section_id'] ?? '').toString();
      if (sid.isEmpty) {
        throw Exception('Session instance is missing section_id.');
      }

      setState(() {
        _sectionId = sid;
        _loadingSection = false;
      });

      _dispatchLoads(sid);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingSection = false;
      });
    }
  }

  void _dispatchLoads(String sectionId) {
    context.read<EnrollmentBloc>().add(LoadEnrollmentsBySection(sectionId));
    context.read<AttendanceBloc>().add(LoadAttendances(sectionId: sectionId, sessionId: widget.sessionId));
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
          child: Text('Không tải được dữ liệu phiên học: $_error'),
        ),
      );
    }
    if (_sectionId == null) {
      return const Center(child: Text('Không tìm thấy lớp của phiên học này.'));
    }

    // Lắng nghe kết quả thao tác Attendance để show SnackBar
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (!mounted) return;
        if (state is AttendanceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${state.message}')),
          );
        }
      },
      child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, enrollmentState) {
          return BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, attendanceState) {
              final isLoading =
                  enrollmentState is EnrollmentLoading ||
                  attendanceState is AttendanceLoading;
              if (isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final enrollmentError = enrollmentState is EnrollmentError ? enrollmentState.message : null;
              final attendanceError = attendanceState is AttendanceError ? attendanceState.message : null;
              final errorMessage = enrollmentError ?? attendanceError;
              if (errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(errorMessage),
                  ),
                );
              }

              final enrollments = enrollmentState is EnrollmentsLoaded
                  ? _normalizeList(enrollmentState.enrollments)
                  : const <Map<String, dynamic>>[];

              // Tạo presentMap: userId -> AttendanceEntity (để lấy attendanceId khi cần xóa)
              final Map<String, AttendanceEntity> presentMap = {};
              if (attendanceState is AttendancesLoaded) {
                for (final a in attendanceState.attendances) {
                  // giả định AttendanceEntity có trường id, userId
                  final uid = a.userId.toString();
                  presentMap[uid] = a;
                }
              }

              // Attendances dạng Map chỉ dùng để fallback (không cần nếu đã có presentMap)
              final attendances = attendanceState is AttendancesLoaded
                  ? _normalizeList(attendanceState.attendances)
                  : const <Map<String, dynamic>>[];

              final attendedIds = presentMap.keys.toSet().isEmpty
                  ? attendances.map((a) => a['user_id']?.toString()).toSet()
                  : presentMap.keys.toSet();

              final items = enrollments.map<Map<String, dynamic>>((row) {
                final id = row['student_id']?.toString() ??
                    row['profile_id']?.toString() ??
                    row['id']?.toString();

                final isPresent = attendedIds.contains(id);
                final attId = isPresent ? presentMap[id]?.id : null;

                return {
                  'student_id': id,
                  'code': row['code'] ?? row['mssv'] ?? '',
                  'full_name': row['full_name'] ?? '',
                  'present': isPresent,
                  'attendance_id': attId,
                };
              }).toList()
                ..sort((a, b) {
                  final aPresent = a['present'] == true ? 1 : 0;
                  final bPresent = b['present'] == true ? 1 : 0;
                  if (aPresent != bPresent) return bPresent.compareTo(aPresent);
                  return (a['code'] ?? '').toString().compareTo((b['code'] ?? '').toString());
                });

              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có sinh viên nào đăng ký lớp này.'),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final student = items[index];
                  final present = student['present'] == true;

                  final bgColor = present
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1);

                  final textColor = present ? Colors.green[800] : Colors.orange[800];

                  return Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: ListTile(
                      title: Text(
                        student['full_name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'MSSV: ${student['code'] ?? ''}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),

                      // ✅ Thay trailing thành 2 nút: Có mặt / Vắng
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          // Nút "Có mặt" — chỉ enable khi chưa present
                          ElevatedButton.icon(
                            onPressed: present
                                ? null
                                : () {
                                    final userId = student['student_id']?.toString();
                                    if (userId != null && _sectionId != null) {
                                      context.read<AttendanceBloc>().add(
                                            CreateAttendance(
                                              userId: userId,
                                              method: AttendanceMethod.manual, // chọn "manual"
                                              sectionId: _sectionId!,
                                              sessionId: widget.sessionId,
                                            ),
                                          );
                                    }
                                  },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Có mặt'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(90, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),

                          // Nút "Vắng" — chỉ enable khi đang present (đã có attendance_id)
                          OutlinedButton.icon(
                            onPressed: !present
                                ? null
                                : () {
                                    final attId = student['attendance_id']?.toString();
                                    if (attId != null && _sectionId != null) {
                                      context.read<AttendanceBloc>().add(
                                            DeleteAttendance(
                                              attendanceId: attId,
                                              sectionId: _sectionId!,
                                              sessionId: widget.sessionId,
                                            ),
                                          );
                                    }
                                  },
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Vắng'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(80, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              side: BorderSide(color: Colors.red.shade300),
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _normalizeList(dynamic value) {
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      return value.map<Map<String, dynamic>>((item) {
        if (item is EnrollmentEntity) {
          return {
            'student_id': item.studentId,
            'profile_id': item.student?.id,
            'code': item.student?.code ?? '',
            'full_name': item.student?.fullName ?? '',
          };
        }
        if (item is AttendanceEntity) {
          return {
            'id': item.id, // ✅ để có thể lấy lại khi cần (fallback)
            'user_id': item.userId,
            'code': item.userCode ?? '',
            'full_name': item.userFullName ?? '',
            'present': true,
          };
        }
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return {'raw': item.toString()};
      }).toList();
    }
    return const [];
  }
}
