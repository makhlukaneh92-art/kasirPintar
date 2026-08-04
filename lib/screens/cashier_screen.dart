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
  List<CartItem> cart = [];
  String search = '';

  double get totalPayment => cart.fold(0, (sum, item) => sum + item.subtotal);
  double get totalModal => cart.fold(0, (sum, item) => sum + item.totalModal);

  void _addToCart(Product product) {
    setState(() {
      int idx = cart.indexWhere((item) => item.product.id == product.id);
      if (idx != -1) {
        if (cart[idx].quantity < product.stock) cart[idx].quantity++;
      } else {
        if (product.stock > 0) cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _showEditQuantityDialog(CartItem item) {
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Jumlah ${item.product.name}'),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Masukkan Jumlah',
            hintText: 'Stok tersedia: ${item.product.stock}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
            onPressed: () {
              int? newQty = int.tryParse(qtyCtrl.text);
              if (newQty != null && newQty > 0) {
                if (newQty <= item.product.stock) {
                  setState(() => item.quantity = newQty);
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Jumlah melebihi stok! Maksimal: ${item.product.stock}')),
                  );
                }
              } else if (newQty == 0) {
                setState(() => cart.remove(item));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  void _printReceipt(SalesTransaction trx) async {
    if (!widget.isConnected) return;
    try {
      widget.bluetooth.printCustom(widget.storeInfo.name.toUpperCase(), 2, 1);
      widget.bluetooth.printCustom(widget.storeInfo.address, 0, 1);
      widget.bluetooth.printCustom('Telp: ${widget.storeInfo.phone}', 0, 1);
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
      widget.bluetooth.printCustom(widget.storeInfo.footer, 0, 1);
      widget.bluetooth.printNewLine();
      widget.bluetooth.printNewLine();
    } catch (e) {
      debugPrint("Gagal cetak struk: $e");
    }
  }

  void _finishTransaction(SalesTransaction trx, bool shouldPrint) {
    for (var item in cart) {
      item.product.stock -= item.quantity;
    }

    widget.onAddTransaction(trx);

    if (shouldPrint && widget.isConnected) {
      _printReceipt(trx);
    }

    setState(() => cart.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(shouldPrint ? 'Transaksi berhasil & struk dicetak!' : 'Transaksi berhasil disimpan!'),
        backgroundColor: const Color(0xFF00897B),
      ),
    );
  }

  void _showCheckoutPreviewDialog() {
    final custNameCtrl = TextEditingController();
    final custPhoneCtrl = TextEditingController();
    final custAddressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPreviewState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Pratinjau Struk & Data Pelanggan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExpansionTile(
                      title: const Text('Data Pelanggan (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF00897B))),
                      initiallyExpanded: true,
                      children: [
                        TextField(
                          controller: custNameCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Pelanggan', isDense: true),
                          onChanged: (_) => setPreviewState(() {}),
                        ),
                        TextField(
                          controller: custPhoneCtrl,
                          decoration: const InputDecoration(labelText: 'No. Telepon Pelanggan', isDense: true),
                          onChanged: (_) => setPreviewState(() {}),
                        ),
                        TextField(
                          controller: custAddressCtrl,
                          decoration: const InputDecoration(labelText: 'Alamat Pelanggan', isDense: true),
                          onChanged: (_) => setPreviewState(() {}),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.storeInfo.logoFile != null) ...[
                            Image.file(widget.storeInfo.logoFile!, height: 50),
                            const SizedBox(height: 6),
                          ],
                          Text(widget.storeInfo.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(widget.storeInfo.address, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                          Text('Telp: ${widget.storeInfo.phone}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          const Divider(),
                          if (custNameCtrl.text.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Pelanggan: ${custNameCtrl.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            if (custPhoneCtrl.text.isNotEmpty)
                              Align(alignment: Alignment.centerLeft, child: Text('No. HP: ${custPhoneCtrl.text}', style: const TextStyle(fontSize: 10))),
                            if (custAddressCtrl.text.isNotEmpty)
                              Align(alignment: Alignment.centerLeft, child: Text('Alamat: ${custAddressCtrl.text}', style: const TextStyle(fontSize: 10))),
                            const Divider(),
                          ],
                          Column(
                            children: cart
                                .map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${item.product.name} x${item.quantity}', style: const TextStyle(fontSize: 11)),
                                          Text('Rp ${item.subtotal.toInt()}', style: const TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Rp ${totalPayment.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00897B))),
                            ],
                          ),
                          const Divider(),
                          Text(widget.storeInfo.footer, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.all(12),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak Struk'),
                    onPressed: () {
                      final trx = SalesTransaction(
                        id: 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                        date: DateTime.now(),
                        items: List.from(cart),
                        totalAmount: totalPayment,
                        totalModal: totalModal,
                        customerName: custNameCtrl.text,
                        customerPhone: custPhoneCtrl.text,
                        customerAddress: custAddressCtrl.text,
                      );
                      Navigator.pop(ctx);
                      _finishTransaction(trx, true);
                    },
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade800),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Selesai Tanpa Cetak'),
                    onPressed: () {
                      final trx = SalesTransaction(
                        id: 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                        date: DateTime.now(),
                        items: List.from(cart),
                        totalAmount: totalPayment,
                        totalModal: totalModal,
                        customerName: custNameCtrl.text,
                        customerPhone: custPhoneCtrl.text,
                        customerAddress: custAddressCtrl.text,
                      );
                      Navigator.pop(ctx);
                      _finishTransaction(trx, false);
                    },
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Transaksi Penjualan (Kasir)', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Cari produk kasir...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00897B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final p = filtered[idx];
                return GestureDetector(
                  onTap: () => _addToCart(p),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                        Text('Rp ${p.sellingPrice.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontSize: 12)),
                        Text('Stok: ${p.stock}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cart.length,
              itemBuilder: (ctx, idx) {
                final item = cart[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Rp ${item.product.sellingPrice.toInt()} / pcs'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                          onPressed: () {
                            setState(() {
                              if (item.quantity > 1) {
                                item.quantity--;
                              } else {
                                cart.removeAt(idx);
                              }
                            });
                          },
                        ),
                        InkWell(
                          onTap: () => _showEditQuantityDialog(item),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00897B)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00897B)),
                          onPressed: () => _addToCart(item.product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => cart.removeAt(idx)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('Rp ${totalPayment.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                  onPressed: cart.isEmpty ? null : _showCheckoutPreviewDialog,
                  child: const Text('Bayar & Cetak'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

