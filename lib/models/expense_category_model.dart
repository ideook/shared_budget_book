class ExpenseCategoryModel {
  String id;
  String name;
  String icon;

  ExpenseCategoryModel({required this.id, required this.name, required this.icon});

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseCategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}
