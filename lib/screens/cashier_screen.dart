import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models.dart';

class CashierScreen extends StatefulWidget {
  final List<Product> products;
  final StoreInfo storeInfo;
  final BlueThermalPrinter bluetooth;
  final bool isConnected;
  final Function(SalesTransaction) onAddTransaction;

  const CashierScreen({
    Key? key,
    required this.products,
    required this.storeInfo,
    required this.bluetooth,
    required this.isConnected,
    required this.onAddTransaction,
  }) : super(key: key);

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final List<CartItem> _cart = [];
  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();
  final TextEditingController _customerAddressCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _cashPaidCtrl = TextEditingController();

  bool _isPaid = true; // Default: LUNAS

  // Hitung Subtotal (Sebelum Diskon)
  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  // Parse Diskon
  double get _discountAmount {
    final text = _discountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(text) ?? 0.0;
  }

  // Grand Total (Setelah Diskon)
  double get _grandTotal {
    final total = _subtotal - _discountAmount;
    return total < 0 ? 0 : total;
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok produk habis!')),
      );
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id);
      if (index != -1) {
        if (_cart[index].quantity < product.stock) {
          _cart[index].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jumlah melebihi stok yang tersedia!')),
          );
        }
      } else {
        _cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      final newQty = _cart[index].quantity + change;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else if (newQty <= _cart[index].product.stock) {
        _cart[index].quantity = newQty;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah melebihi stok yang tersedia!')),
        );
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _formatRow(String left, String right, {int totalWidth = 32}) {
    int space = totalWidth - left.length - right.length;
    if (space < 1) space = 1;
    return left + (' ' * space) + right;
  }

  void _showCheckoutDialog() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang belanja masih kosong!')),
      );
      return;
    }

    _cashPaidCtrl.text = _grandTotal.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double cashPaid = double.tryParse(_cashPaidCtrl.text) ?? 0.0;
            final double change = cashPaid >= _grandTotal ? cashPaid - _grandTotal : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detail & Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Data Pelanggan (Opsional)
                    ExpansionTile(
                      title: const Text('Data Pelanggan (Opsional)', style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold)),
                      children: [
                        TextField(controller: _customerNameCtrl, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
                        TextField(controller: _customerPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. Telepon')),
                        TextField(controller: _customerAddressCtrl, decoration: const InputDecoration(labelText: 'Alamat')),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const Divider(),

                    // Status Pembayaran (Lunas / Kasbon)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ChoiceChip(
                          label: const Text('LUNAS'),
                          selected: _isPaid,
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(color: _isPaid ? Colors.green.shade900 : Colors.grey, fontWeight: FontWeight.bold),
                          onSelected: (selected) => setModalState(() => _isPaid = true),
                        ),
                        ChoiceChip(
                          label: const Text('BELUM LUNAS'),
                          selected: !_isPaid,
                          selectedColor: Colors.orange.shade100,
                          labelStyle: TextStyle(color: !_isPaid ? Colors.orange.shade900 : Colors.grey, fontWeight: FontWeight.bold),
                          onSelected: (selected) => setModalState(() => _isPaid = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Input Diskon (Opsional)
                    TextField(
                      controller: _discountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diskon Tambahan (Rp)',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Input Uang Bayar
                    TextField(
                      controller: _cashPaidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Uang Bayar (Rp)',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Ringkasan Pembayaran
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('Rp ${_subtotal.toStringAsFixed(0)}')]),
                          if (_discountAmount > 0)
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon', style: TextStyle(color: Colors.red)), Text('- Rp ${_discountAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red))]),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL AKHIR', style: TextStyle(fontWeight: FontWeight.bold)), Text('Rp ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal))]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kembalian'), Text('Rp ${change.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Konfirmasi Transaksi
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _processTransaction(double.tryParse(_cashPaidCtrl.text) ?? 0.0);
                        },
                        child: const Text('Proses & Pratinjau Struk', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _processTransaction(double cashPaid) {
    final now = DateTime.now();
    final transaction = SalesTransaction(
      id: 'TRX-${now.millisecondsSinceEpoch.toString().substring(6)}',
      dateTime: now,
      customer: CustomerInfo(
        name: _customerNameCtrl.text,
        phone: _customerPhoneCtrl.text,
        address: _customerAddressCtrl.text,
      ),
      items: List.from(_cart),
      discount: _discountAmount,
      cashPaid: cashPaid,
      isPaid: _isPaid,
    );

    widget.onAddTransaction(transaction);
    _showReceiptPreviewDialog(transaction);
  }

  void _showReceiptPreviewDialog(SalesTransaction tx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pratinjau Struk Penjualan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.storeInfo.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(widget.storeInfo.address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                Text('Telp: ${widget.storeInfo.phone}', style: const TextStyle(fontSize: 11)),
                const Divider(),
                Align(alignment: Alignment.centerLeft, child: Text('No: ${tx.id}', style: const TextStyle(fontSize: 11))),
                Align(alignment: Alignment.centerLeft, child: Text('Tgl: ${_formatDateTime(tx.dateTime)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                if (tx.customer.name.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text('Pelanggan: ${tx.customer.name}', style: const TextStyle(fontSize: 11))),
                Align(alignment: Alignment.centerLeft, child: Text('Status: ${tx.isPaid ? "LUNAS" : "BELUM LUNAS (KASBON)"}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tx.isPaid ? Colors.green : Colors.orange))),
                const Divider(),
                ...tx.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.product.name} x${item.quantity}', style: const TextStyle(fontSize: 11))),
                          Text('Rp ${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(fontSize: 11)), Text('Rp ${tx.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))]),
                if (tx.discount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon', style: TextStyle(fontSize: 11, color: Colors.red)), Text('-Rp ${tx.discount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.red))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text('Rp ${tx.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Bayar', style: TextStyle(fontSize: 11)), Text('Rp ${tx.cashPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kembali', style: TextStyle(fontSize: 11)), Text('Rp ${tx.change.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))]),
                const Divider(),
                Text(widget.storeInfo.footer, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, italic: true)),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            onPressed: () async {
              await _printReceiptToPrinter(tx);
              _clearCartAndClose(ctx);
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Cetak Struk', style: TextStyle(color: Colors.white)),
          ),
          OutlinedButton(
            onPressed: () => _clearCartAndClose(ctx),
            child: const Text('Selesai Tanpa Cetak'),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceiptToPrinter(SalesTransaction tx) async {
    bool? isConnected = await widget.bluetooth.isConnected;
    if (isConnected != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer belum terhubung! Silakan hubungkan printer di Menu Utama.')),
      );
      return;
    }

    try {
      widget.bluetooth.printCustom(widget.storeInfo.name.toUpperCase(), 2, 1);
      widget.bluetooth.printCustom(widget.storeInfo.address, 0, 1);
      widget.bluetooth.printCustom("Telp: ${widget.storeInfo.phone}", 0, 1);
      widget.bluetooth.printCustom("--------------------------------", 0, 1);
      widget.bluetooth.printLeftRight("No: ${tx.id}", "", 0);
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
      widget.bluetooth.printCustom(widget.storeInfo.footer, 0, 1);
      widget.bluetooth.printNewLine();
      widget.bluetooth.printNewLine();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat mencetak: $e')),
      );
    }
  }

  void _clearCartAndClose(BuildContext dialogCtx) {
    Navigator.pop(dialogCtx);
    setState(() {
      _cart.clear();
      _customerNameCtrl.clear();
      _customerPhoneCtrl.clear();
      _customerAddressCtrl.clear();
      _discountCtrl.text = '0';
      _cashPaidCtrl.clear();
      _isPaid = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan (Kasir)'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: isLandscape
          ? Row(
              children: [
                Expanded(flex: 6, child: _buildProductGrid()),
                const VerticalDivider(width: 1),
                Expanded(flex: 4, child: _buildCartPanel()),
              ],
            )
          : Column(
              children: [
                Expanded(child: _buildProductGrid()),
                _buildCartPanel(),
              ],
            ),
    );
  }

  Widget _buildProductGrid() {
    return Column(
      children: [
        Expanded(
          child: widget.products.isEmpty
              ? const Center(child: Text('Belum ada produk. Tambahkan di menu Manajemen Produk.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _addToCart(product),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rp ${product.sellPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                  Text('Stok: ${product.stock}', style: TextStyle(fontSize: 11, color: product.stock < 10 ? Colors.red : Colors.grey.shade700)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCartPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Keranjang (${_cart.length} item)', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_cart.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _cart.clear()),
                    child: const Text('Kosongkan', style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: _cart.isEmpty
                ? const Center(child: Text('Ketuk produk di atas untuk memilih', style: TextStyle(color: Colors.grey, fontSize: 12)))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return ListTile(
                        dense: true,
                        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('Rp ${item.product.sellPrice.toStringAsFixed(0)} x ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => _updateQuantity(index, -1)),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20), onPressed: () => _updateQuantity(index, 1)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Akhir', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Rp ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _showCheckoutDialog,
                  child: const Text('Bayar', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
