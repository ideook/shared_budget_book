class Category {
  final String name;
  final String nameEn;
  Category({required this.name, required this.nameEn});

  // 이미지 경로를 동적으로 생성하기 위한 getter
  String get imagePath => 'assets/images/categories/$nameEn.png';
}
