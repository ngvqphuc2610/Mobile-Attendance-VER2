import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../data/models/entity/student_schedule_entity.dart';
import '../../../data/repositories/student_schedule_repository.dart';
import '../../bloc/studentschedule/student_schedule_bloc.dart';
import '../../bloc/studentschedule/student_schedule_event.dart';
import '../../bloc/studentschedule/student_schedule_state.dart';
import 'StudentDetailSchedulePage.dart';

enum _ScheduleFilterMode { week, semester }

class StudentSchedulePage extends StatefulWidget {
  final String studentId;

  const StudentSchedulePage({super.key, required this.studentId});

  @override
  StudentSchedulePageState createState() => StudentSchedulePageState();
}

class StudentSchedulePageState extends State<StudentSchedulePage> {
  late final StudentScheduleBloc _bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi');
    _bloc = StudentScheduleBloc(
      repository: StudentScheduleRepository(),
    )..add(LoadStudentSchedules(studentId: widget.studentId));
  }

  void refresh() {
    _bloc.add(LoadStudentSchedules(studentId: widget.studentId));
  }

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(StudentSchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      refresh();
    }
  }

  @override
  void dispose() {
    _bloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentScheduleBloc>.value(
      value: _bloc,
      child: _StudentScheduleView(
        studentId: widget.studentId,
        scrollController: _scrollController,
        onRefreshRequested: refresh,
      ),
    );
  }
}

class _StudentScheduleView extends StatefulWidget {
  final String studentId;
  final ScrollController scrollController;
  final VoidCallback onRefreshRequested;

  const _StudentScheduleView({
    required this.studentId,
    required this.scrollController,
    required this.onRefreshRequested,
  });

  @override
  State<_StudentScheduleView> createState() => _StudentScheduleViewState();
}

class _StudentScheduleViewState extends State<_StudentScheduleView> {
  static const Map<int, String> _weekdayLabels = {
    DateTime.monday: 'Thứ 2',
    DateTime.tuesday: 'Thứ 3', 
    DateTime.wednesday: 'Thứ 4',
    DateTime.thursday: 'Thứ 5',
    DateTime.friday: 'Thứ 6',
    DateTime.saturday: 'Thứ 7',
    DateTime.sunday: 'Chủ nhật',
  };

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  _ScheduleFilterMode _mode = _ScheduleFilterMode.week;
  late DateTime _currentWeekStart;
  List<_SemesterOption> _semesterOptions = [];
  _SemesterOption? _selectedSemester;
  List<StudentScheduleEntity>? _lastSchedulesRef;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _startOfWeek(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thoi khoa bieu'),
      ),
      body: BlocConsumer<StudentScheduleBloc, StudentScheduleState>(
        listener: _handleStateChange,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeSelector(),
                const SizedBox(height: 12),
                if (_mode == _ScheduleFilterMode.week)
                  _buildWeekHeader()
                else
                  _buildSemesterHeader(),
                const SizedBox(height: 12),
                Expanded(child: _buildContent(state)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleStateChange(
    BuildContext context,
    StudentScheduleState state,
  ) {
    if (state is StudentSchedulesLoaded) {
      // ✅ Chỉ update semester options khi có data mới
      if (!identical(_lastSchedulesRef, state.schedules)) {
        _lastSchedulesRef = state.schedules;
        _updateSemesterOptions(state.schedules);
      }
      // ✅ KHÔNG gọi _applyFilters ở đây nữa
      // Vì BLoC đã filter data rồi khi load
    }
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('Tuan'),
          selected: _mode == _ScheduleFilterMode.week,
          onSelected: (selected) {
            if (!selected) return;
            setState(() => _mode = _ScheduleFilterMode.week);
            _applyFilters();
          },
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('Hoc ky'),
          selected: _mode == _ScheduleFilterMode.semester,
          onSelected: (selected) {
            if (!selected) return;
            setState(() => _mode = _ScheduleFilterMode.semester);
            _applyFilters();
          },
        ),
      ],
    );
  }

  Widget _buildWeekHeader() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final rangeText =
        '${_dateFormat.format(_currentWeekStart)} den ${_dateFormat.format(weekEnd)}';

    return Row(
      children: [
        const Text(
          'Lich trong tuan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Tuan truoc',
          onPressed: () => _changeWeek(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Tuan sau',
          onPressed: () => _changeWeek(1),
          icon: const Icon(Icons.chevron_right),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Tai lai',
          onPressed: _onRefreshPressed,
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 4),
        Text(rangeText, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSemesterHeader() {
    if (_semesterOptions.isEmpty) {
      return Row(
        children: [
          const Text(
            'Hoc ky',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Text(
            'Khong co du lieu hoc ky',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Text(
          'Hoc ky',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        DropdownButton<_SemesterOption>(
          value: _selectedSemester,
          items: _semesterOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedSemester = value);
            _applyFilters();
          },
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Tai lai',
          onPressed: _onRefreshPressed,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildContent(StudentScheduleState state) {
    if (state is StudentScheduleLoading || state is StudentScheduleInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is StudentScheduleError) {
      return _ErrorView(
        message: state.message,
        onRetry: _onRefreshPressed,
      );
    }

    if (state is! StudentSchedulesLoaded) {
      return const SizedBox.shrink();
    }

    final filtered = state.filteredSchedules;
    if (filtered.isEmpty) {
      return const _EmptyView();
    }

    final sections = _groupByDay(filtered);
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final entry = sections[index];
        return _DaySection(
          weekday: entry.key,
          schedules: entry.value,
          weekdayLabels: _weekdayLabels,
          dateFormat: _dateFormat,
          currentWeekStart: _currentWeekStart,
          onTapSchedule: (schedule) => _openDetail(context, schedule),
        );
      },
    );
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentWeekStart = _startOfWeek(
        _currentWeekStart.add(Duration(days: 7 * delta)),
      );
    });
    _applyFilters();
  }

  // ✅ Handler riêng cho nút refresh
  void _onRefreshPressed() {
    // Load lại data từ server với filter hiện tại
    _applyFilters();
  }

  // ✅ Simplified _applyFilters - LUÔN load từ remote
  void _applyFilters() {
    final bloc = context.read<StudentScheduleBloc>();

    if (_mode == _ScheduleFilterMode.week) {
      final from = _currentWeekStart;
      final to = _currentWeekStart.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      // ✅ LUÔN load từ remote để đảm bảo data mới nhất
      bloc.add(
        LoadStudentSchedules(
          studentId: widget.studentId,
          from: from,
          to: to,
        ),
      );
    } else {
      final opt = _selectedSemester;
      
      // ✅ LUÔN load từ remote để đảm bảo data mới nhất
      bloc.add(
        LoadStudentSchedules(
          studentId: widget.studentId,
          semester: opt?.semester,
          year: opt?.year,
        ),
      );
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final delta = date.weekday - DateTime.monday;
    return DateTime(
      date.year,
      date.month,
      date.day - (delta < 0 ? 0 : delta),
    );
  }

  void _updateSemesterOptions(List<StudentScheduleEntity> schedules) {
    final map = <String, _SemesterOption>{};
    for (final schedule in schedules) {
      final sem = schedule.semester;
      final year = schedule.year;
      if (sem != null && year != null) {
        final key = '$year-$sem';
        map.putIfAbsent(key, () => _SemesterOption(semester: sem, year: year));
      }
    }
    final options = map.values.toList()
      ..sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        return yearCompare != 0 ? yearCompare : b.semester.compareTo(a.semester);
      });

    setState(() {
      _semesterOptions = options;
      if (options.isEmpty) {
        _selectedSemester = null;
      } else if (_selectedSemester == null) {
        _selectedSemester = options.first;
      } else if (!options.contains(_selectedSemester)) {
        _selectedSemester = options.first;
      }
    });
  }

  List<MapEntry<int, List<StudentScheduleEntity>>> _groupByDay(
    List<StudentScheduleEntity> schedules,
  ) {
    final map = <int, List<StudentScheduleEntity>>{};
    for (final schedule in schedules) {
      // Sử dụng dayOfWeek từ startsAt nếu có, không thì dùng dayOfWeek field
      int dayOfWeek = schedule.dayOfWeek;
      if (schedule.startsAt != null) {
        dayOfWeek = schedule.startsAt!.weekday;
      }
      map.putIfAbsent(dayOfWeek, () => []).add(schedule);
    }
    
    for (final list in map.values) {
      list.sort((a, b) {
        final aTime = a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });
    }
    
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  void _openDetail(BuildContext context, StudentScheduleEntity schedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<StudentScheduleBloc>(),
          child: StudentDetailSchedulePage(
            scheduleId: schedule.id,
          ),
        ),
      ),
    );
  }
}

class _SemesterOption {
  final int semester;
  final int year;

  const _SemesterOption({required this.semester, required this.year});

  String get label => 'HK $semester - $year';

  @override
  bool operator ==(Object other) {
    return other is _SemesterOption &&
        other.semester == semester &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(semester, year);
}

class _DaySection extends StatelessWidget {
  final int weekday;
  final List<StudentScheduleEntity> schedules;
  final Map<int, String> weekdayLabels;
  final DateFormat dateFormat;
  final DateTime currentWeekStart;
  final ValueChanged<StudentScheduleEntity> onTapSchedule;

  const _DaySection({
    required this.weekday,
    required this.schedules,
    required this.weekdayLabels,
    required this.dateFormat,
    required this.currentWeekStart,
    required this.onTapSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final headerLabel = weekdayLabels[weekday] ?? 'Ngày $weekday';
    
    // Sử dụng ngày thực tế từ schedule thay vì tính từ currentWeekStart
    String formattedDate = '';
    if (schedules.isNotEmpty) {
      final firstSchedule = schedules.first;
      if (firstSchedule.startsAt != null) {
        // Sử dụng ngày thực tế từ startsAt
        formattedDate = dateFormat.format(firstSchedule.startsAt!);
      } else {
        // Fallback: tính từ currentWeekStart
        final dayOffset = weekday - DateTime.monday;
        final displayDate = currentWeekStart.add(Duration(days: dayOffset));
        formattedDate = dateFormat.format(displayDate);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate.isNotEmpty 
                ? '$headerLabel, $formattedDate'
                : headerLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...schedules.map(
            (schedule) => _ScheduleCard(
              schedule: schedule,
              onTap: () => onTapSchedule(schedule),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final StudentScheduleEntity schedule;
  final VoidCallback onTap;

  const _ScheduleCard({
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tạo title giống như trong detail page
    final subjectLine = [
      schedule.subjectCode,
      schedule.subjectName,
    ].where((e) => e != null && e!.isNotEmpty).join(', ');
    
    final code = schedule.sectionCode ?? '';
    final slot = _buildSlot(schedule);
    final room = schedule.roomName ?? schedule.roomCode ?? 'Đang cập nhật';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị section code làm header
              if (code.isNotEmpty) ...[
                Text(
                  code,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
              ],
              // Hiển thị subject code + name làm title chính
              Text(
                subjectLine.isNotEmpty ? subjectLine : 'Lịch học',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(slot),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.room, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(room),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _buildSlot(StudentScheduleEntity schedule) {
    if (schedule.startsAt != null && schedule.endsAt != null) {
      final start = DateFormat('HH:mm').format(schedule.startsAt!);
      final end = DateFormat('HH:mm').format(schedule.endsAt!);
      return '$start - $end';
    }
    return '${_trimTime(schedule.startTime)} - ${_trimTime(schedule.endTime)}';
  }

  static String _trimTime(String raw) {
    if (raw.isEmpty) return raw;
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Khong co lich hoc nao',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Hay kiem tra lai hoac lien he phong dao tao.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Khong tai duoc thoi khoa bieu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thu lai'),
          ),
        ],
      ),
    );
  }
}