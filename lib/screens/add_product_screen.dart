import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/glass_card.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _descFocus = FocusNode();
  final _priceFocus = FocusNode();

  late final AnimationController _anim;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _descFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = context.read<AuthProvider>().token;
    final product = ProductModel(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim().replaceAll(',', '.')),
    );

    final ok = await context.read<ProductProvider>().addProduct(
      token: token,
      product: product,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk "${product.name}" berhasil ditambahkan!'),
          backgroundColor: const Color(0xFF388E3C),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final errMsg =
          context.read<ProductProvider>().errorMessage ??
          'Gagal menambah produk.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg), backgroundColor: kColorError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdding = context.watch<ProductProvider>().isAdding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Produk',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _nameCtrl,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _descFocus.requestFocus(),
                            decoration: glassInputDecoration(
                              label: 'Nama Produk *',
                              icon: Icons.label_outline_rounded,
                              hint: 'Contoh: Sepatu Sneakers Pria',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama produk wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descCtrl,
                            focusNode: _descFocus,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _priceFocus.requestFocus(),
                            decoration: glassInputDecoration(
                              label: 'Deskripsi *',
                              icon: Icons.description_outlined,
                              hint: 'Jelaskan produk secara singkat...',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Deskripsi wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _priceCtrl,
                            focusNode: _priceFocus,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _priceFocus.requestFocus(),
                            decoration: glassInputDecoration(
                              label: 'Harga *',
                              icon: Icons.price_change,
                              hint: 'Contoh: 100000',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Harga wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isAdding ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kColorPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: isAdding
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.save_alt_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          'Simpan Produk',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
