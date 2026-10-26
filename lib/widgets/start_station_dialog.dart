import 'package:flutter/material.dart';
import '../models/station.dart';

/// Natija: [hours] va [cost] — agar foydalanuvchi "ochiq hisoblash"ni
/// tanlasa ikkalasi ham null bo'ladi.
class StartStationResult {
  final double? hours;
  final double? cost;
  StartStationResult({this.hours, this.cost});
}

class StartStationDialog extends StatefulWidget {
  final Station station;
  const StartStationDialog({super.key, required this.station});

  @override
  State<StartStationDialog> createState() => _StartStationDialogState();
}

class _StartStationDialogState extends State<StartStationDialog> {
  final hoursCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  bool fixedMode = false;

  void _recalcFromHours(String v) {
    final h = double.tryParse(v.replaceAll(',', '.'));
    if (h != null) {
      costCtrl.text = (h * widget.station.tariffPerHour).round().toString();
    }
  }

  void _recalcFromCost(String v) {
    final c = double.tryParse(v);
    if (c != null && widget.station.tariffPerHour > 0) {
      hoursCtrl.text = (c / widget.station.tariffPerHour).toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.station.name} — seansni boshlash'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tarif: ${widget.station.tariffPerHour} so'm/soat",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: const Text("Ochiq hisoblash (to'xtatganda hisoblanadi)"),
              value: false,
              groupValue: fixedMode,
              onChanged: (v) => setState(() => fixedMode = v!),
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: const Text("Belgilangan vaqt (soat yoki summa bo'yicha)"),
              value: true,
              groupValue: fixedMode,
              onChanged: (v) => setState(() => fixedMode = v!),
            ),
            if (fixedMode) ...[
              const SizedBox(height: 8),
              TextField(
                controller: hoursCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Necha soat',
                  suffixText: 'soat',
                  border: OutlineInputBorder(),
                ),
                onChanged: _recalcFromHours,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yoki summa',
                  suffixText: "so'm",
                  border: OutlineInputBorder(),
                ),
                onChanged: _recalcFromCost,
              ),
              const SizedBox(height: 6),
              const Text(
                'Ikkalasidan birini kiriting — ikkinchisi avtomatik hisoblanadi.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
        FilledButton(
          onPressed: () {
            if (!fixedMode) {
              Navigator.pop(context, StartStationResult());
              return;
            }
            final h = double.tryParse(hoursCtrl.text.replaceAll(',', '.'));
            final c = double.tryParse(costCtrl.text);
            if (h == null || h <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Vaqt yoki summani to'g'ri kiriting")),
              );
              return;
            }
            Navigator.pop(context, StartStationResult(hours: h, cost: c));
          },
          child: const Text('Boshlash'),
        ),
      ],
    );
  }
}
