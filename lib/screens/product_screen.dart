import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/glass_card.dart';
import 'login_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _listAnim.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final token = context.read<AuthProvider>().token;
    await context.read<ProductProvider>().fetchProducts(token: token);
    if (!mounted) return;
    if (context.read<ProductProvider>().isUnauthorized) {
      _handleUnauthorized();
      return;
    }
    _listAnim.forward(from: 0);
  }

  Future<void> _handleUnauthorized() async {
    if (!mounted) return;
    context.read<ProductProvider>().reset();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi kamu habis. Silakan login kembali.'),
        backgroundColor: kColorError,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: kColorError)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    context.read<ProductProvider>().reset();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Hapus "${product.name}"?\nAksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: kColorError)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final token = context.read<AuthProvider>().token;
    final ok = await context.read<ProductProvider>().deleteProduct(
      token: token,
      productId: product.id!,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Produk dihapus.'
              : context.read<ProductProvider>().errorMessage ?? 'Gagal hapus.',
        ),
        backgroundColor: ok ? const Color(0xFF388E3C) : kColorError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();

    return Scaffold(
      appBar: _buildAppBar(auth, products),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          backgroundColor: const Color(0xFF1E1B4B),
          child: _buildBody(products),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AuthProvider auth,
    ProductProvider products,
  ) {
    return AppBar(
      backgroundColor: Color.fromARGB(255, 7, 0, 100),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produk Draft',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            'Halo, ${auth.currentUser?.name.isNotEmpty == true ? auth.currentUser!.name : auth.currentUser?.nim ?? ""}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _logout,
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
        ),
        const SizedBox(width: 4),
      ],
    );
  }



  Widget _buildBody(ProductProvider products) {
    if (products.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kColorPrimary, strokeWidth: 2),
      );
    }

    if (products.status == ProductStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Colors.white30,
              ),
              const SizedBox(height: 16),
              Text(
                products.errorMessage ?? 'Terjadi kesalahan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, color: kColorPrimary),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.inter(
                    color: kColorPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: products.productCount,
      itemBuilder: (_, i) {
        final interval = Interval(
          (i * 0.12).clamp(0.0, 0.9),
          ((i * 0.12) + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        );
        final slideAnim = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _listAnim, curve: interval));
        final fadeAnim = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: _listAnim, curve: interval));
        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(
            position: slideAnim,
            child: _ProductCard(
              product: products.products[i],
              onDelete: () => _deleteProduct(products.products[i]),
              index: i,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 52,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada produk',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap tombol + untuk menambahkan\nproduk draft pertamamu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onDelete;
  final int index;

  const _ProductCard({
    required this.product,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kColorPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: kColorError,
              size: 22,
            ),
            tooltip: 'Hapus produk',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
