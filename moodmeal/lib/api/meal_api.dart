// lib/api/meal_api.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealAPI {
  static const String _baseUrl = "https://www.themealdb.com/api/json/v1/1";

  // Ambil daftar makanan berdasarkan kategori
  static Future<List<dynamic>> fetchMealsByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/filter.php?c=$category"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['meals'] ?? []; // fallback jika null
      } else {
        throw Exception("Gagal mengambil data makanan (Status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan saat mengambil data makanan: $e");
    }
  }

  // Ambil detail makanan berdasarkan ID
  static Future<Map<String, dynamic>> fetchMealDetail(String mealId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/lookup.php?i=$mealId"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return data['meals'][0];
        } else {
          throw Exception("Detail makanan tidak ditemukan");
        }
      } else {
        throw Exception("Gagal mengambil detail makanan (Status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan saat mengambil detail makanan: $e");
    }
  }
}
