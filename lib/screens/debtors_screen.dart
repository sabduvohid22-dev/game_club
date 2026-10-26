import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debtor.dart';
import '../services/db_service.dart';
import '../widgets/station_card.dart' show fmtMoney;

class DebtorsScreen extends StatefulWidget {
  final String? initialStation;
  final double? initialAmount;

  const DebtorsScreen({super.key, this.initialStation, this.initialAmount});

  @override
  State<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  List<Debtor> _allDebtors = [];
  List<Debtor> _filteredDebtors = [];
  bool _loading = true;
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.initialAmount != null || widget.initialStation != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addOrEditDebtor(initialStation: widget.initialStation, initialAmount: widget.initialAmount);
        });
      }
    });
  }

  Future<void> _load() async {
    final list = await DbService.instance.getDebtors();
    setState(() {
      _allDebtors = list;
      _filteredDebtors = list;
      _loading = false;
    });
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDebtors = _allDebtors;
      } else {
        _filteredDebtors = _allDebtors.where((d) {
          final q = query.toLowerCase();
          return d.name.toLowerCase().contains(q) || d.phone.contains(q);
        }).toList();
      }
    });
  }

  double get _totalDebt => _allDebtors.where((d) => !d.paid).fold(0.0, (sum, d) => sum + d.amount);

  Future<void> _addOrEditDebtor({Debtor? existing, String? initialStation, double? initialAmount}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final amountCtrl = TextEditingController(
        text: initialAmount != null ? "+${initialAmount.toStringAsFixed(0)}" : '');
    final stationCtrl = TextEditingController(text: existing?.stationName ?? initialStation ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Yangi qarzdor' : 'Qarzni o\'zgartirish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ismi')),
              const SizedBox(height: 10),
              if (existing == null) ...[
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon raqami', hintText: '+998 90 123 45 67'),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Summa (+ qoshish, - ayirish)',
                  hintText: 'Masalan: +5000 yoki -2000',
                  suffixText: "so'm",
                ),
              ),
              const SizedBox(height: 10),
              if (existing == null)
                TextField(
                  controller: stationCtrl,
                  decoration: const InputDecoration(labelText: 'Stansiya (xona)', hintText: 'Masalan: PC-1'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Saqlash')),
        ],
      ),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ismni kiriting"), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    String amountText = amountCtrl.text.trim();
    double currentAmount = existing?.amount ?? 0;
    String? history = existing?.history;
    double inputAmount = 0;

    if (amountText.isNotEmpty) {
      if (amountText.startsWith('+')) {
        inputAmount = double.tryParse(amountText.substring(1)) ?? 0;
        currentAmount += inputAmount;
        if (history == null || history.isEmpty) {
          history = (existing?.amount ?? 0).toStringAsFixed(0);
        }
        history = "$history + ${inputAmount.toStringAsFixed(0)}";
      } else if (amountText.startsWith('-')) {
        inputAmount = double.tryParse(amountText.substring(1)) ?? 0;
        currentAmount -= inputAmount;
        if (history == null || history.isEmpty) {
          history = (existing?.amount ?? 0).toStringAsFixed(0);
        }
        history = "$history - ${inputAmount.toStringAsFixed(0)}";
      } else {
        final parsed = double.tryParse(amountText);
        if (parsed != null) {
          currentAmount = parsed;
          history = currentAmount.toStringAsFixed(0);
        }
      }
    }

    final debtor = Debtor(
      id: existing?.id ?? '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      amount: currentAmount,
      history: history,
      stationName: stationCtrl.text.trim().isEmpty ? null : stationCtrl.text.trim(),
      createdAt: existing?.createdAt,
      paid: existing?.paid ?? false,
    );
    try {
      await DbService.instance.upsertDebtor(debtor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Muvaffaqiyatli saqlandi")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik yuz berdi: $e"), backgroundColor: Colors.red),
        );
      }
    }
    await _load();
  }

  Future<void> _togglePaid(Debtor d) async {
    d.paid = !d.paid;
    await DbService.instance.upsertDebtor(d);
    await _load();
  }

  Future<void> _delete(Debtor d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qarzdorni o\'chirish'),
        content: Text("${d.name}ni rostdan ham o'chirmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha, o\'chirilsin')),
        ],
      ),
    );

    if (confirm == true) {
      await DbService.instance.deleteDebtor(d.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy');
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Qidirish...', border: InputBorder.none),
                onChanged: _filter,
              )
            : const Text('Qarz daftari'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _filteredDebtors = _allDebtors;
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditDebtor(),
        icon: const Icon(Icons.add),
        label: const Text('Qarzdor'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A28),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text('Jami qarzdorlik', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text("${fmtMoney(_totalDebt)} so'm",
                              style: const TextStyle(
                                  color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 26)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredDebtors.isEmpty
                          ? const Center(child: Text("Ma'lumot topilmadi", style: TextStyle(color: Colors.grey)))
                          : isDesktop
                              ? GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 140,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _filteredDebtors.length,
                                  itemBuilder: (ctx, i) => _buildDebtorCard(_filteredDebtors[i], dateFmt),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  itemCount: _filteredDebtors.length,
                                  itemBuilder: (ctx, i) => _buildDebtorCard(_filteredDebtors[i], dateFmt),
                                ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDebtorCard(Debtor d, DateFormat dateFmt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: d.paid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          child: Icon(d.paid ? Icons.check : Icons.person, color: d.paid ? Colors.green : Colors.red),
        ),
        title: Text(
          d.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            decoration: d.paid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${fmtMoney(d.amount)} so'm",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: d.paid ? Colors.grey : Colors.redAccent,
              ),
            ),
            if (d.history != null && d.history!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  d.history!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.phone.isEmpty ? 'Raqam yo\'q' : d.phone,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                if (d.stationName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      d.stationName!,
                      style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              color: Colors.greenAccent,
              onPressed: () => _addOrEditDebtor(existing: d),
              tooltip: 'Qarz qo\'shish',
            ),
            const SizedBox(width: 8),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 26),
              color: Colors.redAccent.withOpacity(0.7),
              onPressed: () => _delete(d),
              tooltip: 'O\'chirish',
            ),
          ],
        ),
        onTap: () => _addOrEditDebtor(existing: d),
      ),
    );
  }
}
