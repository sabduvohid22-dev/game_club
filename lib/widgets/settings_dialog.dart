import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_settings.dart';

class SettingsDialog extends StatefulWidget {
  final AppSettings current;
  const SettingsDialog({super.key, required this.current});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final nameCtrl = TextEditingController(text: widget.current.clubName);
  late final addrCtrl = TextEditingController(text: widget.current.clubAddress);
  late final qrCtrl = TextEditingController(text: widget.current.qrDefault);
  late String qrLogoBase64 = widget.current.qrLogoBase64;

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    setState(() => qrLogoBase64 = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sozlamalar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Klub nomi')),
            const SizedBox(height: 10),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Manzil / izoh')),
            const Divider(height: 28),
            const Text('QR kod', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              "Bu yerga xohlagan narsangizni kiriting — link, telefon raqami, "
                  "karta raqami yoki oddiy matn. Hammasini birga ham yozsangiz bo'ladi "
                  "(masalan: \"Instagram: @club | Karta: 8600 xxxx | +998901234567\"). "
                  "Chekdagi QR shu matnni o'zida saqlaydi.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qrCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'QR uchun matn / link / raqam',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (qrLogoBase64.isNotEmpty)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: MemoryImage(base64Decode(qrLogoBase64)), fit: BoxFit.cover),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(qrLogoBase64.isEmpty ? 'QR markaziga logotip qo\'shish' : 'Logotipni almashtirish'),
                ),
                if (qrLogoBase64.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => qrLogoBase64 = ''),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.current.copyWith(
                clubName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                clubAddress: addrCtrl.text.trim(),
                qrDefault: qrCtrl.text.trim(),
                qrLogoBase64: qrLogoBase64,
              ),
            );
          },
          child: const Text('Saqlash'),
        ),
      ],
    );
  }
}
