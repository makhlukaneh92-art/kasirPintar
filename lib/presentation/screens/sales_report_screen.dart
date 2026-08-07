import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/transaction_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../services/printer_service.dart';
import 'edit_receipt_screen.dart';

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

  // Default filter: Hari Ini (00:00:00 s.d 23:59:59)
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59),
  );

  String _searchQuery = '';
  bool _isLoading = true;

  // Profil Toko
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

  void _applyFilter() {
    List<TransactionModel> result = _allTransactions.where((trx) {
      DateTime date = DateTime.tryParse(trx.transactionDate) ?? DateTime.now();
      
      bool inRange = date.isAfter(_selectedDateRange.start.subtract(const Duration(seconds: 1))) &&
                     date.isBefore(_selectedDateRange.end.add(const Duration(seconds: 1)));
      return inRange;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      result = result.where((trx) {
        final idMatch = trx.id.toString().toLowerCase().contains(_searchQuery.toLowerCase());
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
      _applyFilter();
    }
  }

  String _getCustomerName(dynamic customerId) {
    if (customerId == null) return 'Umum';
    try {
      final cust = _customers.firstWhere((c) => c.id.toString() == customerId.toString());
      return cust.name;
    } catch (_) {
      return 'Umum';
    }
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  double _calculateTotalIncome() {
    return _filteredTransactions.fold(0, (sum, item) => sum + item.totalAmount);
  }

  // --- MENCETAK STRUK ULANG VIA PRINTER THERMAL ---
  Future<void> _printReceiptThermal(TransactionModel trx) async {
    bool success = await PrinterService.printReceipt(trx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Berhasil mencetak struk!' : 'Gagal mencetak struk. Periksa koneksi printer.'),
          backgroundColor: success ? const Color(0xFF00796B) : Colors.red,
        ),
      );
    }
  }

  // --- GENERATE PDF REPORT ---
  Future<void> _exportPdfReport() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final startDateStr = DateFormat('dd/MM/yyyy').format(_selectedDateRange.start);
    final endDateStr = DateFormat('dd/MM/yyyy').format(_selectedDateRange.end);
    final totalOmzet = _calculateTotalIncome();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(_storeName, style: pw.TextStyle(font: fontBold, fontSize: 20)),
                    if (_storeAddress.isNotEmpty) pw.Text(_storeAddress, style: pw.TextStyle(font: font, fontSize: 10)),
                    if (_storePhone.isNotEmpty) pw.Text('Telp: $_storePhone', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('LAPORAN PENJUALAN', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                    pw.Text('Periode: $startDateStr - $endDateStr', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Transaksi: ${_filteredTransactions.length}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                  pw.Text('Total Omzet: ${_formatRupiah(totalOmzet)}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.teal)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            pw.TableHelper.fromTextArray(
              headers: ['No', 'ID', 'Tanggal & Waktu', 'Pelanggan', 'Status', 'Total'],
              data: List.generate(_filteredTransactions.length, (index) {
                final trx = _filteredTransactions[index];
                final dateFormatted = DateFormat('dd/MM/yy HH:mm').format(DateTime.tryParse(trx.transactionDate) ?? DateTime.now());
                final custName = _getCustomerName(trx.customerId);
                return [
                  (index + 1).toString(),
                  '#${trx.id}',
                  dateFormatted,
                  custName,
                  trx.paymentStatus,
                  _formatRupiah(trx.totalAmount),
                ];
              }),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Penjualan_${startDateStr}_${endDateStr}.pdf',
    );
  }

  // --- BUKA HALAMAN EDIT STRUK SECARA UTUH ---
  void _navigateToEditReceipt(TransactionModel trx) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReceiptScreen(
          transaction: trx,
          customers: _customers,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  void _confirmDeleteTransaction(TransactionModel trx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text('Apakah Anda yakin ingin menghapus transaksi #${trx.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _transactionRepo.deleteTransaction(trx.id);
              await _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('HAPUS'),
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
    final totalOmzet = _calculateTotalIncome();

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
                // 1. BILAH INFORMASI TANGGAL & RINGKASAN OMSET
                Container(
                  margin: const EdgeInsets.all(12.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00796B).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _pickDateRange,
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
                                    const Text('Periode Tanggal:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text(dateDisplay, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00796B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Ubah', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: ${_filteredTransactions.length} Transaksi', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('Omzet: ${_formatRupiah(totalOmzet)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00796B))),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. PENCARIAN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilter();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari Transaksi / Barang / Pelanggan...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 3. DAFTAR TRANSAKSI
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(child: Text('Tidak ada transaksi pada periode ini'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
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
                                    child: Icon(Icons.receipt_long, color: Colors.white),
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _confirmDeleteTransaction(trx),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.print, color: Color(0xFF00796B)),
                                              tooltip: 'Cetak Struk Thermal',
                                              onPressed: () => _printReceiptThermal(trx),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () => _navigateToEditReceipt(trx),
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Edit Struk', style: TextStyle(fontSize: 12)),
                                            ),
                                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _filteredTransactions.isEmpty ? null : _exportPdfReport,
        backgroundColor: const Color(0xFF00796B),
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text('Cetak PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
