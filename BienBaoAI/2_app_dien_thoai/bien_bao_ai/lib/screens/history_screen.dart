import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/history.dart';
import '../services/signs.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem>? _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await SignDb.load();
    final v = await HistoryStore.load();
    if (mounted) setState(() => _items = v);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _time(DateTime t) => '${_two(t.day)}/${_two(t.month)}/${t.year} ${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  /// Bấm lần nữa vào nút đang chọn thì bỏ đánh dấu.
  Future<void> _mark(HistoryItem h, bool value) async {
    setState(() => h.correct = (h.correct == value) ? null : value);
    await HistoryStore.saveAll(_items!);
  }

  /// Sao chép toàn bộ lịch sử dạng CSV (dán vào Zalo / Ghi chú / Excel để gửi đi).
  Future<void> _copyCsv() async {
    final items = _items!;
    final b = StringBuffer('stt,thoi_gian,nhan,ma_hieu,ten_bien,do_tin_cay_pct,vuot_nguong_60,thoi_gian_ms,danh_gia\n');
    // stt 1 = lần chạy đầu tiên (danh sách hiển thị lần mới nhất ở trên cùng)
    for (var i = 0; i < items.length; i++) {
      final h = items[items.length - 1 - i];
      final s = SignDb.byId(h.signId);
      final dg = h.correct == null ? '' : (h.correct! ? 'dung' : 'sai');
      b.writeln('${i + 1},${_time(h.time)},${h.signId},${s.code},"${s.name.replaceAll('"', "'")}",'
          '${(h.prob * 100).toStringAsFixed(1)},${h.confident ? 1 : 0},${h.inferenceMs.toStringAsFixed(1)},$dg');
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã sao chép ${items.length} dòng. Dán vào Zalo hoặc Ghi chú để gửi đi.')));
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử?'),
        content: const Text('Nên bấm “Sao chép kết quả” trước khi xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) {
      await HistoryStore.clear();
      _reload();
    }
  }

  Widget _summary(List<HistoryItem> items) {
    final n = items.length;
    final avgMs = items.map((e) => e.inferenceMs).reduce((a, b) => a + b) / n;
    final over = items.where((e) => e.confident).length;
    final marked = items.where((e) => e.correct != null).toList();
    final right = marked.where((e) => e.correct!).length;
    final acc = marked.isEmpty ? '–' : '${(right / marked.length * 100).toStringAsFixed(1)}%';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Số lần: $n   ·   Thời gian chạy mô hình TB: ${avgMs.toStringAsFixed(1)} ms',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Vượt ngưỡng 60%: $over/$n   ·   Đã đánh dấu: ${marked.length}   ·   Đúng: $right ($acc)'),
        const SizedBox(height: 4),
        const Text('Bấm ✓ nếu app nhận diện đúng biển, ✗ nếu sai.', style: TextStyle(fontSize: 12, color: Colors.black54)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final hasItems = items != null && items.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử nhận diện'), actions: [
        IconButton(tooltip: 'Sao chép kết quả', icon: const Icon(Icons.copy_all), onPressed: hasItems ? _copyCsv : null),
        IconButton(tooltip: 'Xóa lịch sử', icon: const Icon(Icons.delete_outline), onPressed: hasItems ? _confirmClear : null),
      ]),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Chưa có lần nhận diện nào'))
              : Column(children: [
                  _summary(items),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final h = items[i];
                        final s = SignDb.byId(h.signId);
                        final t = h.time;
                        return ListTile(
                          leading: Image.asset(s.asset, width: 40, height: 40, fit: BoxFit.cover),
                          title: Text(h.confident ? s.name : 'Chưa chắc chắn: ${s.name}'),
                          subtitle: Text('#${items.length - i}  ·  ${_two(t.day)}/${_two(t.month)} ${_two(t.hour)}:${_two(t.minute)}  ·  '
                              '${(h.prob * 100).toStringAsFixed(1)}%  ·  ${h.inferenceMs.toStringAsFixed(1)} ms'),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              tooltip: 'Đúng',
                              icon: Icon(Icons.check_circle, color: h.correct == true ? Colors.green : Colors.black26),
                              onPressed: () => _mark(h, true),
                            ),
                            IconButton(
                              tooltip: 'Sai',
                              icon: Icon(Icons.cancel, color: h.correct == false ? Colors.red : Colors.black26),
                              onPressed: () => _mark(h, false),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                ]),
    );
  }
}
