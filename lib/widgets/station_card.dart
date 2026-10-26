import 'package:flutter/material.dart';
import '../models/station.dart';

String fmtDuration(int seconds) {
  final h = (seconds ~/ 3600).toString().padLeft(2, '0');
  final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String fmtMoney(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDelete;

  const StationCard({
    super.key,
    required this.station,
    required this.onStart,
    required this.onStop,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = station.status == 'active';
    final isFixed = station.mode == 'fixed';

    Duration elapsed = Duration.zero;
    Duration? remaining;
    if (active && station.startTime != null) {
      elapsed = DateTime.now().difference(station.startTime!);
      if (isFixed && station.endTime != null) {
        remaining = station.endTime!.difference(DateTime.now());
      }
    }
    final overtime = isFixed && remaining != null && remaining.isNegative;
    final statusColor = active ? (overtime ? Colors.redAccent : Colors.amber) : Colors.greenAccent.shade400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFF8B5CF6).withOpacity(0.6) : const Color(0xFF232D40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(station.type, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  active ? (overtime ? 'VAQT TUGADI' : 'Band') : "Bo'sh",
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              active
                  ? (isFixed && remaining != null ? fmtDuration(remaining.inSeconds.abs()) : fmtDuration(elapsed.inSeconds))
                  : '00:00:00',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: active ? const Color(0xFF22D3EE) : Colors.grey,
              ),
            ),
          ),
          if (active && isFixed)
            Center(
              child: Text(
                overtime ? "belgilangan vaqtdan oshdi" : 'qolgan vaqt',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${fmtMoney(station.tariffPerHour)} so'm/soat", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (active)
                Text(
                  "${fmtMoney((elapsed.inSeconds / 3600) * station.tariffPerHour)} so'm",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (active)
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: onStop,
                    child: const Text('Tugatish'),
                  ),
                )
              else ...[
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: onStart,
                    child: const Text('Boshlash'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.close, size: 18, color: Colors.grey)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
