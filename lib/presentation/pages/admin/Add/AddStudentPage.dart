import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
// Using ApiService directly for CRUD operations

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mssvController = TextEditingController();

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _faculties = [];
  String? _selectedFacultyId;
  String? _selectedClassId;
  bool _loading = false;
  bool _loadingClasses = false;
  bool _loadingFalculties = false;
  String? _classError;
  String? _facultyError;
  Map<String, dynamic>? _mssvInfo;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    setState(() => _loadingFalculties = true);
    try {
      final response = await ApiService.getList(ApiConstants.faculties);
      setState(() {
        _faculties = List<Map<String, dynamic>>.from(response);
        _facultyError = null;
      });
    } catch (e) {
      setState(() {
        _facultyError = 'Lỗi tải danh sách khoa: $e';
      });
    } finally {
      setState(() => _loadingFalculties = false);
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedFacultyId == null) {
      setState(() {
        _classes = [];
        _classError = null;
      });
      return;
    }

    setState(() => _loadingClasses = true);
    try {
      final response = await ApiService.getList(
        ApiConstants.classes,
        queryParams: {'faculty_id': _selectedFacultyId!},
      );

      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        _classError = null;
      });
    } catch (e) {
      setState(() {
        _classError = 'Lỗi tải danh sách lớp: $e';
      });
    } finally {
      setState(() => _loadingClasses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Sinh viên'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveStudent,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Mã SV
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã sinh viên *',
                    hintText: 'VD: SV001',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã sinh viên';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: AppSizes.paddingMedium),

                // Họ tên
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên *',
                    hintText: 'VD: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSizes.paddingMedium),

                // MSSV (tùy chọn)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _mssvController,
                      decoration: const InputDecoration(
                        labelText: 'MSSV (10 chữ số)',
                        hintText: 'VD: 2180123456',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      onChanged: _onMssvChanged,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 10)
                            return 'MSSV phải có đúng 10 chữ số';
                          if (!RegExp(r'^\d+$').hasMatch(value))
                            return 'MSSV chỉ được chứa số';
                        }
                        return null;
                      },
                    ),
                    if (_mssvInfo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin từ MSSV:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Khóa: ${_mssvInfo!['cohort']}'),
                            Text('Mã hệ: ${_mssvInfo!['track_code']}'),
                            if (_mssvInfo!['program_track'] != null)
                              Text(
                                'Hệ đào tạo: ${_mssvInfo!['program_track']}',
                              ),
                            Text('Số thứ tự: ${_mssvInfo!['serial']}'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMedium),

                // Dropdown khoa
                if (_loadingFalculties)
                  const Center(child: CircularProgressIndicator())
                else if (_facultyError != null)
                  Column(
                    children: [
                      Text(
                        _facultyError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _loadFaculties,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tải lại danh sách khoa'),
                      ),
                    ],
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedFacultyId,
                    decoration: const InputDecoration(
                      labelText: 'Khoa *',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ..._faculties.map(
                        (faculty) => DropdownMenuItem(
                          value: faculty['id'],
                          child: Text(faculty['name']),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFacultyId = value;
                        _selectedClassId = null; // Reset selected class
                      });
                      _loadClasses(); // Load classes for selected faculty
                    },
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn khoa' : null,
                  ),

                // Dropdown lớp
                if (_loadingClasses)
                  const Center(child: CircularProgressIndicator())
                else if (_classError != null)
                  Column(
                    children: [
                      Text(
                        _classError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _loadClasses,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tải lại danh sách lớp'),
                      ),
                    ],
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Lớp học *',
                      prefixIcon: Icon(Icons.class_),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ..._classes.map(
                        (cls) => DropdownMenuItem(
                          value: cls['id'],
                          child: Text(cls['name']),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedClassId = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn lớp' : null,
                  ),

                const SizedBox(height: AppSizes.paddingLarge),
                const Text(
                  '* Trường bắt buộc',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Create profile via API
      final profileResponse = await ApiService.create('/profiles', {
        'code': _codeController.text.trim(),
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'class_id': _selectedClassId,
        'is_active': true,
      });

      final profileId = profileResponse['id'].toString();

      // 2. Create student record
      await ApiService.create(ApiConstants.students, {
        'profile_id': profileId,
        'class_id': _selectedClassId,
        'mssv': _mssvController.text.trim().isEmpty
            ? null
            : _mssvController.text.trim(),
        'mssv_cohort': _mssvInfo?['cohort'],
        'mssv_track_code': _mssvInfo?['track_code'],
        'mssv_serial': _mssvInfo?['serial'],
      });

      // 3. Create user role
      await ApiService.create('/user_roles', {
        'user_id': profileId,
        'role': 'student',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm sinh viên thành công')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onMssvChanged(String value) {
    if (value.length == 10 && RegExp(r'^\d+$').hasMatch(value)) {
      setState(() {
        _mssvInfo = _parseMssv(value);
      });
    } else {
      setState(() {
        _mssvInfo = null;
      });
    }
  }

  Map<String, dynamic> _parseMssv(String mssv) {
    final cohort = 2000 + int.parse(mssv.substring(0, 2));
    final trackCode = mssv.substring(2, 6);
    final serial = int.parse(mssv.substring(6, 10));

    String? programTrack;
    switch (trackCode) {
      case '8060':
        programTrack = 'Đại trà';
        break;
      case '8080':
        programTrack = 'Chất lượng cao (CLC)';
        break;
      case '8090':
        programTrack = 'Việt-Nhật';
        break;
      case '8070':
        programTrack = 'Việt-Hàn';
        break;
    }

    return {
      'cohort': cohort,
      'track_code': trackCode,
      'program_track': programTrack,
      'serial': serial,
    };
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _mssvController.dispose();
    super.dispose();
  }
}
