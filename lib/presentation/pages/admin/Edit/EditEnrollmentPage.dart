import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class EditEnrollmentPage extends StatefulWidget {
  final Map<String, dynamic> enrollment;

  const EditEnrollmentPage({super.key, required this.enrollment});

  @override
  State<EditEnrollmentPage> createState() => _EditEnrollmentPageState();
}

class _EditEnrollmentPageState extends State<EditEnrollmentPage> {
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  bool _loadingSections = false;
  bool _loadingStudents = false;
  String? _sectionError;
  String? _studentError;

  // mỗi item: {"id": "...", "label": "..."}
  List<Map<String, String>> _sections = [];
  List<Map<String, String>> _students = [];
  String? _selectedSectionId;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    // đọc sẵn section_id / student_id từ enrollment để preselect
    _selectedSectionId = _extractString(widget.enrollment, [
      'section_id',
      'sectionId',
      'section',
      'sectionIdString',
    ]);
    _selectedStudentId = _extractString(widget.enrollment, [
      'student_id',
      'studentId',
      'student',
      'studentIdString',
    ]);

    _fetchSections();
    _fetchStudents();
  }

  // ---------- helpers ----------
  String _extractString(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;

      // If it’s already a primitive, return as string.
      if (v is String || v is num || v is bool) return v.toString();

      // If it’s a nested map like { id: "...", ... }, pull its id-ish field.
      if (v is Map) {
        for (final kk in const [
          'id',
          'section_id',
          'sectionId',
          'student_id',
          'studentId',
        ]) {
          final inner = v[kk];
          if (inner != null) return inner.toString();
        }
      }
    }
    return '';
  }

  List<dynamic> _unwrapList(dynamic resp) {
    if (resp is List) return resp;
    if (resp is Map<String, dynamic>) {
      for (final k in const ['data', 'items', 'results', 'content']) {
        final v = resp[k];
        if (v is List) return v;
      }
    }
    return const [];
  }

  // ---------- fetch ----------
  Future<void> _fetchSections() async {
    if (!mounted) return;
    setState(() {
      _loadingSections = true;
      _sectionError = null;
    });

    try {
      final resp = await ApiService.getList(ApiConstants.classSections);
      final List<dynamic> list = _unwrapList(resp);

      final items = <Map<String, String>>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final e = Map<String, dynamic>.from(raw);

        // id
        String id = '';
        for (final k in ['id', 'sectionId', 'section_id']) {
          final v = e[k];
          if (v != null) {
            id = v.toString();
            break;
          }
        }
        if (id.isEmpty) continue;

        // section code / name
        String sectionCode = '';
        for (final k in [
          'section_code',
          'sectionCode',
          'code',
          'name',
          'sectionName',
        ]) {
          final v = e[k]?.toString().trim();
          if (v != null && v.isNotEmpty) {
            sectionCode = v;
            break;
          }
        }

        // subject name
        String subjectName = '';
        final subj = e['subject'];
        if (subj is Map) {
          subjectName =
              (subj['name'] ?? subj['subjectName'] ?? subj['title'] ?? '')
                  .toString();
        }
        if (subjectName.trim().isEmpty) {
          for (final k in ['subject_name', 'subjectName', 'subject_title']) {
            final v = e[k]?.toString().trim();
            if (v != null && v.isNotEmpty) {
              subjectName = v;
              break;
            }
          }
        }

        final label = (sectionCode.isNotEmpty && subjectName.isNotEmpty)
            ? '$sectionCode • $subjectName'
            : (sectionCode.isNotEmpty
                  ? sectionCode
                  : (subjectName.isNotEmpty
                        ? subjectName
                        : 'Lớp học phần $id'));

        items.add({'id': id, 'label': label});
      }

      if (!mounted) return;
      setState(() {
        _sections = items;
        // nếu id hiện tại không còn trong danh sách => auto chọn phần tử đầu
        if (!_sections.any((s) => s['id'] == _selectedSectionId)) {
          _selectedSectionId = _sections.isNotEmpty
              ? _sections.first['id']
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sectionError = 'Lỗi tải lớp học phần: $e';
        _sections = [];
        // không reset _selectedSectionId để giữ giá trị cũ (nếu có)
      });
    } finally {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() {
      _loadingStudents = true;
      _studentError = null;
    });

    try {
      final resp = await ApiService.getList(ApiConstants.students);
      final List<dynamic> list = _unwrapList(resp);

      final items = <Map<String, String>>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final e = Map<String, dynamic>.from(raw);

        // id
        String id = '';
        for (final k in [
          'id',
          'studentId',
          'student_id',
          'profileId',
          'profile_id',
        ]) {
          final v = e[k];
          if (v != null) {
            id = v.toString();
            break;
          }
        }
        if (id.isEmpty) continue;

        // full name
        String fullName = '';
        for (final k in ['fullName', 'full_name', 'name']) {
          final v = e[k]?.toString().trim();
          if (v != null && v.isNotEmpty) {
            fullName = v;
            break;
          }
        }
        if (fullName.isEmpty) {
          final fn = (e['firstName'] ?? e['first_name'] ?? '')
              .toString()
              .trim();
          final ln = (e['lastName'] ?? e['last_name'] ?? '').toString().trim();
          if (fn.isNotEmpty || ln.isNotEmpty) {
            fullName = [ln, fn].where((s) => s.isNotEmpty).join(' ');
          }
        }
        if (fullName.isEmpty && e['profile'] is Map) {
          final p = e['profile'] as Map;
          final direct = (p['fullName'] ?? p['name'] ?? '').toString().trim();
          if (direct.isNotEmpty) {
            fullName = direct;
          } else {
            final fn = (p['firstName'] ?? p['first_name'] ?? '')
                .toString()
                .trim();
            final ln = (p['lastName'] ?? p['last_name'] ?? '')
                .toString()
                .trim();
            if (fn.isNotEmpty || ln.isNotEmpty) {
              fullName = [ln, fn].where((s) => s.isNotEmpty).join(' ');
            }
          }
        }

        // student code
        String stuCode = '';
        for (final k in ['studentCode', 'student_code', 'code', 'mssv']) {
          final v = e[k]?.toString().trim();
          if (v != null && v.isNotEmpty) {
            stuCode = v;
            break;
          }
        }

        final label = (fullName.isNotEmpty && stuCode.isNotEmpty)
            ? '$fullName • $stuCode'
            : (fullName.isNotEmpty
                  ? fullName
                  : (stuCode.isNotEmpty ? stuCode : 'SV $id'));

        items.add({'id': id, 'label': label});
      }

      if (!mounted) return;
      setState(() {
        _students = items;
        if (!_students.any((s) => s['id'] == _selectedStudentId)) {
          _selectedStudentId = _students.isNotEmpty
              ? _students.first['id']
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _studentError = 'Lỗi tải sinh viên: $e';
        _students = [];
      });
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  // ---------- submit ----------
  Future<void> _updateEnrollment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      String? originalSectionId = _extractString(
        widget.enrollment,
        ['section_id', 'sectionId', 'section'],
      ).trim();
      if (originalSectionId.isEmpty) originalSectionId = null;
      originalSectionId ??= _selectedSectionId?.trim();

      String? originalStudentId = _extractString(
        widget.enrollment,
        ['student_id', 'studentId', 'student'],
      ).trim();
      if (originalStudentId.isEmpty) originalStudentId = null;
      originalStudentId ??= _selectedStudentId?.trim();

      String? identifier = widget.enrollment['id']?.toString().trim();
      identifier ??= widget.enrollment['enrollment_id']?.toString().trim();
      if (identifier != null && identifier.isEmpty) identifier = null;

      Future<void> _doUpdate(String compositeId) async {
        final encodedId = Uri.encodeComponent(compositeId);
        await ApiService.update(ApiConstants.enrollments, encodedId, {
          'section_id': _selectedSectionId,
          'student_id': _selectedStudentId,
        });
      }

      if (identifier != null) {
        await _doUpdate(identifier);
      } else if (originalSectionId != null && originalStudentId != null) {
        try {
          await _doUpdate('$originalSectionId:$originalStudentId');
        } catch (_) {
          try {
            await _doUpdate('$originalSectionId,$originalStudentId');
          } catch (_) {
            await _doUpdate('$originalSectionId|$originalStudentId');
          }
        }
      } else {
        throw Exception(
          'Missing enrollment identifier (id or section_id + student_id).',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cap nhat sinh vien vao lop hoc phan thanh cong!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi khi cap nhat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật sinh viên vào lớp học phần'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _saving
                ? null
                : () {
                    _fetchSections();
                    _fetchStudents();
                  },
          ),
          TextButton(
            onPressed: _saving ? null : _updateEnrollment,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cập nhật', style: TextStyle(color: Colors.black)),
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
                // --- lớp học phần ---
                if (_loadingSections)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _sections.any((s) => s['id'] == _selectedSectionId)
                        ? _selectedSectionId
                        : null,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Lớp học phần *',
                      prefixIcon: Icon(Icons.class_),
                      border: OutlineInputBorder(),
                    ),
                    items: _sections
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(s['label'] ?? ''),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (_) => _sections
                        .map(
                          (s) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              s['label'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSectionId = v),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Vui lòng chọn lớp học phần';
                      if (_sectionError != null) return _sectionError;
                      return null;
                    },
                  ),

                const SizedBox(height: AppSizes.paddingMedium),

                // --- sinh viên ---
                if (_loadingStudents)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _students.any((s) => s['id'] == _selectedStudentId)
                        ? _selectedStudentId
                        : null,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Sinh viên *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    items: _students
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(s['label'] ?? ''),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (_) => _students
                        .map(
                          (s) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              s['label'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStudentId = v),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Vui lòng chọn sinh viên';
                      if (_studentError != null) return _studentError;
                      return null;
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
}

