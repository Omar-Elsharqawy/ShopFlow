
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_add_product_page.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  static const String adminUid =
      'mA8ged6wjhNOsPb1NQQ76Wpstth1';

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        FirebaseAuth.instance.currentUser?.uid == adminUid;

    if (!isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminAddProductPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(
              child: Text('No products yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data();

              final name = data['name']?.toString() ?? '';
              final price = data['price'];
              final stock = data['stock'];

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    'Price: \$${price ?? 0} | Stock: ${stock ?? 0}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminEditProductPage(productId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminEditProductPage extends StatefulWidget {
  final String productId;

  const AdminEditProductPage({
    super.key,
    required this.productId,
  });

  @override
  State<AdminEditProductPage> createState() =>
      _AdminEditProductPageState();
}

class _AdminEditProductPageState
    extends State<AdminEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      final data = doc.data()!;

      _name.text = data['name']?.toString() ?? '';
      _description.text =
          data['description']?.toString() ?? '';
      _imageUrl.text = data['imageUrl']?.toString() ?? '';
      _category.text =
          data['category']?.toString() ?? '';
      _price.text = data['price']?.toString() ?? '';

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    if (FirebaseAuth.instance.currentUser?.uid !=
        AdminProductsPage.adminUid) {
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'imageUrl': _imageUrl.text.trim(),
        'category': _category.text.trim(),
        'price': double.parse(_price.text.trim()),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _category.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid !=
        AdminProductsPage.adminUid) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Name'),
            _field(_description, 'Description'),
            _field(_imageUrl, 'Image URL'),
            _field(_category, 'Category'),
            TextFormField(
              controller: _price,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price',
              ),
              validator: (value) {
                final price =
                double.tryParse(value?.trim() ?? '');
                if (price == null ||
                    !price.isFinite ||
                    price < 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving ? 'Saving...' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String label,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          if (label == 'Image URL') {
            final uri = Uri.tryParse(value.trim());
            if (uri == null ||
                uri.scheme != 'https' ||
                uri.host.isEmpty) {
              return 'Enter a valid HTTPS image URL';
            }
          }
          return null;
        },
      ),
    );
  }
}
