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
  int _selectedPeriodIndex = 0; // 0: Hari Ini, 1: Bulan Ini, 2: Semua

  bool _isSameDay(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
  }

  bool _isSameMonth(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year && dt1.month == dt2.month;
  }

  List<SalesTransaction> get _filteredTransactions {
    final now = DateTime.now();
    if (_selectedPeriodIndex == 0) {
      return widget.transactions.where((tx) => _isSameDay(tx.dateTime, now)).toList();
    } else if (_selectedPeriodIndex == 1) {
      return widget.transactions.where((tx) => _isSameMonth(tx.dateTime, now)).toList();
    }
    return widget.transactions;
  }

  List<CashEntry> get _filteredCashEntries {
    final now = DateTime.now();
    if (_selectedPeriodIndex == 0) {
      return widget.cashEntries.where((ce) => _isSameDay(ce.date, now)).toList();
    } else if (_selectedPeriodIndex == 1) {
      return widget.cashEntries.where((ce) => _isSameMonth(ce.date, now)).toList();
    }
    return widget.cashEntries;
  }

  double get _totalOmzet => _filteredTransactions.fold(0, (sum, tx) => sum + tx.grandTotal);
  double get _totalCost => _filteredTransactions.fold(0, (sum, tx) => sum + tx.totalCost);
  double get _totalExpenses => _filteredCashEntries.fold(0, (sum, ce) => sum + (ce.amount < 0 ? ce.amount.abs() : 0));
  double get _netProfit => _totalOmzet - _totalCost - _totalExpenses;

  void _showAddExpenseDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Catatan Pengeluaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Keterangan (cth: Bensin, Supir)')),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Nominal (Rp)', prefixText: 'Rp ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              if (descCtrl.text.isNotEmpty && amount > 0) {
                final newEntries = List<CashEntry>.from(widget.cashEntries)
                  ..insert(0, CashEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: DateTime.now(),
                    description: descCtrl.text,
                    amount: -amount,
                  ));
                widget.onUpdateCashEntries(newEntries);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(String id) {
    final newEntries = widget.cashEntries.where((ce) => ce.id != id).toList();
    widget.onUpdateCashEntries(newEntries);
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan & Laba Bersih'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Periode
            Row(
              children: [
                _buildPeriodChip(0, 'Hari Ini'),
                const SizedBox(width: 8),
                _buildPeriodChip(1, 'Bulan Ini'),
                const SizedBox(width: 8),
                _buildPeriodChip(2, 'Semua'),
              ],
            ),
            const SizedBox(height: 16),

            // Card Laba Bersih & Detail
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Laba Bersih Penjualan', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_netProfit.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _netProfit >= 0 ? Colors.teal.shade900 : Colors.red,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('Pemasukan (Omzet)', 'Rp ${_totalOmzet.toStringAsFixed(0)}', Colors.green.shade800),
                      _buildSummaryItem('Total Modal (HPP)', 'Rp ${_totalCost.toStringAsFixed(0)}', Colors.red.shade800),
                      _buildSummaryItem('Pengeluaran Kas', 'Rp ${_totalExpenses.toStringAsFixed(0)}', Colors.orange.shade900),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daftar Kas Lain-Lain
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Catatan Kas Lain-Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF00897B), size: 28),
                  onPressed: _showAddExpenseDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),

            _filteredCashEntries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Belum ada catatan pengeluaran kas.', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredCashEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredCashEntries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: entry.amount < 0 ? Colors.red.shade50 : Colors.green.shade50,
                            child: Icon(
                              entry.amount < 0 ? Icons.arrow_upward : Icons.arrow_downward,
                              color: entry.amount < 0 ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text(entry.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_formatDate(entry.date)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rp ${entry.amount.abs().toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: entry.amount < 0 ? Colors.red : Colors.green),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                onPressed: () => _deleteExpense(entry.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPeriodChip(int index, String label) {
    final isSelected = _selectedPeriodIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF00897B),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black80, fontWeight: FontWeight.bold),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriodIndex = index;
          });
        }
      },
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
