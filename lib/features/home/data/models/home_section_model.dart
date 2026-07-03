import '../../domain/entities/home_section.dart';
import 'home_content_item_model.dart';

/// Modelo para HomeSection
class HomeSectionModel extends HomeSection {
  const HomeSectionModel({required super.title, required super.contents});

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    return HomeSectionModel(
      title: json['title'] as String? ?? '',
      contents:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => HomeContentItemMapper.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': contents.map(HomeContentItemMapper.toJson).toList(),
    };
  }
}
