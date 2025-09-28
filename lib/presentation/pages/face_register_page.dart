import 'dart:async';
// import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_theme.dart';

class FaceRegisterPage extends StatefulWidget {
  final String studentId;
  const FaceRegisterPage({super.key, required this.studentId});

  @override
  State<FaceRegisterPage> createState() => _FaceRegisterPageState();
}

class _FaceRegisterPageState extends State<FaceRegisterPage> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  Face? _face;
  String? _error;
  bool _saving = false;

  // Thêm các biến cho stability tracking
  List<Face> _stableFaces = [];
  Timer? _stabilityTimer;
  bool _isStable = false;
  int _stabilityCounter = 0;
  final int _requiredStabilityFrames = 30; // ~1 giây ở 30fps

  // Thêm các biến cho multi-vector capture
  List<List<double>> _capturedVectors = [];
  int _targetVectorCount = 3;
  String _captureStatus = 'Đưa khuôn mặt vào khung hình';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(camera, ResolutionPreset.medium);
      await _cameraController!.initialize();
      _cameraController!.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Không thể mở camera: $e';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation90deg, // Thử rotation khác
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      final faces = await _faceDetector.processImage(inputImage);
      print('Faces detected: ${faces.length}'); // Debug log

      _checkFaceStability(faces);

      setState(() {
        _face = faces.isNotEmpty ? faces.first : null;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi nhận diện: $e';
      });
    } finally {
      _isDetecting = false;
    }
  }

  void _checkFaceStability(List<Face> faces) {
    if (faces.isEmpty) {
      _stabilityCounter = 0;
      _isStable = false;
      _captureStatus = 'Đưa khuôn mặt vào khung hình';
      return;
    }

    final currentFace = faces.first;
    final faceSize =
        currentFace.boundingBox.width * currentFace.boundingBox.height;
    final centerX = currentFace.boundingBox.center.dx;
    final centerY = currentFace.boundingBox.center.dy;

    // Kiểm tra khuôn mặt có trong vùng center không
    final screenCenter = Size(720, 1280); // Giả định kích thước màn hình
    final isInCenter =
        (centerX - screenCenter.width / 2).abs() < 100 &&
        (centerY - screenCenter.height / 2).abs() < 100;

    // Kiểm tra kích thước khuôn mặt phù hợp
    final isGoodSize = faceSize > 10000 && faceSize < 50000;

    if (isInCenter && isGoodSize) {
      _stabilityCounter++;
      if (_stabilityCounter >= _requiredStabilityFrames) {
        _isStable = true;
        if (_capturedVectors.length < _targetVectorCount) {
          _captureStatus =
              'Giữ ổn định! Sẵn sàng chụp ${_capturedVectors.length + 1}/${_targetVectorCount}';
        } else {
          _captureStatus =
              'Đã đủ ${_targetVectorCount} ảnh! Có thể lưu khuôn mặt';
        }
      } else {
        _captureStatus =
            'Giữ ổn định... ${_stabilityCounter}/${_requiredStabilityFrames}';
      }
    } else {
      _stabilityCounter = 0;
      _isStable = false;
      if (!isInCenter) {
        _captureStatus = 'Đưa khuôn mặt vào giữa khung hình';
      } else if (!isGoodSize) {
        _captureStatus = 'Di chuyển gần/xa để có kích thước phù hợp';
      }
    }
  }

  Future<void> _captureVector() async {
    if (_face == null || !_isStable) return;

    // Giả lập embedding từ khuôn mặt hiện tại
    final List<double> embedding = List.generate(
      128,
      (i) => (_face!.boundingBox.left + _face!.boundingBox.top + i) / 1000,
    );

    _capturedVectors.add(embedding);
    _stabilityCounter = 0; // Reset để chụp ảnh tiếp theo
    _isStable = false;

    setState(() {
      if (_capturedVectors.length < _targetVectorCount) {
        _captureStatus =
            'Đã chụp ${_capturedVectors.length}/${_targetVectorCount}. Xoay mặt sang góc khác';
      } else {
        _captureStatus =
            'Đã đủ ${_targetVectorCount} ảnh! Có thể lưu khuôn mặt';
      }
    });

    // Hiệu ứng flash
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã chụp ${_capturedVectors.length}/${_targetVectorCount}',
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _saveFaceEmbedding() async {
    if (_capturedVectors.isEmpty) return;
    setState(() {
      _saving = true;
    });
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('face_embeddings').upsert({
        'user_id': widget.studentId,
        'vectors': _capturedVectors, // Lưu nhiều vectors
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu ${_capturedVectors.length} khuôn mặt!'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi lưu embedding: $e';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký khuôn mặt')),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : Column(
              children: [
                // Camera với guide frame
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      if (_cameraController != null &&
                          _cameraController!.value.isInitialized)
                        Container(
                          width: double.infinity,
                          child: CameraPreview(_cameraController!),
                        )
                      else
                        const Center(child: CircularProgressIndicator()),

                      // Face guide overlay
                      Center(
                        child: Container(
                          width: 250,
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isStable
                                  ? Colors.green
                                  : (_face != null
                                        ? Colors.orange
                                        : Colors.red),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(150),
                          ),
                          child: _face != null
                              ? Icon(
                                  Icons.face,
                                  size: 50,
                                  color: _isStable
                                      ? Colors.green
                                      : Colors.orange,
                                )
                              : const Icon(
                                  Icons.face_outlined,
                                  size: 50,
                                  color: Colors.red,
                                ),
                        ),
                      ),

                      // Progress indicator cho stability
                      if (_stabilityCounter > 0 &&
                          _stabilityCounter < _requiredStabilityFrames)
                        Positioned(
                          top: 50,
                          left: 20,
                          right: 20,
                          child: LinearProgressIndicator(
                            value: _stabilityCounter / _requiredStabilityFrames,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Status và controls
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status text
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingMedium),
                          decoration: BoxDecoration(
                            color: _isStable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isStable ? Colors.green : Colors.orange,
                            ),
                          ),
                          child: Text(
                            _captureStatus,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: _isStable
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),

                        // Capture progress
                        if (_capturedVectors.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMedium,
                              vertical: AppSizes.paddingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Đã chụp: ${_capturedVectors.length}/${_targetVectorCount} ảnh',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        const SizedBox(height: AppSizes.paddingMedium),

                        // Action buttons
                        Row(
                          children: [
                            // Capture button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saving || !_isStable
                                    ? null
                                    : _captureVector,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Chụp ảnh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingMedium),

                            // Save button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saving || _capturedVectors.isEmpty
                                    ? null
                                    : _saveFaceEmbedding,
                                icon: const Icon(Icons.save),
                                label: _saving
                                    ? const Text('Đang lưu...')
                                    : const Text('Lưu khuôn mặt'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.faceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
