import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import disesuaikan dengan struktur folder lib/presentation/screens/
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  double _totalOmset = 0;
  double _totalLabaBersih = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    
    // PERBAIKAN: Menggunakan getAllTransactions() sesuai TransactionRepository terbaru
    final data = await _transactionRepo.getAllTransactions();
    
    double omset = 0;
    double laba = 0;

    for (var trx in data) {
      omset += trx.totalAmount;
      for (var item in trx.items) {
        // Laba = (Harga Jual - Harga Modal) * Jumlah Terjual
        laba += (item.sellPrice - item.buyPrice) * item.quantity;
      }
    }

    setState(() {
      _transactions = data;
      _totalOmset = omset;
      _totalLabaBersih = laba;
      _isLoading = false;
    });
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatDate(String isoString) {
    final date = DateTime.tryParse(isoString) ?? DateTime.now();
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Keuangan'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ringkasan Keuangan
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF80CBC4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Omset', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(_totalOmset),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.grey),
                      Column(
                        children: [
                          const Text('Laba Bersih', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(_totalLabaBersih),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                // Daftar Riwayat Transaksi
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(child: Text('Belum ada transaksi tersimpan'))
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final trx = _transactions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ExpansionTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF00796B),
                                  child: Icon(Icons.receipt, color: Colors.white),
                                ),
                                title: Text(
                                  _formatRupiah(trx.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${_formatDate(trx.transactionDate)}\nPelanggan: ${trx.customerName ?? "Umum"}',
                                ),
                                children: [
                                  const Divider(),
                                  ...trx.items.map((item) => ListTile(
                                        dense: true,
                                        title: Text(item.productName),
                                        subtitle: Text('${item.quantity}x @ ${_formatRupiah(item.sellPrice)}'),
                                        trailing: Text(_formatRupiah(item.subtotal)),
                                      )),
                                ],
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
