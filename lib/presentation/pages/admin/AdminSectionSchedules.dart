import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../bloc/section_schedule/section_schedule_bloc.dart';
import '../../bloc/section_schedule/section_schedule_event.dart';
import '../../bloc/section_schedule/section_schedule_state.dart';
import '../../widgets/loading_widget.dart';

class AdminSectionSchedules extends StatefulWidget {
  const AdminSectionSchedules({super.key});

  @override
  State<AdminSectionSchedules> createState() => _AdminSectionSchedulesState();
}

class _AdminSectionSchedulesState extends State<AdminSectionSchedules> {
  final TextEditingController _searchController = TextEditingController();

  static const Map<int, String> _weekdayLabels = {
    1: 'Thứ 2',
    2: 'Thứ 3', 
    3: 'Thứ 4',
    4: 'Thứ 5',
    5: 'Thứ 6',
    6: 'Thứ 7',
    7: 'Chủ nhật',
  };

  @override
  void initState() {
    super.initState();
    context.read<SectionScheduleBloc>().add(const LoadSectionSchedules());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showScheduleForm([Map<String, dynamic>? schedule]) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleFormDialog(
        schedule: schedule,
        onSaved: () {
          context.read<SectionScheduleBloc>().add(const LoadSectionSchedules());
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> schedule) {
    final id = schedule['id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được ID')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch học'),
        content: Text(
          'Xóa lịch cho section ${schedule['section_code'] ?? schedule['section_id']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SectionScheduleBloc>().add(DeleteSectionSchedule(id));
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
    final content = _buildContent();
    return Scaffold.maybeOf(context) == null
        ? Scaffold(body: content)
        : content;
  }

  Widget _buildContent() {
    return BlocListener<SectionScheduleBloc, SectionScheduleState>(
      listener: (context, state) {
        if (state is SectionScheduleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is SectionScheduleOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<SectionScheduleBloc, SectionScheduleState>(
                builder: (context, state) {
                  if (state is SectionScheduleLoading) {
                    return const LoadingWidget();
                  }

                  if (state is SectionScheduleError) {
                    return _ErrorRetry(
                      message: state.message,
                      onRetry: () {
                        context.read<SectionScheduleBloc>().add(const LoadSectionSchedules());
                      },
                    );
                  }

                  if (state is SectionSchedulesLoaded) {
                    if (state.filteredSchedules.isEmpty) {
                      return const Center(child: Text('Chưa có lịch nào'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: state.filteredSchedules.length,
                      itemBuilder: (context, index) {
                        final schedule = state.filteredSchedules[index];
                        return _ScheduleCard(
                          schedule: schedule,
                          weekdayLabels: _weekdayLabels,
                          onEdit: () => _showScheduleForm(schedule),
                          onDelete: () => _confirmDelete(schedule),
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
                hintText: 'Tìm theo section, môn học hoặc phòng...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              onChanged: (query) {
                context.read<SectionScheduleBloc>().add(FilterSectionSchedules(query));
              },
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          ElevatedButton.icon(
            onPressed: () => _showScheduleForm(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final Map<int, String> weekdayLabels;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.weekdayLabels,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final day = weekdayLabels[_toInt(schedule['day_of_week'])] ?? 'Không rõ';
    final timeRange = '${_hhmm(schedule['start_time'])} - ${_hhmm(schedule['end_time'])}';
    final room = schedule['room_code'] ?? schedule['room_id'] ?? 'Chưa gán phòng';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.success,
          child: Icon(Icons.schedule, color: Colors.white),
        ),
        title: Text(
          schedule['section_code']?.toString() ?? 
          schedule['section_id']?.toString() ?? 
          'Section',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Môn học: ${schedule['subject_name'] ?? '-'}'),
            Text('$day · $timeRange'),
            Text('Phòng: $room'),
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

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _hhmm(dynamic time) {
    if (time == null) return '';
    final s = time.toString();
    if (s.length >= 5 && s.contains(':')) {
      return s.substring(0, 5);
    }
    return s;
  }
}

class _ScheduleFormDialog extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  final VoidCallback onSaved;

  const _ScheduleFormDialog({
    this.schedule,
    required this.onSaved,
  });

  @override
  State<_ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<_ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sectionIdController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _roomIdController = TextEditingController();
  int? _selectedWeekday;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      final schedule = widget.schedule!;
      _sectionIdController.text = schedule['section_id']?.toString() ?? '';
      _roomIdController.text = schedule['room_id']?.toString() ?? '';
      _startTimeController.text = _hhmm(schedule['start_time']);
      _endTimeController.text = _hhmm(schedule['end_time']);
      _selectedWeekday = _toInt(schedule['day_of_week']);
    }
  }

  @override
  void dispose() {
    _sectionIdController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final initial = _parseTime(controller.text) ?? const TimeOfDay(hour: 7, minute: 30);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'section_id': _sectionIdController.text.trim(),
      'day_of_week': _selectedWeekday,
      'start_time': _toServerTime(_startTimeController.text),
      'end_time': _toServerTime(_endTimeController.text),
    };

    if (_roomIdController.text.trim().isNotEmpty) {
      payload['room_id'] = _roomIdController.text.trim();
    }

    if (widget.schedule == null) {
      context.read<SectionScheduleBloc>().add(CreateSectionSchedule(payload));
    } else {
      final id = widget.schedule!['id']?.toString();
      if (id != null && id.isNotEmpty) {
        context.read<SectionScheduleBloc>().add(UpdateSectionSchedule(id, payload));
      }
    }

    Navigator.of(context).pop();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schedule == null ? 'Thêm lịch học' : 'Sửa lịch học'),
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
                  helperText: 'ID của class_section',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập Section ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Thứ trong tuần',
                  border: OutlineInputBorder(),
                ),
                value: _selectedWeekday,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Thứ 2')),
                  DropdownMenuItem(value: 2, child: Text('Thứ 3')),
                  DropdownMenuItem(value: 3, child: Text('Thứ 4')),
                  DropdownMenuItem(value: 4, child: Text('Thứ 5')),
                  DropdownMenuItem(value: 5, child: Text('Thứ 6')),
                  DropdownMenuItem(value: 6, child: Text('Thứ 7')),
                  DropdownMenuItem(value: 7, child: Text('Chủ nhật')),
                ],
                onChanged: (value) {
                  setState(() => _selectedWeekday = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn thứ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickTime(_startTimeController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ bắt đầu',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Chọn giờ bắt đầu';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickTime(_endTimeController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ kết thúc',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Chọn giờ kết thúc';
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

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _toServerTime(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.elementAt(0)) ?? 0;
    final minute = int.tryParse(parts.elementAt(1)) ?? 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  String _hhmm(dynamic time) {
    if (time == null) return '';
    final s = time.toString();
    if (s.length >= 5 && s.contains(':')) {
      return s.substring(0, 5);
    }
    return s;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
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

