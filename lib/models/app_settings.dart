/// Ilova sozlamalari — klub nomi, manzili, QR uchun standart matn.
class AppSettings {
  final String clubName;
  final String clubAddress;
  /// Foydalanuvchi "QR kod yozish" maydoniga nima kiritsa (matn, link,
  /// telefon raqami va h.k. — hammasi bitta erkin matn sifatida) shu yerda saqlanadi.
  final String qrDefault;
  /// Ixtiyoriy: QR kod markazidagi kichik logotip (base64 rasm).
  final String qrLogoBase64;

  const AppSettings({
    this.clubName = 'Game Club Timer',
    this.clubAddress = "O'yin klubi",
    this.qrDefault = '',
    this.qrLogoBase64 = '',
  });

  AppSettings copyWith({String? clubName, String? clubAddress, String? qrDefault, String? qrLogoBase64}) {
    return AppSettings(
      clubName: clubName ?? this.clubName,
      clubAddress: clubAddress ?? this.clubAddress,
      qrDefault: qrDefault ?? this.qrDefault,
      qrLogoBase64: qrLogoBase64 ?? this.qrLogoBase64,
    );
  }

  Map<String, dynamic> toMap() => {
    'clubName': clubName,
    'clubAddress': clubAddress,
    'qrDefault': qrDefault,
    'qrLogoBase64': qrLogoBase64,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    clubName: map['clubName'] as String? ?? 'Game Club Timer',
    clubAddress: map['clubAddress'] as String? ?? "O'yin klubi",
    qrDefault: map['qrDefault'] as String? ?? '',
    qrLogoBase64: map['qrLogoBase64'] as String? ?? '',
  );
}
