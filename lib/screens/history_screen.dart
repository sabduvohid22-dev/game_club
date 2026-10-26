import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/receipt.dart';
import '../services/db_service.dart';
import '../services/pdf_receipt_service.dart';
import '../state/station_store.dart';
import '../widgets/station_card.dart' show fmtDuration, fmtMoney;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Receipt> _receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allReceipts = await DbService.instance.getReceipts();
    final now = DateTime.now();
    // 30 kunlik cheklar (yoki hammasini ko'rish uchun filterni olib tashlang)
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final filtered = allReceipts.where((r) => r.endTime.isAfter(thirtyDaysAgo)).toList();

    setState(() {
      _receipts = filtered;
      _loading = false;
    });
  }

  double get _todayTotal {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return _receipts
        .where((r) => r.endTime.toIso8601String().startsWith(todayStr))
        .fold(0.0, (sum, r) => sum + r.total);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Cheklar tarixi')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A28),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('Bugungi tushum', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("${fmtMoney(_todayTotal)} so'm",
                            style: const TextStyle(
                                color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _receipts.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text("Oxirgi 7 kunda cheklar yo'q", style: TextStyle(color: Colors.grey))),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _receipts.length,
                            itemBuilder: (ctx, i) {
                              final r = _receipts[i];
                              final currentDay = DateFormat('dd.MM.yyyy').format(r.endTime);
                              final prevDay = i > 0 ? DateFormat('dd.MM.yyyy').format(_receipts[i - 1].endTime) : null;
                              final showHeader = currentDay != prevDay;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showHeader)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: Text(
                                        currentDay == DateFormat('dd.MM.yyyy').format(DateTime.now())
                                            ? 'Bugun'
                                            : currentDay,
                                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: CircleAvatar(child: Text('#${r.receiptNumber}')),
                                      title: Text("${r.stationName} · ${fmtMoney(r.total)} so'm"),
                                      subtitle: Text(
                                          '${DateFormat('HH:mm').format(r.endTime)} · davomiyligi ${fmtDuration(r.durationSeconds)}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.print_outlined),
                                        onPressed: () {
                                          final settings = context.read<StationStore>().settings;
                                          PdfReceiptService.printReceipt(
                                            r,
                                            clubName: settings.clubName,
                                            clubAddr: settings.clubAddress,
                                            qrLogoBase64: settings.qrLogoBase64,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
