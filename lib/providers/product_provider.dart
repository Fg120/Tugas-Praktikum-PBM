import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';

enum ProductStatus { initial, loading, loaded, adding, deleting, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  List<ProductModel> _products = [];
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  int? _lastErrorCode;

  static const String _keySubmitted = 'has_submitted';

  ProductStatus get status => _status;
  List<ProductModel> get products => List.unmodifiable(_products);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProductStatus.loading;
  bool get isAdding => _status == ProductStatus.adding;
  bool get isDeleting => _status == ProductStatus.deleting;
  bool get isSubmitting => _isSubmitting;
  bool get hasSubmitted => _hasSubmitted;
  int get productCount => _products.length;
  bool get isEmpty => _products.isEmpty;
  bool get isUnauthorized => _lastErrorCode == 401;

  Future<void> fetchProducts({required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    _hasSubmitted = prefs.getBool(_keySubmitted) ?? false;

    _errorMessage = null;
    _lastErrorCode = null;
    _setStatus(ProductStatus.loading);

    try {
      final result = await ProductService.getDraftProducts(token: token);
      _products = result;
      _setStatus(ProductStatus.loaded);
    } on ApiException catch (e) {
      _lastErrorCode = e.statusCode;
      _errorMessage = e.message;
      _setStatus(ProductStatus.error);
    } catch (_) {
      _errorMessage = 'Gagal memuat produk. Periksa koneksi internet kamu.';
      _setStatus(ProductStatus.error);
    }
  }

  Future<bool> addProduct({
    required String token,
    required ProductModel product,
  }) async {
    _errorMessage = null;
    _lastErrorCode = null;
    _setStatus(ProductStatus.adding);

    try {
      final newProduct = await ProductService.addProduct(
        token: token,
        product: product,
      );
      _products = [..._products, newProduct];
      _setStatus(ProductStatus.loaded);
      return true;
    } on ApiException catch (e) {
      _lastErrorCode = e.statusCode;
      _errorMessage = e.message;
      _setStatus(ProductStatus.error);
      return false;
    } catch (_) {
      _errorMessage = 'Gagal menambah produk. Coba lagi.';
      _setStatus(ProductStatus.error);
      return false;
    }
  }

  Future<bool> deleteProduct({
    required String token,
    required int productId,
  }) async {
    _errorMessage = null;

    final deletedProduct = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw StateError('Produk tidak ditemukan di list lokal'),
    );
    final deletedIndex = _products.indexOf(deletedProduct);

    _products = _products.where((p) => p.id != productId).toList();
    _setStatus(ProductStatus.deleting);

    try {
      await ProductService.deleteProduct(token: token, productId: productId);
      _setStatus(ProductStatus.loaded);
      return true;
    } on ApiException catch (e) {
      final list = List<ProductModel>.from(_products);
      list.insert(deletedIndex, deletedProduct);
      _products = list;
      _errorMessage = e.message;
      _setStatus(ProductStatus.error);
      return false;
    } catch (_) {
      final list = List<ProductModel>.from(_products);
      list.insert(deletedIndex, deletedProduct);
      _products = list;
      _errorMessage = 'Gagal menghapus produk. Coba lagi.';
      _setStatus(ProductStatus.error);
      return false;
    }
  }

  Future<String?> submitFinal({
    required String token,
    required String name,
    required double price,
    required String description,
    required String githubUrl,
  }) async {

    _errorMessage = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      final response = await ProductService.submitFinal(
        token: token,
        name: name,
        price: price,
        description: description,
        githubUrl: githubUrl,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySubmitted, true);
      
      _hasSubmitted = true;
      _isSubmitting = false;
      notifyListeners();

      return response['message'] as String? ?? 'Submission berhasil!';
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Gagal melakukan submission. Coba lagi.';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  void reset() async {
    _products = [];
    _status = ProductStatus.initial;
    _errorMessage = null;
    _isSubmitting = false;
    _hasSubmitted = false;
    _lastErrorCode = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySubmitted);
    
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ProductStatus.error) {
      _status = _products.isEmpty
          ? ProductStatus.initial
          : ProductStatus.loaded;
    }
    notifyListeners();
  }

  void _setStatus(ProductStatus status) {
    _status = status;
    notifyListeners();
  }
}
