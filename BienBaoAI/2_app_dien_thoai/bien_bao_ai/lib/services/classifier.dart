import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Prediction {
  final int id;
  final double prob;
  const Prediction(this.id, this.prob);
}

class ClassifyResult {
  final List<Prediction> top3;
  final double inferenceMs; // chỉ thời gian chạy mô hình
  final double totalMs; // tiền xử lý + chạy mô hình
  final Uint8List preview; // ảnh vùng đã cắt (PNG) để hiển thị
  final int passes; // số lượt chạy mô hình (số vùng cắt)
  const ClassifyResult(this.top3, this.inferenceMs, this.totalMs, this.preview, {this.passes = 1});
}

/// Bộ phân loại dùng mô hình CNN đã chuyển sang TensorFlow Lite.
/// Xử lý ảnh giống traffic_sign.py: ảnh RGB, 30x30, giữ giá trị điểm ảnh 0-255.
class Classifier {
  static const int inputSize = 30;
  static Interpreter? _interpreter;
  static double _runMs = 0; // cộng dồn thời gian chạy mô hình

  static Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset('assets/model.tflite');
  }

  static List<double> _probs(img.Image crop) {
    final rgb = crop.convert(format: img.Format.uint8, numChannels: 3);
    final small = img.copyResize(rgb, width: inputSize, height: inputSize, interpolation: img.Interpolation.cubic);
    final input = [
      List.generate(inputSize, (y) => List.generate(inputSize, (x) {
            final p = small.getPixel(x, y);
            return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
          }))
    ];
    final numClasses = _interpreter!.getOutputTensor(0).shape.last; // 43 hoặc nhiều hơn nếu có thêm biển Việt Nam
    final output = [List<double>.filled(numClasses, 0.0)];
    final sw = Stopwatch()..start();
    _interpreter!.run(input, output);
    sw.stop();
    _runMs += sw.elapsedMicroseconds / 1000.0;
    return output[0];
  }

  /// Nhận diện một vùng ảnh.
  static Future<ClassifyResult> classify(img.Image crop) => classifyMulti([crop]);

  /// Nhận diện nhiều vùng cắt hơi khác nhau của cùng một biển rồi lấy trung bình xác suất.
  /// crops[0] là vùng đúng khung ngắm, dùng để hiển thị.
  static Future<ClassifyResult> classifyMulti(List<img.Image> crops) async {
    await load();
    final total = Stopwatch()..start();
    _runMs = 0;
    List<double>? sum;
    for (final c in crops) {
      final p = _probs(c);
      sum ??= List<double>.filled(p.length, 0.0);
      for (var i = 0; i < p.length; i++) {
        sum[i] += p[i] / crops.length;
      }
    }
    total.stop();
    final probs = sum!;
    final order = List<int>.generate(probs.length, (i) => i)..sort((a, b) => probs[b].compareTo(probs[a]));
    final top3 = order.take(3).map((i) => Prediction(i, probs[i])).toList();

    final rgb = crops.first.convert(format: img.Format.uint8, numChannels: 3);
    final previewImg = img.copyResize(rgb, width: 240, height: 240, interpolation: img.Interpolation.cubic);
    final preview = Uint8List.fromList(img.encodePng(previewImg));

    return ClassifyResult(top3, _runMs, total.elapsedMicroseconds / 1000.0, preview,
        passes: crops.length);
  }
}
