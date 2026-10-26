import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/classifier.dart';
import 'result_screen.dart';

/// Màn hình khung ngắm: người dùng kéo / phóng to để đưa biển báo vào khung vuông.
class CropScreen extends StatefulWidget {
  final File file;
  const CropScreen({super.key, required this.file});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _tc = TransformationController();
  Uint8List? _bytes;
  img.Image? _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final bytes = await widget.file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không đọc được ảnh')));
        Navigator.pop(context);
      }
      return;
    }
    final oriented = img.bakeOrientation(decoded);
    if (mounted) {
      setState(() {
        _image = oriented;
        _bytes = Uint8List.fromList(img.encodeJpg(oriented, quality: 92));
      });
    }
  }

  /// Cắt vùng vuông cạnh [side], góc trên trái (x, y), giới hạn trong ảnh.
  img.Image _cropRect(double x, double y, double side) {
    final image = _image!;
    final w = image.width.toDouble(), h = image.height.toDouble();
    final x0 = x.clamp(0.0, w - 1).toDouble();
    final y0 = y.clamp(0.0, h - 1).toDouble();
    final cw = math.max(1, math.min(side, w - x0)).round();
    final ch = math.max(1, math.min(side, h - y0)).round();
    return img.copyCrop(image, x: x0.round(), y: y0.round(), width: cw, height: ch);
  }

  /// Vùng ảnh gốc nằm trong khung vuông kích thước [s] và 4 biến thể nhỏ quanh nó
  /// (thu nhỏ, phóng to, lệch chéo hai phía) để lấy trung bình kết quả.
  List<img.Image> _cropVariants(double s) {
    final image = _image!;
    final w = image.width.toDouble(), h = image.height.toDouble();
    final k = s / math.max(w, h); // tỉ lệ hiển thị BoxFit.contain
    final ox = (s - w * k) / 2, oy = (s - h * k) / 2;
    final m = _tc.value;
    final scale = m.getMaxScaleOnAxis();
    final tx = m.storage[12], ty = m.storage[13];
    final left = -tx / scale, top = -ty / scale, side = s / scale;
    final x0 = (left - ox) / k, y0 = (top - oy) / k, sz = side / k;
    final cx = x0 + sz / 2, cy = y0 + sz / 2;
    // [tỉ lệ cạnh, lệch x, lệch y] so với khung ngắm
    const specs = [
      [1.0, 0.0, 0.0],
      [0.9, 0.0, 0.0],
      [1.1, 0.0, 0.0],
      [1.0, 0.05, 0.05],
      [1.0, -0.05, -0.05],
    ];
    return specs.map((sp) {
      final d = sz * sp[0];
      return _cropRect(cx + sp[1] * sz - d / 2, cy + sp[2] * sz - d / 2, d);
    }).toList();
  }

  Future<void> _run(double s) async {
    setState(() => _busy = true);
    try {
      final result = await Classifier.classifyMulti(_cropVariants(s));
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi nhận diện: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = math.min(MediaQuery.of(context).size.width - 48, 340.0);
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(title: const Text('Khung ngắm')),
      body: _bytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                child: const Text('Kéo, phóng to để biển báo nằm gọn trong khung',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Container(
                width: s + 6,
                height: s + 6,
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFFD54F), width: 3), borderRadius: BorderRadius.circular(6)),
                child: ClipRect(
                  child: InteractiveViewer(
                    transformationController: _tc,
                    minScale: 1,
                    maxScale: 12,
                    boundaryMargin: EdgeInsets.all(s),
                    child: SizedBox(width: s, height: s, child: Image.memory(_bytes!, fit: BoxFit.contain)),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                    onPressed: _busy ? null : () => _run(s),
                    icon: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search),
                    label: const Text('Nhận diện', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
    );
  }
}
