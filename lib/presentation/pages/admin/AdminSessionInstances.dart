import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../bloc/session_instance/session_instance_bloc.dart';
import '../../bloc/session_instance/session_instance_event.dart';
import '../../bloc/session_instance/session_instance_state.dart';
import '../../widgets/loading_widget.dart';

class AdminSessionInstances extends StatefulWidget {
  const AdminSessionInstances({super.key});

  @override
  State<AdminSessionInstances> createState() => _AdminSessionInstancesState();
}

class _AdminSessionInstancesState extends State<AdminSessionInstances> {
  final TextEditingController _searchController = TextEditingController();

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

  void _showInstanceForm([Map<String, dynamic>? instance]) {
    showDialog(
      context: context,
      builder: (context) => _InstanceFormDialog(
        instance: instance,
        onSaved: () {
          context.read<SessionInstanceBloc>().add(const LoadSessionInstances());
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> instance) {
    final id = instance['id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được ID')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phiên học'),
        content: Text(
          'Bạn muốn xóa phiên học của ${instance['section_code'] ?? instance['section_id']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SessionInstanceBloc>().add(DeleteSessionInstance(id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionInstanceBloc, SessionInstanceState>(
      listener: (context, state) {
        if (state is SessionInstanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is SessionInstanceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: BlocBuilder<SessionInstanceBloc, SessionInstanceState>(
              builder: (context, state) {
                if (state is SessionInstanceLoading) {
                  return const LoadingWidget();
                }

                if (state is SessionInstanceError) {
                  return _ErrorRetry(
                    message: state.message,
                    onRetry: () {
                      context.read<SessionInstanceBloc>().add(const LoadSessionInstances());
                    },
                  );
                }

                if (state is SessionInstancesLoaded) {
                  if (state.filteredInstances.isEmpty) {
                    return const Center(child: Text('Chưa có phiên học nào'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: state.filteredInstances.length,
                    itemBuilder: (context, index) {
                      final instance = state.filteredInstances[index];
                      return _InstanceCard(
                        instance: instance,
                        onEdit: () => _showInstanceForm(instance),
                        onDelete: () => _confirmDelete(instance),
                      );
                    },
                  );
                }

                return const Center(child: Text('Không có dữ liệu'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm theo section, phòng hoặc trạng thái...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              onChanged: (query) {
                context.read<SessionInstanceBloc>().add(FilterSessionInstances(query));
              },
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          ElevatedButton.icon(
            onPressed: () => _showInstanceForm(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

class _InstanceCard extends StatelessWidget {
  final Map<String, dynamic> instance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InstanceCard({
    required this.instance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final starts = _formatDateTime(instance['starts_at']);
    final ends = _formatDateTime(instance['ends_at']);
    final room = instance['room_code'] ?? instance['room_id'] ?? 'Chưa gán phòng';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.info,
          child: Icon(Icons.event_repeat, color: Colors.white),
        ),
        title: Text(
          instance['section_code']?.toString() ?? 
          instance['section_id']?.toString() ?? 
          'Section',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bắt đầu: $starts'),
            Text('Kết thúc: $ends'),
            Text('Phòng: $room'),
            Text('Trạng thái: ${instance['status'] ?? 'planned'}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Sửa'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final local = parsed.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _InstanceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? instance;
  final VoidCallback onSaved;

  const _InstanceFormDialog({
    this.instance,
    required this.onSaved,
  });

  @override
  State<_InstanceFormDialog> createState() => _InstanceFormDialogState();
}

class _InstanceFormDialogState extends State<_InstanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sectionIdController = TextEditingController();
  final _startsAtController = TextEditingController();
  final _endsAtController = TextEditingController();
  final _statusController = TextEditingController();
  final _roomIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.instance != null) {
      final instance = widget.instance!;
      _sectionIdController.text = instance['section_id']?.toString() ?? '';
      _startsAtController.text = instance['starts_at']?.toString() ?? '';
      _endsAtController.text = instance['ends_at']?.toString() ?? '';
      _statusController.text = instance['status']?.toString() ?? 'planned';
      _roomIdController.text = instance['room_id']?.toString() ?? '';
    } else {
      _statusController.text = 'planned';
    }
  }

  @override
  void dispose() {
    _sectionIdController.dispose();
    _startsAtController.dispose();
    _endsAtController.dispose();
    _statusController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final seed = DateTime.tryParse(controller.text.trim()) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (pickedTime == null) return;
    
    final value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    controller.text = value.toIso8601String();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final start = DateTime.tryParse(_startsAtController.text.trim());
    final end = DateTime.tryParse(_endsAtController.text.trim());
    if (start != null && end != null && !end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian kết thúc phải sau thời gian bắt đầu'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'section_id': _sectionIdController.text.trim(),
      'starts_at': _startsAtController.text.trim(),
      'ends_at': _endsAtController.text.trim(),
      'status': _statusController.text.trim(),
    };
    
    if (_roomIdController.text.trim().isNotEmpty) {
      payload['room_id'] = _roomIdController.text.trim();
    }

    if (widget.instance == null) {
      context.read<SessionInstanceBloc>().add(CreateSessionInstance(payload));
    } else {
      final id = widget.instance!['id']?.toString();
      if (id != null && id.isNotEmpty) {
        context.read<SessionInstanceBloc>().add(UpdateSessionInstance(id, payload));
      }
    }

    Navigator.of(context).pop();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.instance == null ? 'Thêm phiên học' : 'Sửa phiên học'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _sectionIdController,
                decoration: const InputDecoration(
                  labelText: 'Section ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập Section ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickDateTime(_startsAtController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _startsAtController,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian bắt đầu',
                      helperText: 'ISO 8601, ví dụ 2024-10-01T08:00:00',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.event_available),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Chọn thời gian bắt đầu';
                      }
                      if (DateTime.tryParse(value.trim()) == null) {
                        return 'Định dạng không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickDateTime(_endsAtController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _endsAtController,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian kết thúc',
                      helperText: 'ISO 8601, ví dụ 2024-10-01T10:00:00',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.event_busy),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Chọn thời gian kết thúc';
                      }
                      if (DateTime.tryParse(value.trim()) == null) {
                        return 'Định dạng không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomIdController,
                decoration: const InputDecoration(
                  labelText: 'Room ID (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                value: _statusController.text.isNotEmpty ? _statusController.text : null,
                items: const [
                  DropdownMenuItem(value: 'planned', child: Text('Đã lên kế hoạch')),
                  DropdownMenuItem(value: 'ongoing', child: Text('Đang diễn ra')),
                  DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                ],
                onChanged: (value) {
                  setState(() => _statusController.text = value ?? 'planned');
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

