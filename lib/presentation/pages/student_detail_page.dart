import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../widgets/loading_widget.dart';
import 'face_register_page.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  Map<String, dynamic>? student;
  String? className;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchStudent();
  }

  Future<void> _fetchStudent() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Get student details
      final response = await ApiService.get(
        '${ApiConstants.students}/${widget.studentId}',
      );
      student = response;

      // Get class name if available
      if (student!['class_id'] != null) {
        try {
          final classRes = await ApiService.get(
            '${ApiConstants.classes}/${student!['class_id']}',
          );
          className = classRes['name'] ?? 'Chưa có lớp';
        } catch (e) {
          className = 'Chưa có lớp';
        }
      } else {
        className = 'Chưa có lớp';
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sinh viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showComingSoonDialog(context);
            },
          ),
        ],
      ),
      body: loading
          ? const LoadingWidget(message: 'Đang tải thông tin...')
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          : Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              student?['full_name']?.isNotEmpty == true
                                  ? student!['full_name'][0].toUpperCase()
                                  : 'SV',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),
                          _buildInfoRow(
                            context,
                            'Tên sinh viên:',
                            student?['full_name'] ?? '',
                          ),
                          _buildInfoRow(
                            context,
                            'Mã sinh viên:',
                            student?['code'] ?? '',
                          ),
                          _buildInfoRow(
                            context,
                            'MSSV:',
                            student?['mssv'] ?? 'Chưa có',
                          ),
                          _buildInfoRow(context, 'Lớp học:', className ?? ''),
                          _buildInfoRow(
                            context,
                            'Email:',
                            student?['email'] ?? '',
                          ),
                          _buildInfoRow(
                            context,
                            'Số điện thoại:',
                            student?['phone'] ?? 'Chưa có',
                          ),
                          _buildInfoRow(
                            context,
                            'Trạng thái:',
                            (student?['is_active'] ?? true)
                                ? 'Hoạt động'
                                : 'Không hoạt động',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FaceRegisterPage(
                                  studentId:
                                      student?['profile_id'] ??
                                      widget.studentId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.face),
                          label: const Text('Đăng ký khuôn mặt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.faceColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showComingSoonDialog(context);
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Lịch sử điểm danh'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sắp ra mắt'),
          content: const Text(
            'Tính năng này sẽ được phát triển trong phiên bản tiếp theo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
