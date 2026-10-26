/// Yakunlangan seans / chek yozuvi — tarix uchun saqlanadi.
class Receipt {
  final int? id;
  final int receiptNumber;
  final String stationId;
  final String stationName;
  final String stationType;
  final int tariffPerHour;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double total; // so'm
  final double barAmount; // alohida bar summasi
  final String? qrData;

  Receipt({
    this.id,
    required this.receiptNumber,
    required this.stationId,
    required this.stationName,
    required this.stationType,
    required this.tariffPerHour,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.total,
    this.barAmount = 0.0,
    this.qrData,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'receiptNumber': receiptNumber,
    'stationId': stationId,
    'stationName': stationName,
    'stationType': stationType,
    'tariffPerHour': tariffPerHour,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationSeconds': durationSeconds,
    'total': total,
    'barAmount': barAmount,
    'qrData': qrData,
  };

  factory Receipt.fromMap(Map<String, dynamic> map) => Receipt(
    id: map['id'] as int?,
    receiptNumber: map['receiptNumber'] as int,
    stationId: map['stationId'] as String,
    stationName: map['stationName'] as String,
    stationType: map['stationType'] as String,
    tariffPerHour: map['tariffPerHour'] as int,
    startTime: DateTime.parse(map['startTime']),
    endTime: DateTime.parse(map['endTime']),
    durationSeconds: map['durationSeconds'] as int,
    total: (map['total'] as num).toDouble(),
    barAmount: (map['barAmount'] as num?)?.toDouble() ?? 0.0,
    qrData: map['qrData'] as String?,
  );
}
