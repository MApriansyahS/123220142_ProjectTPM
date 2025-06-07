//lib/screens/mood_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/notification_service.dart'; // Tambahan untuk notifikasi
import 'meal_detail_screen.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String? _selectedMood;
  String? _currentCity;
  List<dynamic> _meals = [];
  bool _isLoading = false;

  final Map<String, String> moodToCategory = {
    'Senang': 'Seafood',
    'Sedih': 'Dessert',
    'Stres': 'Beef',
    'Bingung': 'Pasta',
    'Santai': 'Chicken',
  };

  final Map<String, int> timezoneOffset = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  final Map<String, double> ratesToIDR = {
    'IDR': 1.0,
    'USD': 15500.0,
    'EUR': 16800.0,
  };

  StreamSubscription? _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupShakeSensor();
    _scheduleMealNotifications();
  }

  void _setupShakeSensor() {
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      if (event.x.abs() > 5 || event.y.abs() > 5 || event.z.abs() > 5) {
        _shakeToChangeMood();
      }
    });
  }

  void _scheduleMealNotifications() {
    NotificationService.showDailyNotification(1, "MoodMeal", "Saatnya sarapan!", 8, 0);
    NotificationService.showDailyNotification(2, "MoodMeal", "Saatnya makan siang!", 12, 0);
    NotificationService.showDailyNotification(3, "MoodMeal", "Saatnya makan malam!", 18, 0);
  }

  void _shakeToChangeMood() {
    final random = Random();
    final moodList = moodToCategory.keys.toList();
    final newMood = moodList[random.nextInt(moodList.length)];

    if (newMood != _selectedMood) {
      _onMoodSelected(newMood);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mood berubah ke $newMood (via shake)!")),
      );
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          _currentCity = placemarks.first.locality;
        });

        if (_selectedMood == null) {
          final kategori = getCategoryByLocation(_currentCity!);
          _fetchMeals(kategori);
        }
      }
    } catch (e) {
      debugPrint("Lokasi gagal: $e");
    }
  }

  String getCategoryByLocation(String city) {
    final cityLower = city.toLowerCase();
    if (cityLower.contains("jakarta")) return "Seafood";
    if (cityLower.contains("yogyakarta")) return "Dessert";
    if (cityLower.contains("bandung")) return "Chicken";
    if (cityLower.contains("bali")) return "Vegetarian";
    return "Beef";
  }

  Future<void> _fetchMeals(String category) async {
    setState(() {
      _isLoading = true;
      _meals.clear();
    });

    final response = await http.get(
      Uri.parse("https://www.themealdb.com/api/json/v1/1/filter.php?c=$category"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _meals = data['meals'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data dari API")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<double> _getEstimatedPrice(String mealId) async {
    final url = "https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId";
    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final meal = data['meals'][0];

      int ingredientCount = 0;
      for (int i = 1; i <= 20; i++) {
        if ((meal['strIngredient$i'] ?? '').toString().trim().isNotEmpty) {
          ingredientCount++;
        }
      }

      return ingredientCount * 5000;
    }

    return 30000;
  }

  void _onMoodSelected(String mood) {
    setState(() {
      _selectedMood = mood;
    });
    _fetchMeals(moodToCategory[mood]!);
  }

  String _convertTime(TimeOfDay time, int offset) {
    int hour = (time.hour + offset) % 24;
    if (hour < 0) hour += 24;
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Map<String, String> getConvertedTimes() {
    final now = TimeOfDay.now();
    Map<String, String> converted = {};
    timezoneOffset.forEach((zone, offset) {
      converted[zone] = _convertTime(now, offset - timezoneOffset['WIB']!);
    });
    return converted;
  }

  Map<String, String> getConvertedPrices(double hargaIDR) {
    Map<String, String> result = {};
    ratesToIDR.forEach((curr, rate) {
      double val = hargaIDR / rate;
      result[curr] = curr == 'IDR'
          ? "Rp${hargaIDR.toStringAsFixed(0)}"
          : "${val.toStringAsFixed(2)} $curr";
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final waktuKonversi = getConvertedTimes();

    return Scaffold(
      appBar: AppBar(
        title: const Text("MoodMeal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: () async {
              setState(() {
                _selectedMood = null;
                _meals.clear();
                _isLoading = false;
              });
              await _getCurrentLocation();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentCity != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Deteksi Lokasi: $_currentCity",
                  style: const TextStyle(fontSize: 16)),
            ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 10,
              children: moodToCategory.keys.map((mood) {
                return ChoiceChip(
                  label: Text(mood),
                  selected: _selectedMood == mood,
                  onSelected: (_) => _onMoodSelected(mood),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const Text(
                        "Waktu Saat Ini di Zona Lain:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...waktuKonversi.entries.map((e) => Text("${e.key}: ${e.value}")),
                      const SizedBox(height: 24),

                      const Text(
                        "Rekomendasi Makanan:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ..._meals.map((meal) {
                        return FutureBuilder<double>(
                          future: _getEstimatedPrice(meal['idMeal']),
                          builder: (context, snapshot) {
                            final hargaIDR = snapshot.data ?? 30000;
                            final hargaKonversi = getConvertedPrices(hargaIDR);

                            return Card(
                              child: ListTile(
                                leading: Image.network(meal['strMealThumb'], width: 50),
                                title: Text(meal['strMeal']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: hargaKonversi.entries
                                      .map((e) => Text("${e.key}: ${e.value}"))
                                      .toList(),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MealDetailScreen(mealId: meal['idMeal']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
