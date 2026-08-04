import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// DATABASE SEMENTARA IDENTITAS TOKO
class StoreData {
  static String storeName = 'TOKO KASIR PINTAR';
  static String address = 'Jl. Raya Utama No. 123, Jakarta';
  static String phone = '081234567890';
  static String receiptFooter = 'Terima Kasih Atas Kunjungan Anda!';
  static File? logoFile; // Menyimpan file foto logo
}

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({Key? key}) : super(key: key);

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _footerController;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: StoreData.storeName);
    _addressController = TextEditingController(text: StoreData.address);
    _phoneController = TextEditingController(text: StoreData.phone);
    _footerController = TextEditingController(text: StoreData.receiptFooter);
    _selectedImage = StoreData.logoFile;
  }

  // Fungsi Ambil Foto dari Galeri
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Simpan Data Toko
  void _saveSettings() {
    setState(() {
      StoreData.storeName = _nameController.text.trim();
      StoreData.address = _addressController.text.trim();
      StoreData.phone = _phoneController.text.trim();
      StoreData.receiptFooter = _footerController.text.trim();
      StoreData.logoFile = _selectedImage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identitas & Logo Toko Berhasil Disimpan!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identitas & Logo Toko', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // UPLOAD LOGO TOKO
            const Text('Logo Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00897B), width: 2),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.storefront, size: 40, color: Color(0xFF00897B)),
                              SizedBox(height: 4),
                              Text('Pilih Logo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF00897B),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FORM INPUT IDENTITAS TOKO
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Toko',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'No. Telp / WhatsApp',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _footerController,
              decoration: const InputDecoration(
                labelText: 'Pesan Bawah Struk (Footer)',
                hintText: 'Contoh: Barang yang sudah dibeli tidak dapat ditukar',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
