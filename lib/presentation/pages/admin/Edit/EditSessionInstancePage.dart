import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class EditSessionInstancePage extends StatefulWidget {
  final Map<String, dynamic> instance;

  const EditSessionInstancePage({super.key, required this.instance});

  @override
  State<EditSessionInstancePage> createState() => _EditSessionInstancePageState();
}

class _EditSessionInstancePageState extends State<EditSessionInstancePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers chỉ để HIỂN THỊ text; giá trị thực dùng DateTime
  final _startsAtController = TextEditingController();
  final _endsAtController = TextEditingController();
  final _statusController = TextEditingController();

  bool _saving = false;
  bool _loadingSections = false;
  bool _loadingRooms = false;
  String? _sectionError;
  String? _roomError;

  DateTime? _startsAt;
  DateTime? _endsAt;

  // mỗi item: {"id": "...", "label": "..."}
  List<Map<String, String>> _sections = [];
  List<Map<String, String>> _rooms = [];
  String? _selectedSectionId;
  String? _selectedRoomId;

  // ====== Date helpers ======
  final _fmtDisplay = DateFormat('yyyy-MM-dd HH:mm');     // hiển thị
  final _fmtSql = DateFormat('yyyy-MM-dd HH:mm:ss');      // gửi API/DB

  String _dtToDisplay(DateTime? dt) =>
      (dt == null) ? '' : _fmtDisplay.format(dt);

  String _dtToSql(DateTime? dt) =>
      (dt == null) ? '' : _fmtSql.format(dt);

  // cố gắng parse ISO/SQL -> DateTime local
  DateTime? _parseDateFlexible(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      // DateTime.parse hỗ trợ ISO (có Z) và một số biến thể
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      // fallback nếu backend trả "yyyy-MM-dd HH:mm:ss"
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true);
        return dt.toLocal();
      } catch (_) {}
      // fallback nếu là "yyyy-MM-dd HH:mm"
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(raw, true);
        return dt.toLocal();
      } catch (_) {}
    }
    return null;
  }

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final base = initial ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  void initState() {
    super.initState();

    // Parse thời gian từ instance -> local & hiển thị đẹp
    _startsAt = _parseDateFlexible(widget.instance['starts_at']?.toString());
    _endsAt = _parseDateFlexible(widget.instance['ends_at']?.toString());
    _startsAtController.text = _dtToDisplay(_startsAt);
    _endsAtController.text = _dtToDisplay(_endsAt);

    _statusController.text = widget.instance['status']?.toString() ?? 'planned';

    _selectedSectionId = widget.instance['section_id']?.toString();
    _selectedRoomId = widget.instance['room_id']?.toString();

    _loadSections();
    _loadRooms();
  }

  @override
  void dispose() {
    _startsAtController.dispose();
    _endsAtController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    setState(() {
      _loadingSections = true;
      _sectionError = null;
    });
    try {
      final list = await ApiService.getList(ApiConstants.classSections);
      _sections = List<Map<String, String>>.from(
        (list as List).map((e) {
          final m = Map<String, dynamic>.from(e);
          final id = m['id']?.toString() ?? '';
          final sectionCode = m['section_code']?.toString() ?? '';
          final semester = m['semester']?.toString() ?? '';
          final year = m['year']?.toString() ?? '';
          final subjectName = (m['subject']?['name'])?.toString() ?? '';
          final label = [
            if (sectionCode.isNotEmpty) '[$sectionCode]',
            if (subjectName.isNotEmpty) subjectName,
            if (semester.isNotEmpty && year.isNotEmpty) ' - $semester/$year',
          ].join(' ');
          return {'id': id, 'label': label.isEmpty ? id : label};
        }),
      );

      // nếu giá trị hiện tại không còn trong list -> buộc chọn lại
      if (_selectedSectionId != null &&
          !_sections.any((e) => e['id'] == _selectedSectionId)) {
        _selectedSectionId = null;
      }
    } catch (e) {
      _sectionError = 'Không tải được danh sách lớp học phần: $e';
    } finally {
      setState(() => _loadingSections = false);
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomError = null;
    });
    try {
      final list = await ApiService.getList(ApiConstants.rooms);
      _rooms = List<Map<String, String>>.from(
        (list as List).map((e) {
          final m = Map<String, dynamic>.from(e);
          final id = m['id']?.toString() ?? '';
          final name = m['name']?.toString() ?? (m['code']?.toString() ?? id);
          return {'id': id, 'label': name};
        }),
      );

      if (_selectedRoomId != null &&
          !_rooms.any((e) => e['id'] == _selectedRoomId)) {
        _selectedRoomId = null;
      }
    } catch (e) {
      _roomError = 'Không tải được danh sách phòng: $e';
    } finally {
      setState(() => _loadingRooms = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionItems = _sections
        .map((e) => DropdownMenuItem<String>(
              value: e['id'],
              child: Text(e['label'] ?? e['id']!),
            ))
        .toList();

    final roomItems = _rooms
        .map((e) => DropdownMenuItem<String>(
              value: e['id'],
              child: Text(e['label'] ?? e['id']!),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa phiên học'),
        backgroundColor: AppTheme.adminPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // ------ SECTION DROPDOWN ------
              DropdownButtonFormField<String>(
                value: _selectedSectionId,
                decoration: InputDecoration(
                  labelText: 'Lớp học phần (Section)',
                  border: const OutlineInputBorder(),
                  helperText: _sectionError,
                  helperStyle: const TextStyle(color: Colors.red),
                ),
                isExpanded: true,
                items: sectionItems,
                onChanged: _loadingSections ? null : (v) => setState(() => _selectedSectionId = v),
                validator: (_) {
                  if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
                    return 'Chọn lớp học phần';
                  }
                  return null;
                },
              ),
              if (_loadingSections)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 16),

              // ------ STARTS_AT (readOnly + date/time picker) ------
              TextFormField(
                controller: _startsAtController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Thời gian bắt đầu',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await _pickDateTime(initial: _startsAt);
                  if (picked != null) {
                    setState(() {
                      _startsAt = picked;
                      _startsAtController.text = _dtToDisplay(_startsAt);
                    });
                  }
                },
                validator: (_) => _startsAt == null ? 'Chọn thời gian bắt đầu' : null,
              ),
              const SizedBox(height: 16),

              // ------ ENDS_AT (readOnly + date/time picker) ------
              TextFormField(
                controller: _endsAtController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Thời gian kết thúc',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await _pickDateTime(initial: _endsAt ?? _startsAt);
                  if (picked != null) {
                    setState(() {
                      _endsAt = picked;
                      _endsAtController.text = _dtToDisplay(_endsAt);
                    });
                  }
                },
                validator: (_) => _endsAt == null ? 'Chọn thời gian kết thúc' : null,
              ),
              const SizedBox(height: 16),

              // ------ STATUS ------
              DropdownButtonFormField<String>(
                value: _statusController.text.isNotEmpty ? _statusController.text : null,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'planned', child: Text('Đã lên kế hoạch')),
                  DropdownMenuItem(value: 'ongoing', child: Text('Đang diễn ra')),
                  DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                ],
                onChanged: (value) => setState(() => _statusController.text = value ?? 'planned'),
                validator: (_) => (_statusController.text.isEmpty) ? 'Chọn trạng thái' : null,
              ),
              const SizedBox(height: 16),

              // ------ ROOM DROPDOWN (optional) ------
              DropdownButtonFormField<String>(
                value: _selectedRoomId,
                decoration: InputDecoration(
                  labelText: 'Phòng học (tùy chọn)',
                  border: const OutlineInputBorder(),
                  helperText: _roomError,
                  helperStyle: const TextStyle(color: Colors.red),
                ),
                isExpanded: true,
                items: roomItems,
                onChanged: _loadingRooms ? null : (v) => setState(() => _selectedRoomId = v),
              ),
              if (_loadingRooms)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.update(
        ApiConstants.sessionInstances,
        widget.instance['id'].toString(),
        {
          'section_id': _selectedSectionId,
          // Gửi về DB theo SQL local time (khớp screenshot DB của bạn)
          'starts_at': _dtToSql(_startsAt),
          'ends_at': _dtToSql(_endsAt),
          'status': _statusController.text.trim(),
          'room_id': (_selectedRoomId == null || _selectedRoomId!.isEmpty) ? null : _selectedRoomId,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật phiên học thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật phiên học: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
