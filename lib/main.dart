import 'package:flutter/material.dart';

void main() {
  runApp(const KasirPintarApp());
}

class KasirPintarApp extends StatelessWidget {
  const KasirPintarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Kasir Pintar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF00897B),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const MainMenuScreen(),
    );
  }
}

// ==========================================
// MODEL DATA
// ==========================================
class Product {
  String id;
  String name;
  double price;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });
}

class CartItem {
  Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;
}

class TransactionModel {
  String id;
  DateTime date;
  String customerName;
  List<CartItem> items;
  double totalPrice;
  double paidAmount;
  double changeAmount;
  String notes;

  TransactionModel({
    required this.id,
    required this.date,
    required this.customerName,
    required this.items,
    required this.totalPrice,
    required this.paidAmount,
    required this.changeAmount,
    this.notes = '',
  });
}

// Data Identitas Toko Global
class StoreData {
  static String name = 'Toko Kasir Pintar';
  static String address = 'Jl. Raya Toko No. 123, Jakarta';
  static String phone = '08123456789';
  static String footerNotes = 'Terima Kasih Atas Kunjungan Anda';
}

// Helper Format Rupiah & Tanggal
String formatRupiah(double amount) {
  return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

String formatTanggalIndo(DateTime dt) {
  String hari = dt.day.toString().padLeft(2, '0');
  String bulan = dt.month.toString().padLeft(2, '0');
  String tahun = dt.year.toString();
  String jam = dt.hour.toString().padLeft(2, '0');
  String menit = dt.minute.toString().padLeft(2, '0');
  return '$hari/$bulan/$tahun $jam:$menit';
}

// Data Dummy Utama
List<Product> globalProducts = [
  Product(id: 'P1', name: 'Kopi Susu', price: 15000, stock: 50),
  Product(id: 'P2', name: 'Roti Bakar', price: 12000, stock: 30),
  Product(id: 'P3', name: 'Es Teh Manis', price: 5000, stock: 100),
  Product(id: 'P4', name: 'Baso Cimanggis', price: 12000, stock: 8), // Stok menipis
];

List<TransactionModel> globalTransactions = [];

// ==========================================
// 1. MENU UTAMA SCREEN
// ==========================================
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOKO KASIR PINTAR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        actions: [
          IconButton(icon: const Icon(Icons.storefront), onPressed: () {}),
          IconButton(icon: const Icon(Icons.print), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner Printer Status
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mencari printer Bluetooth...')),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.print, color: Color(0xFFE65100)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Printer Belum Terhubung (Ketuk ikon printer di atas)',
                        style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Menu Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            _buildMenuItem(context, Icons.store, 'Pengaturan Identitas & Logo Toko', () {
              _showStoreSettingsDialog(context);
            }),
            _buildMenuItem(context, Icons.inventory_2, 'Manajemen Produk (Jual & Modal)', () {}),
            _buildMenuItem(context, Icons.shopping_cart, 'Transaksi Penjualan (Kasir)', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const KasirScreen()));
            }),
            _buildMenuItem(context, Icons.account_balance_wallet, 'Keuangan & Laba Bersih', () {}),
            _buildMenuItem(context, Icons.assignment, 'Laporan Penjualan & Edit Struk', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LaporanScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00897B)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showStoreSettingsDialog(BuildContext context) {
    TextEditingController nameCtrl = TextEditingController(text: StoreData.name);
    TextEditingController addrCtrl = TextEditingController(text: StoreData.address);
    TextEditingController phoneCtrl = TextEditingController(text: StoreData.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Identitas Toko'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Toko')),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Alamat')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No. Telp/WA')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            onPressed: () {
              StoreData.name = nameCtrl.text;
              StoreData.address = addrCtrl.text;
              StoreData.phone = phoneCtrl.text;
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. HALAMAN TRANSAKSI (KASIR)
// ==========================================
class KasirScreen extends StatefulWidget {
  const KasirScreen({Key? key}) : super(key: key);

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  List<CartItem> cart = [];
  String searchQuery = '';

  double get cartTotal => cart.fold(0, (sum, item) => sum + item.subtotal);

  void _addToCart(Product product) {
    int index = cart.indexWhere((item) => item.product.id == product.id);
    setState(() {
      if (index >= 0) {
        if (cart[index].quantity < product.stock) {
          cart[index].quantity++;
        } else {
          _showSnackBar('Stok maksimal tercapai!');
        }
      } else {
        if (product.stock > 0) {
          cart.add(CartItem(product: product, quantity: 1));
        } else {
          _showSnackBar('Stok habis!');
        }
      }
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Dialog Input Angka Keyboard
  void _showQuantityInputDialog(CartItem item) {
    TextEditingController qtyController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Masukkan Jumlah (${item.product.name})'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Jumlah (pcs)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            onPressed: () {
              int? inputQty = int.tryParse(qtyController.text);
              if (inputQty != null && inputQty > 0) {
                if (inputQty <= item.product.stock) {
                  setState(() => item.quantity = inputQty);
                } else {
                  _showSnackBar('Stok tidak mencukupi! Maksimal: ${item.product.stock}');
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Product> filteredProducts = globalProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan (Kasir)'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari produk kasir...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),

          // Horizontal Product Cards
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, idx) {
                Product p = filteredProducts[idx];
                return GestureDetector(
                  onTap: () => _addToCart(p),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      border: Border.all(color: const Color(0xFF80CBC4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1),
                        const SizedBox(height: 4),
                        Text(formatRupiah(p.price), style: const TextStyle(color: Color(0xFF00796B), fontSize: 11)),
                        Text(
                          'Stok: ${p.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            color: p.stock <= 10 ? Colors.red : Colors.grey.shade700,
                            fontWeight: p.stock <= 10 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 24),
          const Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),

          // Cart List
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: cart.length,
                    itemBuilder: (ctx, idx) {
                      CartItem item = cart[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${formatRupiah(item.product.price)} / pcs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),

                              // Tombol -
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

                              // ANGKA JUMLAH DIKETUK UNTUK INPUT KEYBOARD
                              InkWell(
                                onTap: () => _showQuantityInputDialog(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ),

                              // Tombol +
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00897B)),
                                onPressed: () {
                                  if (item.quantity < item.product.stock) {
                                    setState(() => item.quantity++);
                                  } else {
                                    _showSnackBar('Stok maksimal!');
                                  }
                                },
                              ),

                              // Hapus
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => cart.removeAt(idx)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Bar Checkout
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(formatRupiah(cartTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: cart.isEmpty ? null : () => _showPaymentBottomSheet(context),
                  child: const Text('Bayar & Cetak', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // BottomSheet Input Pembayaran
  void _showPaymentBottomSheet(BuildContext context) {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController paidCtrl = TextEditingController(text: cartTotal.toInt().toString());
    double paidAmount = cartTotal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double changeAmount = (paidAmount >= cartTotal) ? (paidAmount - cartTotal) : 0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rincian Transaksi & Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00897B))),
                    const SizedBox(height: 12),

                    // Daftar Item Singkat
                    ...cart.map((item) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.product.name} x${item.quantity}', style: const TextStyle(fontSize: 12)),
                        Text(formatRupiah(item.subtotal), style: const TextStyle(fontSize: 12)),
                      ],
                    )),

                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(formatRupiah(cartTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00897B))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Pelanggan (Opsional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: paidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nominal Uang Dibayar (Rp)', border: OutlineInputBorder()),
                      onChanged: (val) {
                        setModalState(() {
                          paidAmount = double.tryParse(val) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Quick Money Chips
                    Row(
                      children: [
                        _quickMoneyChip('Uang Pas', cartTotal, paidCtrl, setModalState, (v) => paidAmount = v),
                        _quickMoneyChip('20rb', 20000, paidCtrl, setModalState, (v) => paidAmount = v),
                        _quickMoneyChip('50rb', 50000, paidCtrl, setModalState, (v) => paidAmount = v),
                        _quickMoneyChip('100rb', 100000, paidCtrl, setModalState, (v) => paidAmount = v),
                      ],
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian:', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                          Text(formatRupiah(changeAmount), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          if (paidAmount < cartTotal) {
                            _showSnackBar('Uang pembayaran masih kurang!');
                            return;
                          }

                          // Simpan Transaksi
                          TransactionModel newTx = TransactionModel(
                            id: 'TX${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            date: DateTime.now(),
                            customerName: nameCtrl.text.isEmpty ? 'Umum' : nameCtrl.text,
                            items: List.from(cart),
                            totalPrice: cartTotal,
                            paidAmount: paidAmount,
                            changeAmount: changeAmount,
                          );

                          // Kurangi Stok Produk
                          for (var item in cart) {
                            item.product.stock -= item.quantity;
                          }

                          globalTransactions.insert(0, newTx);

                          Navigator.pop(ctx); // Tutup BottomSheet
                          _showReceiptPreviewDialog(newTx); // BUKA PRATINJAU STRUK
                        },
                        child: const Text('KONFIRMASI TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickMoneyChip(String label, double amount, TextEditingController ctrl, StateSetter setModalState, Function(double) onUpdate) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () {
            setModalState(() {
              ctrl.text = amount.toInt().toString();
              onUpdate(amount);
            });
          },
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  // ==========================================
  // PRATINJAU STRUK (SIAP SCREENSHOT & CETAK)
  // ==========================================
  void _showReceiptPreviewDialog(TransactionModel tx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pratinjau Struk Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              // Kotak Tampilan Struk Bersih
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Logo & Nama Toko
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.storefront, size: 36, color: Color(0xFF00897B)),
                          const SizedBox(height: 4),
                          Text(StoreData.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(StoreData.address, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                          Text('Telp: ${StoreData.phone}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1, height: 20),

                    Text('No. Struk : ${tx.id}', style: const TextStyle(fontSize: 11)),
                    Text('Tanggal   : ${formatTanggalIndo(tx.date)}', style: const TextStyle(fontSize: 11)),
                    Text('Pelanggan : ${tx.customerName}', style: const TextStyle(fontSize: 11)),
                    const Divider(thickness: 1, height: 20),

                    // List Items
                    ...tx.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.product.name} x${item.quantity}', style: const TextStyle(fontSize: 11)),
                          Text(formatRupiah(item.subtotal), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    )),

                    const Divider(thickness: 1, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(formatRupiah(tx.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bayar:', style: TextStyle(fontSize: 11)),
                        Text(formatRupiah(tx.paidAmount), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembali:', style: TextStyle(fontSize: 11)),
                        Text(formatRupiah(tx.changeAmount), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    const Divider(thickness: 1, height: 20),
                    Center(
                      child: Text('--- ${StoreData.footerNotes} ---', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(12),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // Button Tanpa Cetak
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => cart.clear());
              _showSnackBar('Transaksi Berhasil Disimpan!');
            },
            child: const Text('Selesai (Tanpa Cetak)', style: TextStyle(fontSize: 11)),
          ),

          // Button Cetak Struk
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            icon: const Icon(Icons.print, size: 14),
            label: const Text('Cetak Struk', style: TextStyle(fontSize: 11)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => cart.clear());
              _showSnackBar('Mencetak struk ke printer...');
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. HALAMAN LAPORAN & EDIT STRUK
// ==========================================
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  double get totalOmzet => globalTransactions.fold(0, (sum, tx) => sum + tx.totalPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan & Edit Struk'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: Column(
        children: [
          // Omzet Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF80CBC4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Omzet Penjualan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(formatRupiah(totalOmzet), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),

          // List Transactions
          Expanded(
            child: globalTransactions.isEmpty
                ? const Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: globalTransactions.length,
                    itemBuilder: (ctx, idx) {
                      TransactionModel tx = globalTransactions[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${tx.id} - ${tx.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${formatTanggalIndo(tx.date)} • ${tx.items.length} jenis item', style: const TextStyle(fontSize: 11)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatRupiah(tx.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                              InkWell(
                                onTap: () => _showEditReceiptDialog(tx),
                                child: const Text('Edit Struk', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
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

  // ==========================================
  // DIALOG EDIT STRUK
  // ==========================================
  void _showEditReceiptDialog(TransactionModel tx) {
    TextEditingController editCustomerName = TextEditingController(text: tx.customerName);
    TextEditingController editNotes = TextEditingController(text: tx.notes);

    List<CartItem> editedItems = tx.items.map((i) => CartItem(product: i.product, quantity: i.quantity)).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double newTotal = editedItems.fold(0, (sum, i) => sum + i.subtotal);

            // Fungsi Simpan & Adjust Stok
            bool _processSave() {
              for (var editedItem in editedItems) {
                CartItem oldItem = tx.items.firstWhere(
                  (i) => i.product.id == editedItem.product.id,
                  orElse: () => CartItem(product: editedItem.product, quantity: 0),
                );
                int diff = editedItem.quantity - oldItem.quantity;

                if (diff > 0 && diff > editedItem.product.stock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stok ${editedItem.product.name} tidak mencukupi!')),
                  );
                  return false;
                }
              }

              // Adjust stok
              for (var editedItem in editedItems) {
                CartItem oldItem = tx.items.firstWhere(
                  (i) => i.product.id == editedItem.product.id,
                  orElse: () => CartItem(product: editedItem.product, quantity: 0),
                );
                int diff = editedItem.quantity - oldItem.quantity;
                editedItem.product.stock -= diff;
              }

              // Update data transaksi utama
              setState(() {
                tx.customerName = editCustomerName.text;
                tx.notes = editNotes.text;
                tx.items = editedItems;
                tx.totalPrice = newTotal;
                tx.changeAmount = (tx.paidAmount >= newTotal) ? (tx.paidAmount - newTotal) : 0;
              });

              return true;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit Struk: ${tx.id}', style: const TextStyle(fontSize: 15)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: editCustomerName,
                      decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Ubah Jumlah Item:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),

                    // LIST ITEM DENGAN ANGKA YANG BISA DIKETUK UNTUK KEYBOARD
                    ...editedItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.product.name, style: const TextStyle(fontSize: 12))),

                            // Tombol -
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  setModalState(() => item.quantity--);
                                }
                              },
                            ),

                            // ANGKA JUMLAH DIKETUK UNTUK INPUT KEYBOARD
                            InkWell(
                              onTap: () {
                                TextEditingController qtyCtrl = TextEditingController(text: item.quantity.toString());
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: Text('Edit Jumlah (${item.product.name})'),
                                    content: TextField(
                                      controller: qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      autofocus: true,
                                      decoration: const InputDecoration(border: OutlineInputBorder()),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
                                      ElevatedButton(
                                        onPressed: () {
                                          int? val = int.tryParse(qtyCtrl.text);
                                          if (val != null && val > 0) {
                                            setModalState(() => item.quantity = val);
                                          }
                                          Navigator.pop(c);
                                        },
                                        child: const Text('Simpan'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),

                            // Tombol +
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                              onPressed: () {
                                setModalState(() => item.quantity++);
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    TextField(
                      controller: editNotes,
                      decoration: const InputDecoration(labelText: 'Catatan Khusus Struk'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(formatRupiah(newTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 15)),
                      ],
                    )
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.all(12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),

                // OPSI 1: SIMPAN SAJA
                OutlinedButton(
                  onPressed: () {
                    if (_processSave()) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Struk ${tx.id} berhasil diperbarui!')));
                    }
                  },
                  child: const Text('Simpan Saja', style: TextStyle(fontSize: 11)),
                ),

                // OPSI 2: SIMPAN & CETAK STRUK
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
                  icon: const Icon(Icons.print, size: 14),
                  label: const Text('Simpan & Cetak', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    if (_processSave()) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Struk ${tx.id} diperbarui & dicetak!')));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

