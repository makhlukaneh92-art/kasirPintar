import 'package:flutter/material.dart';
import '../models.dart';

class ProductManagementScreen extends StatefulWidget {
  final List<Product> products;
  final Function(List<Product>) onUpdateProducts;

  const ProductManagementScreen({Key? key, required this.products, required this.onUpdateProducts}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String search = '';

  void _showAddEditProductDialog([Product? product]) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final sellCtrl = TextEditingController(text: product?.sellingPrice.toInt().toString() ?? '');
    final modalCtrl = TextEditingController(text: product?.modalPrice.toInt().toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
            TextField(controller: sellCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual')),
            TextField(controller: modalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Modal')),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
            onPressed: () {
              if (product == null) {
                widget.products.add(Product(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  sellingPrice: double.tryParse(sellCtrl.text) ?? 0,
                  modalPrice: double.tryParse(modalCtrl.text) ?? 0,
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                ));
              } else {
                product.name = nameCtrl.text;
                product.sellingPrice = double.tryParse(sellCtrl.text) ?? 0;
                product.modalPrice = double.tryParse(modalCtrl.text) ?? 0;
                product.stock = int.tryParse(stockCtrl.text) ?? 0;
              }
              widget.onUpdateProducts(widget.products);
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Manajemen Produk', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Cari nama produk...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00897B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final p = filtered[idx];
                  return Card(
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF00897B), child: Icon(Icons.shopping_bag, color: Colors.white)),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Jual: Rp ${p.sellingPrice.toInt()} | Modal: Rp ${p.modalPrice.toInt()}\nStok: ${p.stock}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showAddEditProductDialog(p)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.products.remove(p);
                                widget.onUpdateProducts(widget.products);
                              });
                            },
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        onPressed: () => _showAddEditProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

