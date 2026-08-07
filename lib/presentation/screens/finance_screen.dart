import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();

  bool _isLoading = true;
  List<TransactionModel> _transactions = [];
  List<Map<String, dynamic>> _expenses = [];

  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();

  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59),
  );

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  @override
  void dispose() {
    _expenseTitleController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);
    
    final allTrx = await _transactionRepo.getTransactions();
    final allExpenses = await _transactionRepo.getExpenses();

    // Filter transaksi berdasarkan range tanggal
    final filteredTrx = allTrx.where((trx) {
      DateTime date = DateTime.tryParse(trx.transactionDate) ?? DateTime.now();
      return date.isAfter(_selectedDateRange.start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(_selectedDateRange.end.add(const Duration(seconds: 1)));
    }).toList();

    // Filter pengeluaran berdasarkan range tanggal
    final filteredExpenses = allExpenses.where((exp) {
      DateTime date = DateTime.tryParse(exp['expense_date'] ?? '') ?? DateTime.now();
      return date.isAfter(_selectedDateRange.start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(_selectedDateRange.end.add(const Duration(seconds: 1)));
    }).toList();

    setState(() {
      _transactions = filteredTrx;
      _expenses = filteredExpenses;
      _isLoading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00796B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
      });
      _loadFinanceData();
    }
  }

  // --- PERHITUNGAN KEUANGAN ---
  
  // 1. Omzet Tunai (Hanya transaksi LUNAS yang masuk ke kas)
  double _calculateTotalOmzet() {
    return _transactions
        .where((trx) => trx.paymentStatus == 'LUNAS')
        .fold(0, (sum, trx) => sum + trx.totalAmount);
  }

  // 2. Total Piutang (KREDIT / BELUM LUNAS - Uang tertahan di pelanggan)
  double _calculateTotalPiutang() {
    return _transactions
        .where((trx) => trx.paymentStatus == 'KREDIT' || trx.paymentStatus == 'BELUM LUNAS')
        .fold(0, (sum, trx) => sum + trx.totalAmount);
  }

  // 3. Total HPP (Modal barang yang terjual dari transaksi LUNAS)
  double _calculateTotalHPP() {
    double totalHpp = 0;
    for (var trx in _transactions.where((t) => t.paymentStatus == 'LUNAS')) {
      for (var item in trx.items) {
        totalHpp += (item.buyPrice * item.quantity);
      }
    }
    return totalHpp;
  }

  double _calculateLabaKotor() {
    return _calculateTotalOmzet() - _calculateTotalHPP();
  }

  double _calculateTotalExpenses() {
    return _expenses.fold(0, (sum, exp) => sum + (exp['amount'] as num).toDouble());
  }

  double _calculateLabaBersih() {
    return _calculateLabaKotor() - _calculateTotalExpenses();
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showAddExpenseDialog() {
    _expenseTitleController.clear();
    _expenseAmountController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pengeluaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _expenseTitleController,
              decoration: const InputDecoration(
                labelText: 'Keterangan / Nama Pengeluaran',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expenseAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final String title = _expenseTitleController.text.trim();
              final double? amount = double.tryParse(_expenseAmountController.text.trim());

              if (title.isNotEmpty && amount != null && amount > 0) {
                await _transactionRepo.createExpense(title, amount);
                if (!mounted) return;
                Navigator.pop(ctx);
                _loadFinanceData();
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startDateStr = DateFormat('dd MMM yyyy').format(_selectedDateRange.start);
    final endDateStr = DateFormat('dd MMM yyyy').format(_selectedDateRange.end);
    final dateDisplay = (startDateStr == endDateStr) ? startDateStr : '$startDateStr - $endDateStr';

    final totalOmzet = _calculateTotalOmzet();
    final totalPiutang = _calculateTotalPiutang();
    final totalHpp = _calculateTotalHPP();
    final labaKotor = _calculateLabaKotor();
    final totalPengeluaran = _calculateTotalExpenses();
    final labaBersih = _calculateLabaBersih();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan & Laba Bersih'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Tanggal
                  InkWell(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00796B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00796B).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.date_range, color: Color(0xFF00796B)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Periode Laporan:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(dateDisplay, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.edit, size: 18, color: Color(0xFF00796B)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // RINGKASAN UTAMA (LABA BERSIH)
                  Card(
                    color: labaBersih >= 0 ? Colors.teal.shade700 : Colors.red.shade700,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ESTIMASI LABA BERSIH (TUNAI)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(labaBersih),
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const Divider(color: Colors.white30, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Omzet Kas: ${_formatRupiah(totalOmzet)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              Text('Operasional: ${_formatRupiah(totalPengeluaran)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // KARTU PIUTANG / UNPAID TRANSACTIONS (JIKA ADA)
                  if (totalPiutang > 0) ...[
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.orange.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.pending_actions, color: Colors.orange),
                        title: const Text(
                          'Piutang / Belum Lunas',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        subtitle: const Text(
                          'Uang tertahan di pelanggan (Belum Masuk Kas)',
                          style: TextStyle(fontSize: 10),
                        ),
                        trailing: Text(
                          _formatRupiah(totalPiutang),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // RINCIAN LABA RUGI
                  const Text('Rincian Perhitungan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          title: const Text(' Total Omzet / Penjualan (Lunas)'),
                          trailing: Text(_formatRupiah(totalOmzet), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          title: const Text(' Total HPP / Modal Barang'),
                          trailing: Text('- ${_formatRupiah(totalHpp)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          tileColor: Colors.grey.shade100,
                          title: const Text('Laba Kotor (Omzet - Modal)', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text(_formatRupiah(labaKotor), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          title: const Text(' Total Pengeluaran Operasional'),
                          trailing: Text('- ${_formatRupiah(totalPengeluaran)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PENGELUARAN OPERASIONAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pengeluaran Operasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _showAddExpenseDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  _expenses.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Belum ada pengeluaran operasional yang dicatat',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final exp = _expenses[index];
                            final DateTime expDate = DateTime.tryParse(exp['expense_date'] ?? '') ?? DateTime.now();
                            final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(expDate);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                dense: true,
                                title: Text(exp['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(formattedDate),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatRupiah((exp['amount'] as num).toDouble()),
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                      onPressed: () async {
                                        await _transactionRepo.deleteExpense(exp['id']);
                                        _loadFinanceData();
                                      },
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
    );
  }
}
