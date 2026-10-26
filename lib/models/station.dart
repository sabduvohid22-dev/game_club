/// Bitta stansiya (kompyuter / PlayStation / VR va h.k.) modeli.
class Station {
  final String id;
  String name;
  String type;
  int tariffPerHour; // so'm / soat

  String status; // 'idle' | 'active'
  String mode; // 'open' (ochiq hisoblash) | 'fixed' (belgilangan vaqt/summa)

  DateTime? startTime;
  DateTime? endTime; // faqat mode == 'fixed' bo'lsa to'ldiriladi
  double? plannedHours;
  double? plannedCost;
  int? createdOrder;
  double barAmount; // Ichimliklar va h.k. summasi

  Station({
    required this.id,
    required this.name,
    required this.type,
    required this.tariffPerHour,
    this.status = 'idle',
    this.mode = 'open',
    this.startTime,
    this.endTime,
    this.plannedHours,
    this.plannedCost,
    this.createdOrder,
    this.barAmount = 0.0,
  });

  Station copyWith({
    String? name,
    String? type,
    int? tariffPerHour,
    String? status,
    String? mode,
    DateTime? startTime,
    DateTime? endTime,
    double? plannedHours,
    double? plannedCost,
    int? createdOrder,
    double? barAmount,
    bool clearSession = false,
  }) {
    return Station(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      tariffPerHour: tariffPerHour ?? this.tariffPerHour,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      startTime: clearSession ? null : (startTime ?? this.startTime),
      endTime: clearSession ? null : (endTime ?? this.endTime),
      plannedHours: clearSession ? null : (plannedHours ?? this.plannedHours),
      plannedCost: clearSession ? null : (plannedCost ?? this.plannedCost),
      createdOrder: createdOrder ?? this.createdOrder,
      barAmount: clearSession ? 0.0 : (barAmount ?? this.barAmount),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'tariffPerHour': tariffPerHour,
    'status': status,
    'mode': mode,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'plannedHours': plannedHours,
    'plannedCost': plannedCost,
    'createdOrder': createdOrder,
    'barAmount': barAmount,
  };

  factory Station.fromMap(Map<String, dynamic> map) => Station(
    id: map['id'] as String,
    name: map['name'] as String,
    type: map['type'] as String,
    tariffPerHour: map['tariffPerHour'] as int,
    status: map['status'] as String,
    mode: map['mode'] as String,
    startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    plannedHours: (map['plannedHours'] as num?)?.toDouble(),
    plannedCost: (map['plannedCost'] as num?)?.toDouble(),
    createdOrder: map['createdOrder'] as int?,
    barAmount: (map['barAmount'] as num?)?.toDouble() ?? 0.0,
  );
}
