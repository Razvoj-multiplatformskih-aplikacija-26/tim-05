import 'package:flutter/material.dart';

Future<String?> prikaziDijalogOdbijanja(BuildContext context, {required String imeStudenta}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DijalogOdbijanja(imeStudenta: imeStudenta),
  );
}

class _DijalogOdbijanja extends StatefulWidget {
  const _DijalogOdbijanja({required this.imeStudenta});

  final String imeStudenta;

  @override
  State<_DijalogOdbijanja> createState() => _DijalogOdbijanjaState();
}

class _DijalogOdbijanjaState extends State<_DijalogOdbijanja> {
  final _razlog = TextEditingController();

  @override
  void dispose() {
    _razlog.dispose();
    super.dispose();
  }

  void _potvrdi() => Navigator.pop(context, _razlog.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odbiti prijavu?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prijava studenta ${widget.imeStudenta} biće odbijena. Ova odluka se ne može promeniti.'),
            const SizedBox(height: 16),
            TextField(
              controller: _razlog,
              autofocus: true,
              maxLines: 1,
              decoration: const InputDecoration(labelText: 'Razlog', helperText: 'Student vidi razlog u svojoj prijavi.'),
              onSubmitted: (_) => _potvrdi(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(onPressed: _potvrdi, child: const Text('Odbij prijavu')),
      ],
    );
  }
}
