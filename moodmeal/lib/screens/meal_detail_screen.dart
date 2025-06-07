//lib/screens/meal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealDetailScreen extends StatefulWidget {
  final String mealId;

  const MealDetailScreen({super.key, required this.mealId});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Map<String, dynamic>? _meal;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchMealDetail();
  }

  Future<void> fetchMealDetail() async {
    final url = "https://www.themealdb.com/api/json/v1/1/lookup.php?i=${widget.mealId}";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _meal = data['meals'][0];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal ambil detail makanan")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = _meal?['strIngredient$i'];
      final measure = _meal?['strMeasure$i'];
      if (ingredient != null &&
          ingredient.toString().isNotEmpty &&
          ingredient.toString() != 'null') {
        ingredients.add(
          "${ingredient.toString().trim()}${(measure != null && measure.toString().trim().isNotEmpty) ? ' - ${measure.toString().trim()}' : ''}",
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_meal?['strMeal'] ?? 'Detail'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: () {
              setState(() {
                _loading = true;
              });
              fetchMealDetail();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _meal?['strMealThumb'] ?? '',
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _meal?['strMeal'] ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_meal?['strCategory'] != null)
                  Chip(
                    label: Text(_meal?['strCategory'] ?? ''),
                    backgroundColor: Colors.teal[50],
                    avatar: const Icon(Icons.category, color: Colors.teal, size: 18),
                    labelStyle: const TextStyle(color: Colors.teal),
                  ),
                const SizedBox(width: 8),
                if (_meal?['strArea'] != null)
                  Chip(
                    label: Text(_meal?['strArea'] ?? ''),
                    backgroundColor: Colors.orange[50],
                    avatar: const Icon(Icons.place, color: Colors.orange, size: 18),
                    labelStyle: const TextStyle(color: Colors.orange),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (ingredients.isNotEmpty) ...[
              const Text(
                "Bahan-bahan:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...ingredients.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.teal, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
            ],
            const Text(
              "Instruksi:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _meal?['strInstructions'] ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
