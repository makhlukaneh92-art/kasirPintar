import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/printer_service.dart';

class EditReceiptScreen extends StatefulWidget {
  final TransactionModel transaction;
  final List<CustomerModel> customers;

  const EditReceiptScreen({
    super.key,
    required this.transaction,
    required this.customers,
  });

  @override
  State<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();

  late String _currentStatus;
  late int? _selectedCustId;
  late List<TransactionItemModel> _items;
  late List<TextEditingController> _controllers;

  // Store profile for receipt preview
  String _storeName = 'Kasir Pintar';
  String _storeAddress = '';
  String _storePhone = '';
  String _storeFooter = 'Terima Kasih Atas Kunjungan Anda!';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.transaction.paymentStatus;
    _selectedCustId = widget.transaction.customerId;

    _items = widget.transaction.items.map((e) => TransactionItemModel(
      id: e.id,
      transactionId: e.transactionId,
      productId: e.productId,
      productName: e.productName,
      quantity: e.quantity,
      buyPrice: e.buyPrice,
      sellPrice: e.sellPrice,
      subtotal: e.subtotal,
    )).toList();

    _controllers = _items.map((e) => TextEditingController(text: e.quantity.toString())).toList();
    _loadStoreInfo();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeName = prefs.getString('store_name') ?? 'Kasir Pintar';
      _storeAddress = prefs.getString('store_address') ?? '';
      _storePhone = prefs.getString('store_phone') ?? '';
      _storeFooter = prefs.getString('store_footer') ?? 'Terima Kasih Atas Kunjungan Anda!';
    });
  }

  double _calcSubtotal() {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double _calcDiscount() {
    double originalDiscount = widget.transaction.subtotal - widget.transaction.totalAmount;
    return originalDiscount > 0 ? originalDiscount : 0;
  }

  double _calcTotal() {
    double sub = _calcSubtotal();
    double tot = sub - _calcDiscount();
    return tot < 0 ? 0 : tot;
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _getCustomerName() {
    if (_selectedCustId == null) return 'Umum';
    try {
      final cust = widget.customers.firstWhere((c) => c.id == _selectedCustId);
      return cust.name;
    } catch (_) {
      return 'Umum';
    }
  }

  void _updateQuantity(int index, int newQty) {
    if (newQty < 1) return;
    setState(() {
      var item = _items[index];
      _items[index] = TransactionItemModel(
        id: item.id,
        transactionId: item.transactionId,
        productId: item.productId,
        productName: item.productName,
        quantity: newQty,
        buyPrice: item.buyPrice,
        sellPrice: item.sellPrice,
        subtotal: newQty * item.sellPrice,
      );
      _controllers[index].text = newQty.toString();
    });
  }

  Future<void> _saveTransaction() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daftar produk tidak boleh kosong')),
      );
      return;
    }

    final updatedTrx = TransactionModel(
      id: widget.transaction.id,
      customerId: _selectedCustId,
      paymentStatus: _currentStatus,
      subtotal: _calcSubtotal(),
      totalAmount: _calcTotal(),
      transactionDate: widget.transaction.transactionDate,
      items: _items,
    );

    await _transactionRepo.createTransaction(updatedTrx);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm')
        .format(DateTime.tryParse(widget.transaction.transactionDate) ?? DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Struk #${widget.transaction.id}'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengaturan Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            // Status Pembayaran Dropdown
            DropdownButtonFormField<String>(
              value: _currentStatus,
              decoration: const InputDecoration(
                labelText: 'Status Pembayaran',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'LUNAS', child: Text('LUNAS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'KREDIT', child: Text('KREDIT', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'BELUM LUNAS', child: Text('BELUM LUNAS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _currentStatus = val);
              },
            ),
            const SizedBox(height: 12),

            // Pelanggan Dropdown
            DropdownButtonFormField<int?>(
              value: widget.customers.any((c) => c.id == _selectedCustId) ? _selectedCustId : null,
              decoration: const InputDecoration(
                labelText: 'Pelanggan',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              hint: const Text('Umum'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Umum')),
                ...widget.customers.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: (val) => setState(() => _selectedCustId = val),
            ),
            const SizedBox(height: 20),

            const Text('Edit Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            // List Item dengan input manual Qty
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                var item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(_formatRupiah(item.sellPrice), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            if (item.quantity > 1) {
                              _updateQuantity(index, item.quantity - 1);
                            } else {
                              setState(() {
                                _items.removeAt(index);
                                _controllers.removeAt(index);
                              });
                            }
                          },
                        ),
                        SizedBox(
                          width: 55,
                          child: TextField(
                            controller: _controllers[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              int? newQty = int.tryParse(val);
                              if (newQty != null && newQty > 0) {
                                _updateQuantity(index, newQty);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                          onPressed: () => _updateQuantity(index, item.quantity + 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 12),

            // --- LIVE PREVIEW STRUK THERMAL ---
            const Center(
              child: Text(
                '--- PREVIEW STRUK THERMAL ---',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(_storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (_storeAddress.isNotEmpty) Text(_storeAddress, style: const TextStyle(fontSize: 11)),
                  if (_storePhone.isNotEmpty) Text('Telp: $_storePhone', style: const TextStyle(fontSize: 11)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tgl: $dateFormatted', style: const TextStyle(fontSize: 11)),
                      Text('Pelanggan: ${_getCustomerName()}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sts: $_currentStatus', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Trx: #${widget.transaction.id}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const Divider(),

                  ..._items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${item.productName} x${item.quantity}', style: const TextStyle(fontSize: 12))),
                        Text(_formatRupiah(item.subtotal), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  )),

                  const Divider(),
                  if (_calcDiscount() > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon', style: TextStyle(fontSize: 12, color: Colors.red)),
                        Text('- ${_formatRupiah(_calcDiscount())}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_formatRupiah(_calcTotal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_storeFooter, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TOMBOL AKSI
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Struk'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final updatedTrx = TransactionModel(
                        id: widget.transaction.id,
                        customerId: _selectedCustId,
                        paymentStatus: _currentStatus,
                        subtotal: _calcSubtotal(),
                        totalAmount: _calcTotal(),
                        transactionDate: widget.transaction.transactionDate,
                        items: _items,
                      );
                      // Menggunakan static method PrinterService
                      await PrinterService.printReceipt(updatedTrx);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saveTransaction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
