# Java ogohlantirishlarini va Build jarayonini tozalash

Rasmda ko'ringan qizil yozuvlar aslida xatolik emas, balki Java versiyasi haqidagi ogohlantirishlardir. Build jarayoni hali davom etmoqda (progress bar ko'rinib turibdi). Biroq, bu ogohlantirishlarni yo'qotish konsolni toza saqlashga yordam beradi.

## Taklif etilayotgan o'zgarishlar

### Android konfiguratsiyasi

#### [MODIFY] [build.gradle.kts](file:///C:/Users/user/StudioProjects/game_club/android/build.gradle.kts)
- `subprojects` blokiga Java 17 versiyasini barcha modullar uchun qo'llash qoidasini qo'shish. Bu pluginlardan kelayotgan Java 8 haqidagi ogohlantirishlarni to'xtatadi.

## Tekshirish rejasi

### Manual tekshirish
- `flutter run` yoki `flutter build apk` buyrug'ini ishga tushirib, ogohlantirishlar yo'qligini va build muvaffaqiyatli yakunlanishini tekshirish.

> [!NOTE]
> Agar ilova yig'ilishi juda uzoq davom etsa yoki oxirida "BUILD FAILED" chiqsa, logning eng pastki qismini ko'rsatishingizni so'rayman. Hozircha bu shunchaki ogohlantirish.
