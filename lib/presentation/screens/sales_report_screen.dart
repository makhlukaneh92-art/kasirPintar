import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../services/printer_service.dart';

enum DateFilter { today, yesterday, thisMonth, lastMonth, thisYear, all }

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CustomerRepository _customerRepo = CustomerRepository();

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  List<CustomerModel> _customers = [];

  DateFilter _selectedFilter = DateFilter.today;
  String _searchQuery = '';
  bool _isLoading = true;

  // Header toko
  String _storeName = 'Kasir Pintar';
  String _storeAddress = '';
  String _storePhone = '';
  String _storeFooter = 'Terima Kasih Atas Kunjungan Anda!';
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeName = prefs.getString('store_name') ?? 'Kasir Pintar';
      _storeAddress = prefs.getString('store_address') ?? '';
      _storePhone = prefs.getString('store_phone') ?? '';
      _storeFooter = prefs.getString('store_footer') ?? 'Terima Kasih Atas Kunjungan Anda!';
      _logoPath = prefs.getString('store_logo');
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _transactionRepo.getTransactions();
    final customerList = await _customerRepo.getCustomers();
    setState(() {
      _allTransactions = list;
      _customers = customerList;
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
        final custName = _getCustomerName(trx.customerId);
        final custMatch = custName.toLowerCase().contains(_searchQuery.toLowerCase());
        return idMatch || itemMatch || custMatch;
      }).toList();
    }

    setState(() {
      _filteredTransactions = result;
    });
  }

  String _getCustomerName(String? customerId) {
    if (customerId == null || customerId.isEmpty) return 'Umum';
    try {
      final cust = _customers.firstWhere((c) => c.id == customerId);
      return cust.name;
    } catch (_) {
      return customerId;
    }
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // --- DIALOG EDIT STRUK ---
  void _showEditReceiptDialog(TransactionModel trx) {
    String currentStatus = trx.paymentStatus;
    String? selectedCustId = trx.customerId;
    List<TransactionItemModel> tempItems = trx.items.map((e) => TransactionItemModel(
      id: e.id,
      transactionId: e.transactionId,
      productId: e.productId,
      productName: e.productName,
      quantity: e.quantity,
      buyPrice: e.buyPrice,
      sellPrice: e.sellPrice,
      subtotal: e.subtotal,
    )).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double calcTotal() {
            return tempItems.fold(0, (sum, item) => sum + item.subtotal);
          }

          return AlertDialog(
            title: Text('Edit Struk #${trx.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Pembayaran:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 12),
                  const Text('Pelanggan:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String?>(
                    value: _customers.any((c) => c.id == selectedCustId) ? selectedCustId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    hint: const Text('Umum'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Umum')),
                      ..._customers.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedCustId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Daftar Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...tempItems.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('@ ${_formatRupiah(item.sellPrice)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                if (item.quantity > 1) {
                                  item.quantity--;
                                  item.subtotal = item.quantity * item.sellPrice;
                                } else {
                                  tempItems.removeAt(idx);
                                }
                              });
                            },
                          ),
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                item.quantity++;
                                item.subtotal = item.quantity * item.sellPrice;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatRupiah(calcTotal()), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B), fontSize: 15)),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
              ElevatedButton(
                onPressed: tempItems.isEmpty
                    ? null
                    : () async {
                        double total = calcTotal();
                        final updatedTrx = TransactionModel(
                          id: trx.id,
                          customerId: selectedCustId,
                          paymentStatus: currentStatus,
                          subtotal: total,
                          totalAmount: total,
                          transactionDate: trx.transactionDate,
                          items: tempItems,
                        );

                        await _transactionRepo.createTransaction(updatedTrx);
                        Navigator.pop(context);
                        await _loadData();

                        // Buka Preview Struk
                        _showReceiptPreviewDialog(updatedTrx);
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

  // --- DIALOG PREVIEW STRUK (SAMA SEPERTI DI KASIR) ---
  void _showReceiptPreviewDialog(TransactionModel trx) {
    String custName = _getCustomerName(trx.customerId);
    String dateFormatted = DateFormat('dd MMM yyyy, HH:mm')
        .format(DateTime.tryParse(trx.transactionDate) ?? DateTime.now());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Toko
              if (_logoPath != null && File(_logoPath!).existsSync())
                Image.file(File(_logoPath!), height: 50, fit: BoxFit.contain)
              else
                const Icon(Icons.store, size: 40, color: Color(0xFF00796B)),
              const SizedBox(height: 6),
              Text(_storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (_storeAddress.isNotEmpty) Text(_storeAddress, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if (_storePhone.isNotEmpty) Text('Telp: $_storePhone', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Divider(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tgl: $dateFormatted', style: const TextStyle(fontSize: 11)),
                  Text('Status: ${trx.paymentStatus}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Pelanggan: $custName', style: const TextStyle(fontSize: 11)),
              ),
              const Divider(),

              // List Barang
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: trx.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 12))),
                            Text('${item.quantity}x ${_formatRupiah(item.sellPrice)}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                  Text(_formatRupiah(trx.subtotal), style: const TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_formatRupiah(trx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00796B))),
                ],
              ),
              const SizedBox(height: 8),
              Text(_storeFooter, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
              const SizedBox(height: 16),

              // Tombol
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BATAL', style: TextStyle(color: Color(0xFF00796B))),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('SIMPAN (TANPA CETAK)'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    _printReceipt(trx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('SIMPAN & CETAK STRUK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printReceipt(TransactionModel trx) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengirimkan data ke printer bluetooth...')),
    );

    bool success = await PrinterService.printReceipt(trx);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil mencetak struk ke printer thermal!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mencetak struk. Buka menu Pengaturan Printer Bluetooth untuk menghubungkan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      hintText: 'Cari Transaksi / Nama Barang / Pelanggan...',
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
                            final custName = _getCustomerName(trx.customerId);

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
                                  subtitle: Text('$dateFormatted\nPelanggan: $custName | Status: ${trx.paymentStatus}'),
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
                                          onPressed: () => _showEditReceiptDialog(trx),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Edit Struk', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _showReceiptPreviewDialog(trx),
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
