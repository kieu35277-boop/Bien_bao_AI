import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/classifier.dart';
import 'services/signs.dart';
import 'screens/crop_screen.dart';
import 'screens/library_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/history_screen.dart';

const kNavy = Color(0xFF1F3864);
const kRed = Color(0xFFE53935);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BienBaoApp());
}

class BienBaoApp extends StatelessWidget {
  const BienBaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biển Báo AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kNavy, primary: kNavy),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        appBarTheme: const AppBarTheme(backgroundColor: kNavy, foregroundColor: Colors.white),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await SignDb.load();
      await Classifier.load();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không nạp được mô hình: $e');
    }
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? f = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 95);
    if (f == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CropScreen(file: File(f.path))));
  }

  Widget _card(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: _ready ? onTap : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Biển Báo AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          Text('Nhận diện biển báo giao thông bằng camera', style: TextStyle(fontSize: 13)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(_ready ? Icons.wifi_off : Icons.hourglass_top, size: 18, color: Colors.green.shade800),
              label: Text(_ready ? 'Chạy ngoại tuyến – không cần Internet' : 'Đang nạp mô hình…'),
              backgroundColor: Colors.green.shade50,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: const TextStyle(color: kRed)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _ready ? () => _pick(ImageSource.camera) : null,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh nhận diện', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kNavy, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _ready ? () => _pick(ImageSource.gallery) : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          _card(Icons.menu_book, kNavy, 'Tra cứu biển báo', 'Tên, mã hiệu, ý nghĩa',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen()))),
          _card(Icons.quiz, const Color(0xFFF9A825), 'Ôn tập trắc nghiệm', '10 câu hỏi ngẫu nhiên về biển báo',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()))),
          _card(Icons.history, const Color(0xFF2E7D32), 'Lịch sử nhận diện', 'Kết quả và thời gian xử lý các lần trước',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          const SizedBox(height: 16),
          const Text(
            'Kết quả chỉ mang tính tham khảo, hỗ trợ học tập luật giao thông.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
