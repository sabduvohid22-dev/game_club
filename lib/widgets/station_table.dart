import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../state/station_store.dart';
import 'station_card.dart' show fmtDuration, fmtMoney;

final _timeFmt = DateFormat('HH:mm:ss');

class StationTable extends StatelessWidget {
  final List<Station> stations;
  final void Function(Station) onStart;
  final void Function(Station) onStop;

  const StationTable({
    super.key,
    required this.stations,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 28),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF131A28)),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(label: Text('Stansiya')),
            DataColumn(label: Text('Boshlanish')),
            DataColumn(label: Text("O'tgan vaqt")),
            DataColumn(label: Text('Holat')),
            DataColumn(label: Text('Qolgan')),
            DataColumn(label: Text('Tugash')),
            DataColumn(label: Text('Narx')),
            DataColumn(label: Text('Menyu')),
          ],
          rows: stations.map((s) => _buildRow(context, s)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Station s) {
    final active = s.status == 'active';
    final isFixed = s.mode == 'fixed';
    final store = context.read<StationStore>();

    Duration elapsed = Duration.zero;
    Duration? remaining;
    if (active && s.startTime != null) {
      elapsed = DateTime.now().difference(s.startTime!);
      if (isFixed && s.endTime != null) {
        remaining = s.endTime!.difference(DateTime.now());
      }
    }
    final overtime = isFixed && remaining != null && remaining.isNegative;
    
    final double rawCost = active ? (elapsed.inSeconds / 3600) * s.tariffPerHour : 0.0;
    final double currentCost = ((rawCost / 500).round() * 500.0) + s.barAmount;

    Color statusColor = active ? (overtime ? Colors.redAccent : Colors.amber) : Colors.greenAccent.shade400;
    String statusText = active ? (overtime ? 'VAQT TUGADI' : 'Band') : 'Bo\'sh';

    return DataRow(
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (isFixed && active) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            Text(s.type, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )),
        DataCell(Text(active && s.startTime != null ? _timeFmt.format(s.startTime!) : '--:--:--')),
        DataCell(Text(
          active ? fmtDuration(elapsed.inSeconds) : '00:00:00',
          style: const TextStyle(fontFamily: 'monospace'),
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
        )),
        DataCell(Text(
          isFixed && remaining != null 
              ? (remaining.isNegative ? "00:00:00" : fmtDuration(remaining.inSeconds)) 
              : '—',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
            color: (active && isFixed && remaining != null && remaining.inSeconds < 300) ? Colors.redAccent : Colors.greenAccent,
          ),
        )),
        DataCell(Text(isFixed && s.endTime != null ? _timeFmt.format(s.endTime!) : '--:--:--')),
        DataCell(Text(
          active ? "${fmtMoney(currentCost)} so'm" : "${fmtMoney(s.tariffPerHour.toDouble())}/soat",
          style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.greenAccent : null),
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => onStop(s),
                child: const Text('Tugatish', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) async {
                  if (val == 'penalty') {
                    _showPenaltyDialog(context, store, s.id);
                  } else if (val == 'bar') {
                    _showBarDialog(context, store, s.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'penalty', child: Text('Shtraf (minut)')),
                  const PopupMenuItem(value: 'bar', child: Text('Bar (summa)')),
                ],
              ),
            ] else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade400,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => onStart(s),
                child: const Text('Boshlash', style: TextStyle(fontSize: 12)),
              ),
          ],
        )),
      ],
    );
  }

  void _showPenaltyDialog(BuildContext context, StationStore store, String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shtraf berish'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Necha minut ayirish kerak?', suffixText: 'min'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          FilledButton(
              onPressed: () {
                final mins = int.tryParse(ctrl.text) ?? 0;
                if (mins > 0) store.applyPenalty(id, mins);
                Navigator.pop(ctx);
              },
              child: const Text('Ayirish')),
        ],
      ),
    );
  }

  void _showBarDialog(BuildContext context, StationStore store, String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bar qo\'shish'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Summa (so\'m)', suffixText: 'so\'m'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          FilledButton(
              onPressed: () {
                final amount = double.tryParse(ctrl.text) ?? 0;
                if (amount > 0) store.addBar(id, amount);
                Navigator.pop(ctx);
              },
              child: const Text('Qo\'shish')),
        ],
      ),
    );
  }
}
