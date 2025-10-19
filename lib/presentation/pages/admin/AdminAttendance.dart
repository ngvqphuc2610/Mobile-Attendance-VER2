import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/attendance_entity.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../../bloc/attendance/attendance_event.dart';
import '../../bloc/attendance/attendance_state.dart';
import '../../widgets/loading_widget.dart';

class AdminAttendance extends StatefulWidget {
  const AdminAttendance({super.key});

  @override
  State<AdminAttendance> createState() => _AdminAttendanceState();
}

class _AdminAttendanceState extends State<AdminAttendance> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  AttendanceMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(const LoadAttendances());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadAttendances();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadAttendances();
  }

  void _loadAttendances() {
    context.read<AttendanceBloc>().add(LoadAttendances(
      fromDate: _fromDate,
      toDate: _toDate,
      method: _selectedMethod,
    ));
  }

  void _showStatsDialog() {
    context.read<AttendanceBloc>().add(LoadAttendanceStats(
      fromDate: _fromDate,
      toDate: _toDate,
    ));

    showDialog(
      context: context,
      builder: (context) => BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (state is AttendanceStatsLoaded) {
            return AlertDialog(
              title: const Text('Thống kê điểm danh'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.stats['total'] != null)
                    Text('Tổng số lượt: ${state.stats['total']}'),
                  const SizedBox(height: 8),
                  if (state.stats['by_method'] != null)
                    ...((state.stats['by_method'] as Map).entries.map((entry) =>
                        Text('${entry.key}: ${entry.value}'))),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Không thể tải thống kê'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý điểm danh'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showStatsDialog,
            icon: const Icon(Icons.analytics),
            tooltip: 'Thống kê',
          ),
        ],
      ),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AttendanceOperationSuccess) {
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
            _buildFilters(),
            Expanded(
              child: BlocBuilder<AttendanceBloc, AttendanceState>(
                builder: (context, state) {
                  if (state is AttendanceLoading) {
                    return const LoadingWidget(message: 'Đang tải điểm danh...');
                  }

                  if (state is AttendanceError) {
                    return _ErrorRetry(
                      message: state.message,
                      onRetry: () {
                        context.read<AttendanceBloc>().add(const LoadAttendances());
                      },
                    );
                  }

                  if (state is AttendancesLoaded) {
                    if (state.filteredAttendances.isEmpty) {
                      return const Center(
                        child: Text('Chưa có dữ liệu điểm danh'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: state.filteredAttendances.length,
                      itemBuilder: (context, index) {
                        final attendance = state.filteredAttendances[index];
                        return _AttendanceCard(attendance: attendance);
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Tìm theo tên, mã sinh viên...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                  ),
                  onChanged: (query) {
                    context.read<AttendanceBloc>().add(FilterAttendances(query));
                  },
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              ElevatedButton.icon(
                onPressed: _showDateRangePicker,
                icon: const Icon(Icons.date_range),
                label: const Text('Chọn ngày'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AttendanceMethod>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Phương thức',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<AttendanceMethod>(
                      value: null,
                      child: Text('Tất cả'),
                    ),
                    ...AttendanceMethod.values.map((method) =>
                        DropdownMenuItem<AttendanceMethod>(
                          value: method,
                          child: Text(_getMethodDisplayName(method)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value;
                    });
                    _loadAttendances();
                  },
                ),
              ),
              if (_fromDate != null && _toDate != null) ...[
                const SizedBox(width: AppSizes.paddingSmall),
                ElevatedButton(
                  onPressed: _clearDateFilter,
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ],
          ),
          if (_fromDate != null && _toDate != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.paddingSmall),
              child: Text(
                'Từ ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year} '
                'đến ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  String _getMethodDisplayName(AttendanceMethod method) {
    switch (method) {
      case AttendanceMethod.face:
        return 'Nhận diện khuôn mặt';
      case AttendanceMethod.barcode:
        return 'Mã vạch';
      case AttendanceMethod.manual:
        return 'Thủ công';
    }
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceEntity attendance;

  const _AttendanceCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMethodColor(attendance.method),
          child: Icon(
            _getMethodIcon(attendance.method),
            color: Colors.white,
          ),
        ),
        title: Text(
          attendance.profile?.fullName ?? 'Không xác định',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attendance.profile?.code != null)
              Text('MSSV: ${attendance.profile!.code}'),
            Text('Phương thức: ${_getMethodDisplayName(attendance.method)}'),
            Text('Thời gian: ${_formatDateTime(attendance.atTime)}'),
            if (attendance.confidenceScore != null)
              Text('Độ tin cậy: ${(attendance.confidenceScore! * 100).toStringAsFixed(1)}%'),
            if (attendance.note != null)
              Text('Ghi chú: ${attendance.note}'),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(AttendanceMethod method) {
    switch (method) {
      case AttendanceMethod.face:
        return Colors.blue;
      case AttendanceMethod.barcode:
        return Colors.green;
      case AttendanceMethod.manual:
        return Colors.orange;
    }
  }

  IconData _getMethodIcon(AttendanceMethod method) {
    switch (method) {
      case AttendanceMethod.face:
        return Icons.face;
      case AttendanceMethod.barcode:
        return Icons.qr_code;
      case AttendanceMethod.manual:
        return Icons.edit;
    }
  }

  String _getMethodDisplayName(AttendanceMethod method) {
    switch (method) {
      case AttendanceMethod.face:
        return 'Nhận diện khuôn mặt';
      case AttendanceMethod.barcode:
        return 'Mã vạch';
      case AttendanceMethod.manual:
        return 'Thủ công';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({
    required this.message,
    required this.onRetry,
  });

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