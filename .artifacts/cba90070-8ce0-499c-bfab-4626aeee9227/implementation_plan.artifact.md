# Seansni yakunlash va Dialoglar takrorlanishini tuzatish

Ushbu reja vaqt tugaganda chiqadigan dialoglarning takrorlanishi va sessiya yakunlanmay qolishi (race condition) bilan bog'liq muammolarni uzil-kesil hal qilishga qaratilgan.

## Proposed Changes

### [State & Logic]

#### [MODIFY] [station_store.dart](file:///C:/Users/user/StudioProjects/game_club/lib/state/station_store.dart)
- **Signal boshqaruvi**: `_notifiedStations` ro'yxatidan faqat stansiya butunlay `idle` holatga o'tgandan keyingina (bazaga saqlab bo'lingach) o'chirish.
- **Tick barqarorligi**: `_tick` metodida stansiya o'chirilish jarayonida (`isStopping` flag qo'shish orqali) ekanligini tekshirish.

### [UI & Screens]

#### [MODIFY] [home_screen.dart](file:///C:/Users/user/StudioProjects/game_club/lib/screens/home_screen.dart)
- **Dialog nazorati**: `_showingDialogs` nazoratini yanada qat'iyroq qilish.
- **Sessiyani yakunlash**: `stopStation` chaqirilganda kutilmagan takroriy dialoglarni bloklash.

## Verification Plan

### Manual Verification
1. VIP sessiyani 1 minutga yoqish.
2. Vaqt tugaganda dialog chiqishini kutish.
3. Dialogdagi "CHOP ETISH"ni bosish.
4. Xona darhol "Bo'sh" bo'lishini va boshqa hech qanday dialog chiqmasligini tekshirish.
