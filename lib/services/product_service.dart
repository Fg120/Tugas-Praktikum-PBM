import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  static Future<List<ProductModel>> getDraftProducts({
    required String token,
  }) async {
    final data = await ApiService.get('/products', token: token);

    if (data == null) return [];

    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      if (data['data'] is Map && data['data']['products'] != null) {
        rawList = data['data']['products'] as List<dynamic>;
      } else if (data['data'] is List) {
        rawList = data['data'] as List<dynamic>;
      } else if (data['products'] != null) {
        rawList = data['products'] as List<dynamic>;
      } else {
        rawList = [];
      }
    } else {
      rawList = [];
    }

    return rawList
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ProductModel> addProduct({
    required String token,
    required ProductModel product,
  }) async {
    final data = await ApiService.post(
      '/products',
      token: token,
      body: product.toJson(),
    );

    if (data == null) {
      throw const ApiException(
        'Response kosong dari server saat menambah produk.',
      );
    }

    Map<String, dynamic> productData;
    if (data is Map && data['data'] != null) {
      if (data['data'] is Map && data['data']['product'] != null) {
        productData = data['data']['product'] as Map<String, dynamic>;
      } else {
        productData = data['data'] as Map<String, dynamic>;
      }
    } else {
      productData = data as Map<String, dynamic>;
    }

    return ProductModel.fromJson(productData);
  }

  static Future<void> deleteProduct({
    required String token,
    required int productId,
  }) async {
    await ApiService.delete('/products/$productId', token: token);
  }

  static Future<Map<String, dynamic>> submitFinal({
    required String token,
    required String name,
    required double price,
    required String description,
    required String githubUrl,
  }) async {
    final data = await ApiService.post(
      '/products/submit',
      token: token,
      body: {
        'name': name,
        'price': price,
        'description': description,
        'github_url': githubUrl,
      },
    );

    if (data == null) {
      return {'message': 'Submission berhasil.'};
    }

    return data as Map<String, dynamic>;
  }
}
