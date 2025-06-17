import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('사용 가능한 카메라가 없습니다.')),
      ),
    ));
    return;
  }
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '두상 촬영 데모',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CameraPreviewScreen(camera: camera),
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraPreviewScreen({super.key, required this.camera});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

// 분석 결과 구조
class HeadAnalysisResult {
  final double cep;
  final double cvai;
  final String shapeType;
  final String guideMessage;
  HeadAnalysisResult(
      {required this.cep,
      required this.cvai,
      required this.shapeType,
      required this.guideMessage});
}

// 촬영 이미지 히스토리 데이터 구조
class HistoryItem {
  final String path;
  final DateTime dateTime;
  final HeadAnalysisResult? result;
  HistoryItem({required this.path, required this.dateTime, this.result});
}

class HistoryScreen extends StatelessWidget {
  final List<HistoryItem> history;
  final void Function(int) onDelete;
  const HistoryScreen(
      {super.key, required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('촬영 히스토리')),
      body: history.isEmpty
          ? const Center(child: Text('촬영된 사진이 없습니다.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Image.file(
                      File(item.path),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                    title: Text(DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(item.dateTime)),
                    onTap: () {
                      if (item.result != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnalysisResultScreen(item: item),
                          ),
                        );
                      }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDelete(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// CVAI, CI 해석 함수
String interpretCVAI(double cvai) {
  if (cvai < 3.5) return '정상';
  if (cvai < 6) return '경도 사두증';
  if (cvai < 9) return '중등도 사두증';
  return '중증 사두증';
}

String interpretCI(double ci) {
  if (ci < 75) return '주상두증(병원 진료 권장)';
  if (ci < 80) return '장두';
  if (ci < 93.5) return '정상';
  if (ci < 100) return '단두증';
  if (ci < 110) return '과두증';
  return '비개통 단두증(병원 진료 권장)';
}

String ciWarning(double ci) {
  if (ci < 75) return '주상두증(봉합 조기폐쇄) 의심, 병원 진료를 권장합니다.';
  if (ci > 110) return '비개통 단두증(양측 관상봉합 조기폐쇄) 의심, 병원 진료를 권장합니다.';
  return '';
}

// 분석 결과 상세 화면
class AnalysisResultScreen extends StatelessWidget {
  final HistoryItem item;
  const AnalysisResultScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final result = item.result!;
    final cvaiGrade = interpretCVAI(result.cvai);
    final ciGrade = interpretCI(result.cep); // result.cep를 CI로 사용
    final ciWarn = ciWarning(result.cep);
    final isNormal = (result.cvai < 3.5) &&
        (result.cep >= 80 && result.cep < 93.5); // CI=cep로 사용
    return Scaffold(
      appBar: AppBar(title: const Text('분석 결과 상세')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.file(File(item.path),
                width: 180, height: 180, fit: BoxFit.cover),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                        'CVAI: ${result.cvai.toStringAsFixed(2)}% ($cvaiGrade)',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('CI: ${result.cep.toStringAsFixed(1)}% ($ciGrade)',
                        style: const TextStyle(fontSize: 16)),
                    if (ciWarn.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(ciWarn,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 8),
                    if (isNormal)
                      Text('두상 형태: 정상',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    if (!isNormal)
                      Text('두상 형태: ${result.shapeType}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(result.guideMessage,
                style: const TextStyle(fontSize: 15, color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;

  // 흔들림 감지 관련 변수
  List<double> _accelHistory = [];
  StreamSubscription? _accelSub;

  // 촬영된 이미지 리스트
  List<HistoryItem> _capturedImages = [];

  // 중앙 메시지 상태
  String? _centerMessage;
  Timer? _centerMessageTimer;

  AnimationController? _msgAnimController;
  Animation<double>? _msgFadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    // 가속도 센서 구독 시작
    _accelSub = accelerometerEvents.listen((event) {
      final magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      setState(() {
        _accelHistory.add(magnitude);
        if (_accelHistory.length > 20) {
          _accelHistory.removeAt(0);
        }
      });
    });
    _msgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _msgFadeAnim = CurvedAnimation(
      parent: _msgAnimController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelSub?.cancel();
    _msgAnimController?.dispose();
    super.dispose();
  }

  bool _isShaking() {
    if (_accelHistory.length < 2) return false;
    double maxDiff = 0;
    for (int i = 1; i < _accelHistory.length; i++) {
      final diff = (_accelHistory[i] - _accelHistory[i - 1]).abs();
      if (diff > maxDiff) maxDiff = diff;
    }
    // 임계값(흔들림 민감도)을 2.5로 상향 조정
    return maxDiff > 2.5;
  }

  Future<void> _detectContourAndShow(String imagePath) async {
    try {
      // 1. 그레이스케일 변환
      final gray = await Cv2.cvtColor(
        CVPathFrom.GALLERY_CAMERA,
        pathString: imagePath,
        Cv2ColorConversion.COLOR_BGR2GRAY,
      );
      // 2. 블러 + 이진화
      final blurred = await Cv2.gaussianBlur(
        pathFrom: CVPathFrom.MEMORY,
        byteData: gray,
        outputPath: '',
        kernelSize: [5, 5],
        sigmaX: 0,
      );
      final thresh = await Cv2.threshold(
        pathFrom: CVPathFrom.MEMORY,
        byteData: blurred,
        outputPath: '',
        maxValue: 255,
        thresholdValue: 80,
        thresholdType: Cv2ThresholdType.THRESH_BINARY,
      );
      // 3. 윤곽선 검출 및 시각화
      final contoured = await Cv2.findContours(
        pathFrom: CVPathFrom.MEMORY,
        byteData: thresh,
        outputPath: '',
        mode: ContourRetrievalMode.RETR_EXTERNAL,
        method: ContourApproximationMethod.CHAIN_APPROX_SIMPLE,
        draw: true,
        color: [255, 0, 0], // 파란색
        thickness: 3,
      );
      // 4. 결과 이미지를 다이얼로그로 표시
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Image.memory(Uint8List.fromList(contoured)),
        ),
      );
    } catch (e) {
      _showCenterMessage('윤곽선 검출 실패: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;
    if (_isShaking()) {
      if (!mounted) return;
      _showCenterMessage('흔들림이 감지되었습니다.\n기기를 고정하고 다시 시도해 주세요.');
      return;
    }
    setState(() {
      _isTakingPicture = true;
    });
    try {
      await _initializeControllerFuture;
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _controller
          .takePicture()
          .then((XFile file) => file.saveTo(filePath));

      // 샘플 분석 결과 생성
      final sampleResult = HeadAnalysisResult(
        cep: 120 + (10 * (0.5 - (DateTime.now().millisecond % 100) / 100)),
        cvai: 3.2 + (2 * (0.5 - (DateTime.now().second % 60) / 60)),
        shapeType: '정상',
        guideMessage: '두상 형태가 정상 범위입니다. 주기적으로 촬영해 변화를 관찰하세요.',
      );
      // 촬영 이미지 리스트에 추가
      setState(() {
        _capturedImages.insert(
            0,
            HistoryItem(
                path: filePath,
                dateTime: DateTime.now(),
                result: sampleResult));
      });

      // OpenCV 윤곽선 검출 및 결과 표시
      final fileBytes = await File(filePath).readAsBytes();
      final contourResult = await detectContoursOnNative(fileBytes);

      if (contourResult != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Image.memory(contourResult),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진이 임시 저장되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showCenterMessage('촬영 실패: $e');
    } finally {
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  void _showCenterMessage(String message) {
    setState(() {
      _centerMessage = message;
    });
    _msgAnimController?.forward(from: 0);
    _centerMessageTimer?.cancel();
    _centerMessageTimer = Timer(const Duration(seconds: 2), () {
      _msgAnimController?.reverse();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _centerMessage = null;
          });
        }
      });
    });
  }

  void _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          history: _capturedImages,
          onDelete: (index) async {
            final item = _capturedImages[index];
            // 파일도 삭제
            final file = File(item.path);
            if (await file.exists()) {
              await file.delete();
            }
            setState(() {
              _capturedImages.removeAt(index);
            });
            Navigator.of(context).pop();
            _openHistory();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('두상 촬영')),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: [
                    // 카메라 프리뷰를 화면 전체에 꽉 차게
                    Positioned.fill(
                      child: CameraPreview(_controller),
                    ),
                    // 중앙 타원형 투명 가이드 오버레이
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CenterCircleOverlayPainter(),
                      ),
                    ),
                    // 상단 가이드 메시지
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          '아이의 머리를 원 안에 위치시키고\n코가 위를 향하도록 해주세요',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // 중앙 메시지(흔들림/초점 안내)
                    if (_centerMessage != null)
                      Center(
                        child: FadeTransition(
                          opacity: _msgFadeAnim ?? kAlwaysCompleteAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800]!.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _centerMessage!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon:
                        Icon(Icons.history, size: 36, color: Colors.grey[400]),
                    onPressed: _openHistory,
                  ),
                  SizedBox(width: 90), // 카메라 버튼 자리 확보
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -30, // 하단바 위로 30px 튀어나오게
              child: Center(
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: IconButton(
                      onPressed: _isTakingPicture ? null : _takePicture,
                      icon: Icon(Icons.camera_alt,
                          size: 44, color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 중앙 타원형 투명 가이드 오버레이 페인터
class CenterCircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[900]!.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 중앙보다 약간 아래로 내린 center
    final center =
        Offset(size.width / 2, size.height * 0.57); // 0.5 -> 0.57로 약간 아래
    final ellipseWidth = size.width * 0.85;
    final ellipseHeight = ellipseWidth * 1.2;
    // 가운데 타원 경로
    final ellipseRect = Rect.fromCenter(
        center: center, width: ellipseWidth, height: ellipseHeight);
    final ellipsePath = Path()..addOval(ellipseRect);
    // 전체 사각형 경로
    final rectPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    // 가운데 타원을 제외한 영역만 칠함
    final overlayPath =
        Path.combine(PathOperation.difference, rectPath, ellipsePath);
    canvas.drawPath(overlayPath, paint);

    // 중앙 수직선/수평선 (반투명 회색 실선)
    final guidePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // 수직선 (타원 중앙)
    canvas.drawLine(Offset(center.dx, ellipseRect.top),
        Offset(center.dx, ellipseRect.bottom), guidePaint);
    // 수평선 (타원 중앙)
    canvas.drawLine(Offset(ellipseRect.left, center.dy),
        Offset(ellipseRect.right, center.dy), guidePaint);

    // 타원 윤곽선(가늘고 반투명한 검은색) - 가장 마지막에 그려서 가이드라인 위에 덮임
    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(ellipseRect, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<Uint8List?> detectContoursOnNative(Uint8List imageBytes) async {
  const channel = MethodChannel('opencv_channel');
  try {
    final result =
        await channel.invokeMethod<Uint8List>('detectContours', imageBytes);
    return result;
  } catch (e) {
    print('윤곽선 네이티브 호출 실패: $e');
    return null;
  }
}
