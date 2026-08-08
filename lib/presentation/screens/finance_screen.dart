import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  List<Map<String, dynamic>> _otherIncomes = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59),
  );

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final allTrx = await _transactionRepo.getTransactions();
      final allExpenses = await _transactionRepo.getExpenses();
      final allIncomes = await _transactionRepo.getOtherIncomes();

      final start = _selectedDateRange.start;
      final end = _selectedDateRange.end;

      // Filter Penjualan
      final filteredTrx = allTrx.where((trx) {
        DateTime? date = DateTime.tryParse(trx.transactionDate);
        if (date == null) return false;
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      // Filter Pengeluaran
      final filteredExpenses = allExpenses.where((exp) {
        String rawDate = exp['expense_date'] ?? '';
        DateTime? date = DateTime.tryParse(rawDate);
        if (date == null) return true;
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      // Filter Pemasukan
      final filteredIncomes = allIncomes.where((inc) {
        String rawDate = inc['income_date'] ?? '';
        DateTime? date = DateTime.tryParse(rawDate);
        if (date == null) return true;
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      if (mounted) {
        setState(() {
          _transactions = filteredTrx;
          _expenses = filteredExpenses;
          _otherIncomes = filteredIncomes;
        });
      }
    } catch (e) {
      debugPrint("Error loading finance data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  double _calculateTotalOmzet() {
    return _transactions
        .where((trx) => trx.paymentStatus == 'LUNAS')
        .fold(0, (sum, trx) => sum + trx.totalAmount);
  }

  double _calculateTotalPiutang() {
    return _transactions
        .where((trx) => trx.paymentStatus == 'KREDIT' || trx.paymentStatus == 'BELUM LUNAS')
        .fold(0, (sum, trx) => sum + trx.totalAmount);
  }

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

  double _calculateTotalOtherIncomes() {
    return _otherIncomes.fold(0, (sum, inc) => sum + (inc['amount'] as num).toDouble());
  }

  double _calculateLabaBersih() {
    return (_calculateLabaKotor() - _calculateTotalExpenses()) + _calculateTotalOtherIncomes();
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showAddDialog({required bool isIncome}) {
    _titleController.clear();
    _amountController.clear();

    final titleLabel = isIncome ? 'Tambah Pemasukan Kas' : 'Tambah Pengeluaran Operasional';
    final descLabel = isIncome ? 'Keterangan / Sumber Pemasukan' : 'Keterangan / Nama Pengeluaran';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titleLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: descLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                border: OutlineInputBorder(),
                hintText: 'Contoh: 50000',
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
              backgroundColor: isIncome ? Colors.green.shade700 : const Color(0xFF00796B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final String title = _titleController.text.trim();
              
              String cleanAmountStr = _amountController.text
                  .replaceAll(RegExp(r'[^0-9]'), '')
                  .trim();

              final double? amount = double.tryParse(cleanAmountStr);

              if (title.isNotEmpty && amount != null && amount > 0) {
                if (isIncome) {
                  await _transactionRepo.createOtherIncome(title, amount);
                } else {
                  await _transactionRepo.createExpense(title, amount);
                }

                if (!mounted) return;
                Navigator.pop(ctx);
                await _loadFinanceData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isIncome ? "Pemasukan" : "Pengeluaran"} berhasil disimpan!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mohon isi keterangan dan nominal angka dengan benar.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI CETAK PDF PERBAIKAN ---
  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    final startDateStr = DateFormat('dd MMM yyyy').format(_selectedDateRange.start);
    final endDateStr = DateFormat('dd MMM yyyy').format(_selectedDateRange.end);
    final dateDisplay = (startDateStr == endDateStr) ? startDateStr : '$startDateStr - $endDateStr';

    final totalOmzet = _calculateTotalOmzet();
    final totalHpp = _calculateTotalHPP();
    final labaKotor = _calculateLabaKotor();
    final totalExpenses = _calculateTotalExpenses();
    final totalIncomes = _calculateTotalOtherIncomes();
    final labaBersih = _calculateLabaBersih();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start, // FIXED: crossAxisAlignment
            children: [
              pw.Text('LAPORAN KEUANGAN & LABA BERSIH',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Periode: $dateDisplay', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // RINGKASAN REKAPITULASI
              pw.Text('1. Ringkasan Keuangan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                data: [
                  ['Komponen', 'Nilai (Rp)'],
                  ['Total Omzet Penjualan (Lunas)', _formatRupiah(totalOmzet)],
                  ['Total HPP / Modal Barang', '- ${_formatRupiah(totalHpp)}'],
                  ['Laba Kotor', _formatRupiah(labaKotor)],
                  ['Total Pengeluaran Operasional', '- ${_formatRupiah(totalExpenses)}'],
                  ['Total Pemasukan Kas Lainnya', '+ ${_formatRupiah(totalIncomes)}'],
                  ['ESTIMASI LABA BERSIH', _formatRupiah(labaBersih)],
                ],
              ),

              pw.SizedBox(height: 16),

              // DETAIL PENGELUARAN OPERASIONAL
              pw.Text('2. Detail Pengeluaran Operasional', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              _expenses.isEmpty
                  ? pw.Text('Tidak ada pengeluaran operasional pada periode ini.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
                  : pw.Table.fromTextArray(
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      data: [
                        ['Keterangan', 'Nominal'],
                        ..._expenses.map((e) => [
                              e['title'] ?? '-',
                              _formatRupiah((e['amount'] as num).toDouble()),
                            ]),
                      ],
                    ),

              pw.SizedBox(height: 16),

              // DETAIL PEMASUKAN LAINNYA
              pw.Text('3. Detail Pemasukan Kas Lainnya', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              _otherIncomes.isEmpty
                  ? pw.Text('Tidak ada pemasukan lain pada periode ini.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
                  : pw.Table.fromTextArray(
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      data: [
                        ['Keterangan / Sumber', 'Nominal'],
                        ..._otherIncomes.map((i) => [
                              i['title'] ?? '-',
                              _formatRupiah((i['amount'] as num).toDouble()),
                            ]),
                      ],
                    ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Keuangan_$dateDisplay.pdf',
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
    final totalPemasukanLain = _calculateTotalOtherIncomes();
    final labaBersih = _calculateLabaBersih();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan & Laba Bersih'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Cetak PDF',
            onPressed: _generatePdfReport,
          ),
        ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Periode Laporan:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(dateDisplay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.edit, size: 16, color: Color(0xFF00796B)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CARD ESTIMASI LABA BERSIH
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

                  // PIUTANG
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
                        title: const Text('Piutang / Belum Lunas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                        subtitle: const Text('Uang tertahan di pelanggan (Belum Masuk Kas)', style: TextStyle(fontSize: 10)),
                        trailing: Text(_formatRupiah(totalPiutang), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // RINCIAN PERHITUNGAN
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
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          title: const Text(' Total Pemasukan Kas Lainnya'),
                          trailing: Text('+ ${_formatRupiah(totalPemasukanLain)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION PENGELUARAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pengeluaran Operasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showAddDialog(isIncome: false),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _expenses.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(child: Text('Belum ada pengeluaran operasional yang dicatat', style: TextStyle(color: Colors.grey.shade600, fontSize: 11))),
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
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              child: ListTile(
                                dense: true,
                                title: Text(exp['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(formattedDate, style: const TextStyle(fontSize: 10)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_formatRupiah((exp['amount'] as num).toDouble()), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
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

                  const SizedBox(height: 20),

                  // SECTION PEMASUKAN LAINNYA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pemasukan Kas Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showAddDialog(isIncome: true),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _otherIncomes.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(child: Text('Belum ada pemasukan lain yang dicatat', style: TextStyle(color: Colors.grey.shade600, fontSize: 11))),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _otherIncomes.length,
                          itemBuilder: (context, index) {
                            final inc = _otherIncomes[index];
                            final DateTime incDate = DateTime.tryParse(inc['income_date'] ?? '') ?? DateTime.now();
                            final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(incDate);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              child: ListTile(
                                dense: true,
                                title: Text(inc['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(formattedDate, style: const TextStyle(fontSize: 10)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_formatRupiah((inc['amount'] as num).toDouble()), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                                      onPressed: () async {
                                        await _transactionRepo.deleteOtherIncome(inc['id']);
                                        _loadFinanceData();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 30),

                  // TOMBOL CETAK PDF
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _generatePdfReport,
                      icon: const Icon(Icons.print),
                      label: const Text('CETAK PDF LAPORAN KEUANGAN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
