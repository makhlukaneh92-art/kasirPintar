import 'package:flutter/material.dart';
import '../models.dart';

class FinanceScreen extends StatefulWidget {
  final List<SalesTransaction> transactions;
  final List<CashEntry> cashEntries;
  final Function(List<CashEntry>) onUpdateCashEntries;

  const FinanceScreen({
    Key? key,
    required this.transactions,
    required this.cashEntries,
    required this.onUpdateCashEntries,
  }) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  void _showAddCashEntryDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    bool isIncome = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Catatan Kas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Pengeluaran'),
                        selected: !isIncome,
                        selectedColor: Colors.red.shade100,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => isIncome = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Pemasukan'),
                        selected: isIncome,
                        selectedColor: Colors.green.shade100,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => isIncome = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Keterangan (Contoh: Listrik/Sewa)')),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal (Rp)')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                onPressed: () {
                  double? val = double.tryParse(amountCtrl.text);
                  if (titleCtrl.text.isNotEmpty && val != null && val > 0) {
                    setState(() {
                      widget.cashEntries.add(CashEntry(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text,
                        amount: val,
                        isIncome: isIncome,
                        date: DateTime.now(),
                      ));
                      widget.onUpdateCashEntries(widget.cashEntries);
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalOmzet = widget.transactions.fold(0, (sum, t) => sum + t.totalAmount);
    double totalModal = widget.transactions.fold(0, (sum, t) => sum + t.totalModal);
    double totalLainPemasukan = widget.cashEntries.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.amount);
    double totalLainPengeluaran = widget.cashEntries.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.amount);

    double labaBersih = (totalOmzet - totalModal) + totalLainPemasukan - totalLainPengeluaran;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Keuangan & Laba Bersih', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Laba Bersih Penjualan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Rp ${labaBersih.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 24)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Omzet: Rp ${totalOmzet.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('Total Modal: Rp ${totalModal.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Catatan Kas Lain-Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Expanded(
              child: widget.cashEntries.isEmpty
                  ? const Center(child: Text('Belum ada catatan keuangan manual', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: widget.cashEntries.length,
                      itemBuilder: (ctx, idx) {
                        final entry = widget.cashEntries[idx];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              entry.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: entry.isIncome ? Colors.green : Colors.red,
                            ),
                            title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${entry.date.day}/${entry.date.month}/${entry.date.year}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${entry.isIncome ? "+" : "-"} Rp ${entry.amount.toInt()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: entry.isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      widget.cashEntries.removeAt(idx);
                                      widget.onUpdateCashEntries(widget.cashEntries);
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        onPressed: _showAddCashEntryDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

