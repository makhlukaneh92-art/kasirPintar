import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/customer_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/transaction_repository.dart';
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
  bool _isLoading = true;

  double _totalOmset = 0;
  double _totalProfit = 0;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _transactionRepo.getAllTransactions();
      final customers = await _customerRepo.getCustomers(); // Menggunakan getCustomers()
      
      _allTransactions = transactions;
      _customers = customers;
      _applyFilter();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    List<TransactionModel> temp = _allTransactions;

    if (_selectedDateRange != null) {
      final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
      final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);

      temp = _allTransactions.where((tx) {
        final txDate = DateTime.tryParse(tx.transactionDate);
        if (txDate == null) return false;
        return txDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            txDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    double omset = 0;
    double profit = 0;

    for (var tx in temp) {
      omset += tx.totalAmount;
      if (tx.items != null) {
        for (var item in tx.items!) {
          double profitPerItem = (item.sellPrice - item.buyPrice) * item.quantity;
          profit += profitPerItem;
        }
      }
    }

    setState(() {
      _filteredTransactions = temp;
      _totalOmset = omset;
      _totalProfit = profit;
      _isLoading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00796B)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _applyFilter();
    }
  }

  void _resetFilter() {
    setState(() => _selectedDateRange = null);
    _applyFilter();
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _getReceiptNo(TransactionModel tx) {
    if (tx.id != null) {
      String idStr = tx.id.toString();
      if (idStr.startsWith('TRX-')) {
        return idStr;
      }
      return 'TRX-$idStr';
    }
    return 'TRX-00';
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final periodText = _selectedDateRange == null
        ? 'Semua Periode'
        : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text('LAPORAN PENJUALAN', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Text('Periode: $periodText', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Total Transaksi: ${_filteredTransactions.length}')),
              pw.Text('Total Omset: ${_formatRupiah(_totalOmset)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'No Struk', 'Status', 'Total'],
            data: _filteredTransactions.map((tx) {
              final dateStr = DateTime.tryParse(tx.transactionDate) != null
                  ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(tx.transactionDate))
                  : tx.transactionDate;
              return [
                dateStr,
                _getReceiptNo(tx),
                tx.paymentStatus,
                _formatRupiah(tx.totalAmount),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodText = _selectedDateRange == null
        ? 'Semua Periode'
        : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _generatePdfReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Color(0xFF00796B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          periodText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      if (_selectedDateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                          onPressed: _resetFilter,
                        ),
                      ElevatedButton(
                        onPressed: _pickDateRange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Filter'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.teal.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Text('Total Omset', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(_formatRupiah(_totalOmset), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Text('Estimasi Keuntungan', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(_formatRupiah(_totalProfit), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(child: Text('Tidak ada data transaksi'))
                      : ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = _filteredTransactions[index];
                            final dateFormatted = DateTime.tryParse(tx.transactionDate) != null
                                ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx.transactionDate))
                                : tx.transactionDate;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                title: Text(_getReceiptNo(tx), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('$dateFormatted • ${tx.paymentStatus}'),
                                trailing: Text(
                                  _formatRupiah(tx.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditReceiptScreen(
                                        transaction: tx,
                                        customers: _customers,
                                      ),
                                    ),
                                  ).then((_) => _loadData());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
