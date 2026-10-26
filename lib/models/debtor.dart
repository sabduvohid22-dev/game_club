/// Qarzdor mijoz yozuvi — "Qarz daftari" uchun.
class Debtor {
  final String id;
  String name;
  String phone;
  double amount; // qarz summasi (so'm)
  String? stationName; // Qaysi xonadan qarz bo'lgani
  String? history; // Qarzlar tarixi (masalan: "10000 + 5000")
  DateTime createdAt;
  bool paid;

  Debtor({
    required this.id,
    required this.name,
    required this.phone,
    required this.amount,
    this.stationName,
    this.history,
    DateTime? createdAt,
    this.paid = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'amount': amount,
    'stationName': stationName,
    'history': history,
    'createdAt': createdAt.toIso8601String(),
    'paid': paid,
  };

  factory Debtor.fromMap(Map<String, dynamic> map) => Debtor(
    id: map['id'] as String,
    name: map['name'] as String,
    phone: map['phone'] as String,
    amount: (map['amount'] as num).toDouble(),
    stationName: map['stationName'] as String?,
    history: map['history'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    paid: map['paid'] as bool? ?? false,
  );
}
