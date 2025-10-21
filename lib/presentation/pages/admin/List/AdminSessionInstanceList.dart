import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // ✅ thêm
import '../../../../core/constants/app_theme.dart';
import '../../../bloc/session_instance/session_instance_bloc.dart';
import '../../../bloc/session_instance/session_instance_event.dart';
import '../../../bloc/session_instance/session_instance_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Edit/EditSessionInstancePage.dart';
import '../Add/AddSesstionInstancePage.dart';

class AdminSessionInstanceList extends StatefulWidget {
  const AdminSessionInstanceList({super.key});

  @override
  State<AdminSessionInstanceList> createState() =>
      _AdminSessionInstanceListState();
}

class _AdminSessionInstanceListState extends State<AdminSessionInstanceList> {
  final TextEditingController _searchController = TextEditingController();

  // ===== Helpers định dạng thời gian =====
  final DateFormat _fmtDisplay = DateFormat('yyyy-MM-dd HH:mm');

  DateTime? _parseDateFlexible(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    // thử ISO trước (có thể có 'Z')
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {}
    // fallback SQL: yyyy-MM-dd HH:mm:ss
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true);
      return dt.toLocal();
    } catch (_) {}
    // fallback ngắn: yyyy-MM-dd HH:mm
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(raw, true);
      return dt.toLocal();
    } catch (_) {}
    return null;
  }

  String _formatDisplay(String? raw) {
    final dt = _parseDateFlexible(raw);
    return dt == null ? '-' : _fmtDisplay.format(dt);
  }
  // ======================================

  @override
  void initState() {
    super.initState();
    context.read<SessionInstanceBloc>().add(const LoadSessionInstances());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterInstances(String query) {
    context.read<SessionInstanceBloc>().add(FilterSessionInstances(query));
  }

  void _deleteInstance(Map<String, dynamic> instance) {
    final id = instance['id']?.toString();
    if (id == null || id.isEmpty) return;
    context.read<SessionInstanceBloc>().add(DeleteSessionInstance(id));
  }

  Future<void> _editInstance(Map<String, dynamic> instance) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSessionInstancePage(instance: instance),
      ),
    );
    if (changed == true && mounted) {
      context.read<SessionInstanceBloc>().add(const LoadSessionInstances());
    }
  }

  Future<void> _addInstance() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddSesstionInstancePage()),
    );
    if (changed == true && mounted) {
      context.read<SessionInstanceBloc>().add(const LoadSessionInstances());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Thêm phiên học'),
        backgroundColor: AppTheme.adminPrimaryColor,
        onPressed: _addInstance,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm theo section, phòng hoặc trạng thái...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              onChanged: _filterInstances,
            ),
          ),
          Expanded(
            child: BlocBuilder<SessionInstanceBloc, SessionInstanceState>(
              builder: (context, state) {
                if (state is SessionInstanceLoading) {
                  return const LoadingWidget();
                }

                if (state is SessionInstanceError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(state.message),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context
                              .read<SessionInstanceBloc>()
                              .add(const LoadSessionInstances()),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is SessionInstancesLoaded) {
                  final List<Map<String, dynamic>> items =
                      state.filteredInstances;
                  if (items.isEmpty) {
                    return const Center(child: Text('Chưa có phiên học nào'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final m = items[index];

                      // An toàn từ Map
                      final id = m['id']?.toString() ?? '';
                      final subjectName = m['subject_name']?.toString() ?? '-';
                      final semester = m['semester']?.toString() ?? '-';
                      final year = m['year']?.toString() ?? '-';
                      final status = m['status']?.toString() ?? '';
                      final room =
                          m['room_code']?.toString() ??
                          (m['room_id']?.toString() ?? '');

                      // ✅ Định dạng thời gian đẹp (local)
                      final startsAtDisp = _formatDisplay(
                        m['starts_at']?.toString(),
                      );
                      final endsAtDisp = _formatDisplay(
                        m['ends_at']?.toString(),
                      );

                      return Card(
                        child: ListTile(
                          title: Text(
                            room.isNotEmpty
                                ? '- Phòng $room \n$startsAtDisp → $endsAtDisp'
                                : '$startsAtDisp → $endsAtDisp',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Môn học: $subjectName'),
                              Text('Học kỳ: $semester/$year'),
                              if (status.isNotEmpty)
                                Text('Trạng thái: $status'),
                              
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              switch (v) {
                                case 'edit':
                                  _editInstance(m);
                                  break;
                                case 'delete':
                                  _confirmDelete(m);
                                  break;
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Sửa'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: Text('Chưa có phiên học nào'));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> instance) {
    final id = instance['id']?.toString() ?? '';
    if (id.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiên học'),
        content: Text('Bạn có chắc muốn xóa phiên học $id?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteInstance(instance);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
