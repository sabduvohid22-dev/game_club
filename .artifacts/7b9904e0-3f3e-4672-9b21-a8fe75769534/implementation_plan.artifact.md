# Dasturni yangilash va xotiralarni (ma'lumotlarni) saqlash

Ushbu reja dasturni yangi talqinga o'tkazish, uni ish stoliga qulay qilib joylash va eng muhimi — barcha eski ma'lumotlarni (cheklar, qarzlar) xavfsiz joyga ko'chirishni o'z ichiga oladi.

## Foydalanuvchi tekshiruvi talab etiladi

> [!IMPORTANT]
> Ma'lumotlar bazasi endi loyiha papkasidan operatsion tizimning maxsus **AppData** papkasiga ko'chiriladi. Bu kelajakda dastur yangilanganda yoki tozalanganda (clean) ma'lumotlar o'chib ketmasligini ta'minlaydi.

## Taklif etilayotgan o'zgarishlar

### Ma'lumotlar bazasi xavfsizligi

#### [MODIFY] [db_service.dart](file:///C:/Users/user/StudioProjects/game_club/lib/services/db_service.dart)
- `path_provider` kutubxonasidan foydalanib, bazani doimiy AppData papkasida saqlash.
- Agar eski joyda (`.dart_tool`) ma'lumotlar bo'lsa, ularni avtomatik yangi joyga ko'chirish (migratsiya).

### Dasturni yig'ish va o'rnatish

#### [ACTION] Dasturni qayta yig'ish (Build)
- Yangi saqlash tizimi bilan Windows versiyasini Build qilish.

#### [ACTION] Ish stoliga joylash
- Ish stolida (Desktop) **"NEON ARENA Hisoblagich"** nomli yarlik yaratish.
- Unga maxsus ikonka biriktirish.

## Tekshirish rejasi

### Qo'lda tekshirish
1.  Dasturni ishga tushirish.
2.  Eski cheklar va qarzdorlar ro'yxati joyidami yoki yo'qligini ko'rish.
3.  Yangi ma'lumot kiritib, dasturni yopib-ochganda saqlanib qolayotganini tekshirish.
