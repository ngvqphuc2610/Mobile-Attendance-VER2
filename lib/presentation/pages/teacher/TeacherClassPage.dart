import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../data/services/auth_service.dart';
import '../../../presentation/bloc/teaching_assignment/teaching_assignment_bloc.dart';
import '../../../presentation/bloc/teaching_assignment/teaching_assignment_event.dart';
import '../../../presentation/bloc/teaching_assignment/teaching_assignment_state.dart';
import 'TeacherSectionSessionsPage.dart';


class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String? _currentTeacherId;

  @override
  void initState() {
    super.initState();
    _loadCurrentTeacher();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTeacher() async {
    try {
      // Lấy thông tin user hiện tại từ AuthService
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _currentTeacherId = currentUser.id;
        });
      }
    } catch (e) {
      debugPrint('Error loading current teacher: $e');
    }
  }

  void _reload(BuildContext context) {
    if (_currentTeacherId != null) {
      context.read<TeachingAssignmentBloc>().add(
        LoadTeachingAssignments(teacherId: _currentTeacherId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeachingAssignmentBloc>(
      create: (_) {
        final bloc = sl<TeachingAssignmentBloc>();
        // Load ngay khi khởi tạo với teacherId
        if (_currentTeacherId != null) {
          bloc.add(LoadTeachingAssignments(teacherId: _currentTeacherId));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Lớp đang dạy'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: () => _reload(context),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _currentTeacherId == null
            ? const _LoadingTeacherInfo()
            : Column(
                children: [
                  _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: BlocBuilder<TeachingAssignmentBloc, TeachingAssignmentState>(
                      builder: (context, state) {
                        if (state is TeachingAssignmentLoading) {
                          return const _CenteredLoading();
                        }

                        if (state is TeachingAssignmentError) {
                          return _ErrorView(
                            message: state.message,
                            onRetry: () => _reload(context),
                          );
                        }

                        if (state is TeachingAssignmentsLoaded) {
                          final items = state.assignments;
                          final filtered = _filter(items, _query);

                          if (filtered.isEmpty) {
                            return _EmptyView(
                              title: _query.isEmpty
                                  ? 'Chưa có lớp nào'
                                  : 'Không có lớp phù hợp',
                              subtitle: _query.isEmpty
                                  ? 'Bạn chưa được phân công dạy lớp nào trong kỳ này.'
                                  : 'Hãy thử từ khóa khác hoặc làm mới dữ liệu.',
                              icon: Icons.school_outlined,
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async => _reload(context),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final m = filtered[index];
                                return _ClassCard(
                                  data: m,
                                  onTap: () {
                                    final sectionId = (m['section_id'] ?? '')
                                        .toString();
                                    final sectionCode =
                                        (m['section_code'] ?? '').toString();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TeacherSectionSessionsPage(
                                              sectionId: sectionId,
                                              sectionCode: sectionCode.isEmpty
                                                  ? null
                                                  : sectionCode,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        }

                        // State khởi tạo
                        return const _EmptyView(
                          title: 'Chưa có dữ liệu',
                          subtitle: 'Kéo xuống để tải hoặc nhấn nút làm mới.',
                          icon: Icons.class_outlined,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> items,
    String q,
  ) {
    if (q.isEmpty) return items;
    final query = q.toLowerCase();
    return items.where((m) {
      bool match(String key) =>
          (m[key] ?? '').toString().toLowerCase().contains(query);
      return match('subject_code') ||
          match('subject_name') ||
          match('section_code') ||
          match('role') ||
          match('year') ||
          match('semester');
    }).toList();
  }
}

// ==================== Widgets ====================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Tìm theo mã môn, tên môn, mã lớp phần…',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ClassCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sectionCode = (data['section_code'] ?? '').toString();
    final year = (data['year'] ?? '').toString();
    final semester = (data['semester'] ?? '').toString();
    final subCode = (data['subject_code'] ?? '').toString();
    final subName = (data['subject_name'] ?? '').toString();
    final role = (data['role'] ?? '').toString();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon môn học
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    subCode.isEmpty ? '?' : subCode[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subName.isEmpty ? subCode : subName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subCode,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _InfoChip(
                          icon: Icons.class_outlined,
                          label: sectionCode,
                        ),
                        _InfoChip(
                          icon: Icons.calendar_today,
                          label: 'Năm $year',
                        ),
                        _InfoChip(
                          icon: Icons.bookmark_outline,
                          label: 'Kỳ $semester',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRoleColor(role).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    color: _getRoleColor(role),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'main':
      case 'chính':
        return Colors.blue;
      case 'assistant':
      case 'phụ':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LoadingTeacherInfo extends StatelessWidget {
  const _LoadingTeacherInfo();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Đang tải thông tin giáo viên...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CenteredLoading extends StatelessWidget {
  const _CenteredLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const _EmptyView({
    required this.title,
    this.subtitle,
    this.icon = Icons.class_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
