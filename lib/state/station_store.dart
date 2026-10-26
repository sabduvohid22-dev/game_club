import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/station.dart';
import '../models/receipt.dart';
import '../models/app_settings.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';

class StationStore extends ChangeNotifier {
  List<Station> stations = [];
  AppSettings settings = const AppSettings();

  int todayCount = 0;
  double todaySum = 0;

  Timer? _ticker;
  final Set<String> _notifiedStations = {};
  final Set<String> _stoppingStations = {};

  final _sessionEndedController = StreamController<Station>.broadcast();
  Stream<Station> get sessionEndedStream => _sessionEndedController.stream;

  int get busyCount => stations.where((s) => s.status == 'active').length;
  int get freeCount => stations.length - busyCount;

  Future<void> init() async {
    try {
      await NotificationService.instance.init();

      settings = await DbService.instance.getSettings();
      stations = await DbService.instance.getStations();

      if (stations.isEmpty) {
        final defaults = [
          Station(id: _newId(), name: 'PC-1', type: 'PC', tariffPerHour: 15000, createdOrder: 0),
          Station(id: _newId(), name: 'PC-2', type: 'PC', tariffPerHour: 15000, createdOrder: 1),
          Station(id: _newId(), name: 'PS5-1', type: 'PlayStation', tariffPerHour: 25000, createdOrder: 2),
        ];
        for (int i = 0; i < defaults.length; i++) {
          await DbService.instance.upsertStation(defaults[i], order: i);
        }
        stations = defaults;
      }

      await _refreshStats();
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      notifyListeners();
    } catch (e) {
      debugPrint("StationStore init error: $e");
    }
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  Future<void> _refreshStats() async {
    try {
      todayCount = await DbService.instance.todayReceiptCount();
      todaySum = await DbService.instance.todayTotal();
    } catch (e) {
      debugPrint("Stats error: $e");
    }
  }

  // ---------------- Stations ----------------

  Future<void> addStation({required String name, required String type, required int tariff}) async {
    final s = Station(
      id: _newId(),
      name: name,
      type: type,
      tariffPerHour: tariff,
      createdOrder: stations.length,
    );
    stations.add(s);
    await DbService.instance.upsertStation(s, order: stations.length - 1);
    notifyListeners();
  }

  Future<void> editStation({required String id, required String name, required String type, required int tariff}) async {
    final idx = stations.indexWhere((s) => s.id == id);
    if (idx == -1) return;

    final s = stations[idx];
    // Agar xonada o'yin ketayotgan bo'lsa, uni to'xtatamiz
    if (s.status == 'active') {
      await stopStation(id);
    }

    // Keyin yangi ma'lumotlarni saqlaymiz
    final updated = stations[idx].copyWith(name: name, type: type, tariffPerHour: tariff);
    stations[idx] = updated;
    await DbService.instance.upsertStation(updated);
    notifyListeners();
  }

  Future<void> deleteStation(String id) async {
    stations.removeWhere((s) => s.id == id);
    await DbService.instance.deleteStation(id);
    notifyListeners();
  }

  Future<void> startStation(String id, {double? plannedHours, double? plannedCost}) async {
    final idx = stations.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final s = stations[idx];

    final start = DateTime.now();
    DateTime? end;
    String mode = 'open';
    if (plannedHours != null && plannedHours > 0) {
      mode = 'fixed';
      end = start.add(Duration(seconds: (plannedHours * 3600).round()));
    }

    final updated = s.copyWith(
      status: 'active',
      mode: mode,
      startTime: start,
      endTime: end,
      plannedHours: plannedHours,
      plannedCost: plannedCost,
    );
    stations[idx] = updated;
    await DbService.instance.upsertStation(updated);

    if (mode == 'fixed' && end != null) {
      await NotificationService.instance.scheduleEndAlarm(
        id: updated.id.hashCode,
        endTime: end,
        stationName: updated.name,
      );
    }
    notifyListeners();
  }

  Future<Receipt> stopStation(String id) async {
    final idx = stations.indexWhere((s) => s.id == id);
    if (idx == -1) throw Exception("Stansiya topilmadi: $id");
    
    final s = stations[idx];
    
    // 1. Zudlik bilan holatni o'zgartirish (UI uchun)
    _stoppingStations.add(id);
    _notifiedStations.remove(id);
    
    final updated = s.copyWith(status: 'idle', clearSession: true);
    stations[idx] = updated;
    notifyListeners(); // Ekranda darhol "Bo'sh" bo'lib ko'rinadi

    final endTime = DateTime.now();
    final startTime = s.startTime ?? endTime;
    int durationSeconds = endTime.difference(startTime).inSeconds;
    if (durationSeconds < 1) durationSeconds = 1;

    final rawCost = (durationSeconds / 3600) * s.tariffPerHour;
    double calculatedTotal = (rawCost / 500).round() * 500.0;
    if (calculatedTotal < 500 && durationSeconds > 10) calculatedTotal = 500;
    final total = calculatedTotal + s.barAmount;

    // 2. Fon vazifalarini bajarish (bazaga yozish va h.k.)
    // Budilnikni fon rejimida o'chiramiz
    if (s.mode == 'fixed') {
      NotificationService.instance.cancelAlarm(s.id.hashCode).catchError((e) => debugPrint("Alarm cancel error: $e"));
    }

    Receipt? receipt;
    try {
      final receiptNumber = await DbService.instance.nextReceiptNumber();
      receipt = Receipt(
        receiptNumber: receiptNumber,
        stationId: s.id,
        stationName: s.name,
        stationType: s.type,
        tariffPerHour: s.tariffPerHour,
        startTime: startTime,
        endTime: endTime,
        durationSeconds: durationSeconds,
        total: total,
        barAmount: s.barAmount,
        qrData: settings.qrDefault.isNotEmpty ? settings.qrDefault : null,
      );
      
      await DbService.instance.insertReceipt(receipt);
      await DbService.instance.upsertStation(updated);
      _refreshStats(); // Fon rejimida yangilaymiz
    } catch (e) {
      debugPrint("stopStation Background DB Error: $e");
      // Agar bazada xato bo'lsa ham receipt obyektini qaytaramiz (UI to'xtab qolmasligi uchun)
      receipt ??= Receipt(
        receiptNumber: 0,
        stationId: s.id,
        stationName: s.name,
        stationType: s.type,
        tariffPerHour: s.tariffPerHour,
        startTime: startTime,
        endTime: endTime,
        durationSeconds: durationSeconds,
        total: total,
        barAmount: s.barAmount,
      );
    } finally {
      _stoppingStations.remove(id);
    }
    
    return receipt;
  }

  Future<void> addBar(String id, double amount) async {
    final idx = stations.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final updated = stations[idx].copyWith(barAmount: stations[idx].barAmount + amount);
    stations[idx] = updated;
    await DbService.instance.upsertStation(updated);
    notifyListeners();
  }

  Future<void> applyPenalty(String id, int minutes) async {
    final idx = stations.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final s = stations[idx];
    if (s.mode != 'fixed' || s.endTime == null) return;

    final updated = s.copyWith(endTime: s.endTime!.subtract(Duration(minutes: minutes)));
    stations[idx] = updated;
    await DbService.instance.upsertStation(updated);

    // Alarmni qayta rejalashtirish
    await NotificationService.instance.cancelAlarm(updated.id.hashCode);
    if (updated.endTime!.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleEndAlarm(
        id: updated.id.hashCode,
        endTime: updated.endTime!,
        stationName: updated.name,
      );
    }
    notifyListeners();
  }

  void _tick() {
    final now = DateTime.now();
    
    // Faqat faol va VIP bo'lgan, vaqti o'tgan stansiyalarni qidiramiz
    final expired = stations.where((s) {
      return s.status == 'active' && 
             s.mode == 'fixed' && 
             s.endTime != null && 
             now.isAfter(s.endTime!) &&
             !_stoppingStations.contains(s.id); // O'chirilayotganlarni chetlab o'tamiz
    }).toList();
    
    if (expired.isNotEmpty) {
      for (final s in expired) {
        // Agar bu stansiya uchun hali signal berilmagan bo'lsa
        if (!_notifiedStations.contains(s.id)) {
          _notifiedStations.add(s.id);
          _sessionEndedController.add(s);
          debugPrint("Signal emitted for station: ${s.name}");
        }
      }
    }
    
    notifyListeners();
  }

  // ---------------- Settings ----------------

  Future<void> saveSettings(AppSettings newSettings) async {
    settings = newSettings;
    await DbService.instance.saveSettings(newSettings);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sessionEndedController.close();
    super.dispose();
  }
}
