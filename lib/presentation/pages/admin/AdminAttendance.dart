import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_theme.dart';
import 'List/AdminAttendanceList.dart';
import '../../widgets/MicListeningDialog.dart';

class AdminAttendance extends StatefulWidget {
  const AdminAttendance({super.key});

  @override
  State<AdminAttendance> createState() => _AdminAttendanceState();
}

class _AdminAttendanceState extends State<AdminAttendance> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _searchText = '';

  // 👇 notifier để dialog nghe theo
  final ValueNotifier<String> _recognizedText = ValueNotifier<String>('');

  BuildContext? _dialogContext;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _recognizedText.dispose();
    _speech.stop();
    super.dispose();
  }

  void _showMicDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _dialogContext = ctx;
        return MicListeningDialog(
          recognizedTextListenable: _recognizedText,
          onStop: () {
            // khi user bấm "Dừng lại" trong dialog
            _speech.stop();
            if (mounted) {
              setState(() => _isListening = false);
            }
          },
        );
      },
    ).then((_) {
      _dialogContext = null;
    });
  }

  void _closeMicDialog() {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop();
      _dialogContext = null;
    }
  }

  Future<void> _startListening() async {
    // reset text cũ
    _recognizedText.value = '';

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
          _closeMicDialog();
        }
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _showMicDialog();

      _speech.listen(
        localeId: 'vi_VN',
        onResult: (val) {
          // cập nhật vào notifier -> dialog tự đổi
          _recognizedText.value = val.recognizedWords;

          // đồng thời đổ vào ô search
          setState(() {
            _searchText = val.recognizedWords;
          });

          // nếu đây là kết quả cuối thì dừng luôn
          if (val.finalResult) {
            _speech.stop();
            _closeMicDialog();
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
      );
    }
  }

  void _toggleMic() {
    if (_isListening) {
      _speech.stop();
      _closeMicDialog();
      setState(() => _isListening = false);
    } else {
      _startListening();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý điểm danh'),
        backgroundColor: AppTheme.adminPrimaryColor,
      ),
      body: Column(
        children: [
          // thanh search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: TextEditingController(text: _searchText)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchText.length),
                ),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, mã, ghi chú...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchText.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                        tooltip: 'Xóa tìm kiếm',
                      ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.redAccent : null,
                      ),
                      onPressed: _toggleMic,
                      tooltip: _isListening ? 'Đang nghe...' : 'Nhấn để nói',
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // list
          Expanded(
            child: AdminAttendanceList(
              searchText: _searchText,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // mở add
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm điểm danh'),
      ),
    );
  }
}
