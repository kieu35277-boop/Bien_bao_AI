import 'package:flutter/material.dart';

import '../services/classifier.dart';
import '../services/history.dart';
import '../services/signs.dart';

/// Ngưỡng tin cậy: dưới ngưỡng thì không khẳng định kết quả.
const double kThreshold = 0.60;

class ResultScreen extends StatefulWidget {
  final ClassifyResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    final best = widget.result.top3.first;
    HistoryStore.add(HistoryItem(DateTime.now(), best.id, best.prob, widget.result.inferenceMs, best.prob >= kThreshold));
  }

  String _pct(double p) => '${(p * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final best = r.top3.first;
    final sign = SignDb.byId(best.id);
    final confident = best.prob >= kThreshold;
    const navy = Color(0xFF1F3864);

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả nhận diện')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(r.preview, width: 150, height: 150, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          if (!confident)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Chưa chắc chắn (độ tin cậy ${_pct(best.prob)} < ${_pct(kThreshold)}). '
                'Hãy chụp lại gần hơn, rõ hơn hoặc đưa biển báo vào giữa khung.',
                style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w600),
              ),
            ),
          Text(confident ? sign.name : 'Có thể là: ${sign.name}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navy)),
          const SizedBox(height: 8),
          Center(
            child: Chip(label: Text('${sign.code} · ${sign.group}', style: const TextStyle(fontWeight: FontWeight.bold, color: navy))),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Độ tin cậy'),
            const Spacer(),
            Text(_pct(best.prob), style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: best.prob,
              minHeight: 10,
              color: confident ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(height: 14),
          _box('Ý nghĩa', Text(sign.meaning, style: const TextStyle(height: 1.4))),
          _box(
            'Khả năng khác',
            Column(
              children: r.top3.skip(1).map((p) {
                final s = SignDb.byId(p.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [Expanded(child: Text(s.name)), Text(_pct(p.prob))]),
                );
              }).toList(),
            ),
          ),
          _box(
            'Thời gian xử lý trên thiết bị',
            Text('Chạy mô hình: ${r.inferenceMs.toStringAsFixed(1)} ms (${r.passes} lượt)   ·   Tổng (kể cả tiền xử lý): ${r.totalMs.toStringAsFixed(1)} ms'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Nhận diện ảnh khác'),
          ),
        ],
      ),
    );
  }

  Widget _box(String title, Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3864))),
          const SizedBox(height: 6),
          child,
        ]),
      );
}
