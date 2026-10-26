import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/station_store.dart';
import '../models/station.dart';
import '../widgets/station_table.dart';
import '../widgets/station_card.dart';
import '../widgets/start_station_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../services/pdf_receipt_service.dart';
import 'history_screen.dart';
import 'debtors_screen.dart';
import 'station_management_screen.dart';
import '../main.dart'; // navigatorKey uchun

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _endedSub;
  final Set<String> _showingDialogs = {};

  @override
  void initState() {
    super.initState();
    final store = context.read<StationStore>();
    _endedSub = store.sessionEndedStream.listen((station) {
      _showSessionEndedDialog(station);
    });
  }

  void _showSessionEndedDialog(Station station) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    // Agar bu stansiya uchun dialog allaqachon ochiq bo'lsa, qayta ochmaymiz
    if (_showingDialogs.contains(station.id)) return;
    _showingDialogs.add(station.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Text('⏰ VAQT TUGADI!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm_on, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              "${station.name} xonasida vaqt yakunlandi.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text(
              "Sessiyani yakunlash turini tanlang:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700, foregroundColor: Colors.black),
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () async {
                  Navigator.pop(context);
                  _showingDialogs.remove(station.id);
                  // handleStop vaqt tugaganini bilib, tasdiqlamasdan to'xtatadi
                  await _handleStop(station);
                },
                label: const Text('TUGATISH (Bo\'shatish)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: Colors.black),
                icon: const Icon(Icons.print_outlined),
                onPressed: () async {
                  final store = context.read<StationStore>();
                  try {
                    Navigator.pop(context);
                    _showingDialogs.remove(station.id);
                    
                    final receipt = await store.stopStation(station.id);
                    await PdfReceiptService.printReceipt(
                      receipt,
                      clubName: store.settings.clubName,
                      clubAddr: store.settings.clubAddress,
                      qrLogoBase64: store.settings.qrLogoBase64,
                    );
                  } catch (e) {
                    debugPrint("Dialog Action Error (Print): $e");
                  }
                },
                label: const Text('CHOP ETISH'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                icon: const Icon(Icons.menu_book_outlined),
                onPressed: () async {
                  final store = context.read<StationStore>();
                  try {
                    Navigator.pop(context);
                    _showingDialogs.remove(station.id);
                    
                    final receipt = await store.stopStation(station.id);
                    if (mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DebtorsScreen(
                            initialAmount: receipt.total,
                            initialStation: receipt.stationName,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Dialog Action Error (Debt): $e");
                  }
                },
                label: const Text('QARZGA YOZISH'),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () {
                  Navigator.pop(context);
                  _showingDialogs.remove(station.id);
                },
                child: const Text('YOPISH (Hozircha qolsun)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _endedSub?.cancel();
    super.dispose();
  }

  Future<void> _handleStart(Station st) async {
    final store = context.read<StationStore>();
    final result = await showDialog<StartStationResult>(
      context: context,
      builder: (_) => StartStationDialog(station: st),
    );
    if (result == null) return;
    await store.startStation(st.id, plannedHours: result.hours, plannedCost: result.cost);
  }

  Future<void> _handleStop(Station st) async {
    final store = context.read<StationStore>();
    
    _showingDialogs.add(st.id);

    final now = DateTime.now();
    final startTime = st.startTime ?? now;
    final duration = now.difference(startTime);
    final rawCost = (duration.inSeconds / 3600) * st.tariffPerHour;
    final currentTotal = ((rawCost / 500).round() * 500.0) + st.barAmount;

    // Vaqt tugaganini tekshiramiz
    final isExpired = st.endTime != null && now.isAfter(st.endTime!);

    if (!mounted) return;

    try {
      bool proceed = false;
      if (isExpired) {
        // Vaqt tugagan bo'lsa, tasdiqlashni so'ramaymiz
        proceed = true;
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tasdiqlash'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${st.name} xonasi seansi tugatilsinmi?"),
                const SizedBox(height: 12),
                const Divider(),
                Text("Vaqt: ${duration.inHours}s ${duration.inMinutes % 60}m",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Jami: ${fmtMoney(currentTotal)} so'm",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BEKOR QILISH')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true), 
                child: const Text('OK, TUGATILSIN'),
              ),
            ],
          ),
        );
        proceed = confirm == true;
      }

      if (proceed) {
        final receipt = await store.stopStation(st.id);
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          await _showReceiptDialog(receipt);
        }
      }
    } catch (e) {
      debugPrint("Stop Station Error: $e");
    } finally {
      _showingDialogs.remove(st.id);
    }
  }

  Future<void> _showReceiptDialog(receipt) async {
    final store = context.read<StationStore>();
    final printReceipt = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Seans yakunlandi'),
        content: Text(
            "Xona muvaffaqiyatli bo'shatildi.\n"
            "Jami to'lov: ${fmtMoney(receipt.total)} so'm.\n\n"
            "Chek chiqarilsinmi?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx, false);
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DebtorsScreen(
                      initialAmount: receipt.total,
                      initialStation: receipt.stationName,
                    ),
                  ),
                );
              }
            }, 
            child: const Text('QARZGA YOZISH'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('KERAK EMAS'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('HA, CHOP ETILSIN'),
          ),
        ],
      ),
    );

    if (printReceipt == true && mounted) {
      await PdfReceiptService.printReceipt(
        receipt,
        clubName: store.settings.clubName,
        clubAddr: store.settings.clubAddress,
        qrLogoBase64: store.settings.qrLogoBase64,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StationStore>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(store.settings.clubName),
        actions: [
          IconButton(
            tooltip: 'Xonalarni boshqarish',
            icon: const Icon(Icons.edit_note),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const StationManagementScreen())),
          ),
          IconButton(
            tooltip: 'Tarix',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            tooltip: 'Qarz daftari',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtorsScreen())),
          ),
          IconButton(
            tooltip: 'Sozlamalar',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (_) => SettingsDialog(current: store.settings),
              );
              if (result != null) await store.saveSettings(result);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => store.init(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isDesktop ? 3.0 : 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _StatBox(label: 'Band', value: '${store.busyCount}', color: Colors.orange),
                    _StatBox(label: "Bo'sh", value: '${store.freeCount}', color: Colors.green),
                    _StatBox(label: 'Bugungi cheklar', value: '${store.todayCount}', color: Colors.cyan),
                    _StatBox(label: 'Xonalar soni', value: '${store.stations.length}', color: Colors.purple),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Stansiyalar', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: StationTable(
                    stations: store.stations,
                    onStart: (st) => _handleStart(st),
                    onStop: (st) => _handleStop(st),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
