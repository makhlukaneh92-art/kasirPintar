import 'package:flutter/material.dart';
import '../models.dart';

class ProductScreen extends StatefulWidget {
  final List<Product> products;
  final Function(List<Product>) onUpdateProducts;

  const ProductScreen({
    Key? key,
    required this.products,
    required this.onUpdateProducts,
  }) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  void _showProductDialog([Product? product]) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final sellCtrl = TextEditingController(
        text: product != null ? product.sellPrice.toInt().toString() : '');
    final modalCtrl = TextEditingController(
        text: product != null ? product.costPrice.toInt().toString() : '');
    final stockCtrl = TextEditingController(
        text: product != null ? product.stock.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          product == null ? 'Tambah Produk' : 'Edit Produk',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              TextField(
                controller: sellCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
              TextField(
                controller: modalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Modal (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B)),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final sellPrice = double.tryParse(sellCtrl.text) ?? 0.0;
              final costPrice = double.tryParse(modalCtrl.text) ?? 0.0;
              final stock = int.tryParse(stockCtrl.text) ?? 0;

              if (name.isNotEmpty) {
                List<Product> updatedList = List.from(widget.products);
                if (product == null) {
                  // Tambah Produk Baru
                  updatedList.add(Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    sellPrice: sellPrice,
                    costPrice: costPrice,
                    stock: stock,
                  ));
                } else {
                  // Update Produk
                  final index =
                      updatedList.indexWhere((p) => p.id == product.id);
                  if (index != -1) {
                    updatedList[index] = Product(
                      id: product.id,
                      name: name,
                      sellPrice: sellPrice,
                      costPrice: costPrice,
                      stock: stock,
                    );
                  }
                }

                widget.onUpdateProducts(updatedList);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String id) {
    final updatedList = widget.products.where((p) => p.id != id).toList();
    widget.onUpdateProducts(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: widget.products.isEmpty
          ? const Center(child: Text('Belum ada produk. Tambahkan produk baru.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final p = widget.products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Jual: Rp ${p.sellPrice.toInt()} | Modal: Rp ${p.costPrice.toInt()}\nStok: ${p.stock}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showProductDialog(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(p.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
