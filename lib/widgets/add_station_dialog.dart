import 'package:flutter/material.dart';

import '../models/station.dart';

class AddStationResult {
  final String name;
  final String type;
  final int tariff;
  AddStationResult({required this.name, required this.type, required this.tariff});
}

class AddStationDialog extends StatefulWidget {
  final Station? existing;
  const AddStationDialog({super.key, this.existing});

  @override
  State<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends State<AddStationDialog> {
  late final nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final tariffCtrl = TextEditingController(text: widget.existing?.tariffPerHour.toString() ?? '15000');
  late String type = widget.existing?.type ?? 'PC';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Yangi stansiya' : 'Stansiyani tahrirlash'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nomi (masalan PC-4)'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: type,
            items: ['PC', 'PlayStation', 'Xbox', 'VR', 'Billiard']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => type = v!),
            decoration: const InputDecoration(labelText: 'Turi'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: tariffCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Tarif (so'm/soat)"),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
        FilledButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              AddStationResult(
                name: nameCtrl.text.trim(),
                type: type,
                tariff: int.tryParse(tariffCtrl.text) ?? 0,
              ),
            );
          },
          child: Text(widget.existing == null ? "Qo'shish" : "Saqlash"),
        ),
      ],
    );
  }
}
