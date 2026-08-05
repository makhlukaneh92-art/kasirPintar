import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Muat data produk dari SQLite
  Future<void> _loadProducts({String? query}) async {
    setState(() => _isLoading = true);
    final data = await _productRepo.getProducts(searchQuery: query);
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  // Dialog Tambah / Edit Produk
  void _showProductDialog({ProductModel? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final buyPriceController = TextEditingController(text: product?.buyPrice.toStringAsFixed(0) ?? '');
    final sellPriceController = TextEditingController(text: product?.sellPrice.toStringAsFixed(0) ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: buyPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Modal (Rp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sellPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual (Rp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final buyPrice = double.tryParse(buyPriceController.text) ?? 0;
              final sellPrice = double.tryParse(sellPriceController.text) ?? 0;
              final stock = int.tryParse(stockController.text) ?? 0;

              if (product == null) {
                // Tambah Produk Baru
                await _productRepo.insertProduct(
                  ProductModel(
                    name: nameController.text.trim(),
                    buyPrice: buyPrice,
                    sellPrice: sellPrice,
                    stock: stock,
                  ),
                );
              } else {
                // Update Produk
                await _productRepo.updateProduct(
                  ProductModel(
                    id: product.id,
                    name: nameController.text.trim(),
                    buyPrice: buyPrice,
                    sellPrice: sellPrice,
                    stock: stock,
                  ),
                );
              }

              if (mounted) {
                Navigator.pop(context);
                _loadProducts(query: _searchController.text);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Baris Pencarian (Search Bar Real-Time)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _loadProducts(query: value),
              decoration: InputDecoration(
                hintText: 'Cari nama produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadProducts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List Data Produk
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Belum ada data produk'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00796B),
                                child: Text(
                                  product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Jual: Rp ${product.sellPrice.toStringAsFixed(0)} | Modal: Rp ${product.buyPrice.toStringAsFixed(0)}\nStok: ${product.stock}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showProductDialog(product: product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      if (product.id != null) {
                                        await _productRepo.deleteProduct(product.id!);
                                        _loadProducts(query: _searchController.text);
                                      }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        backgroundColor: const Color(0xFF00796B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
