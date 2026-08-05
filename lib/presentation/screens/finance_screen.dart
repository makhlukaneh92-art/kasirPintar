import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

enum DateFilter { today, yesterday, thisMonth, lastMonth, thisYear, all }

class CashFlowItem {
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;

  CashFlowItem({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  final List<CashFlowItem> _extraCashFlow = [];

  DateFilter _selectedFilter = DateFilter.today;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _transactionRepo.getTransactions();
    setState(() {
      _allTransactions = list;
      _isLoading = false;
    });
    _applyFilter();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _applyFilter() {
    final now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));

    List<TransactionModel> result = _allTransactions.where((trx) {
      DateTime date = DateTime.tryParse(trx.transactionDate) ?? now;

      switch (_selectedFilter) {
        case DateFilter.today:
          return _isSameDay(date, now);
        case DateFilter.yesterday:
          return _isSameDay(date, yesterday);
        case DateFilter.thisMonth:
          return date.year == now.year && date.month == now.month;
        case DateFilter.lastMonth:
          int lastMonth = now.month == 1 ? 12 : now.month - 1;
          int year = now.month == 1 ? now.year - 1 : now.year;
          return date.year == year && date.month == lastMonth;
        case DateFilter.thisYear:
          return date.year == now.year;
        case DateFilter.all:
          return true;
      }
    }).toList();

    if (_searchQuery.isNotEmpty) {
      result = result.where((trx) {
        final idMatch = trx.id.toLowerCase().contains(_searchQuery.toLowerCase());
        final itemMatch = trx.items.any((item) => item.productName.toLowerCase().contains(_searchQuery.toLowerCase()));
        return idMatch || itemMatch;
      }).toList();
    }

    setState(() {
      _filteredTransactions = result;
    });
  }

  double get _totalOmset {
    return _filteredTransactions.fold(0, (sum, trx) => sum + trx.totalAmount);
  }

  double get _totalHpp {
    double total = 0;
    for (var trx in _filteredTransactions) {
      for (var item in trx.items) {
        total += (item.buyPrice * item.quantity);
      }
    }
    return total;
  }

  double get _extraIncome {
    return _extraCashFlow.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.amount);
  }

  double get _extraExpense {
    return _extraCashFlow.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.amount);
  }

  double get _netProfit {
    return (_totalOmset + _extraIncome) - (_totalHpp + _extraExpense);
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showAddCashFlowDialog(bool isIncome) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncome ? 'Tambah Pemasukan Lain' : 'Tambah Pengeluaran Operasional'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Keterangan', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0;
              if (title.isNotEmpty && amount > 0) {
                setState(() {
                  _extraCashFlow.add(CashFlowItem(
                    title: title,
                    amount: amount,
                    isIncome: isIncome,
                    date: DateTime.now(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan & Laba Bersih'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('Hari Ini', DateFilter.today),
                      _buildFilterChip('Kemarin', DateFilter.yesterday),
                      _buildFilterChip('Bulan Ini', DateFilter.thisMonth),
                      _buildFilterChip('Bulan Kemarin', DateFilter.lastMonth),
                      _buildFilterChip('Tahunan', DateFilter.thisYear),
                      _buildFilterChip('Semua', DateFilter.all),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilter();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari ID Transaksi / Nama Produk...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.all(12),
                  color: const Color(0xFFE0F2F1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Total Omset', _formatRupiah(_totalOmset), Colors.teal[800]!),
                            _buildStatColumn('Laba Bersih', _formatRupiah(_netProfit), Colors.green[800]!),
                          ],
                        ),
                        if (_extraIncome > 0 || _extraExpense > 0) const Divider(),
                        if (_extraIncome > 0 || _extraExpense > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text('Pemasukan Lain: ${_formatRupiah(_extraIncome)}', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                              Text('Pengeluaran: ${_formatRupiah(_extraExpense)}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                            ],
                          )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddCashFlowDialog(true),
                          icon: const Icon(Icons.add_circle, size: 16),
                          label: const Text('Pemasukan', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddCashFlowDialog(false),
                          icon: const Icon(Icons.remove_circle, size: 16),
                          label: const Text('Pengeluaran', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(child: Text('Tidak ada data transaksi'))
                      : ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final trx = _filteredTransactions[index];
                            final dateFormatted = DateFormat('dd MMM yyyy, HH:mm')
                                .format(DateTime.tryParse(trx.transactionDate) ?? DateTime.now());

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ExpansionTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF00796B),
                                  child: Icon(Icons.receipt, color: Colors.white),
                                ),
                                title: Text(_formatRupiah(trx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('$dateFormatted\nStatus: ${trx.paymentStatus}'),
                                children: trx.items.map((item) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(item.productName),
                                    subtitle: Text('${item.quantity}x @ ${_formatRupiah(item.sellPrice)}'),
                                    trailing: Text(_formatRupiah(item.subtotal)),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, DateFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
        selected: isSelected,
        selectedColor: const Color(0xFF00796B),
        onSelected: (val) {
          setState(() {
            _selectedFilter = filter;
          });
          _applyFilter();
        },
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
