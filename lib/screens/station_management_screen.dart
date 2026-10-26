import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/station_store.dart';
import '../widgets/add_station_dialog.dart';
import '../widgets/station_card.dart' show fmtMoney;

class StationManagementScreen extends StatelessWidget {
  const StationManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StationStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xonalarni boshqarish'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog(context: context, builder: (_) => const AddStationDialog());
              if (result != null) {
                await store.addStation(name: result.name, type: result.type, tariff: result.tariff);
              }
            },
          ),
        ],
      ),
      body: store.stations.isEmpty
          ? const Center(child: Text("Hozircha xonalar yo'q"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: store.stations.length,
              itemBuilder: (ctx, i) {
                final s = store.stations[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(s.type[0])),
                    title: Text(s.name),
                    subtitle: Text("Tarif: ${fmtMoney(s.tariffPerHour.toDouble())} so'm/soat"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () async {
                            final result = await showDialog<AddStationResult>(
                              context: context,
                              builder: (ctx) => AddStationDialog(existing: s),
                            );
                            if (result != null) {
                              await store.editStation(
                                id: s.id,
                                name: result.name,
                                type: result.type,
                                tariff: result.tariff,
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xonani o\'chirish'),
                                content: Text("${s.name}ni rostdan ham o'chirmoqchimisiz?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await store.deleteStation(s.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
