// lib/models/model.dart
class Meal {
  final String id;
  final String name;
  final String image;

  const Meal({
    required this.id,
    required this.name,
    required this.image,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['idMeal'] as String,
      name: json['strMeal'] as String,
      image: json['strMealThumb'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strMealThumb': image,
    };
  }
}
