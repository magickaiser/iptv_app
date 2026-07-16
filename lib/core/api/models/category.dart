/// Represents a content category (live TV, movies, or series).
class Category {
  final int categoryId;
  final String name;

  const Category({
    required this.categoryId,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      name: json['category_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category_name': name,
      };
}
