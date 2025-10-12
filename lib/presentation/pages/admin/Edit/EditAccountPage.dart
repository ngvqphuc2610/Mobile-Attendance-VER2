import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/account_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAccountPage extends StatefulWidget {
  final Map<String, dynamic> account;
  
  const EditAccountPage({super.key, required this.account});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountService = AccountService();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mssvController = TextEditingController();
  final _titleController = TextEditingController();
  final _officeController = TextEditingController();
  
  String _selectedRole = 'student';
  String? _selectedClassId;
  String? _selectedFacultyId;
  
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _faculties = [];
  bool _loading = false;
  bool _saving = false;
  bool _resetPassword = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _populateFields();
  }

  void _populateFields() {
    final account = widget.account;
    
    _emailController.text = account['email'] ?? '';
    _fullNameController.text = account['full_name'] ?? '';
    _codeController.text = account['code'] ?? '';
    _phoneController.text = account['phone'] ?? '';
    
    // Get role
    final userRoles = account['user_roles'] as List?;
    if (userRoles != null && userRoles.isNotEmpty) {
      _selectedRole = userRoles.first['role'] ?? 'student';
    }
    
    // Student data
    final students = account['students'] as List?;
    if (students != null && students.isNotEmpty) {
      final student = students.first;
      _mssvController.text = student['mssv'] ?? '';
      _selectedClassId = student['class_id'];
    }
    
    // Teacher data
    final teachers = account['teachers'] as List?;
    if (teachers != null && teachers.isNotEmpty) {
      final teacher = teachers.first;
      _titleController.text = teacher['title'] ?? '';
      _officeController.text = teacher['office'] ?? '';
      _selectedFacultyId = teacher['faculty_id'];
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      // Load classes and faculties
      final classesResponse = await supabase
          .from('classes')
          .select('id, name, code')
          .order('name');
      
      final facultiesResponse = await supabase
          .from('faculties')
          .select('id, name, code')
          .order('name');
      
      setState(() {
        _classes = List<Map<String, dynamic>>.from(classesResponse);
        _faculties = List<Map<String, dynamic>>.from(facultiesResponse);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa Tài khoản'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveAccount,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Role selection
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Vai trò *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                          DropdownMenuItem(value: 'teacher', child: Text('Giáo viên')),
                          DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                            if (value != 'student') _selectedClassId = null;
                            if (value != 'teacher') _selectedFacultyId = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),

                      // Basic info
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),

                      // Password reset
                      CheckboxListTile(
                        title: const Text('Reset mật khẩu'),
                        subtitle: const Text('Đặt lại mật khẩu cho tài khoản này'),
                        value: _resetPassword,
                        onChanged: (value) {
                          setState(() => _resetPassword = value ?? false);
                        },
                      ),
                      
                      if (_resetPassword) ...[
                        const SizedBox(height: AppSizes.paddingMedium),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu mới *',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (_resetPassword && (value == null || value.length < 6)) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: AppSizes.paddingMedium),

                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ tên *',
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

                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: _selectedRole == 'student' ? 'Mã sinh viên *' : 'Mã nhân viên *',
                          prefixIcon: const Icon(Icons.badge),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mã';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),

                      // Role-specific fields
                      if (_selectedRole == 'student') ...[
                        TextFormField(
                          controller: _mssvController,
                          decoration: const InputDecoration(
                            labelText: 'MSSV',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        
                        DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Lớp học',
                            prefixIcon: Icon(Icons.class_),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Chọn lớp')),
                            ..._classes.map((cls) => DropdownMenuItem(
                              value: cls['id'],
                              child: Text('${cls['code']} - ${cls['name']}'),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedClassId = value),
                        ),
                      ],

                      if (_selectedRole == 'teacher') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedFacultyId,
                          decoration: const InputDecoration(
                            labelText: 'Khoa',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Chọn khoa')),
                            ..._faculties.map((faculty) => DropdownMenuItem(
                              value: faculty['id'],
                              child: Text('${faculty['code']} - ${faculty['name']}'),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedFacultyId = value),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Chức danh',
                            prefixIcon: Icon(Icons.work),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        
                        TextFormField(
                          controller: _officeController,
                          decoration: const InputDecoration(
                            labelText: 'Phòng làm việc',
                            prefixIcon: Icon(Icons.room),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

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

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _accountService.updateAccount(
        userId: widget.account['id'],
        email: _emailController.text.trim(),
        password: _resetPassword ? _passwordController.text : null,
        fullName: _fullNameController.text.trim(),
        code: _codeController.text.trim(),
        role: _selectedRole,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        classId: _selectedClassId,
        mssv: _mssvController.text.trim().isEmpty ? null : _mssvController.text.trim(),
        facultyId: _selectedFacultyId,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        office: _officeController.text.trim().isEmpty ? null : _officeController.text.trim(),
        resetPassword: _resetPassword,
        newEmail: _emailController.text.trim() != widget.account['email'] 
            ? _emailController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật tài khoản thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _mssvController.dispose();
    _titleController.dispose();
    _officeController.dispose();
    super.dispose();
  }
}
