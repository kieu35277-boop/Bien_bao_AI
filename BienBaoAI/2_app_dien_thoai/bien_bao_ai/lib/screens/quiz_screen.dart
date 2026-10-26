import 'dart:math';
import 'package:flutter/material.dart';
import '../services/signs.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int total = 10;
  final _rnd = Random();
  List<SignInfo> _all = [];
  late SignInfo _answer;
  List<SignInfo> _options = [];
  int _index = 0, _score = 0;
  int? _chosen;

  @override
  void initState() {
    super.initState();
    SignDb.load().then((v) {
      // bỏ biển không có trong QCVN khỏi bài ôn tập
      _all = v.where((s) => s.code != '—').toList();
      if (mounted) _next();
    });
  }

  void _next() {
    final pool = List<SignInfo>.from(_all)..shuffle(_rnd);
    setState(() {
      _answer = pool.first;
      _options = pool.take(4).toList()..shuffle(_rnd);
      _chosen = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_options.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_index >= total) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ôn tập trắc nghiệm')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Bạn trả lời đúng $_score/$total câu', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _index = 0;
                  _score = 0;
                });
                _next();
              },
              child: const Text('Làm lại'),
            ),
          ]),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Câu ${_index + 1}/$total')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Biển báo này có tên là gì?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(_answer.asset, width: 160, height: 160, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
          ),
        ),
        const SizedBox(height: 16),
        ..._options.map((o) {
          Color? bg;
          if (_chosen != null) {
            if (o.id == _answer.id) {
              bg = Colors.green.shade100;
            } else if (o.id == _chosen) {
              bg = Colors.red.shade100;
            }
          }
          return Card(
            color: bg ?? Colors.white,
            child: ListTile(
              title: Text(o.name),
              onTap: _chosen != null
                  ? null
                  : () => setState(() {
                        _chosen = o.id;
                        if (o.id == _answer.id) _score++;
                      }),
            ),
          );
        }),
        if (_chosen != null) ...[
          const SizedBox(height: 8),
          Text('${_answer.code}: ${_answer.meaning}'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() => _index++);
              if (_index < total) _next();
            },
            child: Text(_index + 1 < total ? 'Câu tiếp theo' : 'Xem kết quả'),
          ),
        ],
      ]),
    );
  }
}
