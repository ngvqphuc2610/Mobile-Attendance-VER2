import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class EditClassSectionPage extends StatefulWidget {
  final Map<String, dynamic> classSection;

  const EditClassSectionPage({super.key, required this.classSection});

  @override
  State<EditClassSectionPage> createState() => _EditClassSectionPageState();
}

class _EditClassSectionPageState extends State<EditClassSectionPage> {
  final _formKey = GlobalKey<FormState>();

  final _semesterController = TextEditingController();
  final _yearController = TextEditingController();
  final _sectionCodeController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _saving = false;

  // Subjects dropdown
  bool _loadingSubjects = false;
  String? _subjectError;
  List<Map<String, String>> _subjects = []; // mỗi item: {'id': '...', 'label': '...'}
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();

    // Bind dữ liệu cũ vào form
    _selectedSubjectId = widget.classSection['subject_id']?.toString()
        ?? widget.classSection['subjectId']?.toString();

    _semesterController.text =
        (widget.classSection['semester'] ?? '').toString();
    _yearController.text =
        (widget.classSection['year'] ?? '').toString();

    _sectionCodeController.text =
        (widget.classSection['section_code'] ??
         widget.classSection['sectionCode'] ??
         '')
            .toString();

    _capacityController.text =
        (widget.classSection['capacity'] ?? '').toString();

    // Tải danh sách môn học, giữ selection nếu có
    _fetchSubjects();
  }

  @override
  void dispose() {
    _semesterController.dispose();
    _yearController.dispose();
    _sectionCodeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // ---------------- Fetch & helpers ----------------

  Future<void> _fetchSubjects() async {
    if (!mounted) return;
    setState(() {
      _loadingSubjects = true;
      _subjectError = null;
    });

    try {
      final resp = await ApiService.getList(ApiConstants.subjects);
      final list = _unwrapList(resp);

      final items = <Map<String, String>>[];
      for (final e in list) {
        if (e is! Map) continue;
        final id = _extractId(e, ['id', 'subjectId', 'subject_id']);
        if (id.isEmpty) continue;

        // Hiển thị đẹp: ưu tiên name; fallback code
        final name = _extractFirstNonEmpty(e, ['name', 'code']);
        items.add({'id': id, 'label': name.isNotEmpty ? name : 'Môn $id'});
      }

      if (!mounted) return;
      setState(() {
        _subjects = items;

        // Giữ selection cũ nếu còn tồn tại, nếu không, chọn phần tử đầu
        if (_subjects.any((s) => s['id'] == _selectedSubjectId) == false) {
          _selectedSubjectId = _subjects.isNotEmpty ? _subjects.first['id'] : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subjectError = 'Lỗi tải môn học: $e';
        _subjects = [];
        _selectedSubjectId = null;
      });
    } finally {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  List<dynamic> _unwrapList(dynamic resp) {
    if (resp == null) return [];
    if (resp is List) return resp;
    if (resp is Map) {
      // các trường hay gặp: data / items / results
      for (final key in ['data', 'items', 'results']) {
        final v = resp[key];
        if (v is List) return v;
      }
    }
    return [];
  }

  String _extractId(Map m, List<String> candidates) {
    for (final k in candidates) {
      final v = m[k];
      if (v != null) return v.toString();
    }
    return '';
  }

  String _extractFirstNonEmpty(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return '';
  }

  // ---------------- Update ----------------

  void _updateClassSection() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    // Bắt buộc chọn môn
    if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn môn học')),
      );
      return;
    }

    // Parse số an toàn
    final semester = int.tryParse(_semesterController.text.trim());
    final year = int.tryParse(_yearController.text.trim());
    final capacity = _capacityController.text.trim().isEmpty
        ? null
        : int.tryParse(_capacityController.text.trim());

    if (semester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Học kỳ phải là số nguyên hợp lệ')),
      );
      return;
    }
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Năm học phải là số nguyên hợp lệ')),
      );
      return;
    }
    if (_capacityController.text.trim().isNotEmpty && capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sức chứa phải là số nguyên')),
      );
      return;
    }

    // Lấy id để update
    final id = (widget.classSection['id'] ??
            widget.classSection['section_id'] ??
            widget.classSection['sectionId'])
        .toString();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiếu ID lớp học phần để cập nhật'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final payload = <String, dynamic>{
      'subject_id': _selectedSubjectId,
      'semester': semester,
      'year': year,
      'section_code': _sectionCodeController.text.trim(),
      if (capacity != null) 'capacity': capacity, // chỉ gửi khi có
    };

    setState(() => _saving = true);
    try {
      await ApiService.update(ApiConstants.classSections, id, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật lớp học phần thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async => !_saving, // chặn back khi đang lưu
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sửa Lớp học phần'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: _saving ? null : _updateClassSection,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: const Text('Lưu', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                AppSizes.paddingMedium + bottom,
              ),
              child: Column(
                children: [
                  // Subject dropdown
                  if (_loadingSubjects)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _subjects.any((s) => s['id'] == _selectedSubjectId)
                          ? _selectedSubjectId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Môn học *',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      items: _subjects.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['id'],
                          child: Text(s['label'] ?? ''),
                        );
                      }).toList(),
                      selectedItemBuilder: (_) => _subjects.map((s) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            s['label'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Vui lòng chọn môn học' : null,
                    ),
                  if (!_loadingSubjects && _subjects.isEmpty && _subjectError != null) ...[
                    const SizedBox(height: 8),
                    Text(_subjectError!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _fetchSubjects,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],

                  const SizedBox(height: AppSizes.paddingMedium),

                  // Semester
                  TextFormField(
                    controller: _semesterController,
                    decoration: const InputDecoration(
                      labelText: 'Học kỳ *',
                      hintText: 'VD: 1, 2, 3...',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Vui lòng nhập học kỳ';
                      final parsed = int.tryParse(v);
                      if (parsed == null) return 'Học kỳ phải là số nguyên';
                      if (parsed <= 0) return 'Học kỳ phải lớn hơn 0';
                      return null;
                    },
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: AppSizes.paddingMedium),

                  // Year
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Năm học *',
                      hintText: 'VD: 2024...',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Vui lòng nhập năm học';
                      final parsed = int.tryParse(v);
                      if (parsed == null) return 'Năm học phải là số nguyên';
                      if (parsed <= 0) return 'Năm học phải lớn hơn 0';
                      return null;
                    },
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: AppSizes.paddingMedium),

                  // Section code
                  TextFormField(
                    controller: _sectionCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã lớp học phần *',
                      hintText: 'VD: SE01',
                      prefixIcon: Icon(Icons.code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Vui lòng nhập mã lớp học phần';
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.paddingMedium),

                  // Capacity (optional)
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Sức chứa (không bắt buộc)',
                      hintText: 'VD: 50',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
