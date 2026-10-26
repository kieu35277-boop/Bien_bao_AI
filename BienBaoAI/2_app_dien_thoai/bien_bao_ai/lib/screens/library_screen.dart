import 'package:flutter/material.dart';
import '../services/signs.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<SignInfo> _all = [];
  String _query = '';
  String _group = 'Tất cả';

  @override
  void initState() {
    super.initState();
    SignDb.load().then((v) {
      if (mounted) setState(() => _all = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = ['Tất cả', ..._all.map((e) => e.group).toSet()];
    final q = _query.toLowerCase();
    final list = _all
        .where((s) => _group == 'Tất cả' || s.group == _group)
        .where((s) => q.isEmpty || s.name.toLowerCase().contains(q) || s.code.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tra cứu biển báo')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã biển…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: groups
                .map((g) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(label: Text(g), selected: _group == g, onSelected: (_) => setState(() => _group = g)),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final s = list[i];
              return Card(
                color: Colors.white,
                child: ExpansionTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(s.asset, width: 44, height: 44, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                  ),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${s.code} · ${s.group}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [Align(alignment: Alignment.centerLeft, child: Text(s.meaning))],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
