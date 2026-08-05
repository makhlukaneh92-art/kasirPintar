import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerRepository _customerRepo = CustomerRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<CustomerModel> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // Muat data pelanggan dari SQLite
  Future<void> _loadCustomers({String? query}) async {
    setState(() => _isLoading = true);
    final data = await _customerRepo.getCustomers(searchQuery: query);
    setState(() {
      _customers = data;
      _isLoading = false;
    });
  }

  // Dialog Tambah / Edit Pelanggan
  void _showCustomerDialog({CustomerModel? customer}) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP / WhatsApp',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              if (customer == null) {
                // Tambah Pelanggan Baru
                await _customerRepo.insertCustomer(
                  CustomerModel(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  ),
                );
              } else {
                // Update Pelanggan
                await _customerRepo.updateCustomer(
                  CustomerModel(
                    id: customer.id,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  ),
                );
              }

              if (mounted) {
                Navigator.pop(context);
                _loadCustomers(query: _searchController.text);
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
        title: const Text('Data Pelanggan'),
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
              onChanged: (value) => _loadCustomers(query: value),
              decoration: InputDecoration(
                hintText: 'Cari nama atau no. telepon...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadCustomers();
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

          // List Data Pelanggan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? const Center(child: Text('Belum ada data pelanggan'))
                    : ListView.builder(
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00796B),
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                customer.phone != null && customer.phone!.isNotEmpty
                                    ? customer.phone!
                                    : 'Tidak ada nomor kontak',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showCustomerDialog(customer: customer),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      if (customer.id != null) {
                                        await _customerRepo.deleteCustomer(customer.id!);
                                        _loadCustomers(query: _searchController.text);
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
        onPressed: () => _showCustomerDialog(),
        backgroundColor: const Color(0xFF00796B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
