import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_theme.dart';

class EditStudentPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const EditStudentPage({super.key, required this.student});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _mssvController;

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  bool _loading = false;
  bool _loadingClasses = false;
  String? _classError;
  Map<String, dynamic>? _mssvInfo;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadClasses();
  }

  void _initializeControllers() {
    _codeController = TextEditingController(text: widget.student['code'] ?? '');
    _nameController = TextEditingController(
      text: widget.student['full_name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.student['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.student['phone'] ?? '',
    );
    _mssvController = TextEditingController(text: widget.student['mssv'] ?? '');

    if (widget.student['mssv'] != null) {
      _onMssvChanged(widget.student['mssv']);
    }
  }

  Future<void> _loadClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final response = await Supabase.instance.client
          .from('classes')
          .select('id, name, code')
          .order('name');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        // Set selected class if exists
        _selectedClassId = widget.student['class_id'];
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa Sinh viên'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _updateStudent,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cập nhật', style: TextStyle(color: Colors.white)),
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
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã sinh viên *',
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

                TextFormField(
                  controller: _nameController,
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
                  controller: _mssvController,
                  decoration: const InputDecoration(
                    labelText: 'MSSV (10 chữ số)',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length != 10) {
                        return 'MSSV phải có đúng 10 chữ số';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'MSSV chỉ được chứa số';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),

                _loadingClasses
                    ? const Center(child: CircularProgressIndicator())
                    : _classError != null
                    ? Text(
                        _classError!,
                        style: const TextStyle(color: Colors.red),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Lớp học',
                          prefixIcon: Icon(Icons.class_),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Chọn lớp học'),
                          ),
                          ..._classes.map(
                            (cls) => DropdownMenuItem(
                              value: cls['id'],
                              child: Text(cls['name']),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedClassId = value);
                        },
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

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Update profile
      await Supabase.instance.client
          .from('profiles')
          .update({
            'code': _codeController.text.trim(),
            'full_name': _nameController.text.trim(),
            'email': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            'class_id': _selectedClassId,
          })
          .eq('id', widget.student['profile_id']);

      // 2. Update student record
      await Supabase.instance.client
          .from('students')
          .update({
            'class_id': _selectedClassId,
            'mssv': _mssvController.text.trim().isEmpty
                ? null
                : _mssvController.text.trim(),
            'mssv_cohort': _mssvInfo?['cohort'],
            'mssv_track_code': _mssvInfo?['track_code'],
            'mssv_serial': _mssvInfo?['serial'],
          })
          .eq('profile_id', widget.student['profile_id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật sinh viên thành công')),
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

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _mssvController.dispose();
    super.dispose();
  }
}
