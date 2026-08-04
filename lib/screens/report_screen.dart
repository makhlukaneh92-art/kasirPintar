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
  void _directPrint(SalesTransaction trx) async {
    if (!widget.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer belum terhubung!')));
      return;
    }
    try {
      widget.bluetooth.printCustom(trx.id, 1, 1);
      widget.bluetooth.printCustom('--------------------------------', 1, 1);

      if (trx.customerName != null && trx.customerName!.trim().isNotEmpty) {
        widget.bluetooth.printLeftRight('Pelanggan:', trx.customerName!, 0);
        widget.bluetooth.printCustom('--------------------------------', 1, 1);
      }

      for (var item in trx.items) {
        widget.bluetooth.printLeftRight(
          '${item.product.name} x${item.quantity}',
          'Rp ${item.subtotal.toInt()}',
          0,
        );
      }

      widget.bluetooth.printCustom('--------------------------------', 1, 1);
      widget.bluetooth.printLeftRight('TOTAL:', 'Rp ${trx.totalAmount.toInt()}', 1);
      widget.bluetooth.printCustom('--------------------------------', 1, 1);
      widget.bluetooth.printNewLine();
      widget.bluetooth.printNewLine();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Struk berhasil dicetak ulang!')));
    } catch (e) {
      debugPrint("Gagal cetak ulang: $e");
    }
  }

  void _showEditTransactionDialog(SalesTransaction trx) {
    List<CartItem> editedItems = trx.items.map((e) => e.copy()).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setEditState) {
          double calcTotal = editedItems.fold(0, (sum, i) => sum + i.subtotal);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Struk ${trx.id}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: editedItems.length,
                      itemBuilder: (context, index) {
                        final item = editedItems[index];
                        return ListTile(
                          title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('Rp ${item.product.sellingPrice.toInt()}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                                onPressed: () {
                                  setEditState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      editedItems.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              InkWell(
                                onTap: () {
                                  final qCtrl = TextEditingController(text: item.quantity.toString());
                                  showDialog(
                                    context: context,
                                    builder: (qCtx) => AlertDialog(
                                      title: Text('Jumlah ${item.product.name}'),
                                      content: TextField(controller: qCtrl, keyboardType: TextInputType.number, autofocus: true),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(qCtx), child: const Text('Batal')),
                                        ElevatedButton(
                                          onPressed: () {
                                            int? n = int.tryParse(qCtrl.text);
                                            if (n != null && n >= 0) {
                                              setEditState(() {
                                                if (n == 0) {
                                                  editedItems.remove(item);
                                                } else {
                                                  item.quantity = n;
                                                }
                                              });
                                            }
                                            Navigator.pop(qCtx);
                                          },
                                          child: const Text('OK'),
                                        )
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00897B), size: 20),
                                onPressed: () => setEditState(() => item.quantity++),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rp ${calcTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var oldItem in trx.items) {
                      oldItem.product.stock += oldItem.quantity;
                    }
                    widget.transactions.remove(trx);
                    widget.onUpdateTransactions(widget.transactions);
                    widget.onUpdateProducts(widget.products);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Hapus Transaksi', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                onPressed: () {
                  setState(() {
                    for (var oldItem in trx.items) {
                      oldItem.product.stock += oldItem.quantity;
                    }
                    for (var newItem in editedItems) {
                      newItem.product.stock -= newItem.quantity;
                    }
                    trx.items = editedItems;
                    trx.totalAmount = editedItems.fold(0, (sum, i) => sum + i.subtotal);
                    trx.totalModal = editedItems.fold(0, (sum, i) => sum + i.totalModal);

                    widget.onUpdateTransactions(widget.transactions);
                    widget.onUpdateProducts(widget.products);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalOmzet = widget.transactions.fold(0, (sum, t) => sum + t.totalAmount);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Laporan Penjualan & Edit Struk', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Omzet Penjualan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Rp ${totalOmzet.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Riwayat Transaksi (Ketuk untuk edit)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Expanded(
              child: widget.transactions.isEmpty
                  ? const Center(child: Text('Belum ada transaksi tercatat', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: widget.transactions.length,
                      itemBuilder: (ctx, idx) {
                        final t = widget.transactions[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => _showEditTransactionDialog(t),
                            title: Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (t.customerName != null && t.customerName!.isNotEmpty)
                                  Text('Pelanggan: ${t.customerName}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.w500)),
                                Text('${t.items.length} Barang | Total: Rp ${t.totalAmount.toInt()}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${t.date.day}/${t.date.month}/${t.date.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.print, color: Color(0xFF00897B)),
                                  onPressed: () => _directPrint(t),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

