import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models.dart';

class ReportScreen extends StatefulWidget {
  final List<SalesTransaction> transactions;
  final List<Product> products;
  final BlueThermalPrinter bluetooth;
  final bool isConnected;
  final Function(List<SalesTransaction>) onUpdateTransactions;
  final Function(List<Product>) onUpdateProducts;

  const ReportScreen({
    Key? key,
    required this.transactions,
    required this.products,
    required this.bluetooth,
    required this.isConnected,
    required this.onUpdateTransactions,
    required this.onUpdateProducts,
  }) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedFilterIndex = 0; // 0: Hari Ini, 1: Bulan Ini, 2: Semua

  bool _isSameDay(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
  }

  bool _isSameMonth(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year && dt1.month == dt2.month;
  }

  bool _isSameYear(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year;
  }

  // Kalkulasi Omset Berkala
  double get _omzetToday {
    final now = DateTime.now();
    return widget.transactions
        .where((tx) => _isSameDay(tx.dateTime, now))
        .fold(0.0, (sum, tx) => sum + tx.grandTotal);
  }

  double get _omzetThisMonth {
    final now = DateTime.now();
    return widget.transactions
        .where((tx) => _isSameMonth(tx.dateTime, now))
        .fold(0.0, (sum, tx) => sum + tx.grandTotal);
  }

  double get _omzetThisYear {
    final now = DateTime.now();
    return widget.transactions
        .where((tx) => _isSameYear(tx.dateTime, now))
        .fold(0.0, (sum, tx) => sum + tx.grandTotal);
  }

  List<SalesTransaction> get _filteredTransactions {
    final now = DateTime.now();
    if (_selectedFilterIndex == 0) {
      return widget.transactions.where((tx) => _isSameDay(tx.dateTime, now)).toList();
    } else if (_selectedFilterIndex == 1) {
      return widget.transactions.where((tx) => _isSameMonth(tx.dateTime, now)).toList();
    }
    return widget.transactions;
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showEditReceiptDialog(SalesTransaction tx) {
    final nameCtrl = TextEditingController(text: tx.customer.name);
    final phoneCtrl = TextEditingController(text: tx.customer.phone);
    final discountCtrl = TextEditingController(text: tx.discount.toStringAsFixed(0));
    bool isPaid = tx.isPaid;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Struk (${tx.id})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No. Telepon')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Diskon (Rp)', prefixText: 'Rp '),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status Pembayaran:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ChoiceChip(
                        label: const Text('LUNAS', style: TextStyle(fontSize: 11)),
                        selected: isPaid,
                        selectedColor: Colors.green.shade100,
                        onSelected: (val) => setDialogState(() => isPaid = true),
                      ),
                      ChoiceChip(
                        label: const Text('KASBON', style: TextStyle(fontSize: 11)),
                        selected: !isPaid,
                        selectedColor: Colors.orange.shade100,
                        onSelected: (val) => setDialogState(() => isPaid = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Hapus Transaksi
                  final newTxs = widget.transactions.where((t) => t.id != tx.id).toList();
                  widget.onUpdateTransactions(newTxs);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi berhasil dihapus')));
                },
                child: const Text('Hapus Transaksi', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
                onPressed: () {
                  final newDiscount = double.tryParse(discountCtrl.text) ?? tx.discount;
                  final updatedTx = SalesTransaction(
                    id: tx.id,
                    dateTime: tx.dateTime,
                    customer: CustomerInfo(
                      name: nameCtrl.text,
                      phone: phoneCtrl.text,
                      address: tx.customer.address,
                    ),
                    items: tx.items,
                    discount: newDiscount,
                    cashPaid: tx.cashPaid,
                    isPaid: isPaid,
                  );

                  final index = widget.transactions.indexWhere((t) => t.id == tx.id);
                  if (index != -1) {
                    final updatedList = List<SalesTransaction>.from(widget.transactions);
                    updatedList[index] = updatedTx;
                    widget.onUpdateTransactions(updatedList);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Struk berhasil diperbarui')));
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reprintReceipt(SalesTransaction tx) async {
    bool? isConnected = await widget.bluetooth.isConnected;
    if (isConnected != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer belum terhubung! Silakan hubungkan printer di Menu Utama.')),
      );
      return;
    }

    try {
      widget.bluetooth.printCustom("CETAK ULANG STRUK", 1, 1);
      widget.bluetooth.printCustom("--------------------------------", 0, 1);
      widget.bluetooth.printLeftRight("No:", tx.id, 0);
      widget.bluetooth.printLeftRight("Tgl:", _formatDateTime(tx.dateTime), 0);
      if (tx.customer.name.isNotEmpty) {
        widget.bluetooth.printLeftRight("Pelanggan:", tx.customer.name, 0);
      }
      widget.bluetooth.printLeftRight("Status:", tx.isPaid ? "LUNAS" : "BELUM LUNAS", 0);
      widget.bluetooth.printCustom("--------------------------------", 0, 1);

      for (var item in tx.items) {
        widget.bluetooth.printCustom("${item.product.name} x${item.quantity}", 0, 0);
        widget.bluetooth.printLeftRight("", "Rp ${item.totalPrice.toStringAsFixed(0)}", 0);
      }

      widget.bluetooth.printCustom("--------------------------------", 0, 1);
      widget.bluetooth.printLeftRight("Subtotal:", "Rp ${tx.subtotal.toStringAsFixed(0)}", 0);
      if (tx.discount > 0) {
        widget.bluetooth.printLeftRight("Diskon:", "-Rp ${tx.discount.toStringAsFixed(0)}", 0);
      }
      widget.bluetooth.printLeftRight("TOTAL:", "Rp ${tx.grandTotal.toStringAsFixed(0)}", 1);
      widget.bluetooth.printLeftRight("Bayar:", "Rp ${tx.cashPaid.toStringAsFixed(0)}", 0);
      widget.bluetooth.printLeftRight("Kembali:", "Rp ${tx.change.toStringAsFixed(0)}", 0);
      widget.bluetooth.printCustom("--------------------------------", 0, 1);
      widget.bluetooth.printNewLine();
      widget.bluetooth.printNewLine();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencetak struk...')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencetak: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan & Edit Struk'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringkasan Omset 3 Baris (Hari Ini, Bulan Ini, Tahun Ini)
            const Text('Ringkasan Omset Penjualan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _buildOmzetCard('Hari Ini', _omzetToday, Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildOmzetCard('Bulan Ini', _omzetThisMonth, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildOmzetCard('Tahun Ini', _omzetThisYear, Colors.indigo)),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Riwayat Transaksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                DropdownButton<int>(
                  value: _selectedFilterIndex,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Hari Ini', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 1, child: Text('Bulan Ini', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 2, child: Text('Semua', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFilterIndex = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista Riwayat Transaksi
            _filteredTransactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _showEditReceiptDialog(tx),
                          title: Row(
                            children: [
                              Text(tx.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tx.isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tx.isPaid ? 'LUNAS' : 'KASBON',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tx.isPaid ? Colors.green.shade800 : Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tx.customer.name.isNotEmpty) Text('Pelanggan: ${tx.customer.name}', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                              Text('${tx.items.length} Barang | Total: Rp ${tx.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(_formatDateTime(tx.dateTime), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.print, color: Color(0xFF00897B)),
                            onPressed: () => _reprintReceipt(tx),
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

  Widget _buildOmzetCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rp ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
