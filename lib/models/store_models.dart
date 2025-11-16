class StoreItemDTO {
  final int id;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final String category;
  final String assetUrl;

  StoreItemDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.assetUrl,
  });

  /// JSON → StoreItemDTO
  factory StoreItemDTO.fromJson(Map<String, dynamic> json) {
    return StoreItemDTO(
      id: json['itemId'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      assetUrl: json['assetUrl'] as String,
    );
  }

  /// StoreItemDTO → JSON
  Map<String, dynamic> toJson() => {
    'itemId': id,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'assetUrl': assetUrl,
  };
}
