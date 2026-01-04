import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../helpers/image_helper.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({Key? key}) : super(key: key);

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  final _searchController = TextEditingController();

  final List<String> units = [
    'Tablet',
    'Kaplet',
    'Kapsul',
    'Sachet',
    'Botol',
    'Strip',
    'Box',
    'Tube',
    'Ampul',
    'Vial',
    'Pcs',
  ];

  final List<String> categories = [
    'Obat Bebas',
    'Obat Bebas Terbatas',
    'Obat Keras',
    'Obat Psikotropika',
    'Obat Narkotika',
    'Suplemen',
    'Vitamin',
    'Alat Kesehatan',
    'Herbal',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllProducts();
      if (mounted) {
        setState(() {
          products = data;
          filteredProducts = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _searchProducts(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((product) {
          return product['name']
                  .toString()
                  .toLowerCase()
                  .contains(keyword.toLowerCase()) ||
              product['product_id']
                  .toString()
                  .toLowerCase()
                  .contains(keyword.toLowerCase());
        }).toList();
      }
    });
  }

  String _generateProductId() {
    if (products.isEmpty) return 'PRD001';
    final lastProduct = products.last;
    final lastId = lastProduct['product_id'] as String;
    final numStr = lastId.replaceAll(RegExp(r'[^0-9]'), '');
    if (numStr.isEmpty) return 'PRD001';
    final num = int.parse(numStr) + 1;
    return 'PRD${num.toString().padLeft(3, '0')}';
  }

  String _generateBatchNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final random =
        (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'BTH$year$month$random';
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Pilih Tanggal Expired',
    );

    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    String? imagePath = product?['image_path'];

    final idController = TextEditingController(
      text: isEdit ? product['product_id'] : _generateProductId(),
    );
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController =
        TextEditingController(text: product?['price']?.toString() ?? '');
    final stockController =
        TextEditingController(text: product?['stock']?.toString() ?? '');
    final batchController = TextEditingController(
      text: product?['batch'] ?? _generateBatchNumber(),
    );
    final expController =
        TextEditingController(text: product?['exp_date'] ?? '');

    String? selectedUnit = product?['unit'];
    String? selectedCategory = product?['category'];
    bool isPrescription = product?['is_prescription'] == 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add_circle,
                color: const Color(0xFF1FA397),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // === GAMBAR PRODUK ===
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text('Ambil Foto'),
                              onTap: () async {
                                Navigator.pop(context);
                                final newPath =
                                    await ImageHelper.pickImageFromCamera();
                                if (newPath != null) {
                                  // Hapus gambar lama jika ada
                                  if (imagePath != null) {
                                    await ImageHelper.deleteImage(imagePath);
                                  }
                                  setDialogState(() => imagePath = newPath);
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Pilih dari Galeri'),
                              onTap: () async {
                                Navigator.pop(context);
                                final newPath =
                                    await ImageHelper.pickImageFromGallery();
                                if (newPath != null) {
                                  // Hapus gambar lama jika ada
                                  if (imagePath != null) {
                                    await ImageHelper.deleteImage(imagePath);
                                  }
                                  setDialogState(() => imagePath = newPath);
                                }
                              },
                            ),
                            if (imagePath != null)
                              ListTile(
                                leading:
                                    const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Hapus Gambar'),
                                onTap: () {
                                  Navigator.pop(context);
                                  setDialogState(() => imagePath = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imagePath != null &&
                            ImageHelper.getImageFile(imagePath) != null &&
                            ImageHelper.getImageFile(imagePath)!.existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              ImageHelper.getImageFile(imagePath)!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk upload foto produk',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    labelText: 'ID Produk *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.qr_code),
                    suffixIcon: isEdit
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              idController.text = _generateProductId();
                            },
                          ),
                  ),
                  enabled: !isEdit,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stok *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: units.map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedUnit = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.list),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                        value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchController,
                  decoration: InputDecoration(
                    labelText: 'Batch',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.batch_prediction),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        batchController.text = _generateBatchNumber();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: expController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Expired',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () => _selectDate(context, expController),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, expController),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Memerlukan Resep'),
                  value: isPrescription,
                  onChanged: (value) {
                    setDialogState(() => isPrescription = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
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
                if (idController.text.isEmpty ||
                    nameController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    stockController.text.isEmpty ||
                    selectedUnit == null ||
                    selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Field dengan * harus diisi!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final productData = {
                    'product_id': idController.text,
                    'name': nameController.text,
                    'price': int.tryParse(priceController.text) ?? 0,
                    'stock': int.tryParse(stockController.text) ?? 0,
                    'unit': selectedUnit,
                    'category': selectedCategory,
                    'batch': batchController.text,
                    'exp_date': expController.text,
                    'image_path': imagePath,
                    'is_prescription': isPrescription ? 1 : 0,
                  };

                  if (isEdit) {
                    // Hapus gambar lama jika diganti
                    if (product['image_path'] != imagePath &&
                        product['image_path'] != null) {
                      await ImageHelper.deleteImage(product['image_path']);
                    }
                    await DatabaseHelper.instance
                        .updateProduct(product['id'], productData);
                  } else {
                    await DatabaseHelper.instance.insertProduct(productData);
                  }

                  await _loadProducts();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit
                            ? 'Produk berhasil diupdate'
                            : 'Produk berhasil ditambahkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1FA397),
              ),
              child: Text(
                isEdit ? 'Update' : 'Tambah',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin hapus ${product['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                if (product['image_path'] != null) {
                  await ImageHelper.deleteImage(product['image_path']);
                }
                await DatabaseHelper.instance.deleteProduct(product['id']);
                await _loadProducts();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produk berhasil dihapus'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    final hasImage = product['image_path'] != null &&
        ImageHelper.imageExists(product['image_path']) as bool;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    ImageHelper.getImageFile(product['image_path'])!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (hasImage) const SizedBox(height: 16),
              _buildDetailRow('ID', product['product_id']),
              _buildDetailRow('Harga', 'Rp ${product['price']}'),
              _buildDetailRow(
                  'Stok', '${product['stock']} ${product['unit']}'),
              _buildDetailRow('Kategori', product['category']),
              _buildDetailRow('Batch', product['batch'] ?? '-'),
              _buildDetailRow('Expired', product['exp_date'] ?? '-'),
              _buildDetailRow(
                  'Resep', product['is_prescription'] == 1 ? 'Ya' : 'Tidak'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showProductDialog(product: product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1FA397),
            ),
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Produk', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchProducts,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${filteredProducts.length} produk',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2,
                                size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('Belum ada produk',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isLowStock = product['stock'] < 10;
                            final hasImage = product['image_path'] != null &&
                                ImageHelper.getImageFile(
                                        product['image_path']) !=
                                    null &&
                                ImageHelper.getImageFile(product['image_path'])!
                                    .existsSync();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: hasImage
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            ImageHelper.getImageFile(
                                                product['image_path'])!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.medication,
                                          color: Color(0xFF1FA397), size: 30),
                                ),
                                title: Text(
                                  product['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('ID: ${product['product_id']}',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12)),
                                    Text('Rp ${product['price']}',
                                        style: const TextStyle(
                                            color: Color(0xFF1FA397),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2,
                                            size: 14,
                                            color: isLowStock
                                                ? Colors.red
                                                : Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Stok: ${product['stock']} ${product['unit']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isLowStock
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                            fontWeight: isLowStock
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, size: 20),
                                          SizedBox(width: 8),
                                          Text('Lihat'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Hapus',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'view') {
                                      _showProductDetail(product);
                                    } else if (value == 'edit') {
                                      _showProductDialog(product: product);
                                    } else if (value == 'delete') {
                                      _deleteProduct(product);
                                    }
                                  },
                                ),
                                onTap: () => _showProductDetail(product),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: const Color(0xFF1FA397),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Produk',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}