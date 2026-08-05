import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

enum DateFilter { today, yesterday, thisMonth, lastMonth, thisYear, all }

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];

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

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showEditReceiptDialog(TransactionModel trx, int indexInFilteredList) {
    String currentStatus = trx.paymentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit Struk #${trx.id}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ubah Status Pembayaran:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: currentStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'LUNAS', child: Text('LUNAS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'KREDIT', child: Text('KREDIT', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'BELUM LUNAS', child: Text('BELUM LUNAS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => currentStatus = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
              ElevatedButton(
                onPressed: () async {
                  // Membuat objek baru dengan status yang diupdate
                  final updatedTrx = TransactionModel(
                    id: trx.id,
                    customerId: trx.customerId,
                    paymentStatus: currentStatus,
                    subtotal: trx.subtotal,
                    totalAmount: trx.totalAmount,
                    transactionDate: trx.transactionDate,
                    items: trx.items,
                  );

                  await _transactionRepo.createTransaction(updatedTrx);

                  Navigator.pop(context);
                  _loadData(); // Reload data transaksi dari DB
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Status transaksi berhasil diperbarui!'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
                child: const Text('SIMPAN PERUBAHAN'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _printReceipt(TransactionModel trx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: Color(0xFF00796B)),
            SizedBox(width: 8),
            Text('Cetak Struk Thermal'),
          ],
        ),
        content: Text('Mencari printer bluetooth & mengirimkan data cetak struk #${trx.id}...'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perintah cetak berhasil dikirim ke printer thermal!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan & Edit Struk'),
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
                      hintText: 'Cari Transaksi / Nama Barang...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(child: Text('Tidak ada riwayat penjualan ditemukan'))
                      : ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final trx = _filteredTransactions[index];
                            final dateFormatted = DateFormat('dd MMM yyyy, HH:mm')
                                .format(DateTime.tryParse(trx.transactionDate) ?? DateTime.now());

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ExpansionTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF00796B),
                                    child: Icon(Icons.print_outlined, color: Colors.white),
                                  ),
                                  title: Text(_formatRupiah(trx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('$dateFormatted\nStatus: ${trx.paymentStatus}'),
                                  children: [
                                    ...trx.items.map((item) {
                                      return ListTile(
                                        dense: true,
                                        title: Text(item.productName),
                                        subtitle: Text('${item.quantity}x @ ${_formatRupiah(item.sellPrice)}'),
                                        trailing: Text(_formatRupiah(item.subtotal)),
                                      );
                                    }),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _showEditReceiptDialog(trx, index),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Edit Struk', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _printReceipt(trx),
                                          icon: const Icon(Icons.print, size: 16),
                                          label: const Text('Cetak Struk', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF00796B),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
}
