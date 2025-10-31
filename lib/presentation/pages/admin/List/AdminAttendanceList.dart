import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/entity/attendance_entity.dart';
import '../../../bloc/attendance/attendance_bloc.dart';
import '../../../bloc/attendance/attendance_event.dart';
import '../../../bloc/attendance/attendance_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Add/AddAttendancePage.dart';
import '../Edit/EditAttendancePage.dart';

class AdminAttendanceList extends StatefulWidget {
  final String searchText;
  const AdminAttendanceList({super.key, this.searchText = ''});

  @override
  State<AdminAttendanceList> createState() => _AdminAttendanceListState();
}

class _AdminAttendanceListState extends State<AdminAttendanceList> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(const LoadAttendances());

    if (widget.searchText.isNotEmpty) {
      context
          .read<AttendanceBloc>()
          .add(FilterAttendances(widget.searchText));
    }
  }

  @override
  void didUpdateWidget(covariant AdminAttendanceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchText != widget.searchText) {
      context
          .read<AttendanceBloc>()
          .add(FilterAttendances(widget.searchText));
    }
  }

  Future<void> _openEdit(AttendanceEntity a) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAttendancePage(attendance: a.toJson()),
      ),
    );
    if (updated == true && mounted) {
      context.read<AttendanceBloc>().add(const LoadAttendances());
    }
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAttendancePage()),
    );
    if (created == true && mounted) {
      context.read<AttendanceBloc>().add(const LoadAttendances());
    }
  }

  void _deleteAttendance(AttendanceEntity a) {
    context.read<AttendanceBloc>().add(DeleteAttendance(attendanceId: a.id!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceOperationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const LoadingWidget();
          }

          if (state is AttendanceError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context
                        .read<AttendanceBloc>()
                        .add(const LoadAttendances()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is AttendancesLoaded) {
            final items = state.filteredAttendances;
            if (items.isEmpty) {
              return const Center(
                child: Text('Không có bản ghi điểm danh'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AttendanceBloc>().add(const LoadAttendances());
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final a = items[index];

                  final userName = a.userFullName ?? 'Người dùng';
                  final userCode =
                      a.userCode != null ? ' • ${a.userCode}' : '';
                  final method = a.method.name;
                  final note = a.note;
                  final timeStr = a.atTime.toLocal().toString();
                  final time =
                      timeStr.isNotEmpty ? timeStr.substring(0, 16) : '';

                  return Dismissible(
                    key: ValueKey(a.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xoá điểm danh'),
                              content:
                                  Text('Xoá bản ghi của $userName$userCode?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Huỷ'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('Xoá'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) => _deleteAttendance(a),
                    child: ListTile(
                      leading: const Icon(Icons.how_to_reg),
                      title: Text(
                        '$userName$userCode',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phương thức: ${method.toUpperCase()}'),
                          if (timeStr.isNotEmpty) Text('Thời gian: $time'),
                          if (note != null && note.isNotEmpty)
                            Text('Ghi chú: $note'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openEdit(a),
                      ),
                      onTap: () => _openEdit(a),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
