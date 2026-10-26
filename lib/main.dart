import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/station_store.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const GameClubApp());
}

class GameClubApp extends StatelessWidget {
  const GameClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StationStore()..init(),
      child: MaterialApp(
        title: "Game Club Timer",
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0D14),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5CF6),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0A0D14),
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
